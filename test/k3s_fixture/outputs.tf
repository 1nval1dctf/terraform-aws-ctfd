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