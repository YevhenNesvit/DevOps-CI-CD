variable "bucket_name" {
  description = "Назва S3 бакету для зберігання стейт-файлів"
  type        = string
}

variable "table_name" {
  description = "Назва DynamoDB таблиці для блокування стейтів"
  type        = string
  default     = "terraform-locks"
}

variable "region" {
  description = "AWS регіон"
  type        = string
  default     = "us-east-1"
}