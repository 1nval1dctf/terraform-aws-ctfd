resource "kubernetes_persistent_volume_claim" "ctfd_logs_claim" {
  metadata {
    name      = "ctfd-logs-claim"
    namespace = local.namespace
    labels = {
      content = "ctfd-log-data"
    }
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.create_eks ? module.eks_extras[0].ctfd_logs_persistent_volume.spec[0].storage_class_name : "local-path"
    resources {
      requests = {
        storage = "100Mi"
      }
    }
  }
  wait_until_bound = var.create_eks ? true : false
  depends_on       = [module.eks_extras[0].ctfd_logs_persistent_volume]
}

resource "kubernetes_persistent_volume_claim" "ctfd_uploads_claim" {
  metadata {
    name      = "ctfd-uploads-claim"
    namespace = local.namespace
    labels = {
      content = "ctfd-file-upload-data"
    }
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.create_eks ? module.eks_extras[0].ctfd_uploads_persistent_volume.spec[0].storage_class_name : "local-path"
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  wait_until_bound = var.create_eks ? true : false
  depends_on       = [module.eks_extras[0].ctfd_uploads_persistent_volume]
}
