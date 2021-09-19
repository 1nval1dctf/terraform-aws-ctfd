variable "vpc_id" {
  type        = string
  description = "Id for the VPC for CTFd"
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
  default     = []
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
  default     = []
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the created EKS cluster"
  default     = "ctfd-eks"
}

variable "eks_users" {
  description = "Additional AWS users to add to the EKS aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

variable "eks_namespace" {
  type        = string
  description = "namespace for the CTFd deployment in EKS."
  default     = "default"
}