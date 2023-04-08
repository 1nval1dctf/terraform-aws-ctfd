terraform {
  required_version = ">= 1.0.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

resource "docker_container" "ctfd" {
  name  = "ctfd"
  image = docker_image.ctfd.image_id
  user  = "root"
  env = [
    "UPLOAD_FOLDER=${local.upload_dir}",
    "DATABASE_URL=mysql+pymysql://${var.db_user}:${random_password.db_password.result}@${docker_container.db.name}/${var.db_name}",
    "REDIS_URL=redis://${docker_container.cache.name}:${local.cache_port}",
    "WORKERS=1",
    "ACCESS_LOG=-",
    "ERROR_LOG=-",
    "REVERSE_PROXY=true",
  ]
  mounts {
    target = local.upload_dir
    type   = "tmpfs"
  }
  restart = "always"
  ports {
    internal = 8000
    external = var.web_port
  }
  networks_advanced {
    name = docker_network.internal.id
  }
}

resource "docker_image" "ctfd" {
  name = var.ctfd_image
}
