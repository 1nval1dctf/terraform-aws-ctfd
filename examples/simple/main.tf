module "ctfd" {
  source            = "../../"
  force_destroy_challenge_bucket = true
  db_cluster_instance_type = "db.t2.small"
  db_delection_protection = false
  elasticache_cluster_instance_type = "cache.t2.micro"
  elasticache_cluster_intances = 2
  asg_instance_type = "t2.micro"
  workers = 3
  worker_connections = 3000
  ctfd_version = "2.3.3"
}
