terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "test" {
  source                         = "../../"
  force_destroy_challenge_bucket = true
  force_destroy_log_bucket       = true
  db_deletion_protection         = false
  elasticache_cluster_instances  = 2
  db_engine_mode                 = "serverless"
  db_skip_final_snapshot         = true
}
