provider "aws" {
  region = var.aws_region
}

provider "docker" {
  registry_auth {
    address  = var.registry_server
    username = var.registry_username
    password = var.registry_password
  }
}
