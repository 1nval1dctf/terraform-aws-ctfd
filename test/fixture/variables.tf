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

variable "ctf_domain" {
  type        = string
  description = "Domain to use for the CTFd deployment. Only used if `create_cdn` is `true`"
  default     = null
}

variable "ctf_domain_zone_id" {
  type        = string
  description = "zone id for the route53 zone for the ctf_domain. Only used if `create_cdn` is `true`"
  default     = null
}