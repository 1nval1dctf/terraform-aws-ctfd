output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.eks.kubeconfig
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.config_map_aws_auth
}

output "eks_cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
}

output "eks_worker_security_group_id" {
  value = module.eks.worker_security_group_id
}

output "eks_cluster_ca" {
  value = data.aws_eks_cluster.cluster.certificate_authority.0.data
}
output "eks_token" {
  value = data.aws_eks_cluster_auth.cluster.token
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "worker_iam_role_name" {
  value = module.eks.worker_iam_role_name
}

output "fargate_iam_role_arn" {
  value = module.eks.fargate_iam_role_arn
}

output "fargate_profile_ids" {
  value = module.eks.fargate_profile_ids
}

