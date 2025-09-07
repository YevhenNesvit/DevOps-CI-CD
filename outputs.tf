output "s3_bucket_name" {
  description = "Назва S3 бакету для стейт-файлів"
  value       = module.s3_backend.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN S3 бакету"
  value       = module.s3_backend.bucket_arn
}

output "dynamodb_table_name" {
  description = "Назва DynamoDB таблиці для блокування"
  value       = module.s3_backend.dynamodb_table_name
}

# Виведення інформації про VPC
output "vpc_id" {
  description = "ID VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs публічних підмереж"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs приватних підмереж"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "ID NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

# Виведення інформації про ECR
output "ecr_repository_url" {
  description = "URL ECR репозиторію"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN ECR репозиторію"
  value       = module.ecr.repository_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "jenkins_url" {
  description = "Jenkins service URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_service_account_role_arn" {
  description = "Jenkins service account IAM role ARN"
  value       = module.jenkins.jenkins_service_account_role_arn
}

# Argo CD outputs
output "argocd_url" {
  description = "Argo CD server URL"
  value       = module.argocd.argocd_url
}

output "argocd_admin_password" {
  description = "Argo CD initial admin password"
  value       = module.argocd.argocd_admin_password
  sensitive   = true
}

output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = module.argocd.argocd_namespace
}

output "argocd_application_name" {
  description = "Created Argo CD application name"
  value       = module.argocd.argocd_application_name
}

# Connection information
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    cluster_name     = module.eks.cluster_name
    jenkins_url      = module.jenkins.jenkins_url
    argocd_url      = module.argocd.argocd_url
    ecr_repository  = module.ecr.repository_url
    app_namespace   = var.django_app_namespace
  }
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = module.rds.endpoint
}

output "database_reader_endpoint" {
  description = "Database reader endpoint (Aurora only)"
  value       = module.rds.reader_endpoint
}

output "database_port" {
  description = "Database port"
  value       = module.rds.port
}

output "database_name" {
  description = "Database name"
  value       = module.rds.database_name
}

output "database_username" {
  description = "Database username"
  value       = module.rds.username
  sensitive   = true
}

output "database_identifier" {
  description = "Database identifier"
  value       = module.rds.identifier
}

output "database_arn" {
  description = "Database ARN"
  value       = module.rds.arn
}

output "database_engine" {
  description = "Database engine"
  value       = module.rds.engine
}

output "database_engine_version" {
  description = "Database engine version"
  value       = module.rds.engine_version
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = module.rds.security_group_id
}

output "database_subnet_group_name" {
  description = "Database subnet group name"
  value       = module.rds.subnet_group_name
}

output "database_parameter_group_name" {
  description = "Database parameter group name"
  value       = module.rds.parameter_group_name
}

output "database_connection_string" {
  description = "Database connection string (without password)"
  value       = module.rds.connection_string
  sensitive   = true
}

output "database_secrets_manager_arn" {
  description = "Database master user secret ARN in Secrets Manager (if managed by AWS)"
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}

output "database_type" {
  description = "Database type (Aurora or RDS)"
  value       = var.use_aurora ? "Aurora PostgreSQL" : "RDS PostgreSQL"
}

# Aurora specific outputs
output "aurora_cluster_identifier" {
  description = "Aurora cluster identifier (if Aurora is used)"
  value       = var.use_aurora ? module.rds.identifier : null
}

output "aurora_instance_identifiers" {
  description = "Aurora instance identifiers (if Aurora is used)"
  value       = var.use_aurora ? module.rds.instance_identifiers : null
}