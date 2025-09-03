resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      name = var.argocd_namespace
    }
  }
}

# Secret для Git репозиторію
resource "kubernetes_secret" "github_repo" {
  metadata {
    name      = "github-repo-secret"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    type     = "git"
    url      = var.github_repo_url
    username = var.github_username
    password = var.github_token
  }

  depends_on = [kubernetes_namespace.argocd]
}

# Argo CD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = var.argocd_namespace

  values = [
    templatefile("${path.module}/values.yaml", {
      github_repo_url = var.github_repo_url
      github_username = var.github_username
      github_token    = var.github_token
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    kubernetes_secret.github_repo
  ]

  timeout = 900

  # Додаткові налаштування
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
}

# Argo CD Application для Django додатку
resource "kubernetes_manifest" "django_app_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.app_name
      namespace = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.github_repo_url
        targetRevision = var.target_revision
        path           = var.chart_path
        helm = {
          valueFiles = ["values.yaml"]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.app_namespace
      }
      syncPolicy = var.sync_policy_automated ? {
        automated = {
          prune    = var.auto_prune
          selfHeal = var.self_heal
        }
        syncOptions = [
          "CreateNamespace=true",
          "ApplyOutOfSyncOnly=true"
        ]
      } : {}
    }
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.github_repo
  ]
}

# AppProject для кращої організації
resource "kubernetes_manifest" "default_app_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "django-project"
      namespace = var.argocd_namespace
    }
    spec = {
      description = "Project for Django applications"
      sourceRepos = [var.github_repo_url]
      destinations = [
        {
          namespace = var.app_namespace
          server    = "https://kubernetes.default.svc"
        },
        {
          namespace = "default"
          server    = "https://kubernetes.default.svc"
        }
      ]
      clusterResourceWhitelist = [
        {
          group = ""
          kind  = "*"
        },
        {
          group = "*"
          kind  = "*"
        }
      ]
      namespaceResourceWhitelist = [
        {
          group = ""
          kind  = "*"
        },
        {
          group = "apps"
          kind  = "*"
        },
        {
          group = "extensions"
          kind  = "*"
        }
      ]
    }
  }

  depends_on = [helm_release.argocd]
}

# Repository для Argo CD
resource "kubernetes_manifest" "github_repository" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "github-helm-repo"
      namespace = var.argocd_namespace
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }
    type = "Opaque"
    stringData = {
      type     = "git"
      url      = var.github_repo_url
      username = var.github_username
      password = var.github_token
    }
  }

  depends_on = [kubernetes_namespace.argocd]
}