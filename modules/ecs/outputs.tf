output "lb_dns_name" {
  value       = aws_lb.ctfd.dns_name
  description = "DNS name for the Load Balancer"
}
