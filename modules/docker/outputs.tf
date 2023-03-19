output "lb_dns_name" {
  value       = "127.0.0.1"
  description = "IP for the Load Balancer"
}

output "lb_port" {
  description = "Port CTFd is listening in"
  value       = var.web_port
}
