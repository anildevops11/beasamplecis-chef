source "vsphere-iso" "linux_base" {
  # ... vCenter connection + ISO boot config specific to your vSphere setup ...
}

build {
  sources = ["source.vsphere-iso.linux_base"]

  provisioner "chef-solo" {
    cookbook_paths = ["../chef/cookbooks"]
    run_list       = ["recipe[serverbuild]", "recipe[cis_level1]"]
  }

  provisioner "shell" {
    inline = ["cloud-init clean", "rm -f /etc/machine-id"]
  }
}
