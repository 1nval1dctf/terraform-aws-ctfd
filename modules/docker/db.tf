resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "docker_container" "db" {
  name  = "db"
  image = docker_image.mariadb.image_id
  env = [
    "MARIADB_ROOT_PASSWORD=${random_password.db_password.result}",
    "MARIADB_USER=${var.db_user}",
    "MARIADB_PASSWORD=${random_password.db_password.result}",
    "MARIADB_DATABASE=${var.db_name}"
  ]
  entrypoint = [
    "/usr/local/bin/docker-entrypoint.sh",
    "mysqld",
    "--character-set-server=${var.db_character_set}",
    "--collation-server=${var.db_collation}",
    "--wait_timeout=28800",
    "--log-warnings=0",
  ]
  mounts {
    target = "/var/lib/mysql"
    # For testing otherwise password etc will be preserved and not match the terraform generated one
    type = "tmpfs"
  }
  networks_advanced {
    name = docker_network.internal.id
  }
  network_mode = "bridge"
  restart      = "always"
}

resource "docker_image" "mariadb" {
  name = "mariadb:10.11.2"
}
