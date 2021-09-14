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