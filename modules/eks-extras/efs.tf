data "aws_vpc" "selected" {
  id = var.vpc_id
}
module "efs" {
  source  = "cloudposse/efs/aws"
  version = "0.31.1"
  region  = data.aws_region.current.name
  vpc_id  = var.vpc_id
  subnets = var.private_subnet_ids
  security_group_rules = [
    {
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.selected.cidr_block]
      description = "Allow ingress traffic to EFS from trusted Security Groups"
    }
  ]
}
