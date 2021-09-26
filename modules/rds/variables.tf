variable "vpc_id" {
  type        = string
  description = "Id for the VPC for CTFd"
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
  default     = []
}

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

variable "db_engine_family" {
  type        = string
  description = "Family for the RDS cluster"
  default     = "aurora-mysql5.7"
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

variable "rds_encryption_key_arn" {
  type        = string
  description = "Encryption key for use with RDS at-rest encryption. Unencrypted if this is empty."
  default     = ""
}

variable "character_set" {
  default     = "utf8mb4"
  type        = string
  description = "The database character set."
}

variable "collation" {
  default     = "utf8mb4_bin"
  type        = string
  description = "The database collation."
}
