#annoying that we need this, even when not used
provider "aws" {
  region = "us-east-1"
}

module "ctfd" {
  source       = "../../"
  ctfd_version = "3.3.0"
  db_user      = "ctfd"
  db_name      = "ctfd"
  k8s_backend  = true
  k8s_config   = "~/.kube/config"
  create_eks   = false
}