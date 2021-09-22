#PV for ctfd logs
resource "aws_efs_access_point" "ctfd_logs" {
  file_system_id = module.efs.id
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
        volume_handle = "${module.efs.id}::${aws_efs_access_point.ctfd_logs.id}"
      }
    }
  }
  depends_on = [
    module.efs,
    aws_efs_access_point.ctfd_logs
  ]
}

#PV for ctfd uploads
resource "aws_efs_access_point" "ctfd_uploads" {
  file_system_id = module.efs.id
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
        volume_handle = "${module.efs.id}::${aws_efs_access_point.ctfd_uploads.id}"
      }
    }
  }
  depends_on = [
    module.efs,
    aws_efs_access_point.ctfd_uploads
  ]
}