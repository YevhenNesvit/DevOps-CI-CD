output "repository_url" {
  description = "URL ECR репозиторію"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ARN ECR репозиторію"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Назва ECR репозиторію"
  value       = aws_ecr_repository.main.name
}

output "registry_id" {
  description = "Registry ID"
  value       = aws_ecr_repository.main.registry_id
}

output "iam_role_arn" {
  description = "ARN IAM ролі для ECR"
  value       = aws_iam_role.ecr_role.arn
}