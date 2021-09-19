terraform {
  required_version = ">= 1.0.0"
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
  }
}

resource "aws_elasticache_subnet_group" "default" {
  name       = "${var.app_name}-cache-subnet"
  subnet_ids = var.private_subnet_ids
}

#tfsec:ignore:AWS035
#tfsec:ignore:AWS036
resource "aws_elasticache_replication_group" "default" {
  replication_group_id          = var.elasticache_cluster_id
  replication_group_description = "Cache replication group for CTFd"
  node_type                     = var.elasticache_cluster_instance_type
  port                          = var.elasticache_cluster_port
  parameter_group_name          = "default.redis6.x"
  subnet_group_name             = aws_elasticache_subnet_group.default.name
  automatic_failover_enabled    = true
  security_group_ids            = [aws_security_group.elasticache.id]
  number_cache_clusters         = var.elasticache_cluster_instances
  at_rest_encryption_enabled    = var.elasticache_encryption_key_arn != "" ? true : null
  kms_key_id                    = var.elasticache_encryption_key_arn
}