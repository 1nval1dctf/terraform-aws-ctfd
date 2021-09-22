variable "vpc_id" {
  type        = string
  description = "Id for the VPC for CTFd"
  default     = null
}

variable "eks_cluster_id" {
  type        = string
  description = "EKS Cluster id"
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
  default     = []
}

variable "fargate_iam_role_arn" {
  type        = string
  description = "ARN for the fargate IAM role for EKS"
  default     = null
}

variable "worker_iam_role_name" {
  type        = string
  description = "Role name for EKS workers"
  default     = null
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "OIDC issuer url for EKS"
  default     = null
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN for EKS"
  default     = null
}

variable "fargate_profile_ids" {
  type        = list(string)
  description = "Fargate profile ID"
  default     = null
}