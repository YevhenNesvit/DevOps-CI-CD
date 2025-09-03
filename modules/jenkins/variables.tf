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

variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_chart_version" {
  description = "Jenkins Helm chart version"
  type        = string
  default     = "5.0.13"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "ecr_registry" {
  description = "ECR registry URL"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "storage_class" {
  description = "Storage class for Jenkins PVC"
  type        = string
  default     = "gp2"
}

variable "jenkins_cpu_request" {
  description = "Jenkins CPU request"
  type        = string
  default     = "1000m"
}

variable "jenkins_memory_request" {
  description = "Jenkins memory request"
  type        = string
  default     = "2Gi"
}

variable "jenkins_cpu_limit" {
  description = "Jenkins CPU limit"
  type        = string
  default     = "2000m"
}

variable "jenkins_memory_limit" {
  description = "Jenkins memory limit"
  type        = string
  default     = "4Gi"
}