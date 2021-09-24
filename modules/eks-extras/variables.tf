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

variable "fargate_pod_execution_role_name" {
  description = "The IAM Role that provides permissions for the EKS Fargate Profile."
  type        = string
  default     = null
}