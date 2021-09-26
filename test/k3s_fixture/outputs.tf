output "lb_dns_name" {
  value       = module.test.lb_dns_name
  description = "DNS name for the Load Balancer"
}

output "ctfd_connection_string" {
  value       = "http://${module.test.lb_dns_name}:${module.test.lb_port}"
  description = "URL for CTFd"
}
