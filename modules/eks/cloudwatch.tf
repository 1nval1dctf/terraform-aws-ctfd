data "aws_iam_policy" "cloudwatch_logs" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = module.eks.worker_iam_role_name
  policy_arn = data.aws_iam_policy.cloudwatch_logs.arn
}

resource "helm_release" "cloudwatch_logs" {
  name       = "aws-for-fluent-bit"
  chart      = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  version    = "0.1.7"
  namespace  = local.fluent_bit_namespace

  set {
    name  = "clusterName"
    value = module.eks.cluster_id
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
    value = "/aws/eks/${module.eks.cluster_id}/$(kubernetes['labels']['app'])"
  }

  values = [
    <<EOT
      tollerations:
        key: "eks.amazonaws.com/compute-type"
        value: "fargate"
        effect: "NoExecute"
    EOT
  ]
}
