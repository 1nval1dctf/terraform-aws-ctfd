output "challenge_bucket" {
  value       = aws_s3_bucket.challenge_bucket
  description = "Challenge bucket"
}

output "log_bucket" {
  value       = aws_s3_bucket.log_bucket
  description = "Logging bucket"
}