output "lb_dns_name" {
  value       = module.ctfd.lb_dns_name
  description = "DNS name for the Load Balancer"
}

output "lb_port" {
  value       = module.ctfd.lb_port
  description = "Port that CTFd is reachable on"
}

output "db_password" {
  value     = module.ctfd.db_password
  sensitive = true
}