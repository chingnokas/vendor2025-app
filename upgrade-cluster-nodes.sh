#!/bin/bash

# 🚀 DigitalOcean Kubernetes Cluster Node Upgrade Script
# This script safely upgrades your cluster nodes to higher CPU/RAM

echo "🚀 DigitalOcean Kubernetes Cluster Node Upgrade"
echo "=============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    echo -e "${RED}❌ Error: main.tf not found. Please run this script from the infrastructure directory.${NC}"
    exit 1
fi

# Available node sizes
echo -e "${BLUE}📊 Available Node Sizes:${NC}"
echo "1. s-2vcpu-4gb  (2 vCPUs, 4GB RAM)  - ~$24/month per node"
echo "2. s-4vcpu-8gb  (4 vCPUs, 8GB RAM)  - ~$48/month per node"
echo "3. c-2          (2 vCPUs, 4GB RAM)  - ~$24/month per node (CPU optimized)"
echo "4. c-4          (4 vCPUs, 8GB RAM)  - ~$48/month per node (CPU optimized)"
echo "5. m-2vcpu-16gb (2 vCPUs, 16GB RAM) - ~$72/month per node (Memory optimized)"
echo "6. Custom size"
echo ""

# Get current node size
CURRENT_SIZE=$(grep -A1 'variable "node_size"' variables.tf | grep 'default' | sed 's/.*= "//' | sed 's/".*//')
echo -e "${YELLOW}Current node size: $CURRENT_SIZE${NC}"
echo ""

# Get user choice
read -p "Select new node size (1-6): " choice

case $choice in
    1) NEW_SIZE="s-2vcpu-4gb" ;;
    2) NEW_SIZE="s-4vcpu-8gb" ;;
    3) NEW_SIZE="c-2" ;;
    4) NEW_SIZE="c-4" ;;
    5) NEW_SIZE="m-2vcpu-16gb" ;;
    6) 
        echo "Available sizes: s-1vcpu-1gb, s-1vcpu-2gb, s-2vcpu-2gb, s-2vcpu-4gb, s-4vcpu-8gb, s-8vcpu-16gb"
        echo "                 c-2, c-4, c-8, c-16, c-32"
        echo "                 m-2vcpu-16gb, m-4vcpu-32gb, m-8vcpu-64gb, m-16vcpu-128gb"
        read -p "Enter custom size: " NEW_SIZE
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}🔄 Upgrade Plan:${NC}"
echo "From: $CURRENT_SIZE"
echo "To:   $NEW_SIZE"
echo ""

# Confirm upgrade
read -p "Do you want to proceed with this upgrade? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Upgrade cancelled."
    exit 0
fi

# Check if DO token is set
if [ -z "$TF_VAR_do_token" ]; then
    echo -e "${YELLOW}⚠️  Digital Ocean token not set.${NC}"
    read -p "Enter your DO token: " do_token
    export TF_VAR_do_token="$do_token"
fi

echo ""
echo -e "${BLUE}📋 Step 1: Planning the upgrade...${NC}"
tofu plan -var="node_size=$NEW_SIZE"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Planning failed. Please check your configuration.${NC}"
    exit 1
fi

echo ""
read -p "Does the plan look correct? Continue with upgrade? (y/N): " proceed
if [[ ! $proceed =~ ^[Yy]$ ]]; then
    echo "Upgrade cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}🚀 Step 2: Applying the upgrade...${NC}"
echo -e "${YELLOW}⏳ This may take 5-10 minutes. DigitalOcean will:${NC}"
echo "   1. Create new nodes with upgraded specs"
echo "   2. Drain workloads from old nodes"
echo "   3. Delete old nodes"
echo "   4. Your applications will remain available"
echo ""

tofu apply -var="node_size=$NEW_SIZE" -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Upgrade completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📊 Verification:${NC}"
    echo "Run these commands to verify:"
    echo "  kubectl get nodes -o wide"
    echo "  kubectl describe nodes"
    echo ""
    echo -e "${BLUE}💰 Cost Impact:${NC}"
    echo "Your monthly cost will change based on the new node size."
    echo "Check your DigitalOcean billing dashboard for updated estimates."
else
    echo -e "${RED}❌ Upgrade failed. Check the error messages above.${NC}"
    exit 1
fi
