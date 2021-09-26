terraform {
  required_version = ">= 1.0.0"
}

module "test" {
  source            = "../../"
  k8s_backend       = true
  k8s_config        = "~/.kube/k3s_config"
  create_eks        = false
  registry_server   = var.registry_server
  registry_username = var.registry_username
  registry_password = var.registry_password
}