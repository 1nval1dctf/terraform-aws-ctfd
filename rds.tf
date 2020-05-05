# Create a subnet group with all of our RDS subnets. The group will be applied to the database cluster.  
resource "aws_db_subnet_group" "default" {
  name        = "${var.db_cluster_name}-db-subnet"
  subnet_ids  = module.subnets.private_subnet_ids
  description = "${var.db_cluster_name} RDS subnet group"
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.db_cluster_instances
  identifier         = "${var.db_cluster_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.ctfdb.id
  instance_class     = var.db_cluster_instance_type
  engine_version     = var.db_engine_version
  engine             = var.db_engine
  apply_immediately  = true
}

resource "random_password" "password" {
  length  = 16
  special = false
}


resource "aws_rds_cluster" "ctfdb" {
  cluster_identifier     = var.db_cluster_name
  database_name          = var.db_name
  master_username        = var.db_user
  master_password        = random_password.password.result
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  engine                 = var.db_engine
  #final_snapshot_identifier       = "ctfd-db-snapshot"
  #snapshot_identifier             = "ctfd-db-snapshot"
  skip_final_snapshot             = true
  engine_version                  = var.db_engine_version
  deletion_protection             = var.db_delection_protection
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

}

