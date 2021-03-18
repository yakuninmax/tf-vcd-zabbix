# Create Zabbix VM
module zabbix-vm {
  source = "github.com/yakuninmax/tf-vcd-centos-vm"

  vapp             = var.vapp
  template         = var.template
  name             = var.name
  cpus             = var.cpus
  ram              = var.ram
  system_disk_size = var.system_disk_size
  storage_profile  = var.storage_profile != "" ? var.storage_profile : ""

  nics = [
    {
      network = var.network
      ip      = var.internal_ip
    }
  ]

  allow_external_ssh = true
  external_ip        = var.external_ip != "" ? var.external_ip : data.vcd_edgegateway.edge.external_network_ips[0]
  external_ssh_port  = var.external_ssh_port != "" ? var.external_ssh_port : ""
  root_password      = var.root_password != "" ? var.root_password : ""  
}

# Install Zabbix
resource "null_resource" "copy-selinux-policy" {
  depends_on = [ module.zabbix-vm ]

  provisioner "file" {

    connection {
      type     = "ssh"
      user     = var.root_user
      password = module.zabbix-vm.password
      host     = module.zabbix-vm.external-ip
      port     = module.zabbix-vm.external-ssh-port
      timeout  = "15m"
    }

    source      = "${path.module}/zabbix_server_add.te"
    destination = "/tmp/zabbix_server_add.te"
  }
}

resource "null_resource" "install-zabbix" {
  depends_on = [ null_resource.copy-selinux-policy ]
  
  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      user        = var.root_user
      password    = module.zabbix-vm.password
      host        = module.zabbix-vm.external-ip
      port        = module.zabbix-vm.external-ssh-port
      script_path = "/tmp/terraform_%RAND%.sh"
      timeout     = "15m"
    }

    inline = [
                "rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm",
                "yum clean all",
                "yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent mariadb-server policycoreutils checkpolicy setroubleshoot-server",
                "systemctl enable --now mariadb",
                "mysql -e \"UPDATE mysql.user SET Password=PASSWORD('${var.mariadb_root_password}') WHERE User='root';\"",
                "mysql -e \"DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');\"",
                "mysql -e \"DELETE FROM mysql.user WHERE User='';\"",
                "mysql -e \"FLUSH PRIVILEGES;\"",
                "mysql -uroot -p'${var.mariadb_root_password}' -e \"create database zabbix character set utf8 collate utf8_bin;\"",
                "mysql -uroot -p'${var.mariadb_root_password}' -e \"grant all privileges on zabbix.* to zabbix@localhost identified by '${var.zbx_db_password}';\"",
                "mysql -uroot -p'${var.mariadb_root_password}' zabbix -e \"set global innodb_strict_mode='OFF';\"",
                "zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p'${var.zbx_db_password}' zabbix",
                "mysql -uroot -p'${var.mariadb_root_password}' zabbix -e \"set global innodb_strict_mode='ON';\"",
                "sed -i 's/# DBPassword=/DBPassword=${var.zbx_db_password}/' /etc/zabbix/zabbix_server.conf",
                "cp /usr/share/zabbix/conf/zabbix.conf.php.example /etc/zabbix/web/zabbix.conf.php",
                "sed -i \"s/\\['PASSWORD'\\]\\s*=\\s''/\\['PASSWORD'\\] = '${var.zbx_db_password}'/g\" /etc/zabbix/web/zabbix.conf.php",
                "sed -i \"s/;\\s*php_value\\[date.timezone\\] = Europe\\/Riga/php_value\\[date.timezone\\] = Europe\\/Moscow/\" /etc/php-fpm.d/zabbix.conf",
                "checkmodule -M -m -o zabbix_server_add.mod /tmp/zabbix_server_add.te",
                "semodule_package -m zabbix_server_add.mod -o zabbix_server_add.pp",
                "semodule -i zabbix_server_add.pp",
                "setsebool -P httpd_can_network_connect 1",
                "setsebool -P httpd_can_connect_zabbix 1",
                "setsebool zabbix_can_network on",
                "firewall-cmd --add-service={http,https,zabbix-server,zabbix-agent} --permanent",
                "firewall-cmd --reload",
                "systemctl enable --now zabbix-server zabbix-agent httpd"
             ]
  }
}

# Zabbix DNAT rule
resource "vcd_nsxv_dnat" "zabbix-dnat-rule" {
  count = var.external_http_port != "" ? 1 : 0
  
  edge_gateway = data.vcd_edgegateway.edge.name
  network_type = "ext"
  network_name = tolist(data.vcd_edgegateway.edge.external_network)[0].name  

  original_address   = data.vcd_edgegateway.edge.external_network_ips[0]
  original_port      = var.external_http_port
  translated_address = module.zabbix-vm.internal-ip
  translated_port    = "80"
  protocol           = "tcp"

  description = "HTTP to ${module.zabbix-vm.name}"
}

# Zabbix firewall rule
resource "vcd_nsxv_firewall_rule" "zabbix-firewall-rule" {  
  count = var.external_http_port != "" ? 1 : 0

  edge_gateway = data.vcd_edgegateway.edge.name
  name         = "HTTP to ${module.zabbix-vm.name}"

  source {
    ip_addresses = [trimspace(data.http.terraform-external-ip.body)]
  }

  destination {
    ip_addresses = [data.vcd_edgegateway.edge.external_network_ips[0]]
  }

  service {
    protocol = "tcp"
    port     = var.external_http_port
  }
}

# Create Zabbix Windows host group
resource "zabbix_host_group" "windows-group" {
  name = "Windows servers"
}

# Create Zabbix hosts
resource "zabbix_host" "linux-host" {
  count = length(var.zbx_linux_hosts)

  host = var.zbx_linux_hosts[count.index].ip
  name = var.zbx_linux_hosts[count.index].name
  
  interfaces {
    ip = var.zbx_linux_hosts[count.index].ip
    main = true
  }
  
  groups = ["Linux servers"]
  templates = ["Template ICMP Ping"] 
}