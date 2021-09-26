output "challenge_bucket_id" {
  description = "Challenge bucket name"
  value       = module.test.challenge_bucket_id
}

output "log_bucket_id" {
  description = "Log bucket name"
  value       = module.test.log_bucket_id
}

output "vpc_id" {
  value       = module.test.vpc_id
  description = "VPC ID"
}

output "private_subnet_ids" {
  value       = module.test.private_subnet_ids
  description = "VPC private subnet IDs"
}

output "public_subnet_ids" {
  value       = module.test.public_subnet_ids
  description = "VPC public subnet IDs"
}

output "lb_dns_name" {
  value       = module.test.lb_dns_name
  description = "DNS name for the Load Balancer"
}

output "ctfd_connection_string" {
  value       = "http://${module.test.lb_dns_name}:${module.test.lb_port}"
  description = "URL for CTFd"
}

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.test.kubeconfig
}
