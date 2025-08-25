output "bucket_name" {
  description = "Назва S3 бакету"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "bucket_arn" {
  description = "ARN S3 бакету"
  value       = aws_s3_bucket.terraform_state.arn
}

output "bucket_id" {
  description = "ID S3 бакету"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Назва DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_locks.arn
}