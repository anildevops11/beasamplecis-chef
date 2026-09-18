module "web_01" {
  source = "../../modules/onprem_server"

  vm_name          = "web-01"
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  network_id       = var.network_id
  template_uuid    = var.template_uuid
  ssh_user         = var.ssh_user
  ssh_key_path     = var.ssh_key_path
}
