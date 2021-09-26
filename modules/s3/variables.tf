variable "force_destroy_challenge_bucket" {
  type        = bool
  default     = false
  description = "Whether the S3 bucket containing the CTFD challenge data should be force destroyed"
}

variable "force_destroy_log_bucket" {
  type        = bool
  default     = false
  description = "Whether the S3 bucket containing the logging data should be force destroyed"
}

variable "s3_encryption_key_arn" {
  type        = string
  description = "Encryption key for use with S3 bucket at-rest encryption. Unencrypted if this is empty."
  default     = ""
}
