resource "kubernetes_namespace" "metrics_server" {
  count = var.create_eks ? 1 : 0
  metadata {
    name = local.metrics_namespace
  }
}

resource "aws_eks_fargate_profile" "metrics_server" {
  count                  = var.create_eks ? 1 : 0
  cluster_name           = module.eks[0].eks_cluster_id
  fargate_profile_name   = "metrics-server"
  pod_execution_role_arn = module.eks[0].fargate_iam_role_arn
  subnet_ids             = module.vpc[0].private_subnet_ids
  selector {
    namespace = kubernetes_namespace.metrics_server[0].metadata[0].name
  }
}

resource "helm_release" "metrics_server" {
  count      = var.create_eks ? 1 : 0
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  namespace  = kubernetes_namespace.metrics_server[0].metadata[0].name

  values = [
    <<EOT
      tollerations:
        key: "eks.amazonaws.com/compute-type"
        value: "fargate"
        effect: "NoExecute"
    EOT
  ]
  depends_on = [
    aws_eks_fargate_profile.metrics_server[0]
  ]
}