provider "helm" {
  kubernetes = {
    config_path = "../cluster/kubeconfig"  # Path to kubeconfig copied from master
  }
}
