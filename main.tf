terraform {
  required_version = ">= 0.14.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.34"
    }
  }
}

resource "random_password" "ctfd_secret_key" {
  length  = 24
  special = true
}