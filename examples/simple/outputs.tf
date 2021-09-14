output "lb_dns_name" {
  value = module.ctfd.lb_dns_name
}
output "db_password" {
  value     = module.ctfd.db_password
  sensitive = true
}
