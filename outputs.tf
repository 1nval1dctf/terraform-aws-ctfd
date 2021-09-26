output "lb_dns_name" {
  value       = var.create_eks ? kubernetes_ingress.ctfd_web.status[0].load_balancer[0].ingress[0].hostname : kubernetes_ingress.ctfd_web.status[0].load_balancer[0].ingress[0].ip
  description = "DNS name for the Load Balancer"
}

output "lb_port" {
  value       = 80
  description = "Port that CTFd is reachable on"
}

output "vpc_id" {
  value       = var.create_eks ? module.vpc[0].vpc_id : null
  description = "Id for the VPC created for CTFd"
}

output "challenge_bucket_id" {
  value       = var.create_eks ? module.s3[0].challenge_bucket.id : null
  description = "Challenge bucket name"
}

output "log_bucket_id" {
  value       = var.create_eks ? module.s3[0].log_bucket.id : null
  description = "Logging bucket name"
}

output "private_subnet_ids" {
  value       = var.create_eks ? module.vpc[0].private_subnet_ids : null
  description = "List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2)"
}

output "public_subnet_ids" {
  value       = var.create_eks ? module.vpc[0].public_subnet_ids : null
  description = "List of public subnets that contain frontend infrastructure (ALB)"
}

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = var.create_eks ? module.eks[0].kubeconfig : null
}
