output "db_password" {
  value       = var.k8s_backend ? module.k8s.0.db_password : module.rds.0.rds_password
  description = "Generated password for the database"
  sensitive   = true
}

output "lb_dns_name" {
  value       = var.create_eks ? kubernetes_service.ctfd-web.spec[0].cluster_ip : kubernetes_ingress.ctfd-web.0.status.0.load_balancer.0.ingress.0.hostname
  description = "DNS name for the Load Balancer"
}
output "lb_port" {
  value       = var.create_eks ? kubernetes_service.ctfd-web.spec[0].port[0].port : 80
  description = "Port that CTFd is reachable on"
}

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = var.create_eks ? module.eks.0.kubeconfig : null
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = var.create_eks ? module.eks.0.config_map_aws_auth : null
}
