output "db_connection_string" {
  value       = "mysql+pymysql://${var.db_user}:${random_password.password.result}@${aws_rds_cluster.ctfdb.endpoint}:${var.db_port}/${var.db_name}"
  description = "connection string for RDS"
  sensitive   = true
}

output "rds_endpoint_address" {
  value       = aws_rds_cluster.ctfdb.endpoint
  description = "Endpoint address for RDS"
}


output "rds_id" {
  value       = aws_rds_cluster.ctfdb.id
  description = "Id of RDS cluster"
}

output "rds_port" {
  value       = var.db_port
  description = "Port for RDS"
}

output "rds_password" {
  value       = random_password.password.result
  description = "Generated password for the database"
  sensitive   = true
}

output "rds_user" {
  value       = var.db_user
  description = "Username for the RDS database"
}

output "rds_db_name" {
  value       = var.db_name
  description = "Name for the database in RDS"
}