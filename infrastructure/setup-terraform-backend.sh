#!/bin/bash

# Terraform Backend Setup Script
# This script creates the necessary AWS resources for Terraform remote state

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏗️ Terraform Backend Setup${NC}"
echo "============================"

# Configuration
BUCKET_NAME="${1:-auth-stack-terraform-state-$(date +%s)}"
DYNAMODB_TABLE="${2:-terraform-state-lock}"
REGION="${3:-us-east-1}"

echo -e "${YELLOW}Configuration:${NC}"
echo "S3 Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${DYNAMODB_TABLE}"
echo "Region: ${REGION}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1: Creating S3 bucket for Terraform state...${NC}"

# Create S3 bucket
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Bucket ${BUCKET_NAME} already exists${NC}"
else
    if [ "${REGION}" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
    else
        aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" \
            --create-bucket-configuration LocationConstraint="${REGION}"
    fi
    echo -e "${GREEN}✅ Created S3 bucket: ${BUCKET_NAME}${NC}"
fi

# Enable versioning
aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled
echo -e "${GREEN}✅ Enabled versioning on S3 bucket${NC}"

# Enable server-side encryption
aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
echo -e "${GREEN}✅ Enabled encryption on S3 bucket${NC}"

# Block public access
aws s3api put-public-access-block --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
echo -e "${GREEN}✅ Blocked public access on S3 bucket${NC}"

echo -e "${BLUE}Step 2: Creating DynamoDB table for state locking...${NC}"

# Create DynamoDB table for state locking
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" &> /dev/null; then
    echo -e "${YELLOW}⚠️ DynamoDB table ${DYNAMODB_TABLE} already exists${NC}"
else
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "${REGION}"
    
    # Wait for table to be active
    echo -e "${YELLOW}⏳ Waiting for DynamoDB table to be active...${NC}"
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${REGION}"
    echo -e "${GREEN}✅ Created DynamoDB table: ${DYNAMODB_TABLE}${NC}"
fi

echo -e "${BLUE}Step 3: Generating backend configuration...${NC}"

# Generate backend configuration
cat > backend-config.tf << EOF
# Auto-generated Terraform backend configuration
# Generated on: $(date)

terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "auth-stack/terraform.tfstate"
    region         = "${REGION}"
    encrypt        = true
    dynamodb_table = "${DYNAMODB_TABLE}"
  }
}
EOF

echo -e "${GREEN}✅ Generated backend-config.tf${NC}"

echo -e "${BLUE}Step 4: Instructions for next steps...${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Review the generated backend-config.tf file"
echo "2. Replace the backend configuration in main.tf with the contents of backend-config.tf"
echo "3. Run 'terraform init' to initialize the backend"
echo "4. Run 'terraform plan' to verify everything works"
echo ""
echo -e "${YELLOW}🔧 Commands to run:${NC}"
echo "cd infrastructure/"
echo "terraform init"
echo "terraform plan"
echo ""
echo -e "${YELLOW}💰 Cost Information:${NC}"
echo "- S3 bucket: ~\$0.023 per GB per month"
echo "- DynamoDB table: ~\$0.25 per month (with minimal usage)"
echo ""
echo -e "${GREEN}🎉 Terraform backend setup completed successfully!${NC}"