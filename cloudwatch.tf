resource "kubernetes_namespace" "fluent_bit" {
  count = var.create_eks ? 1 : 0
  metadata {
    name = local.fluent_bit_namespace
  }
}

data "aws_iam_policy" "cloudwatch_logs" {
  count = var.create_eks ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  count      = var.create_eks ? 1 : 0
  role       = module.eks[0].worker_iam_role_name
  policy_arn = data.aws_iam_policy.cloudwatch_logs[0].arn
}

resource "aws_eks_fargate_profile" "fluent_bit" {
  count                  = var.create_eks ? 1 : 0
  cluster_name           = module.eks[0].eks_cluster_id
  fargate_profile_name   = "fluent_bit"
  pod_execution_role_arn = module.eks[0].fargate_iam_role_arn
  subnet_ids             = module.vpc[0].private_subnet_ids
  selector {
    namespace = kubernetes_namespace.fluent_bit[0].metadata[0].name
  }
}

resource "helm_release" "cloudwatch_logs" {
  count      = var.create_eks ? 1 : 0
  name       = "aws-for-fluent-bit"
  chart      = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  namespace  = kubernetes_namespace.fluent_bit[0].metadata[0].name

  set {
    name  = "clusterName"
    value = module.eks[0].eks_cluster_id
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-for-fluent-bit"
  }

  set {
    name  = "cloudWatch.region"
    value = data.aws_region.current[0].name
  }

  set {
    name  = "cloudWatch.logGroupName"
    value = "/aws/eks/${module.eks[0].eks_cluster_id}/$(kubernetes['labels']['app'])"
  }
  depends_on = [
    aws_eks_fargate_profile.fluent_bit
  ]
}
