# see https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html

resource "kubernetes_namespace" "fluent_bit" {
  metadata {
    name = local.fluent_bit_namespace
    labels = {
      aws-observability = "enabled"
    }
  }
}

# https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json
data "aws_iam_policy_document" "fluent_bit" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "fluent_bit" {
  name   = "eks-fargate-logging-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.fluent_bit.json
}

resource "aws_iam_role_policy_attachment" "fluent_bit" {
  policy_arn = aws_iam_policy.fluent_bit.arn
  role       = var.fargate_pod_execution_role_name
}

resource "kubernetes_config_map" "aws_logging" {
  metadata {
    name      = "aws-logging"
    namespace = local.fluent_bit_namespace
  }

  data = {
    "output.conf"  = templatefile("${path.module}/templates/output.conf", { aws_region = data.aws_region.current.name })
    "parsers.conf" = file("${path.module}/templates/parsers.conf")
    "filters.conf" = file("${path.module}/templates/filters.conf")
  }
}