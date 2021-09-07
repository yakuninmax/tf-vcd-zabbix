terraform {

  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "~> 3.3.0"
    }
    
    zabbix = {
      source  = "claranet/zabbix"
      version = "~> 0.2" 
    }
  }

  required_version = "~> 1"
}
