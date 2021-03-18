output "external-ip" {
  value = module.zabbix-vm.external-ip
}

output "external-http-port" {
  value = var.external_http_port
}