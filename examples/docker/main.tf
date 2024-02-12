terraform {
  required_version = ">= 1.7.3"
}

module "ctfd" {
  source        = "../../" # Actually set to "1nval1dctf/ctfd/aws"
  db_user       = "ctfd"
  db_name       = "ctfd"
  create_in_aws = false
}
