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

module "vpc" {
  source   = "./modules/vpc"
  app_name = var.app_name
}

resource "random_password" "ctfd_secret_key" {
  length  = 24
  special = true
}

module "rds" {
  count                      = var.k8s_backend ? 0 : 1
  source                     = "./modules/rds"
  vpc_id                     = module.vpc.0.vpc_id
  private_subnet_ids         = module.vpc.0.private_subnet_ids
  public_subnet_ids          = module.vpc.0.public_subnet_ids
  frontend_security_groups   = [module.eks.0.eks_worker_security_group_id]
  db_cluster_instances       = var.db_cluster_instances
  db_cluster_name            = var.db_cluster_name
  db_cluster_instance_type   = var.db_cluster_instance_type
  db_engine                  = var.db_engine
  db_engine_mode             = var.db_engine_mode
  db_engine_version          = var.db_engine_version
  db_port                    = var.db_port
  db_user                    = var.db_user
  db_name                    = var.db_name
  db_deletion_protection     = var.db_deletion_protection
  db_skip_final_snapshot     = var.db_skip_final_snapshot
  db_serverless_min_capacity = var.db_serverless_min_capacity
  db_serverless_max_capacity = var.db_serverless_max_capacity
  rds_encryption_key_arn     = var.rds_encryption_key_arn
}

module "elasticache" {
  count                             = var.k8s_backend ? 0 : 1
  source                            = "./modules/elasticache"
  vpc_id                            = module.vpc.0.vpc_id
  private_subnet_ids                = module.vpc.0.private_subnet_ids
  public_subnet_ids                 = module.vpc.0.public_subnet_ids
  frontend_security_groups          = [module.eks.0.eks_worker_security_group_id]
  elasticache_cluster_id            = var.elasticache_cluster_id
  elasticache_cluster_instances     = var.elasticache_cluster_instances
  elasticache_cluster_instance_type = var.elasticache_cluster_instance_type
  elasticache_cluster_port          = var.elasticache_cluster_port
  elasticache_encryption_key_arn    = var.elasticache_encryption_key_arn
}
module "eks" {
  source                    = "./modules/eks"
  vpc_id                    = module.vpc.0.vpc_id
  private_subnet_ids        = module.vpc.0.private_subnet_ids
  public_subnet_ids         = module.vpc.0.public_subnet_ids
  eks_users                 = var.eks_users
  eks_fargate_namespace     = local.namespace
  default_security_group_id = module.vpc.0.default_security_group_id
}

module "s3" {
  source                         = "./modules/s3"
  force_destroy_challenge_bucket = var.force_destroy_challenge_bucket
  s3_encryption_key_arn          = var.s3_encryption_key_arn
  force_destroy_log_bucket       = var.force_destroy_log_bucket
}

module "cdn" {
  count                 = var.create_cdn ? 1 : 0
  source                = "./modules/cdn"
  ctf_domain            = var.ctf_domain
  app_name              = var.app_name
  ctf_domain_zone_id    = var.ctf_domain_zone_id
  https_certificate_arn = var.https_certificate_arn
  log_bucket            = module.s3.0.log_bucket_arn
  origin_domain_name    = kubernetes_service.ctfd-web.status.0.load_balancer.0.ingress.0.hostname
}
