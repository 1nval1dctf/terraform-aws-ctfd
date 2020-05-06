output "aws_availability_zones" {
  value = module.test.aws_availability_zones
}

output "s3_bucket_name" {
  description = ""
  value       = module.test.s3_bucket.bucket
}

output "s3_bucket_region" {
  description = ""
  value       = module.test.s3_bucket.region
}

output "vpc_id" {
  value = module.test.vpc_id
}

output "private_subnet_ids" {
  value = module.test.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.test.public_subnet_ids
}

output "elasticache_cluster_id" {
  value = module.test.elasticache_cluster_id
}

output "rds_endpoint_address" {
  value = module.test.rds_endpoint_address
}

output "rds_id" {
  value = module.test.rds_id
}

output "rds_port" {
  value = module.test.rds_port
}

output "rds_password" {
  value = module.test.rds_password
}

output "lb_dns_name" {
  value = module.test.lb_dns_name
}
