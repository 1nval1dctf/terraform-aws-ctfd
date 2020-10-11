# Create a VPC to launch our instances into
module "vpc" {
  source               = "cloudposse/vpc/aws"
  version              = "0.17.0"
  name                 = "${var.app_name}-vpc"
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
}

# Grab the list of availability zones
data "aws_availability_zones" "available" {}

# Create subnets to launch our instances into
# creates both private and public subnets
module "subnets" {
  source             = "cloudposse/dynamic-subnets/aws"
  version            = "0.30.0"
  availability_zones = [data.aws_availability_zones.available.names[0],data.aws_availability_zones.available.names[1]]
  vpc_id             = module.vpc.vpc_id
  igw_id             = module.vpc.igw_id
  cidr_block         = module.vpc.vpc_cidr_block
  max_subnet_count   = 2
}

# Create a security group for instances that require outbound internet access.
# todo, remove once new AMI is created and this no longer needs internet access
resource "aws_security_group" "outbound" {
  name        = "outbound_security_group"
  description = "Allows outbound access"
  vpc_id      = module.vpc.vpc_id
  # allow all outbound HTTP traffic
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # allow all outbound HTTPS traffic
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "outbound_security_group"
  }
}

# Create an application load balancer security group.
resource "aws_security_group" "alb" {
  name        = "alb_security_group"
  description = "application load balancer security group"
  vpc_id      = module.vpc.vpc_id

  # Inbound HTTP traffic to the load balancer.
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Inbound HTTPS traffic to the load balancer.
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  tags = {
    Name = "alb_security_group"
  }
}

# Create an auto scaling group security group.
resource "aws_security_group" "asg" {
  name        = "asg_security_group"
  description = "auto scaling group security group"
  vpc_id      = module.vpc.vpc_id

  # Allow port 80 from the load balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  tags = {
    Name = "asg_security_group"
  }
}

# Create a security group for outbound connections from the LoadBalancer
resource "aws_security_group" "alb_outboud" {
  name        = "alb_outboud_security_group"
  description = "auto scaling group inbound security group"
  vpc_id      = module.vpc.vpc_id

  # allow outbound traffic to the auto scaling group
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.asg.id]
  }

  tags = {
    Name = "alb_outboud_security_group"
  }
}

# Create an RDS security group.
resource "aws_security_group" "rds" {
  name        = "rds_security_group"
  description = "RDS security group"
  vpc_id      = module.vpc.vpc_id

  # Allow db port from the auto scaling group security group
  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.asg.id]
  }

  # allow outbound traffic to asg
  egress {
    from_port       = 1024
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.asg.id]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# Create an ElastiCache security group.
resource "aws_security_group" "elasticache" {
  name        = "elasticache_security_group"
  description = "ElastiCache security group"
  vpc_id      = module.vpc.vpc_id

  # Allow ElastiCache port from the auto scaling group security group
  ingress {
    from_port       = var.elasticache_cluster_port
    to_port         = var.elasticache_cluster_port
    protocol        = "tcp"
    security_groups = [aws_security_group.asg.id]
  }

  # allow outbound traffic to asg
  egress {
    from_port       = 1024
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.asg.id]
  }

  tags = {
    Name = "elasticache_security_group"
  }
}

# Create a security group for asg to connect out to elastiCache and RDS
resource "aws_security_group" "asg_outboud" {
  name        = "asg_outboud_security_group"
  description = "auto scaling group outbound security group"
  vpc_id      = module.vpc.vpc_id

  # allow outbound traffic to RDS
  egress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
  }

  # allow outbound traffic to ElastiCache
  egress {
    from_port       = var.elasticache_cluster_port
    to_port         = var.elasticache_cluster_port
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticache.id]
  }

  # allow outbound traffic for ntp
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow outbound traffic to LoadBalancer
  egress {
    from_port       = 1024
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  tags = {
    Name = "asg_outboud_security_group"
  }
}