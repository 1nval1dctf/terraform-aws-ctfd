# Create a subnet group with all of our RDS subnets. The group will be applied to the database cluster.  
resource "aws_db_subnet_group" "default" {
  name        = "${var.db_cluster_name}-db-subnet"
  subnet_ids  = module.subnets.private_subnet_ids
  description = "${var.db_cluster_name} RDS subnet group"
}


resource "random_password" "password" {
  length  = 16
  special = false
}


resource "aws_rds_cluster" "ctfdb" {
  cluster_identifier              = var.db_cluster_name
  database_name                   = var.db_name
  master_username                 = var.db_user
  master_password                 = random_password.password.result
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_subnet_group_name            = aws_db_subnet_group.default.name
  engine                          = var.db_engine
  engine_mode                     = var.db_engine_mode
  engine_version                  = var.db_engine_version
  apply_immediately               = true
  final_snapshot_identifier       = var.db_cluster_name
  skip_final_snapshot             = var.db_skip_final_snapshot
  deletion_protection             = var.db_deletion_protection
  enabled_cloudwatch_logs_exports = var.db_engine_mode == "serverless" ? null : ["audit", "error", "general", "slowquery"]
  storage_encrypted               = var.db_engine_mode == "serverless" ? null : var.rds_encryption_key_arn != "" ? true : null
  #tfsec:ignore:AWS051
  kms_key_id = var.rds_encryption_key_arn

  dynamic "scaling_configuration" {
    for_each = var.db_engine_mode == "serverless" ? [1] : []
    content {
      auto_pause               = false
      max_capacity             = var.db_serverless_max_capacity
      min_capacity             = var.db_serverless_min_capacity
      seconds_until_auto_pause = 86400
      timeout_action           = "ForceApplyCapacityChange"
    }
  }
}


resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.db_engine_mode == "provisioned" ? var.db_cluster_instances : 0
  identifier         = "${var.db_cluster_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.ctfdb.id
  instance_class     = var.db_cluster_instance_type
  engine_version     = var.db_engine_version
  engine             = var.db_engine
  apply_immediately  = true
}
