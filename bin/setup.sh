#!/bin/bash
################################################################################
# AWS Terraform Starter Kit - Setup Script
# Copyright (c) 2025 RUWANPURAGE PAVITHRA PARAMI RANASINGHE
# Licensed for single commercial use - See LICENSE.txt
################################################################################
set -e

# CUSTOMIZE THESE
PROJECT_NAME="myapp" 
REGION="us-east-1"
BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"

echo "🚀 Starting 10-Minute SaaS Launch (High-Security Edition)..."
echo "=================================================="
echo "Project Name: $PROJECT_NAME"
echo "Region: $REGION"
echo "S3 Bucket: $BUCKET_NAME"
echo "=================================================="
echo ""

# 1. Create S3 Bucket for Remote State
echo "📦 Creating S3 bucket for Terraform state..."
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION 2>/dev/null || {
    echo "⚠️  Bucket might already exist or creation failed"
}

aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

echo "✅ S3 Bucket Created: $BUCKET_NAME"

# 2. Create DynamoDB Table for Locking
echo ""
echo "🔒 Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name terraform-state-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION 2>/dev/null || {
    echo "⚠️  DynamoDB table might already exist"
}

echo "✅ DynamoDB Table Created."

# 3. Create ECR Repository
echo ""
echo "🐳 Creating ECR repository..."
aws ecr create-repository \
    --repository-name "${PROJECT_NAME}-production" \
    --region $REGION \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 2>/dev/null || {
    echo "⚠️  ECR repository might already exist"
}

echo "✅ ECR Repository Created: ${PROJECT_NAME}-production"

# 4. Update backend.tf automatically (FIXED: Case sensitivity)
echo ""
echo "📝 Updating backend.tf with bucket name..."
if [ -f "terraform/backend.tf" ]; then
    # Use portable sed syntax (works on both macOS and Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/YOUR-PROJECT-terraform-state/$BUCKET_NAME/g" terraform/backend.tf
    else
        # Linux
        sed -i "s/YOUR-PROJECT-terraform-state/$BUCKET_NAME/g" terraform/backend.tf
    fi
    echo "✅ terraform/backend.tf updated with bucket name."
else
    echo "⚠️  backend.tf not found at terraform/backend.tf"
fi

# 5. Create terraform.tfvars if it doesn't exist
echo ""
if [ ! -f "terraform/terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars..."
    cat > terraform/terraform.tfvars <<EOF
project_name = "$PROJECT_NAME"
environment  = "production"
aws_region   = "$REGION"

# Container configuration
container_image = "REPLACE_ME_AFTER_ECR_PUSH"
container_port  = 3000

# Resource sizing
cpu           = 256
memory        = 512
desired_count = 1

# Environment variables
app_environment_variables = [
  {
    name  = "NODE_ENV"
    value = "production"
  },
  {
    name  = "PORT"
    value = "3000"
  }
]
EOF
    echo "✅ terraform/terraform.tfvars created"
else
    echo "ℹ️  terraform.tfvars already exists, skipping creation"
fi

echo ""
echo "=================================================="
echo "🎉 SETUP COMPLETE!"
echo "=================================================="
echo ""
echo "Next Steps:"
echo "1. cd terraform/"
echo "2. Uncomment the backend block in backend.tf"
echo "3. Run: terraform init"
echo "4. Build and push your Docker image to ECR"
echo "5. Update container_image in terraform.tfvars"
echo "6. Run: terraform apply -var=\"project_name=$PROJECT_NAME\""
echo ""
echo "ECR Login Command:"
echo "aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin \$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com"
echo ""
echo "=================================================="
