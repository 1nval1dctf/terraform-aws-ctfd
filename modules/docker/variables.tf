variable "ctfd_image" {
  type        = string
  description = "Docker image for the ctfd frontend."
  default     = null
}

variable "db_user" {
  type        = string
  description = "Username for the database"
  default     = "ctfd"
}

variable "db_name" {
  type        = string
  description = "Name for the database"
  default     = "ctfd"
}

variable "web_port" {
  type        = number
  description = "Port to expose CTFd on"
  default     = 8080
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
