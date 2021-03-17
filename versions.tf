terraform {

  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "~> 3.1.0"
    }
    
    zabbix = {
      source  = "claranet/zabbix"
      version = "~> 0.2" 
    }
  }

  required_version = "~> 0.14"
}
