data "aws_vpc" "selected" {
  count = var.create_eks ? 1 : 0
  id    = module.vpc.0.vpc_id
}

module "efs" {
  count   = var.create_eks ? 1 : 0
  source  = "cloudposse/efs/aws"
  version = "0.31.1"
  region  = data.aws_region.current.0.name
  vpc_id  = module.vpc.0.vpc_id
  subnets = module.vpc.0.private_subnet_ids
  security_group_rules = [
    {
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.selected.0.cidr_block]
      description = "Allow ingress traffic to EFS from trusted Security Groups"
    }
  ]
}
