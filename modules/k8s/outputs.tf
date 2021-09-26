output "db_connection_string" {
  value       = "mysql+pymysql://${var.db_user}:${random_password.password.result}@${local.db_service_name}:${var.db_port}/${var.db_name}"
  description = "connection string for k8s db"
  sensitive   = true
}

output "cache_connection_string" {
  value       = "redis://${local.cache_service_name}:${var.cache_port}"
  description = "connection string for k8s cache"
}

output "db_password" {
  value       = random_password.password.result
  description = "password for db"
  sensitive   = true
}
