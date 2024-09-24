resource "docker_container" "cache" {
  name  = "cache"
  image = docker_image.redis.image_id
  mounts {
    target = "/data"
    type   = "tmpfs"
  }
  restart = "always"
  networks_advanced {
    name = docker_network.internal.id
  }
  network_mode = "bridge"
}

resource "docker_image" "redis" {
  name = "redis:4"
}
