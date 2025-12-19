################################################################################
# TERRAFORM REMOTE STATE BACKEND
################################################################################
# This is your infrastructure's "Safety Net"
#
# Without this, your Terraform state lives locally on your laptop.
# If you lose that file, you lose the ability to manage your AWS resources.
#
# This S3 + DynamoDB backend stores your state remotely and prevents multiple
# people (or CI/CD runs) from modifying infrastructure at the same time.
#
# SETUP INSTRUCTIONS:
# 1. Create the S3 bucket and DynamoDB table FIRST (do this manually or use the
#    bootstrap commands below)
# 2. Uncomment the terraform block below
# 3. Run: terraform init -migrate-state
#
# BOOTSTRAP COMMANDS (run these once):
#
# aws s3api create-bucket \
#   --bucket YOUR-PROJECT-terraform-state \
#   --region us-east-1
#
# aws s3api put-bucket-versioning \
#   --bucket YOUR-PROJECT-terraform-state \
#   --versioning-configuration Status=Enabled
#
# aws s3api put-bucket-encryption \
#   --bucket YOUR-PROJECT-terraform-state \
#   --server-side-encryption-configuration '{
#     "Rules": [{
#       "ApplyServerSideEncryptionByDefault": {
#         "SSEAlgorithm": "AES256"
#       }
#     }]
#   }'
#
# aws dynamodb create-table \
#   --table-name terraform-state-locks \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1
#
################################################################################

# Uncomment this block after running the bootstrap commands above
#
# terraform {
#   backend "s3" {
#     bucket         = "YOUR-PROJECT-terraform-state"
#     key            = "production/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-locks"
#   }
# }

################################################################################
# WHY THIS MATTERS
################################################################################
# S3 Bucket: Stores your infrastructure state file safely in the cloud
# Versioning: Lets you recover if something goes wrong
# Encryption: Protects sensitive data in your state file
# DynamoDB Table: Prevents two deploys from running at the same time (state locking)
#
# Cost: ~$0.50/month (S3) + ~$0.10/month (DynamoDB) = negligible
################################################################################
