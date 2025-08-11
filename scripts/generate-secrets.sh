#!/bin/bash

# Secure Secrets Generation Script for Kubernetes
# This script generates secure passwords and creates Kubernetes secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Kubernetes Secrets Generator${NC}"
echo "=================================="

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate JWT secret
generate_jwt_secret() {
    openssl rand -base64 64 | tr -d "=+/" | cut -c1-50
}

# Generate secure values
DB_ROOT_PASSWORD=$(generate_password)
DB_NAME="auth_db"
DB_USERNAME="auth_user"
DB_PASSWORD=$(generate_password)
JWT_SECRET=$(generate_jwt_secret)

echo -e "${YELLOW}Generated secure values:${NC}"
echo "Database Root Password: ${DB_ROOT_PASSWORD}"
echo "Database Name: ${DB_NAME}"
echo "Database Username: ${DB_USERNAME}"
echo "Database Password: ${DB_PASSWORD}"
echo "JWT Secret: ${JWT_SECRET}"
echo ""

# Base64 encode values
DB_ROOT_PASSWORD_B64=$(echo -n "${DB_ROOT_PASSWORD}" | base64)
DB_NAME_B64=$(echo -n "${DB_NAME}" | base64)
DB_USERNAME_B64=$(echo -n "${DB_USERNAME}" | base64)
DB_PASSWORD_B64=$(echo -n "${DB_PASSWORD}" | base64)
JWT_SECRET_B64=$(echo -n "${JWT_SECRET}" | base64)

echo -e "${BLUE}Creating Kubernetes secrets...${NC}"

# Create namespace if it doesn't exist
kubectl create namespace auth-app --dry-run=client -o yaml | kubectl apply -f -

# Create MariaDB secret
kubectl create secret generic mariadb-secret \
  --from-literal=root-password="${DB_ROOT_PASSWORD}" \
  --from-literal=database="${DB_NAME}" \
  --from-literal=username="${DB_USERNAME}" \
  --from-literal=password="${DB_PASSWORD}" \
  --namespace=auth-app \
  --dry-run=client -o yaml | kubectl apply -f -

# Create JWT secret
kubectl create secret generic jwt-secret \
  --from-literal=secret="${JWT_SECRET}" \
  --namespace=auth-app \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Secrets created successfully!${NC}"
echo ""
echo -e "${YELLOW}📝 Save these values securely:${NC}"
echo "Database Root Password: ${DB_ROOT_PASSWORD}"
echo "Database Password: ${DB_PASSWORD}"
echo "JWT Secret: ${JWT_SECRET}"
echo ""
echo -e "${BLUE}🔍 Verify secrets:${NC}"
echo "kubectl get secrets -n auth-app"
echo "kubectl describe secret mariadb-secret -n auth-app"
echo "kubectl describe secret jwt-secret -n auth-app"