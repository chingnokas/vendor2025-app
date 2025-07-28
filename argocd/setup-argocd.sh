#!/bin/bash

# ArgoCD Setup Script for Authentication Stack
# This script installs ArgoCD and configures the authentication stack application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="v2.9.3"
APP_NAME="auth-stack"

echo -e "${BLUE}🚀 ArgoCD Setup for Authentication Stack${NC}"
echo "=============================================="

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ kubectl is available${NC}"
}

# Function to install ArgoCD
install_argocd() {
    echo -e "\n${YELLOW}📦 Installing ArgoCD...${NC}"
    
    # Create namespace
    kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml
    
    echo -e "${GREEN}✅ ArgoCD installed successfully${NC}"
}

# Function to wait for ArgoCD to be ready
wait_for_argocd() {
    echo -e "\n${YELLOW}⏳ Waiting for ArgoCD to be ready...${NC}"
    
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $ARGOCD_NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n $ARGOCD_NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n $ARGOCD_NAMESPACE
    
    echo -e "${GREEN}✅ ArgoCD is ready${NC}"
}

# Function to get ArgoCD admin password
get_argocd_password() {
    echo -e "\n${YELLOW}🔐 Getting ArgoCD admin password...${NC}"
    
    ARGOCD_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    echo -e "${GREEN}✅ ArgoCD admin password retrieved${NC}"
    echo -e "${BLUE}Username: admin${NC}"
    echo -e "${BLUE}Password: $ARGOCD_PASSWORD${NC}"
}

# Function to setup port forwarding
setup_port_forwarding() {
    echo -e "\n${YELLOW}🔗 Setting up port forwarding...${NC}"
    
    # Kill any existing port forwarding
    pkill -f "kubectl port-forward.*argocd-server" 2>/dev/null || true
    
    # Start port forwarding in background
    kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443 &
    ARGOCD_PF_PID=$!
    
    # Save PID for cleanup
    echo $ARGOCD_PF_PID > /tmp/argocd-pf.pid
    
    echo -e "${GREEN}✅ Port forwarding setup complete${NC}"
    echo -e "${GREEN}ArgoCD UI: https://localhost:8080${NC}"
    echo -e "${YELLOW}Note: You may need to accept the self-signed certificate${NC}"
}

# Function to install ArgoCD CLI
install_argocd_cli() {
    echo -e "\n${YELLOW}🔧 Installing ArgoCD CLI...${NC}"
    
    if command -v argocd &> /dev/null; then
        echo -e "${GREEN}✅ ArgoCD CLI already installed${NC}"
        return
    fi
    
    # Download and install ArgoCD CLI
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    
    echo -e "${GREEN}✅ ArgoCD CLI installed successfully${NC}"
}

# Function to login to ArgoCD CLI
login_argocd_cli() {
    echo -e "\n${YELLOW}🔑 Logging in to ArgoCD CLI...${NC}"
    
    # Wait for port forwarding to be ready
    sleep 5
    
    # Login to ArgoCD (skip TLS verification for local setup)
    echo "$ARGOCD_PASSWORD" | argocd login localhost:8080 --username admin --password-stdin --insecure
    
    echo -e "${GREEN}✅ Logged in to ArgoCD CLI${NC}"
}

# Function to create ArgoCD project and application
create_argocd_resources() {
    echo -e "\n${YELLOW}📋 Creating ArgoCD project and application...${NC}"
    
    # Apply project configuration
    kubectl apply -f argocd/project.yaml
    
    # Apply application configuration
    kubectl apply -f argocd/application.yaml
    
    echo -e "${GREEN}✅ ArgoCD resources created successfully${NC}"
}

# Function to configure GitHub repository access
configure_repo_access() {
    echo -e "\n${YELLOW}🔗 Configuring repository access...${NC}"
    
    # Add repository to ArgoCD (public repo, no credentials needed)
    argocd repo add https://github.com/chingnokas/vendor2025-app.git --type git --name vendor2025-app
    
    echo -e "${GREEN}✅ Repository access configured${NC}"
}

# Function to sync the application
sync_application() {
    echo -e "\n${YELLOW}🔄 Syncing authentication stack application...${NC}"
    
    # Sync the application
    argocd app sync $APP_NAME --prune
    
    # Wait for sync to complete
    argocd app wait $APP_NAME --timeout 300
    
    echo -e "${GREEN}✅ Application synced successfully${NC}"
}

# Function to show application status
show_status() {
    echo -e "\n${YELLOW}📊 Application Status${NC}"
    echo "===================="
    
    # Show ArgoCD application status
    argocd app get $APP_NAME
    
    # Show Kubernetes resources
    echo -e "\n${BLUE}Kubernetes Resources:${NC}"
    kubectl get all -n auth-app
}

# Function to show access information
show_access_info() {
    echo -e "\n${YELLOW}🌐 Access Information${NC}"
    echo "====================="
    
    echo -e "${GREEN}ArgoCD UI:${NC}"
    echo -e "  URL: https://localhost:8080"
    echo -e "  Username: admin"
    echo -e "  Password: $ARGOCD_PASSWORD"
    
    echo -e "\n${GREEN}Authentication Stack:${NC}"
    echo -e "  Frontend: kubectl port-forward -n auth-app svc/frontend-service 8081:8080"
    echo -e "  Backend: kubectl port-forward -n auth-app svc/backend-service 3000:3000"
    echo -e "  Database: kubectl port-forward -n auth-app svc/mariadb-service 3306:3306"
}

# Function to show help
show_help() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Options:"
    echo "  install     Install ArgoCD and setup application (default)"
    echo "  status      Show application status"
    echo "  sync        Sync the application"
    echo "  uninstall   Uninstall ArgoCD and application"
    echo "  password    Get ArgoCD admin password"
    echo "  --help, -h  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install      # Install and setup everything"
    echo "  $0 status       # Show current status"
    echo "  $0 sync         # Sync the application"
}

# Function to uninstall ArgoCD
uninstall_argocd() {
    echo -e "\n${YELLOW}🗑️ Uninstalling ArgoCD...${NC}"
    
    # Delete application
    kubectl delete -f argocd/application.yaml --ignore-not-found=true
    
    # Delete project
    kubectl delete -f argocd/project.yaml --ignore-not-found=true
    
    # Delete ArgoCD
    kubectl delete -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml --ignore-not-found=true
    
    # Delete namespace
    kubectl delete namespace $ARGOCD_NAMESPACE --ignore-not-found=true
    
    # Kill port forwarding
    if [ -f /tmp/argocd-pf.pid ]; then
        kill $(cat /tmp/argocd-pf.pid) 2>/dev/null || true
        rm -f /tmp/argocd-pf.pid
    fi
    
    echo -e "${GREEN}✅ ArgoCD uninstalled successfully${NC}"
}

# Main execution
main() {
    case "${1:-install}" in
        "install")
            check_kubectl
            install_argocd
            wait_for_argocd
            get_argocd_password
            setup_port_forwarding
            install_argocd_cli
            login_argocd_cli
            configure_repo_access
            create_argocd_resources
            sync_application
            show_status
            show_access_info
            ;;
        "status")
            check_kubectl
            show_status
            ;;
        "sync")
            check_kubectl
            argocd app sync $APP_NAME --prune
            argocd app wait $APP_NAME --timeout 300
            echo -e "${GREEN}✅ Application synced successfully${NC}"
            ;;
        "uninstall")
            uninstall_argocd
            ;;
        "password")
            get_argocd_password
            ;;
        "--help"|"-h")
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
    
    if [[ "${1:-install}" == "install" ]]; then
        echo -e "\n${GREEN}🎉 ArgoCD setup completed successfully!${NC}"
        echo -e "${BLUE}Your authentication stack is now managed by ArgoCD${NC}"
        echo -e "${YELLOW}Any changes pushed to the main branch will be automatically deployed${NC}"
    fi
}

# Run main function
main "$@"
