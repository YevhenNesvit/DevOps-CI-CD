output "jenkins_url" {
  description = "Jenkins service URL"
  value       = "http://${data.kubernetes_service.jenkins.status.0.load_balancer.0.ingress.0.hostname}:8080"
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = var.jenkins_namespace
}

output "jenkins_service_account_role_arn" {
  description = "Jenkins service account IAM role ARN"
  value       = aws_iam_role.jenkins_service_account.arn
}

# Отримання інформації про Jenkins service
data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = var.jenkins_namespace
  }
  depends_on = [helm_release.jenkins]
}