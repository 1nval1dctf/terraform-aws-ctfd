terraform {
  required_version = ">= 1.0.0"
  required_providers {

    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

#annoying that we need this, even when not used
provider "aws" {
  region = var.aws_region
}


module "test" {
  source       = "../../"
  ctfd_version = "3.3.0"
  db_user      = "ctfd"
  db_name      = "ctfd"
  k8s_backend  = true
  k8s_config   = "~/.kube/config"
  create_eks   = false
}
