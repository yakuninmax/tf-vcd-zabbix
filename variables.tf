variable "cpus" {
  type        = number
  description = "Zabbix VM vCPU count"
  default     = 2
  
}

variable "external_ssh_port" {
  type        = string
  description = "External SSH port"
  default     = ""
}

variable "mariadb_root_password" {
  type        = string
  description = "Mariadb root password"
  #sensitive   = true
}

variable "network" {
  type        = string
  description = "Network name"
}

variable "internal_ip" {
  type        = string
  description = "Zabbix VM internal IP"
  default     = ""
}

variable "ram" {
  type        = number
  description = "Zabbix VM RAM"
  default     = 8
}

variable "root_password" {
  type        = string
  description = "Root password"
  default     = ""
  sensitive   = true
}

variable "root_user" {
  type        = string
  description = "Linux admin user password"
  default     = "root"
}

variable "storage_profile" {
  type        = string
  description = "VM storage profile"
  default     = ""
}

variable "system_disk_size" {
  type        = number
  description = "VM system disk size in gigabytes"
  default     = 20
}

variable "template" {
  type = object({
    catalog = string
    name    = string
  })
  
  description = "CentOS VM template"
}

variable "vapp_name" {
  type        = string
  description = "vAPP name"
}

variable "vcd_url" {
  type        = string
  description = "vCD URL"
}

variable "vcd_user" {
  type        = string
  description = "vCD user name"
}

variable "vcd_password" {
  type        = string
  description = "vCD user password"
  sensitive   = true
}

variable "vcd_org" {
  type = string
  description = "vCD organization name"
}

variable "org_vdc" {
  type = string
  description = "Organization VDC"
}

variable "zbx_db_password" {
  type        = string
  description = "Zabbix database password"
  #sensitive   = true
}

variable "zbx_name" {
  type        = string
  description = "Zabbix VM name"
  default     = "ZBX01"
}

variable "zbx_external_ip" {
  type        = string
  description = "VM external IP address"
  default     = ""
}

variable "zbx_external_port" {
  type        = string
  description = "Zabbix web interface external port"
  default     = ""
}

variable "zbx_linux_hosts" {
  type = list(object({
    name  = string
    ip    = string
  }))

  description = "List of Linux hosts"
  default = []
}

variable "zbx_windows_hosts" {
  type = list(object({
    name  = string
    ip    = string
  }))

  description = "List of Windows hosts"
  default = []
}