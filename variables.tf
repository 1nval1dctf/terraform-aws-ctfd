variable "app_name" {
  type        = string
  default     = "ctfd"
  description = "Name of application (ex: \"ctfd\")"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The top-level CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "force_destroy_challenge_bucket" {
  type        = bool
  default     = false
  description = "Whether the S3 bucket containing the CTFD challenge data should be force destroyed"
}

#  configuration
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
  default     = "cache.m5.large"
}

variable "elasticache_cluster_port" {
  type        = number
  description = "Port to connect to the ElastiCache cluster on"
  default     = 6379
}

# RDS configuration
variable "db_cluster_instances" {
  type        = number
  description = "Number of instances to create in the RDS cluster"
  default     = 1
}

variable "db_cluster_name" {
  type        = string
  description = "Name of the created RDS cluster"
  default     = "ctfd-db-cluster"
}

variable "db_cluster_instance_type" {
  type        = string
  description = "Type of instances to create in the RDS cluster"
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
  default     = "5.7.mysql_aurora.2.07.2"
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

# Frontend Auto Scaling Group Configuration
variable "launch_configuration_name_prefix" {
  type        = string
  description = "Name prefix for the launch configuration"
  default     = "ctfd-web-"
}

variable "asg_min_size" {
  type        = number
  description = "Minimum of instances in frontend auto scaling group"
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "Maximum of instances in frontend auto scaling group"
  default     = 1
}

variable "asg_instance_type" {
  type        = string
  description = "Type of instances in frontend auto scaling group"
  default     = "t3a.micro"
}

# gunicorn variables
variable "workers" {
  type        = number
  description = "Number of workers (processes) for gunicorn. Should be (CPU's *2) + 1) based on CPU's from asg_instance_type"
  default     = 5
}

variable "worker_class" {
  type        = string
  description = "Type of worker class for gunicorn"
  default     = "gevent"
}

variable "worker_connections" {
  type        = number
  description = "Number of worker connections (pseudo-threads) per worker for gunicorn. Should be (CPU's *2) + 1) * 1000. based on CPU's from asg_instance_type"
  default     = 5000
}

variable "log_dir" {
  type        = string
  description = "CTFd log directory"
  default     = "/var/log/CTFd"
}

variable "access_log" {
  type        = string
  description = "CTFd access log location"
  default     = "/var/log/CTFd/access.log"
}

variable "error_log" {
  type        = string
  description = "CTFd error log location"
  default     = "/var/log/CTFd/error.log"
}

variable "worker_temp_dir" {
  type        = string
  description = "temp location for workers"
  default     = "/dev/shm"
}

variable "https_certificate_arn" {
  type        = string
  description = "SSL Certificate ARN to be used for the HTTPS server."
  default     = ""
}

variable "ctfd_version" {
  type        = string
  description = "Version of CTFd to deploy"
}

variable "ctfd_overlay" {
  type        = string
  default     = "most/certainly/does/not/exist"
  description = "Path to compressed package to unpack over the top of the CTFd repository. Used to package custom themes and plugins. Must be a gzip compressed tarball"
}

variable "scripts_dir" {
  type        = string
  description = "Where helper scripts are deployed on EC2 instances of CTFd asg"
  default     = "/opt/ctfd-scripts"
}

variable "ctfd_dir" {
  type        = string
  description = "Where CTFd is cloned to on EC2 instances of CTFd asg"
  default     = "/opt/ctfd"
}

variable "allowed_cidr_blocks" {
  type        = list(any)
  description = "Cidr blocks allowed to hit the frontend (ALB)"
  default     = ["0.0.0.0/0"]
}