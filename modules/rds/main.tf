terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.36.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

# Create a subnet group with all of our RDS subnets. The group will be applied to the database cluster.
resource "aws_db_subnet_group" "default" {
  name        = "${var.app_name}-db-subnet"
  subnet_ids  = var.private_subnet_ids
  description = "${var.app_name} RDS subnet group"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

#tfsec:ignore:AWS051
resource "aws_rds_cluster" "ctfdb" {
  cluster_identifier              = "${var.app_name}-db-cluster"
  database_name                   = var.db_name
  master_username                 = var.db_user
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default.name
  master_password                 = random_password.password.result
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_subnet_group_name            = aws_db_subnet_group.default.name
  engine                          = var.db_engine
  engine_mode                     = "provisioned"
  engine_version                  = var.db_engine_version
  apply_immediately               = true
  final_snapshot_identifier       = "${var.app_name}-db-cluster"
  skip_final_snapshot             = var.db_skip_final_snapshot
  deletion_protection             = var.db_deletion_protection
  enabled_cloudwatch_logs_exports = var.db_serverless ? null : ["audit", "error", "general", "slowquery"]
  storage_encrypted               = var.db_serverless ? true : var.rds_encryption_key_arn != "" ? true : null
  backup_retention_period         = 2
  kms_key_id                      = var.rds_encryption_key_arn

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.db_serverless ? [1] : []
    content {
      max_capacity = var.db_serverless_max_capacity
      min_capacity = var.db_serverless_min_capacity
    }
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  cluster_identifier = aws_rds_cluster.ctfdb.id
  instance_class     = var.db_serverless ? "db.serverless" : var.db_cluster_instance_type
  engine_version     = var.db_engine_version
  engine             = var.db_engine
  apply_immediately  = true
}


resource "aws_rds_cluster_parameter_group" "default" {
  name   = "${var.app_name}-db-cluster-pg"
  family = var.db_engine_family

  parameter {
    name         = "character_set_client"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_connection"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_database"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_results"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_server"
    value        = var.character_set
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_connection"
    value        = var.collation
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = var.collation
    apply_method = "immediate"
  }
}
