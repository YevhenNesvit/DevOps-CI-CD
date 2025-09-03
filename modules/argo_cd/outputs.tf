output "argocd_url" {
  description = "Argo CD server URL"
  value       = "http://${data.kubernetes_service.argocd_server.status.0.load_balancer.0.ingress.0.hostname}"
}

output "argocd_admin_password" {
  description = "Argo CD initial admin password"
  value       = data.kubernetes_secret.argocd_initial_admin_secret.data["password"]
  sensitive   = true
}

output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = var.argocd_namespace
}

output "argocd_application_name" {
  description = "Created Argo CD application name"
  value       = var.app_name
}

# Отримання інформації про Argo CD service
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = var.argocd_namespace
  }
  depends_on = [helm_release.argocd]
}

# Отримання початкового пароля адміністратора
data "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
  }
  depends_on = [helm_release.argocd]
}