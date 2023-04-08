provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = var.create_in_aws ? false : true
  skip_requesting_account_id  = var.create_in_aws ? false : true
}

provider "docker" {
  registry_auth {
    address  = var.registry_server
    username = var.registry_username
    password = var.registry_password
  }
}
