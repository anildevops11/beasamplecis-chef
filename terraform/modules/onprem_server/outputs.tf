output "vm_name" {
  value = vsphere_virtual_machine.server.name
}

output "ip_address" {
  value = vsphere_virtual_machine.server.default_ip_address
}

output "vm_id" {
  value = vsphere_virtual_machine.server.id
}
