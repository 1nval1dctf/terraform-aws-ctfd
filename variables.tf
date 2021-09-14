variable "app_name" {
  type        = string
  default     = "ctfd"
  description = "Name of application (ex: \"ctfd\")"
}

variable "force_destroy_challenge_bucket" {
  type        = bool
  default     = false
  description = "Whether the S3 bucket containing the CTFD challenge data should be force destroyed"
}

variable "elasticache_cluster_id" {
  type        = string
  description = "Id to assign the new ElastiCache cluster"
  default     = "ctfd-cache-cluster"
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
variable "db_cluster_instances" {
  type        = number
  description = "Number of instances to create in the RDS cluster. Only used if db_engine_mode set to `provisioned`"
  default     = 1
}

variable "db_cluster_name" {
  type        = string
  description = "Name of the created RDS cluster"
  default     = "ctfd-db-cluster"
}

variable "db_cluster_instance_type" {
  type        = string
  description = "Type of instances to create in the RDS cluster. Only used if db_engine_mode set to `provisioned`"
  default     = "db.r5.large"
}

variable "db_engine" {
  type        = string
  description = "Engine for the RDS cluster"
  default     = "aurora-mysql"
}

variable "db_engine_mode" {
  type        = string
  description = "Engine mode the RDS cluster, can be `provisioned` or `serverless`"
  default     = "serverless"
}

variable "db_engine_version" {
  type        = string
  description = "Engine version for the RDS cluster"
  default     = "5.7.mysql_aurora.2.07.1"
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
  description = "Minimum capacity for serverless RDS. Only used if db_engine_mode set to `serverless`"
  default     = 1
}

variable "db_serverless_max_capacity" {
  type        = number
  description = "Maximum capacity for serverless RDS. Only used if db_engine_mode set to `serverless`"
  default     = 128
}

variable "https_certificate_arn" {
  type        = string
  description = "SSL Certificate ARN to be used for the HTTPS server."
  default     = ""
}

variable "ctfd_version" {
  type        = string
  description = "Version of CTFd docker image to deploy"
  default     = "latest"
}

variable "allowed_cidr_blocks" {
  type        = list(any)
  description = "Cidr blocks allowed to hit the frontend (ALB)"
  default     = ["0.0.0.0/0"]
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
  description = "Domain to use for the CTFd deployment. Only used if `create_cdn` is `true`"
  default     = ""
}

variable "ctf_domain_zone_id" {
  description = "zone id for the route53 zone for the ctf_domain. Only used if `create_cdn` is `true`"
  default     = ""
}

variable "upload_filesize_limit" {
  type        = string
  description = "Nginx setting `client_max_bosy_size` which limits the max size of any handouts you can upload."
  default     = "100M"
}

variable "registry_server" {
  type        = string
  description = "Container registry server."
  default     = "gitlab.com"
}

variable "registry_username" {
  type        = string
  description = "Username for container registry."
  default     = null
}

variable "registry_password" {
  type        = string
  description = "Password for container registry."
  default     = null
  sensitive   = true
}

variable "ctfd_image" {
  type        = string
  description = "Docker image for the ctfd frontend."
  default     = "ctfd/ctfd"
}

variable "eks_users" {
  description = "Additional AWS users to add to the EKS aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}
variable "force_destroy_log_bucket" {
  type        = bool
  default     = false
  description = "Whether the S3 bucket containing the logging data should be force destroyed"
}