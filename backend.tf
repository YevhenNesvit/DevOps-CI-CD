# terraform {
#   backend "s3" {
#     bucket         = "nesvit-terraform-state-bucket"  # Змініть на ваше ім'я бакету
#     key            = "lesson-7/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-locks-lesson7"
#     encrypt        = true
#   }
# }