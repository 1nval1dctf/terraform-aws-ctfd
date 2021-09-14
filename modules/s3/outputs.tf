output "challenge_bucket_arn" {
  value       = aws_s3_bucket.challenge_bucket.arn
  description = "Challenge bucket arn"
}

output "log_bucket_arn" {
  value       = aws_s3_bucket.log_bucket.arn
  description = "Logging bucket arn"
}