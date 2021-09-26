output "ctfd_uploads_persistent_volume" {
  value       = kubernetes_persistent_volume.ctfd_uploads
  description = "Persistent volume for CTFd uploads"
}

output "ctfd_logs_persistent_volume" {
  value       = kubernetes_persistent_volume.ctfd_logs
  description = "Persistent volume for CTFd logs"
}