output "db_password" {
  value       = module.rds.0.rds_password
  description = "Generated password for the database"
  sensitive   = true
}

output "lb_dns_name" {
  value       = kubernetes_service.ctfd-web.spec[0].cluster_ip
  description = "DNS name for the Load Balancer"
}
output "lb_port" {
  value       = kubernetes_service.ctfd-web.spec[0].port[0].port
  description = "Port that CTFd is reachable on"
}

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.eks.0.kubeconfig
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.0.config_map_aws_auth
}
