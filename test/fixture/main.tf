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
  region = var.aws_region
}

module "test" {
  source                         = "../../"
  force_destroy_challenge_bucket = true
  db_deletion_protection         = false
  elasticache_cluster_instances  = 2
  asg_instance_type              = "t3.medium"
  asg_min_size                   = 1
  workers                        = 5
  worker_connections             = 5000
  ctfd_version                   = "3.2.1"
  db_engine_mode                 = "serverless"
  db_skip_final_snapshot         = true
}
