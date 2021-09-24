output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.eks.kubeconfig
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.config_map_aws_auth
}

output "eks_cluster_endpoint" {
  value       = data.aws_eks_cluster.cluster.endpoint
  description = "EKS cluster endpoint"
}

output "eks_cluster_id" {
  value       = module.eks.cluster_id
  description = "EKS cluster ID"
}

output "eks_cluster_security_group_id" {
  value       = module.eks.cluster_primary_security_group_id
  description = "EKS cluster primary security group ID"
}

output "eks_worker_security_group_id" {
  value       = module.eks.worker_security_group_id
  description = "EKS cluster worker security group ID"
}

output "eks_cluster_ca" {
  value       = data.aws_eks_cluster.cluster.certificate_authority[0].data
  description = "EKS cluster certificate authority"
}

output "cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "EKS cluster OIDC issuer URL"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "EKS cluster OIDC provider ARN"
}

output "fargate_iam_role_arn" {
  value       = module.eks.fargate_iam_role_arn
  description = "EKS cluster fargate IAM role name"
}

output "fargate_profile_ids" {
  value       = module.eks.fargate_profile_ids
  description = "EKS cluster fargate profile IDs"
}

output "fargate_iam_role_name" {
  value       = module.eks.fargate_iam_role_name
  description = "IAM role name for EKS Fargate pods"
}