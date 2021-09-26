data "aws_region" "current" {}

module "load_balancer_controller" {
  source                           = "DNXLabs/eks-lb-controller/aws"
  version                          = "0.4.1"
  enabled                          = true
  cluster_identity_oidc_issuer     = var.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = var.oidc_provider_arn
  cluster_name                     = var.eks_cluster_id
  settings = {
    region = data.aws_region.current.name,
    vpcId  = var.vpc_id

    tolerations = [{
      key    = "eks.amazonaws.com/compute-type"
      value  = "fargate"
      effect = "NoExecute"
    }]
  }
  create_namespace = false
  namespace        = "kube-system"

  depends_on = [
    var.fargate_profile_ids,
  ]
}
