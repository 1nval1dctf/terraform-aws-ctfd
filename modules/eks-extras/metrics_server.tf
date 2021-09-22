resource "kubernetes_namespace" "metrics_server" {
  metadata {
    name = local.metrics_namespace
  }
}

resource "aws_eks_fargate_profile" "metrics_server" {
  cluster_name           = var.eks_cluster_id
  fargate_profile_name   = "metrics-server"
  pod_execution_role_arn = var.fargate_iam_role_arn
  subnet_ids             = var.private_subnet_ids
  selector {
    namespace = kubernetes_namespace.metrics_server.metadata[0].name
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  namespace  = kubernetes_namespace.metrics_server.metadata[0].name

  values = [
    <<EOT
      tollerations:
        key: "eks.amazonaws.com/compute-type"
        value: "fargate"
        effect: "NoExecute"
    EOT
  ]
  depends_on = [
    aws_eks_fargate_profile.metrics_server
  ]
}