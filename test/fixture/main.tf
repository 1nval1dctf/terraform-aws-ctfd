provider "aws" {
  region = var.aws_region
}

module "test" {
  source                            = "../../"
  force_destroy_challenge_bucket    = true
  db_cluster_instance_type          = "db.t2.small"
  db_deletion_protection            = false
  elasticache_cluster_instance_type = "cache.t2.micro"
  elasticache_cluster_instances     = 2
  asg_instance_type                 = "t3a.micro"
  workers                           = 5
  worker_connections                = 5000
  ctfd_version                      = "master"
}
