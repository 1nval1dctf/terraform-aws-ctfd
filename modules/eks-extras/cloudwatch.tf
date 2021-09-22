resource "kubernetes_namespace" "fluent_bit" {
  metadata {
    name = local.fluent_bit_namespace
  }
}

data "aws_iam_policy" "cloudwatch_logs" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = var.worker_iam_role_name
  policy_arn = data.aws_iam_policy.cloudwatch_logs.arn
}

resource "aws_eks_fargate_profile" "fluent_bit" {
  cluster_name           = var.eks_cluster_id
  fargate_profile_name   = "fluent_bit"
  pod_execution_role_arn = var.fargate_iam_role_arn
  subnet_ids             = var.private_subnet_ids
  selector {
    namespace = kubernetes_namespace.fluent_bit.metadata[0].name
  }
}

resource "helm_release" "cloudwatch_logs" {
  name       = "aws-for-fluent-bit"
  chart      = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  namespace  = kubernetes_namespace.fluent_bit.metadata[0].name

  set {
    name  = "clusterName"
    value = var.eks_cluster_id
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-for-fluent-bit"
  }

  set {
    name  = "cloudWatch.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "cloudWatch.logGroupName"
    value = "/aws/eks/${var.eks_cluster_id}/$(kubernetes['labels']['app'])"
  }
  depends_on = [
    aws_eks_fargate_profile.fluent_bit
  ]
}
