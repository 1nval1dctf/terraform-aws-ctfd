terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }
}

data "aws_region" "current" {}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.20.0"
  cluster_name    = var.eks_cluster_name
  cluster_version = "1.21.2"
  subnets         = concat(var.private_subnet_ids, var.public_subnet_ids)
  fargate_subnets = var.private_subnet_ids
  vpc_id          = var.vpc_id
  # needed for OpenID Connect Provider
  enable_irsa = true
  # avoid the need for aws-iam-authenticator
  kubeconfig_aws_authenticator_command      = "aws"
  kubeconfig_aws_authenticator_command_args = ["eks", "get-token", "--region", data.aws_region.current.name, "--cluster-name", var.eks_cluster_name]
  map_users                                 = var.eks_users

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "kube-system"
        },
        {
          namespace = var.eks_namespace
        }
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

resource "local_file" "kube_ca" {
  content  = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  filename = "${path.module}/.terraform/ca.crt"
}

# Hopefully not needed at some point: https://github.com/hashicorp/terraform-provider-kubernetes/issues/723
resource "null_resource" "k8s_patcher" {
  depends_on = [module.eks[0]]
  triggers = {
    # fire any time the cluster is update in a way that changes its endpoint or auth
    endpoint = data.aws_eks_cluster.cluster.endpoint
    ca_crt   = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  }
  provisioner "local-exec" {
    command = <<EOF
kubectl \
  --server=$KUBESERVER --token=$KUBETOKEN --certificate-authority=$KUBECA \
  patch deployment coredns -n kube-system --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
kubectl \
  --server=$KUBESERVER --token=$KUBETOKEN --certificate-authority=$KUBECA \
  rollout restart -n kube-system deployment coredns
EOF
    environment = {
      KUBESERVER = data.aws_eks_cluster.cluster.endpoint
      KUBETOKEN  = data.aws_eks_cluster_auth.cluster.token
      KUBECA     = local_file.kube_ca.filename
    }
  }
}
