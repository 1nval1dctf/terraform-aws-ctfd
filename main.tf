terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

module "vpc" {
  count    = var.create_in_aws ? 1 : 0
  source   = "./modules/vpc"
  app_name = var.app_name
}

resource "random_password" "ctfd_secret_key" {
  length  = 24
  special = true
}

module "rds" {
  count                      = var.create_in_aws ? 1 : 0
  source                     = "./modules/rds"
  app_name                   = var.app_name
  vpc_id                     = module.vpc[0].vpc_id
  private_subnet_ids         = module.vpc[0].private_subnet_ids
  db_cluster_instance_type   = var.db_cluster_instance_type
  db_engine                  = var.db_engine
  db_serverless              = var.db_serverless
  db_engine_version          = var.db_engine_version
  db_port                    = var.db_port
  db_user                    = var.db_user
  db_name                    = var.db_name
  db_deletion_protection     = var.db_deletion_protection
  db_skip_final_snapshot     = var.db_skip_final_snapshot
  db_serverless_min_capacity = var.db_serverless_min_capacity
  db_serverless_max_capacity = var.db_serverless_max_capacity
  rds_encryption_key_arn     = var.rds_encryption_key_arn
  character_set              = var.db_character_set
  collation                  = var.db_collation
}

module "elasticache" {
  count                             = var.create_in_aws ? 1 : 0
  source                            = "./modules/elasticache"
  app_name                          = var.app_name
  vpc_id                            = module.vpc[0].vpc_id
  private_subnet_ids                = module.vpc[0].private_subnet_ids
  elasticache_cluster_instances     = var.elasticache_cluster_instances
  elasticache_cluster_instance_type = var.elasticache_cluster_instance_type
  elasticache_cluster_port          = var.elasticache_cluster_port
  elasticache_encryption_key_arn    = var.elasticache_encryption_key_arn
}

module "ecs" {
  count                            = var.create_in_aws ? 1 : 0
  source                           = "./modules/ecs"
  app_name                         = var.app_name
  ecs_cluster_name                 = var.ecs_cluster_name
  vpc_id                           = module.vpc[0].vpc_id
  private_subnet_ids               = module.vpc[0].private_subnet_ids
  public_subnet_ids                = module.vpc[0].public_subnet_ids
  ctfd_image                       = var.ctfd_image
  db_connection_string             = module.rds[0].db_connection_string
  cache_connection_string          = module.elasticache[0].cache_connection_string
  ctfd_secret_key                  = random_password.ctfd_secret_key.result
  registry_username                = var.registry_username
  registry_password                = var.registry_password
  challenge_bucket                 = module.s3[0].challenge_bucket.id
  challenge_bucket_arn             = module.s3[0].challenge_bucket.arn
  frontend_desired_count           = var.frontend_desired_count
  frontend_minimum_healthy_percent = var.frontend_minimum_healthy_percent
  frontend_maximum_percent         = var.frontend_maximum_percent
  ctf_domain                       = var.create_cdn ? null : var.ctf_domain
  ctf_domain_zone_id               = var.create_cdn ? null : var.ctf_domain_zone_id
  create_cdn                       = var.create_cdn
  https_certificate_arn            = var.https_certificate_arn
}

module "s3" {
  count                          = var.create_in_aws ? 1 : 0
  source                         = "./modules/s3"
  app_name                       = var.app_name
  force_destroy_challenge_bucket = var.force_destroy_challenge_bucket
  s3_encryption_key_arn          = var.s3_encryption_key_arn
}

module "cdn" {
  count                    = var.create_in_aws ? var.create_cdn ? 1 : 0 : 0
  source                   = "./modules/cdn"
  ctf_domain               = var.ctf_domain
  app_name                 = var.app_name
  ctf_domain_zone_id       = var.ctf_domain_zone_id
  https_certificate_arn    = var.https_certificate_arn
  force_destroy_log_bucket = var.force_destroy_log_bucket
  origin_domain_name       = var.create_in_aws ? module.ecs[0].lb_dns_name : ""
}

module "docker" {
  count            = var.create_in_aws ? 0 : 1
  source           = "./modules/docker"
  ctfd_image       = var.ctfd_image
  db_character_set = var.db_character_set
  db_collation     = var.db_collation
}
