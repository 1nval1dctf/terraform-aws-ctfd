
output "log_bucket_id" {
  value       = module.cdn.logs.bucket_id
  description = "Logging bucket name"
}
