terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "ctfd" {
  source                            = "../../" # Actually set to "1nval1dctf/ctfd/aws"
  db_deletion_protection            = false
  elasticache_cluster_instance_type = "cache.t2.micro"
  elasticache_cluster_instances     = 2
  db_serverless                     = true
}
