# Terraform Backend Configuration
# Uncomment and configure based on your preferred backend

# Option 1: AWS S3 Backend (Recommended for AWS users)
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "auth-stack/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }

# Option 2: Google Cloud Storage Backend
# terraform {
#   backend "gcs" {
#     bucket = "your-terraform-state-bucket"
#     prefix = "auth-stack"
#   }
# }

# Option 3: Azure Storage Backend
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "terraform-state-rg"
#     storage_account_name = "terraformstatestorage"
#     container_name       = "tfstate"
#     key                  = "auth-stack.terraform.tfstate"
#   }
# }

# Option 4: Terraform Cloud Backend
# terraform {
#   backend "remote" {
#     organization = "your-organization"
#     workspaces {
#       name = "auth-stack"
#     }
#   }
# }

# Option 5: HTTP Backend (Generic)
# terraform {
#   backend "http" {
#     address        = "https://your-backend-url/terraform/state"
#     lock_address   = "https://your-backend-url/terraform/state/lock"
#     unlock_address = "https://your-backend-url/terraform/state/unlock"
#   }
# }