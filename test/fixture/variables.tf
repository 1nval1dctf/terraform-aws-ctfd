variable "aws_region" {
  type        = string
  description = "Region to deploy CTFd into"
  default     = "us-east-1"
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
