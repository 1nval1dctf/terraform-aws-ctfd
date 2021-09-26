output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.eks.kubeconfig
}

output "eks_cluster_id" {
  value       = module.eks.cluster_id
  description = "EKS cluster ID"
}

output "cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "EKS cluster OIDC issuer URL"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "EKS cluster OIDC provider ARN"
}

output "fargate_profile_ids" {
  value       = module.eks.fargate_profile_ids
  description = "EKS cluster fargate profile IDs"
}

output "fargate_iam_role_name" {
  value       = module.eks.fargate_iam_role_name
  description = "IAM role name for EKS Fargate pods"
}
