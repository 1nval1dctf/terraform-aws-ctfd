# Create an RDS security group.
resource "aws_security_group" "rds" {
  name        = "rds_security_group"
  description = "RDS security group"
  vpc_id      = var.vpc_id

  # Allow connections to db port from the frontend security group
  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = var.frontend_security_groups
  }

  # allow outbound traffic to the frontend security group
  egress {
    from_port       = 1024
    to_port         = 65535
    protocol        = "tcp"
    security_groups = var.frontend_security_groups
  }

  tags = {
    Name = "rds-security-group"
  }
}
