variable "app_name" {
  type        = string
  default     = "ctfd"
  description = "Name of application (eg: \"ctfd\")"
}
variable "eks_cluster_name" {
  type        = string
  default     = "ctfd-eks"
  description = "Name of the eks cluster"
}
variable "vpc_cidr_block" {
  type        = string
  description = "The top-level CIDR block for the VPC."
  default     = "10.0.0.0/16"
}
