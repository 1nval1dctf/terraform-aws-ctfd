variable "app_name" {
  type        = string
  default     = "ctfd"
  description = "Name of application (ex: \"ctfd\")"
}

variable "aws_region" {
  type        = string
  description = "Region to deploy CTFd into"
  default     = "us-east-1"
}

variable "force_destroy_challenge_bucket" {
  type        = bool
  default     = false
  description = "Whether the S3 bucket containing the CTFD challenge data should be force destroyed"
}

variable "elasticache_cluster_instances" {
  type        = number
  description = "Number of instances in ElastiCache cluster"
  default     = 3
}

variable "elasticache_cluster_instance_type" {
  type        = string
  description = "Instance type for instance in ElastiCache cluster"
  default     = "cache.r6g.large"
}

variable "elasticache_cluster_port" {
  type        = number
  description = "Port to connect to the ElastiCache cluster on"
  default     = 6379
}

# RDS configuration
variable "db_serverless" {
  type        = bool
  description = "Configure serverless RDS cluster"
  default     = true
}

variable "db_cluster_instance_type" {
  type        = string
  description = "Type of instances to create in the RDS cluster. Only used if db_serverless set to `false`"
  default     = "db.r5.large"
}

variable "db_engine" {
  type        = string
  description = "Engine for the RDS cluster"
  default     = "aurora-mysql"
}

variable "db_engine_version" {
  type        = string
  description = "Engine version for the RDS cluster"
  default     = "8.0.mysql_aurora.3.02.2"
}

variable "db_port" {
  type        = number
  description = "Port to connect to the RDS cluster on"
  default     = 3306
}

variable "db_user" {
  type        = string
  description = "Username for the RDS database"
  default     = "ctfd"
}

variable "db_name" {
  type        = string
  description = "Name for the database in RDS"
  default     = "ctfd"
}

variable "db_deletion_protection" {
  type        = bool
  description = "If true database will not be able to be deleted without manual intervention"
  default     = true
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "If true database will not be snapshoted before deletion."
  default     = false
}

variable "db_serverless_min_capacity" {
  type        = number
  description = "Minimum capacity for serverless RDS. Only used if db_serverless set to `true`"
  default     = 1
}

variable "db_serverless_max_capacity" {
  type        = number
  description = "Maximum capacity for serverless RDS. Only used if db_serverless set to `true`"
  default     = 128
}

variable "db_character_set" {
  default     = "utf8mb4"
  type        = string
  description = "The database character set."
}

variable "db_collation" {
  default     = "utf8mb4_bin"
  type        = string
  description = "The database collation."
}

variable "https_certificate_arn" {
  type        = string
  description = "SSL Certificate ARN to be used for the HTTPS server."
  default     = ""
}

variable "s3_encryption_key_arn" {
  type        = string
  description = "Encryption key for use with S3 bucket at-rest encryption. Unencrypted if this is empty."
  default     = ""
}

variable "rds_encryption_key_arn" {
  type        = string
  description = "Encryption key for use with RDS at-rest encryption. Unencrypted if this is empty."
  default     = ""
}
variable "elasticache_encryption_key_arn" {
  type        = string
  description = "Encryption key for use with ElastiCache at-rest encryption. Unencrypted if this is empty."
  default     = ""
}

variable "create_cdn" {
  type        = bool
  default     = false
  description = "Whether to create a cloudfront CDN deployment."
}

variable "ctf_domain" {
  type        = string
  description = "Domain to use for the CTFd deployment. Only used if `create_cdn` is `true`"
  default     = ""
}

variable "ctf_domain_zone_id" {
  type        = string
  description = "zone id for the route53 zone for the ctf_domain. Only used if `create_cdn` is `true`"
  default     = ""
}

variable "registry_server" {
  type        = string
  description = "Container registry server. Needed if using a private registry for a custom CTFd image."
  default     = "registry.gitlab.com"
}

variable "registry_username" {
  type        = string
  description = "Username for container registry. Needed if using a private registry for a custom CTFd image."
  default     = null
}

variable "registry_password" {
  type        = string
  description = "Password for container registry. Needed if using a private registry for a custom CTFd image."
  default     = null
  sensitive   = true
}

variable "ctfd_image" {
  type        = string
  description = "Docker image for the ctfd frontend."
  default     = "ctfd/ctfd"
}

variable "frontend_desired_count" {
  type        = number
  description = "Desired number of task instances for the frontend service."
  default     = 2
}

variable "frontend_minimum_healthy_percent" {
  type        = number
  description = "Minimum health percent for the frontend service."
  default     = 75
}
variable "frontend_maximum_percent" {
  type        = number
  description = " health percent for the frontend service."
  default     = 150
}

variable "create_in_aws" {
  type        = bool
  default     = true
  description = "Create AWS resources. If false an instance will be spun up locally with docker"
}

variable "force_destroy_log_bucket" {
  type        = bool
  default     = false
  description = "Whether the S3 bucket containing the logging data should be force destroyed"
}
