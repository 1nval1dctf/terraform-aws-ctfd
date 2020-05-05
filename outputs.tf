output "aws_region" {
  value = var.aws_region
}

output "s3_bucket" {
  value = aws_s3_bucket.challenge_bucket
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available.names
}

output "private_subnet_ids" {
  value = module.subnets.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.subnets.public_subnet_ids
}

output "elasticache_cluster_id" {
  value = aws_elasticache_replication_group.default.id
}

output "rds_endpoint_address" {
  value = aws_rds_cluster.ctfdb.endpoint
}

output "rds_port" {
  value = aws_rds_cluster.ctfdb.port
}

output "rds_first_instance" {
  value = aws_rds_cluster_instance.cluster_instances.0
}

output "rds_password" {
  value = random_password.password.result
}

output "lb_dns_name" {
  value = aws_lb.lb.dns_name
}