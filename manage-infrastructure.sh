#!/bin/bash

# 🏗️ Infrastructure Management Script with OpenTofu
# Manages DigitalOcean Kubernetes clusters for different environments

echo "🏗️ Infrastructure Management with OpenTofu"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/infrastructure"

# Functions
show_usage() {
    echo "Usage: $0 [COMMAND] [ENVIRONMENT]"
    echo ""
    echo "Commands:"
    echo "  plan      - Show what changes will be made"
    echo "  apply     - Apply infrastructure changes"
    echo "  destroy   - Destroy infrastructure"
    echo "  output    - Show infrastructure outputs"
    echo "  status    - Show current infrastructure status"
    echo ""
    echo "Environments:"
    echo "  staging   - Staging environment (default)"
    echo "  production - Production environment"
    echo ""
    echo "Examples:"
    echo "  $0 plan staging"
    echo "  $0 apply production"
    echo "  $0 destroy staging"
}

check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if tofu is installed
    if ! command -v tofu &> /dev/null; then
        echo -e "${RED}❌ OpenTofu is not installed. Please install it first.${NC}"
        echo "Visit: https://opentofu.org/docs/intro/install/"
        exit 1
    fi
    
    # Check if DO token is set
    if [ -z "$TF_VAR_do_token" ] && [ -z "$DIGITALOCEAN_TOKEN" ]; then
        echo -e "${YELLOW}⚠️  DigitalOcean token not found.${NC}"
        read -p "Enter your DigitalOcean token: " do_token
        export TF_VAR_do_token="$do_token"
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

init_terraform() {
    local env=$1
    echo -e "${BLUE}🏗️ Initializing OpenTofu for $env environment...${NC}"
    
    cd "$INFRA_DIR"
    tofu init
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to initialize OpenTofu${NC}"
        exit 1
    fi
}

plan_infrastructure() {
    local env=$1
    echo -e "${BLUE}📋 Planning infrastructure for $env environment...${NC}"
    
    cd "$INFRA_DIR"
    
    if [ -f "environments/${env}.tfvars" ]; then
        tofu plan -var-file="environments/${env}.tfvars" -out="${env}.tfplan"
    else
        echo -e "${YELLOW}⚠️  No specific tfvars file found for $env, using defaults${NC}"
        tofu plan \
            -var="cluster_name=auth-stack-${env}" \
            -var="node_count=2" \
            -var="node_size=s-2vcpu-4gb" \
            -out="${env}.tfplan"
    fi
}

apply_infrastructure() {
    local env=$1
    echo -e "${BLUE}🚀 Applying infrastructure for $env environment...${NC}"
    
    cd "$INFRA_DIR"
    
    # Check if plan exists
    if [ ! -f "${env}.tfplan" ]; then
        echo -e "${YELLOW}⚠️  No plan found, creating one first...${NC}"
        plan_infrastructure "$env"
    fi
    
    echo -e "${YELLOW}⚠️  This will create/modify infrastructure in DigitalOcean.${NC}"
    read -p "Are you sure you want to proceed? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        tofu apply "${env}.tfplan"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Infrastructure applied successfully!${NC}"
            
            # Export kubeconfig
            echo -e "${BLUE}📤 Exporting kubeconfig...${NC}"
            tofu output -raw kubeconfig > "kubeconfig-${env}.yaml"
            echo -e "${GREEN}✅ Kubeconfig saved to kubeconfig-${env}.yaml${NC}"
            
            # Show access information
            show_access_info "$env"
        else
            echo -e "${RED}❌ Failed to apply infrastructure${NC}"
            exit 1
        fi
    else
        echo "Operation cancelled."
    fi
}

destroy_infrastructure() {
    local env=$1
    echo -e "${RED}💥 Destroying infrastructure for $env environment...${NC}"
    
    cd "$INFRA_DIR"
    
    echo -e "${RED}⚠️  WARNING: This will DESTROY all infrastructure in $env environment!${NC}"
    echo -e "${RED}⚠️  This action cannot be undone!${NC}"
    read -p "Type 'destroy' to confirm: " confirm
    
    if [ "$confirm" = "destroy" ]; then
        if [ -f "environments/${env}.tfvars" ]; then
            tofu destroy -var-file="environments/${env}.tfvars" -auto-approve
        else
            tofu destroy \
                -var="cluster_name=auth-stack-${env}" \
                -var="node_count=2" \
                -var="node_size=s-2vcpu-4gb" \
                -auto-approve
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Infrastructure destroyed successfully!${NC}"
            
            # Clean up kubeconfig
            if [ -f "kubeconfig-${env}.yaml" ]; then
                rm "kubeconfig-${env}.yaml"
                echo -e "${GREEN}✅ Kubeconfig cleaned up${NC}"
            fi
        else
            echo -e "${RED}❌ Failed to destroy infrastructure${NC}"
            exit 1
        fi
    else
        echo "Operation cancelled."
    fi
}

show_outputs() {
    local env=$1
    echo -e "${BLUE}📊 Infrastructure outputs for $env environment:${NC}"
    
    cd "$INFRA_DIR"
    tofu output
}

show_status() {
    local env=$1
    echo -e "${BLUE}📊 Infrastructure status for $env environment:${NC}"
    
    cd "$INFRA_DIR"
    
    # Show state list
    echo -e "${PURPLE}Resources:${NC}"
    tofu state list
    
    echo ""
    echo -e "${PURPLE}Outputs:${NC}"
    tofu output
    
    # Check if kubeconfig exists
    if [ -f "kubeconfig-${env}.yaml" ]; then
        echo ""
        echo -e "${GREEN}✅ Kubeconfig available: kubeconfig-${env}.yaml${NC}"
        
        # Test cluster connectivity
        if command -v kubectl &> /dev/null; then
            echo -e "${BLUE}🔍 Testing cluster connectivity...${NC}"
            KUBECONFIG="kubeconfig-${env}.yaml" kubectl cluster-info --request-timeout=5s 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Cluster is accessible${NC}"
            else
                echo -e "${YELLOW}⚠️  Cluster connectivity test failed${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  No kubeconfig found for $env environment${NC}"
    fi
}

show_access_info() {
    local env=$1
    echo ""
    echo -e "${GREEN}🎉 Infrastructure Ready!${NC}"
    echo ""
    echo -e "${BLUE}🔗 Access Information:${NC}"
    echo "====================="
    echo ""
    echo -e "${YELLOW}Kubeconfig:${NC}"
    echo "  export KUBECONFIG=infrastructure/kubeconfig-${env}.yaml"
    echo ""
    echo -e "${YELLOW}Cluster Info:${NC}"
    echo "  kubectl cluster-info"
    echo "  kubectl get nodes"
    echo ""
    echo -e "${YELLOW}Deploy Applications:${NC}"
    echo "  ./deploy-monitoring.sh"
    echo "  helm upgrade --install auth-stack helm/auth-stack --namespace auth-app --create-namespace"
    echo ""
    echo -e "${YELLOW}DigitalOcean Console:${NC}"
    echo "  https://cloud.digitalocean.com/kubernetes/clusters"
}

# Main script logic
COMMAND=${1:-help}
ENVIRONMENT=${2:-staging}

case $COMMAND in
    plan)
        check_prerequisites
        init_terraform "$ENVIRONMENT"
        plan_infrastructure "$ENVIRONMENT"
        ;;
    apply)
        check_prerequisites
        init_terraform "$ENVIRONMENT"
        apply_infrastructure "$ENVIRONMENT"
        ;;
    destroy)
        check_prerequisites
        init_terraform "$ENVIRONMENT"
        destroy_infrastructure "$ENVIRONMENT"
        ;;
    output)
        cd "$INFRA_DIR"
        show_outputs "$ENVIRONMENT"
        ;;
    status)
        cd "$INFRA_DIR"
        show_status "$ENVIRONMENT"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $COMMAND${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
