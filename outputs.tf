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