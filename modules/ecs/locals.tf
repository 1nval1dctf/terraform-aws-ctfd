locals {
  container_port = 8000
  access_log     = "-"
  error_log      = "-"
  secrets_arn_list = [
    aws_secretsmanager_secret.database_url.arn,
    aws_secretsmanager_secret.redis_url.arn,
    aws_secretsmanager_secret.ctfd_secret.arn
  ]
}
