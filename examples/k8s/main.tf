terraform {
  required_version = ">= 1.0.0"
}

module "ctfd" {
  source      = "../../" # Actually set to "1nval1dctf/ctfd/aws"
  db_user     = "ctfd"
  db_name     = "ctfd"
  k8s_backend = true
  k8s_config  = "~/.kube/config"
  create_eks  = false
}
