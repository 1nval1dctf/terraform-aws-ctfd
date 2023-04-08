
variable "ecs_cluster_name" {
  type        = string
  description = "Name of the created ECS cluster"
  default     = "ctfd-ecs"
}

variable "vpc_id" {
  type        = string
  description = "Id for the VPC for CTFd"
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet ids"
}

variable "app_name" {
  type        = string
  default     = "ctfd"
  description = "Name of application (eg: \"ctfd\")"
}


variable "ctfd_image" {
  type        = string
  description = "Docker image for the ctfd frontend."
  default     = "ctfd/ctfd"
}

variable "cache_connection_string" {
  type        = string
  description = "Connection string for cache"
  default     = null
  sensitive   = true
}

variable "db_connection_string" {
  type        = string
  description = "Connection string for db"
  default     = null
  sensitive   = true
}

variable "ctfd_secret_key" {
  type        = string
  description = "Secret key for CTFd"
  default     = null
  sensitive   = true
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

variable "challenge_bucket_arn" {
  type        = string
  default     = null
  description = "Challenge bucket ARN"
}
variable "challenge_bucket" {
  type        = string
  default     = null
  description = "Challenge bucket"
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

variable "frontend_minimum_count" {
  type        = number
  description = "Minimum number of task instances for the frontend service."
  default     = 1
}

variable "frontend_maximum_count" {
  type        = number
  description = "Maximum number of task instances for the frontend service."
  default     = 4
}
