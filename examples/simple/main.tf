terraform {
  required_version = ">= 0.14.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.34"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "ctfd" {
  source                            = "../../"
  force_destroy_challenge_bucket    = true
  db_cluster_instance_type          = "db.t2.small"
  db_deletion_protection            = false
  elasticache_cluster_instance_type = "cache.t2.micro"
  elasticache_cluster_instances     = 2
  asg_instance_type                 = "t2.micro"
  workers                           = 3
  worker_connections                = 3000
  ctfd_version                      = "3.2.1"
}
