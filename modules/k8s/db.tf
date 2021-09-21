resource "random_password" "password" {
  length  = 16
  special = false
}

resource "kubernetes_persistent_volume_claim" "db_data_claim" {
  metadata {
    name      = "db-data-claim"
    namespace = var.namespace
    labels = {
      content = "db-data"
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
resource "kubernetes_deployment" "ctfd_db" {
  metadata {
    name      = local.db_service_name
    namespace = var.namespace
    labels = {
      service = local.db_service_name
    }
  }
  spec {
    selector {
      match_labels = {
        service = local.db_service_name
        role    = local.db_role
      }
    }
    template {
      metadata {
        labels = {
          service = local.db_service_name
          role    = local.db_role
        }
      }
      spec {
        container {
          name  = "db"
          image = "mariadb:10.4"
          env {
            name  = "MYSQL_PASSWORD"
            value = random_password.password.result
          }
          env {
            name  = "MYSQL_DATABASE"
            value = var.db_name
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = random_password.password.result
          }
          env {
            name  = "MYSQL_USER"
            value = var.db_user
          }
          args = [
            "mysqld",
            "--character-set-server=utf8mb4",
            "--collation-server=utf8mb4_unicode_ci",
            "--wait_timeout=28800",
            "--log-warnings=0"
          ]
          volume_mount {
            mount_path = "/var/lib/mysql"
            name       = "db-data"
          }
          port {
            container_port = 3306
          }
          liveness_probe {
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 15
            exec {
              command = [
                "mysqladmin",
                "ping",
              ]
            }
          }
          readiness_probe {
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 1
            exec {
              command = [
                "mysqladmin",
                "status",
                "--user=${var.db_user}",
                "--password=${random_password.password.result}",
              ]
            }
          }
        }
        volume {
          name = "db-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.db_data_claim.metadata[0].name
          }
        }
      }
    }
    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "ctfd_db" {
  metadata {
    name      = local.db_service_name
    namespace = var.namespace
    labels = {
      service = local.db_service_name
      role    = local.db_role
    }
  }
  spec {
    selector = {
      service = kubernetes_deployment.ctfd_db.metadata[0].labels.service
    }
    port {
      port        = var.db_port
      target_port = 3306
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}
