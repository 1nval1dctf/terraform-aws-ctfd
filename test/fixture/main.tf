provider "aws" {
  region = var.aws_region
}

module "test" {
  source                         = "../../"
  force_destroy_challenge_bucket = true
  db_deletion_protection         = false
  elasticache_cluster_instances  = 2
  asg_instance_type              = "t4g.medium"
  asg_min_size                   = 1
  workers                        = 5
  worker_connections             = 5000
  ctfd_version                   = "master"
  db_engine_mode                 = "serverless"
  db_skip_final_snapshot         = true
}
