output "challenge_bucket_arn" {
  description = "Challenge bucket ARN"
  value       = module.test.challenge_bucket_arn
}

output "log_bucket_arn" {
  description = "Log bucket ARN"
  value       = module.test.log_bucket_arn
}

output "vpc_id" {
  value       = module.test.vpc_id
  description = "VPC ID"
}

output "private_subnet_ids" {
  value       = module.test.private_subnet_ids
  description = "VPC private subnet IDs"
}

output "public_subnet_ids" {
  value       = module.test.public_subnet_ids
  description = "VPC public subnet IDs"
}

output "elasticache_cluster_id" {
  value       = module.test.elasticache_cluster_id
  description = "Elasticache cluster ID"
}

output "rds_endpoint_address" {
  value       = module.test.rds_endpoint_address
  description = "RDS enpoint"
}

output "rds_id" {
  value       = module.test.rds_id
  description = "RDS ID"
}

output "rds_port" {
  value       = module.test.rds_port
  description = "RDS Port"
}

output "rds_password" {
  value       = module.test.db_password
  sensitive   = true
  description = "Generated password for the database"
}

output "lb_dns_name" {
  value       = module.test.lb_dns_name
  description = "DNS name for the Load Balancer"
}

output "lb_port" {
  value       = module.test.lb_port
  description = "Port that CTFd is reachable on"
}

output "ctfd_connection_string" {
  value       = "http://${module.test.lb_dns_name}:${module.test.lb_port}"
  description = "URL for CTFd"
}
output "db_password" {
  value       = module.test.db_password
  sensitive   = true
  description = "Generated password for the database"
}