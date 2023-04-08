output "lb_dns_name" {
  value       = var.create_in_aws ? module.ecs[0].lb_dns_name : module.docker[0].lb_dns_name
  description = "DNS name for the Load Balancer"
}

output "lb_port" {
  value       = var.create_in_aws ? 80 : module.docker[0].lb_port
  description = "Port that CTFd is reachable on"
}

output "vpc_id" {
  value       = var.create_in_aws ? module.vpc[0].vpc_id : null
  description = "Id for the VPC created for CTFd"
}

output "challenge_bucket_id" {
  value       = var.create_in_aws ? module.s3[0].challenge_bucket.id : null
  description = "Challenge bucket name"
}

output "log_bucket_id" {
  value       = var.create_in_aws ? var.create_cdn ? module.cdn[0].log_bucket_id : null : null
  description = "Logging bucket name"
}

output "private_subnet_ids" {
  value       = var.create_in_aws ? module.vpc[0].private_subnet_ids : null
  description = "List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2)"
}

output "public_subnet_ids" {
  value       = var.create_in_aws ? module.vpc[0].public_subnet_ids : null
  description = "List of public subnets that contain frontend infrastructure (ALB)"
}
