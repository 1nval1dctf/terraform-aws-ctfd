terraform {
  required_version = ">= 1.0.0"
}

module "test" {
  source      = "../../"
  k8s_backend = true
  k8s_config  = "~/.kube/k3s_config"
  create_eks  = false
}
