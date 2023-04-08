
variable "ctf_domain" {
  type        = string
  description = "Domain to use for the CTFd deployment."
  default     = null
}

variable "app_name" {
  type        = string
  default     = "ctfd"
  description = "Name of application (ex: \"ctfd\")"
}

variable "ctf_domain_zone_id" {
  type        = string
  description = "zone id for the route53 zone for the ctf_domain."
  default     = null
}

variable "https_certificate_arn" {
  type        = string
  description = "SSL Certificate ARN to be used for the HTTPS server."
  default     = null
}

variable "origin_domain_name" {
  type        = string
  description = "Domain for load balancer to be used as origin for CDN"
  default     = null
}

variable "force_destroy_log_bucket" {
  type        = bool
  default     = false
  description = "Whether the S3 bucket containing the logging data should be force destroyed"
}
