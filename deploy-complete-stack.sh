#!/bin/bash

# 🚀 Complete Stack Deployment Script
# This script helps you deploy the complete authentication stack with OpenTofu, ArgoCD, and monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main function
main() {
    echo "🚀 Complete Authentication Stack Deployment"
    echo "==========================================="
    echo ""

    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists git; then
        print_error "git is required but not installed"
        exit 1
    fi
    
    if ! command_exists kubectl; then
        print_warning "kubectl not found - you'll need it to manage the cluster"
    fi
    
    if ! command_exists helm; then
        print_warning "helm not found - you'll need it for manual deployments"
    fi
    
    if ! command_exists doctl; then
        print_warning "doctl not found - useful for DigitalOcean management"
    fi

    print_success "Prerequisites check completed"
    echo ""

    # Get environment
    echo "Select deployment environment:"
    echo "1) Staging (cost-optimized, 2 nodes)"
    echo "2) Production (high-availability, 3+ nodes)"
    read -p "Enter choice (1-2): " env_choice

    case $env_choice in
        1)
            ENVIRONMENT="staging"
            ;;
        2)
            ENVIRONMENT="production"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    print_status "Selected environment: $ENVIRONMENT"
    echo ""

    # Check GitHub secrets
    print_status "Checking GitHub repository setup..."
    
    if [ ! -d ".git" ]; then
        print_error "This script must be run from the root of your Git repository"
        exit 1
    fi

    REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -z "$REPO_URL" ]; then
        print_error "No Git remote 'origin' found"
        exit 1
    fi

    print_success "Git repository detected: $REPO_URL"
    echo ""

    # Configuration check
    print_status "Checking configuration files..."
    
    required_files=(
        "infrastructure/main.tf"
        "infrastructure/variables.tf"
        "infrastructure/environments/${ENVIRONMENT}.tfvars"
        ".github/workflows/infrastructure-ci.yml"
        ".github/workflows/full-stack-ci.yml"
        "helm/auth-stack/values.yaml"
        "monitoring/prometheus-config.yml"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Required file not found: $file"
            exit 1
        fi
    done

    print_success "All configuration files found"
    echo ""

    # GitHub Secrets reminder
    print_warning "IMPORTANT: Ensure these GitHub Secrets are configured:"
    echo "  - DIGITALOCEAN_TOKEN: Your DigitalOcean API token"
    echo "  - GRAFANA_ADMIN_PASSWORD: Password for Grafana admin user"
    echo ""
    read -p "Have you configured the required GitHub Secrets? (y/N): " secrets_confirmed

    if [[ ! "$secrets_confirmed" =~ ^[Yy]$ ]]; then
        print_error "Please configure GitHub Secrets first"
        echo "Go to: https://github.com/$(echo $REPO_URL | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/settings/secrets/actions"
        exit 1
    fi

    # Production IP configuration check
    if [ "$ENVIRONMENT" = "production" ]; then
        print_warning "Production environment detected"
        echo "Please ensure you've updated the SSH allowed IPs in:"
        echo "  infrastructure/environments/production.tfvars"
        echo ""
        echo "Current configuration should replace 'YOUR_OFFICE_IP/32' with your actual IP"
        echo ""
        read -p "Have you configured the production IP restrictions? (y/N): " ip_confirmed

        if [[ ! "$ip_confirmed" =~ ^[Yy]$ ]]; then
            print_error "Please update production IP restrictions first"
            exit 1
        fi
    fi

    # Deployment options
    echo "Select deployment method:"
    echo "1) Automatic (push to trigger GitHub Actions)"
    echo "2) Manual (trigger GitHub Actions workflow)"
    read -p "Enter choice (1-2): " deploy_choice

    case $deploy_choice in
        1)
            deploy_automatic
            ;;
        2)
            deploy_manual
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

deploy_automatic() {
    print_status "Preparing automatic deployment..."
    
    # Check if there are uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_status "Uncommitted changes detected. Committing..."
        git add .
        git commit -m "feat: deploy complete stack to $ENVIRONMENT"
    fi

    # Push to trigger deployment
    print_status "Pushing to trigger deployment..."
    git push origin main

    print_success "Deployment triggered!"
    echo ""
    print_status "Monitor deployment progress:"
    echo "  1. GitHub Actions: https://github.com/$(echo $(git remote get-url origin) | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/actions"
    echo "  2. DigitalOcean Console: https://cloud.digitalocean.com/kubernetes/clusters"
    echo ""
    print_status "Deployment will take approximately 10-15 minutes"
}

deploy_manual() {
    print_status "Manual deployment selected"
    echo ""
    print_status "To trigger manual deployment:"
    echo "  1. Go to: https://github.com/$(echo $(git remote get-url origin) | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/actions"
    echo "  2. Select '🏗️ Infrastructure CI/CD with OpenTofu'"
    echo "  3. Click 'Run workflow'"
    echo "  4. Select environment: $ENVIRONMENT"
    echo "  5. Select action: apply"
    echo "  6. Click 'Run workflow'"
    echo ""
    print_status "After infrastructure deployment completes, applications will deploy automatically"
}

# Post-deployment instructions
show_post_deployment() {
    echo ""
    print_success "Deployment initiated successfully!"
    echo ""
    print_status "Next steps after deployment completes:"
    echo ""
    echo "1. 📊 Access Grafana:"
    echo "   kubectl get services -n monitoring"
    echo "   # Use the LoadBalancer IP for Grafana"
    echo "   # Username: admin"
    echo "   # Password: (your configured password)"
    echo ""
    echo "2. 🔄 Access ArgoCD:"
    echo "   kubectl get services -n argocd"
    echo "   # Use the LoadBalancer IP for ArgoCD"
    echo "   # Username: admin"
    echo "   # Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    echo ""
    echo "3. 🚀 Access Application:"
    echo "   kubectl get services -n auth-app"
    echo "   # Use the LoadBalancer IP for your application"
    echo ""
    echo "4. 📋 Download kubeconfig:"
    echo "   # Download from GitHub Actions artifacts"
    echo "   # File: kubeconfig-$ENVIRONMENT.yaml"
    echo ""
    print_status "For detailed instructions, see: COMPLETE-DEPLOYMENT-GUIDE.md"
}

# Cleanup function
cleanup() {
    echo ""
    print_status "To destroy the infrastructure later:"
    echo "  1. Go to GitHub Actions"
    echo "  2. Run '🏗️ Infrastructure CI/CD with OpenTofu'"
    echo "  3. Select environment: $ENVIRONMENT"
    echo "  4. Select action: destroy"
    echo ""
    print_warning "This will permanently delete all resources!"
}

# Run main function
main "$@"
show_post_deployment
cleanup

print_success "Setup complete! 🎉"