#PV for ctfd logs
resource "aws_efs_access_point" "ctfd_logs" {
  count          = var.create_eks ? 1 : 0
  file_system_id = module.efs[0].id
  root_directory {
    path = "/logs"
    creation_info {
      owner_uid   = 1001
      owner_gid   = 1001
      permissions = "755"
    }
  }
}
resource "kubernetes_persistent_volume" "ctfd_logs" {
  count = var.create_eks ? 1 : 0
  metadata {
    name = "efs-pv-logs"
  }
  spec {
    capacity = {
      storage = "100Mi"
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Recycle" #todo: only for testing
    storage_class_name               = "efs-sc"
    mount_options                    = ["tls"]
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${module.efs[0].id}::${aws_efs_access_point.ctfd_logs[0].id}"
      }
    }
  }
}

#PV for ctfd uploads
resource "aws_efs_access_point" "ctfd_uploads" {
  count          = var.create_eks ? 1 : 0
  file_system_id = module.efs[0].id
  root_directory {
    path = "/uploads"
    creation_info {
      owner_uid   = 1001
      owner_gid   = 1001
      permissions = "755"
    }
  }
}
resource "kubernetes_persistent_volume" "ctfd_uploads" {
  count = var.create_eks ? 1 : 0
  metadata {
    name = "efs-pv-uploads"
  }
  spec {
    capacity = {
      storage = "1Gi"
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Recycle" #todo: only for testing
    storage_class_name               = "efs-sc"
    mount_options                    = ["tls"]
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${module.efs[0].id}::${aws_efs_access_point.ctfd_uploads[0].id}"
      }
    }
  }
}