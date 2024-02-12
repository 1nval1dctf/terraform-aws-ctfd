terraform {
  required_version = ">= 1.7.3"
}


module "test" {
  source            = "../../"
  ctfd_image        = var.ctfd_image
  create_in_aws     = false
  registry_server   = var.registry_server
  registry_username = var.registry_username
  registry_password = var.registry_password
}
