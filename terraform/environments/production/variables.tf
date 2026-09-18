variable "resource_pool_id" { type = string }
variable "datastore_id" { type = string }
variable "network_id" { type = string }
variable "template_uuid" { type = string }
variable "ssh_user" { type = string }
variable "ssh_key_path" { type = string }
variable "vsphere_password" {
  type      = string
  sensitive = true
}
