data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Create an RDS security group.
resource "aws_security_group" "rds" {
  name        = "${var.app_name}_rds_security_group"
  description = "RDS security group for ${var.app_name}"
  vpc_id      = var.vpc_id

  # Allow connections to db port from the frontend security group
  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
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
    Name = "${var.app_name}-rds-security-group"
  }
}
