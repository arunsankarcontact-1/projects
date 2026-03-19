resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress"
  create_namespace = true
  replace    = true  # Forces replace if needed
  atomic     = true  # Roll back on failure

  values = [
    yamlencode({
      controller = {
        hostNetwork = true  # Enable host network
        service = {
          type = "NodePort"
          nodePorts = {
            http  = 30080
            https = 30443
          }
        }
      }
    })
  ]
}
