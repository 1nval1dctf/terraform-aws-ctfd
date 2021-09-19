output "challenge_bucket_arn" {
  description = ""
  value       = module.test.challenge_bucket_arn
}

output "log_bucket_arn" {
  description = ""
  value       = module.test.log_bucket_arn
}

output "vpc_id" {
  value = module.test.vpc_id
}

output "private_subnet_ids" {
  value = module.test.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.test.public_subnet_ids
}

output "elasticache_cluster_id" {
  value = module.test.elasticache_cluster_id
}

output "rds_endpoint_address" {
  value = module.test.rds_endpoint_address
}

output "rds_id" {
  value = module.test.rds_id
}

output "rds_port" {
  value = module.test.rds_port
}

output "rds_password" {
  value     = module.test.db_password
  sensitive = true
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
  value     = module.test.db_password
  sensitive = true
}