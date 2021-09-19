data "aws_vpc" "selected" {
  id = var.vpc_id
}
# Create an ElastiCache security group.
resource "aws_security_group" "elasticache" {
  name        = "elasticache_security_group"
  description = "ElastiCache security group"
  vpc_id      = var.vpc_id

  # Allow ElastiCache port from the frontend security group
  ingress {
    from_port = var.elasticache_cluster_port
    to_port   = var.elasticache_cluster_port
    protocol  = "tcp"
    #security_groups = var.frontend_security_groups
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # allow outbound traffic to the frontend security group
  egress {
    from_port = 1024
    to_port   = 65535
    protocol  = "tcp"
    #security_groups = var.frontend_security_groups
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  tags = {
    Name = "elasticache_security_group"
  }
}