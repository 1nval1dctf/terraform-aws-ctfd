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
  region = var.aws_region
}

module "test" {
  source                            = "../../"
  force_destroy_challenge_bucket    = true
  force_destroy_log_bucket          = true
  db_deletion_protection            = false
  elasticache_cluster_instances     = 2
  elasticache_cluster_instance_type = "cache.t3.micro"
  db_serverless                     = true
  db_skip_final_snapshot            = true
  registry_server                   = var.registry_server
  registry_username                 = var.registry_username
  registry_password                 = var.registry_password
  ctfd_image                        = var.ctfd_image
  ctf_domain                        = var.ctf_domain
  ctf_domain_zone_id                = var.ctf_domain_zone_id
}
