terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "nesvit-terraform-state-bucket"  # Змініть на ваше унікальне ім'я
  table_name  = "terraform-state-locks-lesson7"
  region      = "us-east-1"
}

# Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_name           = "lesson-7-vpc"
}

# Підключаємо модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-ecr"
  scan_on_push = true
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name         = "django-eks-cluster"
  kubernetes_version   = "1.31"
  subnet_ids           = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids   = module.vpc.private_subnet_ids
  node_instance_types  = ["t3.medium"]
  node_desired_size    = 2
  node_max_size        = 4
  node_min_size        = 1
}

module "jenkins" {
  source = "./modules/jenkins"
  
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  
  jenkins_namespace     = var.jenkins_namespace
  jenkins_chart_version = var.jenkins_chart_version
  jenkins_admin_password = var.jenkins_admin_password
  
  ecr_registry = module.ecr.repository_url
  aws_region   = var.aws_region
  
  github_username = var.github_username
  github_token    = var.github_token
  aws_access_key  = var.aws_access_key
  aws_secret_key  = var.aws_secret_key
  
  storage_class = "gp2"
  
  depends_on = [module.eks]
}

# Підключення модуля Argo CD
module "argocd" {
  source = "./modules/argo_cd"
  
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  
  argocd_namespace    = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version
  
  github_repo_url     = var.github_charts_repo_url
  github_username     = var.github_username
  github_token        = var.github_token
  
  app_name         = var.django_app_name
  app_namespace    = var.django_app_namespace
  chart_path       = var.helm_chart_path
  target_revision  = var.target_revision
  
  sync_policy_automated = var.sync_policy_automated
  auto_prune           = var.auto_prune
  self_heal           = var.self_heal
  
  depends_on = [module.eks]
}
