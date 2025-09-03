variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  type        = string
}

variable "cluster_token" {
  description = "EKS cluster token"
  type        = string
  default     = ""
}

variable "argocd_namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "github_repo_url" {
  description = "GitHub repository URL with helm charts"
  type        = string
}

variable "github_username" {
  description = "GitHub username"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "django-app"
}

variable "app_namespace" {
  description = "Application namespace"
  type        = string
  default     = "default"
}

variable "chart_path" {
  description = "Path to helm chart in repository"
  type        = string
  default     = "charts/django-app"
}

variable "target_revision" {
  description = "Target revision (branch/tag)"
  type        = string
  default     = "main"
}

variable "sync_policy_automated" {
  description = "Enable automated sync policy"
  type        = bool
  default     = true
}

variable "auto_prune" {
  description = "Enable auto prune"
  type        = bool
  default     = true
}

variable "self_heal" {
  description = "Enable self heal"
  type        = bool
  default     = true
}