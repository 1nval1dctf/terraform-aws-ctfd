locals {
  registry_cred_name = "regcred"
  service_name       = "ctfd"
  role               = "web"
  namespace          = "default"
  log_dir            = "/var/log/CTFd"
  access_log         = "/var/log/CTFd/access.log"
  error_log          = "/var/log/CTFd/error.log"
}