variable "namespace" {
  type        = string
  description = "namespace for the CTFd deployment in EKS"
  default     = "default"
}

variable "db_port" {
  type        = number
  description = "Port to connect to the DB"
  default     = 3306
}

variable "db_user" {
  type        = string
  description = "Username for the  database"
  default     = "ctfd"
}

variable "db_name" {
  type        = string
  description = "Name for the database"
  default     = "ctfd"
}

variable "cache_port" {
  type        = number
  description = "Port to connect to redis"
  default     = 6379
}
