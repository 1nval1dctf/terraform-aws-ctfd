
variable "ctf_domain" {
  description = "Domain to use for the CTFd deployment."
  default     = null
}

variable "app_name" {
  type        = string
  default     = "ctfd"
  description = "Name of application (ex: \"ctfd\")"
}

variable "ctf_domain_zone_id" {
  description = "zone id for the route53 zone for the ctf_domain."
  default     = null
}

variable "https_certificate_arn" {
  type        = string
  description = "SSL Certificate ARN to be used for the HTTPS server."
  default     = null
}

variable "log_bucket" {
  type        = string
  description = "Bucket for S3 and ALB log data. Logging disabled if empty"
  default     = ""
}

variable "origin_domain_name" {
  type        = string
  description = "Domain for load balancer to be used as origin for CDN"
  default     = null
}
