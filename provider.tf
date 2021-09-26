data "aws_eks_cluster" "cluster" {
  count = var.create_eks ? 1 : 0
  name  = module.eks[0].eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.create_eks ? 1 : 0
  name  = module.eks[0].eks_cluster_id
}
provider "aws" {
  region = var.aws_region
}
provider "kubernetes" {
  host                   = var.create_eks ? data.aws_eks_cluster.cluster[0].endpoint : null
  cluster_ca_certificate = var.create_eks ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
  token                  = var.create_eks ? data.aws_eks_cluster_auth.cluster[0].token : null
  config_path            = var.create_eks ? null : var.k8s_config
}

provider "helm" {
  kubernetes {
    host                   = var.create_eks ? data.aws_eks_cluster.cluster[0].endpoint : null
    cluster_ca_certificate = var.create_eks ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
    token                  = var.create_eks ? data.aws_eks_cluster_auth.cluster[0].token : null
    config_path            = var.create_eks ? null : var.k8s_config
  }
}
provider "kubectl" {
  host                   = var.create_eks ? data.aws_eks_cluster.cluster[0].endpoint : null
  cluster_ca_certificate = var.create_eks ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
  token                  = var.create_eks ? data.aws_eks_cluster_auth.cluster[0].token : null
  config_path            = var.create_eks ? null : var.k8s_config
  load_config_file       = var.create_eks ? false : true
}
