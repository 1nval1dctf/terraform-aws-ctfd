#annoying that we need this, even when not used
provider "aws" {
  region = "us-east-1"
}

module "ctfd" {
  source      = "1nval1dctf/ctfd/aws"
  db_user     = "ctfd"
  db_name     = "ctfd"
  k8s_backend = true
  k8s_config  = "~/.kube/config"
  create_eks  = false
}