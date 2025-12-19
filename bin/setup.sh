#!/bin/bash
set -e # Exit immediately if a command fails

PROJECT_NAME="myapp" 
REGION="us-east-1"
BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"

echo "🚀 Starting 10-Minute SaaS Launch..."

# 1. Create S3 Bucket for Remote State
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
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

# 4. RUTHLESS AUTOMATION: Update backend.tf automatically
# This replaces the placeholder in backend.tf with the actual bucket name
if [ -f "terraform/backend.tf" ]; then
    # Use sed to swap the placeholder for the real bucket name
    sed -i '' "s/YOUR-PROJECT-terraform-state/$BUCKET_NAME/g" terraform/backend.tf 2>/dev/null || \
    sed -i "s/YOUR-PROJECT-terraform-state/$BUCKET_NAME/g" terraform/backend.tf
    echo "✅ backend.tf updated with bucket name."
fi

echo "----------------------------------------------------"
echo "DONE! Your AWS foundation is ready."
echo "Next Step: cd terraform && terraform init"
echo "----------------------------------------------------"
