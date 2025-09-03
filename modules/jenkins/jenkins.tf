resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
  }
}

# Service Account для Jenkins з IAM роллю
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = var.jenkins_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_service_account.arn
    }
  }
  depends_on = [kubernetes_namespace.jenkins]
}

# IAM роль для Jenkins Service Account
resource "aws_iam_role" "jenkins_service_account" {
  name = "jenkins-service-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.cluster_endpoint, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(var.cluster_endpoint, "https://", "")}:sub" = "system:serviceaccount:${var.jenkins_namespace}:jenkins"
          }
        }
      }
    ]
  })
}

# Політики для Jenkins Service Account
resource "aws_iam_role_policy" "jenkins_ecr_policy" {
  name = "jenkins-ecr-policy"
  role = aws_iam_role.jenkins_service_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

# Docker registry credentials
resource "kubernetes_secret" "docker_registry" {
  metadata {
    name      = "regcred"
    namespace = var.jenkins_namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.ecr_registry}" = {
          username = "AWS"
          password = data.aws_ecr_authorization_token.token.password
          auth     = base64encode("AWS:${data.aws_ecr_authorization_token.token.password}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.jenkins]
}

# Отримання поточного AWS account ID
data "aws_caller_identity" "current" {}

# Отримання ECR токену
data "aws_ecr_authorization_token" "token" {}

# Створення ConfigMap з Jenkins Configuration as Code
resource "kubernetes_config_map" "jenkins_casc" {
  metadata {
    name      = "jenkins-casc-config"
    namespace = var.jenkins_namespace
  }

  data = {
    "jenkins.yaml" = templatefile("${path.module}/casc-config.yaml", {
      github_username = var.github_username
      github_token    = var.github_token
      ecr_registry    = var.ecr_registry
    })
  }

  depends_on = [kubernetes_namespace.jenkins]
}

# Jenkins Helm Release
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.jenkins_chart_version
  namespace  = var.jenkins_namespace

  values = [
    templatefile("${path.module}/values.yaml", {
      admin_password    = var.jenkins_admin_password
      cpu_request       = var.jenkins_cpu_request
      memory_request    = var.jenkins_memory_request
      cpu_limit         = var.jenkins_cpu_limit
      memory_limit      = var.jenkins_memory_limit
      storage_class     = var.storage_class
      aws_region        = var.aws_region
      ecr_registry      = var.ecr_registry
      aws_account_id    = data.aws_caller_identity.current.account_id
      github_username   = var.github_username
      github_token      = var.github_token
      aws_access_key    = var.aws_access_key
      aws_secret_key    = var.aws_secret_key
    })
  ]

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_service_account.jenkins,
    kubernetes_secret.docker_registry,
    aws_iam_role_policy.jenkins_ecr_policy
  ]

  timeout = 600

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  set {
    name  = "controller.serviceType"
    value = "LoadBalancer"
  }
}

# Додаткові змінні для GitHub та AWS credentials
variable "github_username" {
  description = "GitHub username"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}