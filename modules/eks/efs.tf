module "efs" {
  source  = "cloudposse/efs/aws"
  version = "0.31.0"
  region  = data.aws_region.current.name
  vpc_id  = var.vpc_id
  subnets = var.private_subnet_ids
  security_group_rules = [
    {
      type                     = "egress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "-1"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = "Allow all egress trafic"
    },
    {
      type                     = "ingress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      cidr_blocks              = []
      source_security_group_id = var.default_security_group_id
      description              = "Allow ingress traffic to EFS from trusted Security Groups"
    }
  ]
}

#storage class for EFS
resource "kubernetes_storage_class" "ctfd" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
}

#PV of some size 
resource "kubernetes_persistent_volume" "ctfd" {
  metadata {
    name = "efs-pv"
  }
  spec {
    capacity = {
      storage = "5Gi"
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "efs-sc"
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = module.efs.id
      }
    }
  }
  depends_on = [kubernetes_storage_class.ctfd]
}
