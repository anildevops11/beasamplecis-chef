terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.6"
    }
  }
}

resource "vsphere_virtual_machine" "server" {
  name             = var.vm_name
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  num_cpus         = var.cpu
  memory           = var.memory_mb
  guest_id         = var.guest_os_id

  network_interface {
    network_id = var.network_id
  }

  disk {
    label = "disk0"
    size  = var.disk_gb
  }

  clone {
    template_uuid = var.template_uuid # a base OS template, NOT yet hardened
  }
}

resource "null_resource" "chef_bootstrap" {
  depends_on = [vsphere_virtual_machine.server]

  triggers = {
    vm_id = vsphere_virtual_machine.server.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      knife bootstrap ${vsphere_virtual_machine.server.default_ip_address} \
        --ssh-user ${var.ssh_user} \
        --sudo \
        --node-name ${var.vm_name} \
        --run-list 'recipe[serverbuild],recipe[cis_level1]' \
        -i ${var.ssh_key_path}
    EOT
  }
}
