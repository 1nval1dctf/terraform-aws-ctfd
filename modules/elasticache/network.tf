data "aws_vpc" "selected" {
  id = var.vpc_id
}
# Create an ElastiCache security group.
resource "aws_security_group" "elasticache" {
  name        = "${var.app_name}_elasticache_security_group"
  description = "ElastiCache security group for ${var.app_name}"
  vpc_id      = var.vpc_id

  # Allow ElastiCache port from the frontend security group
  ingress {
    from_port   = var.elasticache_cluster_port
    to_port     = var.elasticache_cluster_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # allow outbound traffic to the frontend security group
  egress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  tags = {
    Name = "${var.app_name}_elasticache_security_group"
  }
}
