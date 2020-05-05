output "lb_dns_name" {
  value = module.ctfd.lb_dns_name
}

output "s3_bucket_name" {
  value = module.ctfd.s3_bucket.bucket
}

output "rds_password" {
  value = module.ctfd.rds_password
}
