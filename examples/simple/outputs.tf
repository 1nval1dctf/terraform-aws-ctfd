output "lb_dns_name" {
  value       = module.ctfd.lb_dns_name
  description = "DNS name for the Load Balancer"
}
output "db_password" {
  value       = module.ctfd.db_password
  sensitive   = true
  description = "Generated password for the database"
}
