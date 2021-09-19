data "aws_region" "current" {
  count = var.create_eks ? 1 : 0
}

module "load_balancer_controller" {
  count                            = var.create_eks ? 1 : 0
  source                           = "DNXLabs/eks-lb-controller/aws"
  version                          = "0.4.1"
  enabled                          = true
  cluster_identity_oidc_issuer     = module.eks.0.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.0.oidc_provider_arn
  cluster_name                     = module.eks.0.eks_cluster_id
  settings = {
    region = data.aws_region.current.0.name,
    vpcId  = module.vpc.0.vpc_id

    tolerations = [{
      key    = "eks.amazonaws.com/compute-type"
      value  = "fargate"
      effect = "NoExecute"
    }]
  }
  create_namespace = false
  namespace        = "kube-system"
  depends_on = [
    module.eks.0.fargate_profile_ids,
    module.eks,
    module.vpc
  ]
}
