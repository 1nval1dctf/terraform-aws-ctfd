resource "kubernetes_persistent_volume_claim" "cache_data_claim" {
  metadata {
    name      = "cache-data-claim"
    namespace = var.namespace
    labels = {
      content = "cache-data"
    }
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "100Mi"
      }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment" "ctfd_cache" {
  metadata {
    name      = local.cache_service_name
    namespace = var.namespace
    labels = {
      service = local.cache_service_name
    }
  }
  spec {
    selector {
      match_labels = {
        service = local.cache_service_name
        role    = local.cache_role
      }
    }
    template {
      metadata {
        labels = {
          service = local.cache_service_name
          role    = local.cache_role
        }
      }
      spec {
        container {
          name  = "cache"
          image = "redis:4"
          volume_mount {
            mount_path = "/data"
            name       = "data"
          }
          port {
            container_port = 6379
          }
          liveness_probe {
            exec {
              command = [
                "redis-cli",
                "ping",
              ]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
          }
          readiness_probe {
            exec {
              command = [
                "redis-cli",
                "ping",
              ]
            }
            initial_delay_seconds = 5
            period_seconds        = 2
            timeout_seconds       = 1
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.cache_data_claim.metadata[0].name
          }
        }
      }
    }
    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "ctfd_cache" {
  metadata {
    name      = local.cache_service_name
    namespace = var.namespace
    labels = {
      service = local.cache_service_name
      role    = local.cache_role
    }
  }
  spec {
    selector = {
      service = kubernetes_deployment.ctfd_cache.metadata[0].labels.service
    }
    port {
      port        = var.cache_port
      target_port = 6379
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}
