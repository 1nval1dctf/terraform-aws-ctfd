terraform {
  required_version = ">= 1.7.3"
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "5.36.0"
    }
  }
}

resource "aws_elasticache_subnet_group" "default" {
  name       = "${var.app_name}-cache-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_parameter_group" "default" {
  name   = "cache-params"
  family = "redis7"
}

#tfsec:ignore:AWS035
#tfsec:ignore:AWS036
resource "aws_elasticache_replication_group" "default" {
  replication_group_id       = "${var.app_name}-cache-cluster"
  description                = "Cache replication group for CTFd"
  node_type                  = var.elasticache_cluster_instance_type
  port                       = var.elasticache_cluster_port
  parameter_group_name       = aws_elasticache_parameter_group.default.name
  subnet_group_name          = aws_elasticache_subnet_group.default.name
  automatic_failover_enabled = true
  security_group_ids         = [aws_security_group.elasticache.id]
  num_cache_clusters         = var.elasticache_cluster_instances
  at_rest_encryption_enabled = var.elasticache_encryption_key_arn != "" ? true : null
  kms_key_id                 = var.elasticache_encryption_key_arn
}
