terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38.0"
    }
  }
}

module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  version      = "6.6.1"
  cluster_name = var.ecs_cluster_name

  # Capacity provider
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 20
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }
}
