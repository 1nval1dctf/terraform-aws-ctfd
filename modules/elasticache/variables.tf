variable "app_name" {
  type        = string
  default     = "ctfd"
  description = "Name of application (eg: \"ctfd\")"
}

variable "vpc_id" {
  type        = string
  description = "Id for the VPC for CTFd"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
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

variable "elasticache_encryption_key_arn" {
  type        = string
  description = "Encryption key for use with ElastiCache at-rest encryption. Unencrypted if this is empty."
  default     = ""
}