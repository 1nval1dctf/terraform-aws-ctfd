output "s3_bucket" {
  value       = aws_s3_bucket.challenge_bucket
  description = "Challenge bucket arn"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Id for the VPC created for CTFd"
}

output "aws_availability_zones" {
  value       = data.aws_availability_zones.available.names
  description = "list of availability zones ctfd was deployed into"
}

output "private_subnet_ids" {
  value       = module.subnets.private_subnet_ids
  description = "List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2)"
}

output "public_subnet_ids" {
  value       = module.subnets.public_subnet_ids
  description = "List of public subnets that contain frontend infrastructure (ALB)"
}

output "elasticache_cluster_id" {
  value       = aws_elasticache_replication_group.default.id
  description = "Id of the ElastiCache cluster"
}

output "rds_endpoint_address" {
  value       = aws_rds_cluster.ctfdb.endpoint
  description = "Endpoint address for RDS"
}

output "rds_id" {
  value       = aws_rds_cluster.ctfdb.id
  description = "Id of RDS cluster"
}

output "rds_port" {
  value       = var.db_port
  description = "Port for RDS"
}

output "rds_password" {
  value       = random_password.password.result
  description = "Generated password for the database"
}

output "lb_dns_name" {
  value       = aws_lb.lb.dns_name
  description = "DNS name for the Load Balancer"
}

output "lb_dns_zone_id" {
  value       = aws_lb.lb.zone_id
  description = "The canonical hosted zone ID of the Load Balancer"
}