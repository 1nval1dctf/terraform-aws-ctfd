locals {
  registry_cred_name              = "regcred"
  service_name                    = "ctfd"
  role                            = "web"
  namespace                       = "default"
  log_dir                         = "/var/log/CTFd"
  access_log                      = "${local.log_dir}/access.log"
  error_log                       = "${local.log_dir}/error.log"
  fargate_pod_execution_role_name = "AmazonEKSFargatePodExecutionRole"
}
