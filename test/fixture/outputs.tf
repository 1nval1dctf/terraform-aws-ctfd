# output "aws_availability_zones" {
#   value = module.test.aws_availability_zones
# }

# output "s3_bucket_name" {
#   description = ""
#   value       = module.test.s3_bucket.bucket
# }

# output "s3_bucket_region" {
#   description = ""
#   value       = module.test.s3_bucket.region
# }

# output "vpc_id" {
#   value = module.test.vpc_id
# }

# output "private_subnet_ids" {
#   value = module.test.private_subnet_ids
# }

# output "public_subnet_ids" {
#   value = module.test.public_subnet_ids
# }

# output "elasticache_cluster_id" {
#   value = module.test.elasticache_cluster_id
# }

# output "rds_endpoint_address" {
#   value = module.test.rds_endpoint_address
# }

# output "rds_id" {
#   value = module.test.rds_id
# }

# output "rds_port" {
#   value = module.test.rds_port
# }

# output "rds_password" {
#   value     = module.test.rds_password
#   sensitive = true
# }
output "lb_dns_name" {
  value       = module.test.lb_dns_name
  description = "DNS name for the Load Balancer"
}

output "lb_port" {
  value       = module.test.lb_port
  description = "Port that CTFd is reachable on"
}

output "ctfd_connection_string" {
  value       = "http://${module.test.lb_dns_name}:${module.test.lb_port}"
  description = "URL for CTFd"
}
output "db_password" {
  value     = module.test.db_password
  sensitive = true
}
output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.test.kubeconfig
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.test.config_map_aws_auth
}