variable "ecr_name" {
  description = "Назва ECR репозиторію"
  type        = string
}

variable "scan_on_push" {
  description = "Увімкнути сканування образів при push"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Можливість змінювати теги образів"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Значення image_tag_mutability має бути MUTABLE або IMMUTABLE."
  }
}