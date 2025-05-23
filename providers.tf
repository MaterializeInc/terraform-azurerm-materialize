provider "kubernetes" {
  config_path = "~/.kube/config" # Or use cluster_ca_certificate and token
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config" # Or use cluster_ca_certificate and token
  }
}
