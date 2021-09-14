provider "kubernetes" {
  host                   = var.k8s_backend ? null : module.eks.0.eks_cluster_endpoint
  cluster_ca_certificate = var.k8s_backend ? null : base64decode(module.eks.0.eks_cluster_ca)
  config_path            = var.k8s_backend ? var.k8s_config : null
  dynamic "exec" {
    for_each = var.k8s_backend ? [] : [1]
    content {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.0.eks_cluster_id]
      command     = "aws"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = var.k8s_backend ? null : module.eks.0.eks_cluster_endpoint
    cluster_ca_certificate = var.k8s_backend ? null : base64decode(module.eks.0.eks_cluster_ca)
    config_path            = var.k8s_backend ? var.k8s_config : null
    dynamic "exec" {
      for_each = var.k8s_backend ? [] : [1]
      content {
        api_version = "client.authentication.k8s.io/v1alpha1"
        args        = ["eks", "get-token", "--cluster-name", module.eks.0.eks_cluster_id]
        command     = "aws"
      }
    }
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
            name  = "DATABASE_URL"
            value = var.k8s_backend ? module.k8s.0.db_connection_string : module.rds.0.db_connection_string
          }
          env {
            name  = "REDIS_URL"
            value = var.k8s_backend ? module.k8s.0.cache_connection_string : module.elasticache.0.cache_connection_string
          }
          env {
            name  = "SECRET_KEY"
            value = random_password.ctfd_secret_key.result
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
            http_get {
              path = "/themes/core/static/css/main.min.css"
              port = 8000

              http_header {
                name  = "X-Custom-Header"
                value = "liveness-probe"
              }
            }
          }

          readiness_probe {
            http_get {
              path = "/themes/core/static/css/main.min.css"
              port = 8000

              http_header {
                name  = "X-Custom-Header"
                value = "liveness-probe"
              }
            }
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
    type = "NodePort"
  }
  depends_on = [kubernetes_deployment.ctfd]
}

resource "kubernetes_ingress" "ctfd-web" {
  count                  = var.create_eks ? 0 : 1
  wait_for_load_balancer = true
  metadata {
    name      = local.service_name
    namespace = local.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" : "internet-facing"
    }
  }
  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = kubernetes_service.ctfd-web.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
  depends_on = [kubernetes_service.ctfd-web]
}

resource "kubernetes_persistent_volume_claim" "ctfd-logs-claim" {
  metadata {
    name      = "ctfd-logs-claim"
    namespace = local.namespace
    labels = {
      content = "ctfd-log-data"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "100Mi"
      }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_persistent_volume_claim" "ctfd-uploads-claim" {
  metadata {
    name      = "ctfd-uploads-claim"
    namespace = local.namespace
    labels = {
      content = "ctfd-file-upload-data"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  wait_until_bound = false
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