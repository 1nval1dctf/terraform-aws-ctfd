terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.46"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.2"
    }
  }
}

locals {
  alb_namespace        = "alb-controller"
  metrics_namespace    = "metrics-server"
  fluent_bit_namespace = "aws-cloudwatch-logs"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_iam_role" "worker_role" {
  name = module.eks.worker_iam_role_name
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.18.0"
  cluster_name    = var.eks_cluster_name
  cluster_version = "1.20"
  subnets         = var.private_subnet_ids
  vpc_id          = var.vpc_id
  # needed for OpenID Connect Provider
  enable_irsa = true
  # avoid the need for aws-iam-authenticator
  kubeconfig_aws_authenticator_command      = "aws"
  kubeconfig_aws_authenticator_command_args = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
  map_users                                 = var.eks_users
  # workers_group_defaults = {
  #   root_volume_type = "gp2"
  # }
  # worker_groups = [
  #   {
  #     name                 = "${var.eks_cluster_name}-kube-system-node-group"
  #     instance_type        = "t3.micro"
  #     asg_desired_capacity = 1
  #     asg_min_size         = 1
  #   }
  # ]
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = var.eks_fargate_namespace
        }
      ]
    },
    alb = {
      name = "alb"
      selectors = [
        {
          namespace = local.alb_namespace
        },
      ]
    },
    metrics = {
      name = "metrics"
      selectors = [
        {
          namespace = local.metrics_namespace
        },
      ]
    },
    fluent_bit = {
      name = "fluent_bit"
      selectors = [
        {
          namespace = local.fluent_bit_namespace
        },
      ]
    }
  }
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]
}


data "aws_region" "current" {}

resource "kubernetes_namespace" "metrics-server" {
  metadata {
    name = local.metrics_namespace
  }
}

resource "kubernetes_namespace" "alb-controller" {
  metadata {
    name = local.alb_namespace
  }
}

resource "kubernetes_namespace" "fluent_bit" {
  metadata {
    name = local.fluent_bit_namespace
  }
}

module "metrics-server" {
  source               = "cookielab/metrics-server/kubernetes"
  version              = "0.11.1"
  kubernetes_namespace = local.metrics_namespace
  depends_on           = [module.eks.aws_eks_fargate_profile]
  kubernetes_deployment_tolerations = [{
    key      = "eks.amazonaws.com/compute-type"
    value    = "fargate"
    operator = "Equal"
    effect   = "NoExecute"
  }]
}

# module "eks-cloudwatch-logs" {
#   source                           = "DNXLabs/eks-cloudwatch-logs/aws"
#   version                          = "0.1.3"
#   cluster_name                     = module.eks.cluster_id
#   cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
#   cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
#   worker_iam_role_name             = module.eks.worker_iam_role_name
#   region                           = data.aws_region.current.name
#   namespace                        = local.fluent_bit_namespace
#   create_namespace                 = false
#   depends_on                       = [module.eks]
#   settings = {
#     tolerations = [{
#       key = "eks.amazonaws.com/compute-type"
#       value = "fargate'"
#       effect = "NoExecute"
#     }]
#   }
# }

module "load_balancer_controller" {
  source                           = "DNXLabs/eks-lb-controller/aws"
  version                          = "0.4.1"
  enabled                          = true
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  cluster_name                     = module.eks.cluster_id
  depends_on                       = [module.eks.aws_eks_fargate_profile]
  settings = {
    region      = data.aws_region.current.name,
    vpcId       = var.vpc_id
    tolerations = <<EOT
    [{
      key = "eks.amazonaws.com/compute-type"
      value = "fargate"
      effect = "NoExecute"
    }]
    EOT
  }
  create_namespace = false
  namespace        = local.alb_namespace
}