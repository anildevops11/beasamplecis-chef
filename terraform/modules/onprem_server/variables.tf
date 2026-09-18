variable "vm_name" {
  description = "Name for the provisioned virtual machine"
  type        = string
}

variable "resource_pool_id" {
  type = string
}

variable "datastore_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "template_uuid" {
  description = "UUID of the base (unhardened) VM template to clone"
  type        = string
}

variable "guest_os_id" {
  type    = string
  default = "otherLinux64Guest"
}

variable "cpu" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  default = 4096
}

variable "disk_gb" {
  type    = number
  default = 60
}

variable "ssh_user" {
  type = string
}

variable "ssh_key_path" {
  type = string
}
