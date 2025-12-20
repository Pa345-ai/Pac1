#!/bin/bash
set -e

# CUSTOMIZE THESE
PROJECT_NAME="myapp" 
REGION="us-east-1"
BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"

echo "🚀 Starting 10-Minute SaaS Launch (High-Security Edition)..."

# 1. Create S3 Bucket for Remote State
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
echo "✅ S3 Bucket Created: $BUCKET_NAME"

# 2. Create DynamoDB Table for Locking
aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region $REGION
echo "✅ DynamoDB Table Created."

# 3. Create ECR Repository
aws ecr create-repository --repository-name "${PROJECT_NAME}-production" --region $REGION
echo "✅ ECR Repository Created."

# 4. Update backend.tf automatically
if [ -f "backend.tf" ]; then
    sed -i '' "s/YOUR-PROJECT-terraform-state/$BUCKET_NAME/g" Backend.tf 2>/dev/null || \
    sed -i "s/YOUR-PROJECT-terraform-state/$BUCKET_NAME/g" Backend.tf
    echo "✅ backend.tf updated with bucket name."
fi

echo "-------------------------------------------------------"
echo "🎉 SETUP COMPLETE!"
echo "1. Run: terraform init"
echo "2. Run: terraform apply -var=\"project_name=$PROJECT_NAME\""
echo "-------------------------------------------------------"

