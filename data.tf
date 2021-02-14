locals {
  service_user  = "www-data"
  service_group = "www-data"
  overlay_file  = fileexists(var.ctfd_overlay) ? var.ctfd_overlay : "${path.module}/templates/empty.tar.gz"
}

resource "aws_s3_bucket_object" "ctfd_overlay" {
  bucket = aws_s3_bucket.challenge_bucket.id
  key    = "ctfd_overlay"
  source = local.overlay_file
  etag   = filemd5(local.overlay_file)
}

data "template_file" "db_check" {
  template = file("${path.module}/templates/db_check.sh.tpl")

  vars = {
    DATABASE_HOST = aws_rds_cluster.ctfdb.endpoint
    DATABASE_NAME = var.db_name
    DATABASE_PORT = var.db_port
  }
}

data "template_file" "db_upgrade" {
  template = file("${path.module}/templates/db_upgrade.sh.tpl")

  vars = {
    DATABASE_URL = "mysql+pymysql://${var.db_user}:${random_password.password.result}@${aws_rds_cluster.ctfdb.endpoint}:${var.db_port}/${var.db_name}"
    CTFD_DIR     = var.ctfd_dir
  }
}

data "template_file" "gunicorn_conf" {
  template = file("${path.module}/templates/gunicorn.conf.tpl")

  vars = {
    SERVICE_USER  = local.service_user
    SERVICE_GROUP = local.service_group
  }
}

data "template_file" "gunicorn_service" {
  template = file("${path.module}/templates/gunicorn.service.tpl")

  vars = {
    SCRIPTS_DIR   = var.scripts_dir
    CTFD_DIR      = var.ctfd_dir
    SERVICE_USER  = local.service_user
    SERVICE_GROUP = local.service_group
  }
}

data "template_file" "gunicorn" {
  template = file("${path.module}/templates/gunicorn.sh.tpl")

  vars = {
    DATABASE_URL       = "mysql+pymysql://${var.db_user}:${random_password.password.result}@${aws_rds_cluster.ctfdb.endpoint}:${var.db_port}/${var.db_name}"
    SECRET_KEY         = random_password.ctfd_secret_key.result
    REDIS_URL          = "redis://${aws_elasticache_replication_group.default.primary_endpoint_address}:${var.elasticache_cluster_port}"
    WORKERS            = var.workers
    WORKER_CLASS       = var.worker_class
    WORKER_CONNECTIONS = var.worker_connections
    LOG_DIR            = var.log_dir
    ACCESS_LOG         = var.access_log
    ERROR_LOG          = var.error_log
    WORKER_TEMP_DIR    = var.worker_temp_dir
    CHALLENGE_BUCKET   = aws_s3_bucket.challenge_bucket.id
  }
}

data "template_file" "cloudwatch_agent" {
  template = file("${path.module}/templates/cloudwatch_agent.json.tpl")

  vars = {
    ACCESS_LOG = var.access_log
    ERROR_LOG  = var.error_log
  }
}


data "template_file" "cloud-config" {
  template = file("${path.module}/templates/cloud-config.tpl")

  vars = {
    GUNICORN         = base64encode(data.template_file.gunicorn.rendered)
    CLOUDWATCH_AGENT = base64encode(data.template_file.cloudwatch_agent.rendered)
    LOG_DIR          = var.log_dir
    SCRIPTS_DIR      = var.scripts_dir
    CTFD_REPO        = var.ctfd_repo
    CTFD_DIR         = var.ctfd_dir
    CTFD_OVERLAY     = "${aws_s3_bucket.challenge_bucket.id}/${aws_s3_bucket_object.ctfd_overlay.id}"
    DB_CHECK         = base64encode(data.template_file.db_check.rendered)
    DB_UPGRADE       = base64encode(data.template_file.db_upgrade.rendered)
    GUNICORN_SERVICE = base64encode(data.template_file.gunicorn_service.rendered)
    GUNICORN_SOCKET  = base64encode(templatefile("${path.module}/templates/gunicorn.socket.tpl", { SERVICE_USER = local.service_user }))
    GUNICORN_CONF    = base64encode(data.template_file.gunicorn_conf.rendered)
    NGINX_CONF       = base64encode(templatefile("${path.module}/templates/nginx.conf.tpl", { CTFD_DIR = var.ctfd_dir }))
    CTFD_VERSION     = var.ctfd_version
    SERVICE_USER     = local.service_user
    SERVICE_GROUP    = local.service_group
  }
}

# Render a multi-part cloud-init config making use of the part
# above, and other source files
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud-config.rendered
  }
}
