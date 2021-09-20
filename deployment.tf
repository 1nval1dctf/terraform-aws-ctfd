
resource "kubernetes_secret" "deployment_secrets" {
  metadata {
    name = "deployment-secrets"
  }
  data = {
    "db_connection_string"    = var.k8s_backend ? module.k8s.0.db_connection_string : module.rds.0.db_connection_string
    "ctfd_secret"             = random_password.ctfd_secret_key.result
    "redis_connection_string" = var.k8s_backend ? module.k8s.0.cache_connection_string : module.elasticache.0.cache_connection_string
  }
}

resource "kubernetes_deployment" "ctfd" {
  metadata {
    name      = local.service_name
    namespace = local.namespace
    labels = {
      service = local.service_name
    }
  }
  spec {
    selector {
      match_labels = {
        service = local.service_name
        role    = local.role
      }
    }
    template {
      metadata {
        labels = {
          service = local.service_name
          role    = local.role
        }
      }
      spec {
        toleration {
          key    = "eks.amazonaws.com/compute-type"
          value  = "fargate"
          effect = "NoExecute"
        }
        dynamic "image_pull_secrets" {
          for_each = var.registry_password != null ? [1] : []
          content {
            name = kubernetes_secret.regcred[0].metadata.0.name
          }
        }
        container {
          name  = "frontend"
          image = var.ctfd_image
          env {
            name  = "WORKERS"
            value = 3
          }
          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.deployment_secrets.metadata.0.name
                key  = "db_connection_string"

              }
            }
          }
          env {
            name = "REDIS_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.deployment_secrets.metadata.0.name
                key  = "redis_connection_string"

              }
            }
          }
          env {
            name = "SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.deployment_secrets.metadata.0.name
                key  = "ctfd_secret"

              }
            }
          }
          dynamic "env" {
            for_each = var.k8s_backend ? [] : [1]
            content {
              name  = "UPLOAD_PROVIDER"
              value = "s3"
            }
          }
          dynamic "env" {
            for_each = var.k8s_backend ? [] : [1]
            content {
              name  = "AWS_S3_BUCKET"
              value = module.s3.0.challenge_bucket_arn
            }
          }
          env {
            name  = "LOG_FOLDER"
            value = local.log_dir
          }
          env {
            name  = "REVERSE_PROXY"
            value = true
          }
          env {
            name  = "ACCESS_LOG"
            value = local.access_log
          }
          env {
            name  = "ERROR_LOG"
            value = local.error_log
          }
          dynamic "env" {
            for_each = var.k8s_backend ? [] : [1]
            content {
              name  = "CHALLENGE_BUCKET"
              value = module.s3.0.challenge_bucket_arn
            }
          }
          volume_mount {
            mount_path = local.log_dir
            name       = "logs"
          }
          volume_mount {
            mount_path = "/var/uploads"
            name       = "uploads"
          }
          port {
            container_port = 8000
          }
          resources {
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
            requests = {
              cpu    = "1"
              memory = "512Mi"
            }
          }

          liveness_probe {
            tcp_socket {
              port = 8000
            }
          }

          readiness_probe {
            http_get {
              path = "/themes/core/static/css/main.min.css"
              port = 8000

              http_header {
                name  = "X-Custom-Header"
                value = "readiness-probe"
              }
            }
            initial_delay_seconds = 20
          }
        }
        volume {
          name = "logs"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ctfd-logs-claim.metadata.0.name
          }
        }
        volume {
          name = "uploads"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ctfd-uploads-claim.metadata.0.name
          }
        }
      }
    }
    strategy {
      type = "Recreate"
    }
  }
  depends_on = [
    kubernetes_persistent_volume_claim.ctfd-logs-claim,
    kubernetes_persistent_volume_claim.ctfd-uploads-claim,
    module.eks.0.fargate_profile_ids
  ]
}

resource "kubernetes_service" "ctfd-web" {
  metadata {
    name      = local.service_name
    namespace = local.namespace
    annotations = {
      "alb.ingress.kubernetes.io/target-type" : "ip"
    }
    labels = {
      service = local.service_name
      role    = local.role
    }
  }
  spec {
    selector = {
      service = kubernetes_deployment.ctfd.metadata.0.labels.service
    }
    port {
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
  depends_on = [
    kubernetes_deployment.ctfd
  ]
}

resource "kubernetes_ingress" "ctfd-web" {
  wait_for_load_balancer = true
  metadata {
    name      = local.service_name
    namespace = local.namespace
    annotations = {
      "kubernetes.io/ingress.class" = var.create_eks ? "alb" : "traefik"
      "alb.ingress.kubernetes.io/scheme" : "internet-facing"
    }
  }
  spec {
    rule {
      http {
        path {
          path = var.create_eks ? "/*" : "/"
          backend {
            service_name = kubernetes_service.ctfd-web.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_service.ctfd-web,
    module.load_balancer_controller
  ]

}

resource "kubernetes_horizontal_pod_autoscaler" "ctfd-web" {
  metadata {
    name      = local.service_name
    namespace = local.namespace
  }

  spec {
    max_replicas = 10
    min_replicas = 1

    scale_target_ref {
      kind = "Deployment"
      name = local.service_name
    }
  }
}

resource "kubernetes_secret" "regcred" {
  count = var.registry_password != null ? 1 : 0
  metadata {
    name = local.registry_cred_name
  }
  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "${var.registry_server}": {
      "auth": "${base64encode("${var.registry_username}:${var.registry_password}")}"
    }
  }
}
DOCKER
  }
  type = "kubernetes.io/dockerconfigjson"
}