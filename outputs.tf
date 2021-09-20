output "lb_dns_name" {
  value       = var.create_eks ? kubernetes_ingress.ctfd-web.status.0.load_balancer.0.ingress.0.hostname : kubernetes_ingress.ctfd-web.status.0.load_balancer.0.ingress.0.ip
  description = "DNS name for the Load Balancer"
}

output "lb_port" {
  value       = 80
  description = "Port that CTFd is reachable on"
}

output "vpc_id" {
  value       = var.create_eks ? module.vpc.0.vpc_id : null
  description = "Id for the VPC created for CTFd"
}

output "challenge_bucket_arn" {
  value       = var.create_eks ? module.s3.0.challenge_bucket_arn : null
  description = "Challenge bucket arn"
}

output "log_bucket_arn" {
  value       = var.create_eks ? module.s3.0.log_bucket_arn : null
  description = "Logging bucket arn"
}

output "private_subnet_ids" {
  value       = var.create_eks ? module.vpc.0.private_subnet_ids : null
  description = "List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2)"
}

output "public_subnet_ids" {
  value       = var.create_eks ? module.vpc.0.public_subnet_ids : null
  description = "List of public subnets that contain frontend infrastructure (ALB)"
}

output "elasticache_cluster_id" {
  value       = var.create_eks ? module.elasticache.0.elasticache_cluster_id : null
  description = "Id of the ElastiCache cluster"
}

output "rds_endpoint_address" {
  value       = var.create_eks ? module.rds.0.rds_endpoint_address : null
  description = "Endpoint address for RDS"
}

output "rds_id" {
  value       = var.create_eks ? module.rds.0.rds_id : null
  description = "Id of RDS cluster"
}

output "rds_port" {
  value       = var.create_eks ? module.rds.0.rds_port : null
  description = "Port for RDS"
}

output "db_password" {
  value       = var.k8s_backend ? module.k8s.0.db_password : module.rds.0.rds_password
  description = "Generated password for the database"
  sensitive   = true
}