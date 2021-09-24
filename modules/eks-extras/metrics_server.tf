resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  namespace  = "kube-system"

  values = [
    <<EOT
      tollerations:
        key: "eks.amazonaws.com/compute-type"
        value: "fargate"
        effect: "NoExecute"
    EOT
  ]
}