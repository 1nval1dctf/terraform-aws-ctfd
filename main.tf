resource "random_password" "ctfd_secret_key" {
  length  = 24
  special = true
}