output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Id for the VPC created for CTFd"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2)"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "List of public subnets that contain frontend infrastructure (ALB)"
}
