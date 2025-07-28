#!/bin/bash

# Frontend-Focused ArgoCD Setup Script
# This script sets up ArgoCD specifically for frontend auto-deployment

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
APP_NAME="auth-stack-frontend"

echo -e "${BLUE}🚀 Frontend-Focused ArgoCD Setup${NC}"
echo "=================================="
echo -e "${YELLOW}This setup focuses on frontend auto-deployment${NC}"
echo -e "${YELLOW}ArgoCD will automatically pull and deploy frontend changes${NC}"
echo ""

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
    echo $ARGOCD_PF_PID > /tmp/argocd-frontend-pf.pid
    
    echo -e "${GREEN}✅ Port forwarding setup complete${NC}"
    echo -e "${GREEN}ArgoCD UI: https://localhost:8080${NC}"
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

# Function to create frontend-focused ArgoCD application
create_frontend_application() {
    echo -e "\n${YELLOW}📋 Creating frontend-focused ArgoCD application...${NC}"
    
    # Apply frontend application configuration
    kubectl apply -f argocd/frontend-application.yaml
    
    echo -e "${GREEN}✅ Frontend ArgoCD application created${NC}"
    echo -e "${BLUE}Application: $APP_NAME${NC}"
    echo -e "${BLUE}Auto-sync: Enabled for frontend changes${NC}"
}

# Function to configure repository access
configure_repo_access() {
    echo -e "\n${YELLOW}🔗 Configuring repository access...${NC}"
    
    # Add repository to ArgoCD
    argocd repo add https://github.com/chingnokas/vendor2025-app.git --type git --name vendor2025-app
    
    echo -e "${GREEN}✅ Repository access configured${NC}"
}

# Function to sync the application
sync_application() {
    echo -e "\n${YELLOW}🔄 Initial sync of frontend application...${NC}"
    
    # Sync the application
    argocd app sync $APP_NAME --prune
    
    # Wait for sync to complete
    argocd app wait $APP_NAME --timeout 300
    
    echo -e "${GREEN}✅ Frontend application synced successfully${NC}"
}

# Function to show application status
show_status() {
    echo -e "\n${YELLOW}📊 Frontend Application Status${NC}"
    echo "==============================="
    
    # Show ArgoCD application status
    argocd app get $APP_NAME
    
    # Show Kubernetes resources
    echo -e "\n${BLUE}Kubernetes Resources:${NC}"
    kubectl get all -n auth-app -l app=frontend
}

# Function to test frontend change detection
test_frontend_pipeline() {
    echo -e "\n${YELLOW}🧪 Testing Frontend Pipeline${NC}"
    echo "============================="
    
    echo -e "${BLUE}To test the frontend auto-deployment:${NC}"
    echo ""
    echo -e "${GREEN}1. Make a change to frontend code:${NC}"
    echo "   echo '// Pipeline test' >> src/main.ts"
    echo ""
    echo -e "${GREEN}2. Commit and push:${NC}"
    echo "   git add src/main.ts"
    echo "   git commit -m 'test: trigger frontend pipeline'"
    echo "   git push origin main"
    echo ""
    echo -e "${GREEN}3. Watch the process:${NC}"
    echo "   - GitHub Actions will build new frontend image"
    echo "   - Helm values will be updated with new image tag"
    echo "   - ArgoCD will detect changes and auto-deploy"
    echo ""
    echo -e "${GREEN}4. Monitor deployment:${NC}"
    echo "   - GitHub Actions: https://github.com/chingnokas/vendor2025-app/actions"
    echo "   - ArgoCD UI: https://localhost:8080"
    echo "   - Pods: kubectl get pods -n auth-app -l app=frontend"
}

# Function to show access information
show_access_info() {
    echo -e "\n${YELLOW}🌐 Access Information${NC}"
    echo "====================="
    
    echo -e "${GREEN}ArgoCD UI:${NC}"
    echo -e "  URL: https://localhost:8080"
    echo -e "  Username: admin"
    echo -e "  Password: $ARGOCD_PASSWORD"
    echo -e "  Application: $APP_NAME"
    
    echo -e "\n${GREEN}Frontend Application:${NC}"
    echo -e "  Port Forward: kubectl port-forward -n auth-app svc/frontend-service 8081:8080"
    echo -e "  Access: http://localhost:8081"
    
    echo -e "\n${GREEN}Monitoring Commands:${NC}"
    echo -e "  App Status: argocd app get $APP_NAME"
    echo -e "  App Sync: argocd app sync $APP_NAME"
    echo -e "  Pod Status: kubectl get pods -n auth-app -l app=frontend"
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
            create_frontend_application
            sync_application
            show_status
            test_frontend_pipeline
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
            echo -e "${GREEN}✅ Frontend application synced successfully${NC}"
            ;;
        "test")
            test_frontend_pipeline
            ;;
        "--help"|"-h")
            echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
            echo ""
            echo "Options:"
            echo "  install     Install ArgoCD and setup frontend application (default)"
            echo "  status      Show frontend application status"
            echo "  sync        Sync the frontend application"
            echo "  test        Show how to test the pipeline"
            echo "  --help, -h  Show this help message"
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            exit 1
            ;;
    esac
    
    if [[ "${1:-install}" == "install" ]]; then
        echo -e "\n${GREEN}🎉 Frontend-focused ArgoCD setup completed!${NC}"
        echo -e "${BLUE}Your frontend will now auto-deploy when you push changes${NC}"
        echo -e "${YELLOW}Push frontend changes → GitHub Actions builds → ArgoCD pulls → Kubernetes deploys${NC}"
    fi
}

# Run main function
main "$@"
