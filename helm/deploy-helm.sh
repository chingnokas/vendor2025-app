#!/bin/bash

# Helm Deployment Script for Authentication Stack
# This script deploys the authentication stack using Helm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHART_PATH="./helm/auth-stack"
RELEASE_NAME="auth-stack"
NAMESPACE="auth-app"

echo -e "${BLUE}🎯 Helm Authentication Stack Deployment${NC}"
echo "============================================="

# Function to check if Helm is available
check_helm() {
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}❌ Helm is not installed or not in PATH${NC}"
        echo "Please install Helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi
    echo -e "${GREEN}✅ Helm is available ($(helm version --short))${NC}"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ kubectl is available${NC}"
}

# Function to lint the chart
lint_chart() {
    echo -e "\n${YELLOW}🔍 Linting Helm Chart...${NC}"
    if helm lint $CHART_PATH; then
        echo -e "${GREEN}✅ Chart linting passed${NC}"
    else
        echo -e "${RED}❌ Chart linting failed${NC}"
        exit 1
    fi
}

# Function to deploy the chart
deploy_chart() {
    echo -e "\n${YELLOW}🚀 Deploying Helm Chart...${NC}"
    
    # Check if release already exists
    if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
        echo -e "${YELLOW}📦 Release $RELEASE_NAME already exists, upgrading...${NC}"
        helm upgrade $RELEASE_NAME $CHART_PATH \
            --namespace $NAMESPACE \
            --wait \
            --timeout 10m
        echo -e "${GREEN}✅ Release upgraded successfully${NC}"
    else
        echo -e "${BLUE}📦 Installing new release $RELEASE_NAME...${NC}"
        helm install $RELEASE_NAME $CHART_PATH \
            --namespace $NAMESPACE \
            --create-namespace \
            --wait \
            --timeout 10m
        echo -e "${GREEN}✅ Release installed successfully${NC}"
    fi
}

# Function to show deployment status
show_status() {
    echo -e "\n${YELLOW}📊 Deployment Status${NC}"
    echo "===================="
    
    echo -e "\n${BLUE}Helm Release Status:${NC}"
    helm status $RELEASE_NAME -n $NAMESPACE
    
    echo -e "\n${BLUE}Kubernetes Resources:${NC}"
    kubectl get all -n $NAMESPACE
    
    echo -e "\n${BLUE}Persistent Volumes:${NC}"
    kubectl get pvc -n $NAMESPACE
}

# Function to setup port forwarding
setup_port_forwarding() {
    echo -e "\n${YELLOW}🔗 Setting up Port Forwarding${NC}"
    echo "================================"
    
    echo -e "${BLUE}Setting up port forwarding for frontend (8080)...${NC}"
    kubectl port-forward -n $NAMESPACE svc/frontend-service 8080:8080 &
    FRONTEND_PID=$!
    
    echo -e "${BLUE}Setting up port forwarding for backend (3000)...${NC}"
    kubectl port-forward -n $NAMESPACE svc/backend-service 3000:3000 &
    BACKEND_PID=$!
    
    echo -e "${GREEN}✅ Port forwarding setup complete${NC}"
    echo -e "${GREEN}Frontend: http://localhost:8080${NC}"
    echo -e "${GREEN}Backend API: http://localhost:3000${NC}"
    
    # Save PIDs for cleanup
    echo $FRONTEND_PID > /tmp/helm-frontend-pf.pid
    echo $BACKEND_PID > /tmp/helm-backend-pf.pid
    
    echo -e "\n${YELLOW}To stop port forwarding later, run:${NC}"
    echo "kill $FRONTEND_PID $BACKEND_PID"
}

# Function to test the deployment
test_deployment() {
    echo -e "\n${YELLOW}🧪 Testing Deployment${NC}"
    echo "====================="
    
    # Wait a moment for services to be fully ready
    sleep 5
    
    # Test backend health
    echo -e "${BLUE}Testing backend health...${NC}"
    if curl -s -f http://localhost:3000/health > /dev/null; then
        echo -e "${GREEN}✅ Backend health check passed${NC}"
    else
        echo -e "${RED}❌ Backend health check failed${NC}"
    fi
    
    # Test frontend
    echo -e "${BLUE}Testing frontend...${NC}"
    if curl -s -f http://localhost:8080 > /dev/null; then
        echo -e "${GREEN}✅ Frontend is accessible${NC}"
    else
        echo -e "${RED}❌ Frontend is not accessible${NC}"
    fi
}

# Function to show help
show_help() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Options:"
    echo "  deploy      Deploy the Helm chart (default)"
    echo "  upgrade     Upgrade existing deployment"
    echo "  uninstall   Uninstall the deployment"
    echo "  status      Show deployment status"
    echo "  test        Test the deployment"
    echo "  lint        Lint the chart only"
    echo "  template    Show rendered templates"
    echo "  --help, -h  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy           # Deploy the chart"
    echo "  $0 upgrade          # Upgrade existing deployment"
    echo "  $0 status           # Show status"
    echo "  $0 uninstall        # Remove deployment"
}

# Main execution
main() {
    case "${1:-deploy}" in
        "deploy")
            check_helm
            check_kubectl
            lint_chart
            deploy_chart
            show_status
            setup_port_forwarding
            test_deployment
            ;;
        "upgrade")
            check_helm
            check_kubectl
            lint_chart
            helm upgrade $RELEASE_NAME $CHART_PATH -n $NAMESPACE --wait
            echo -e "${GREEN}✅ Release upgraded successfully${NC}"
            ;;
        "uninstall")
            check_helm
            helm uninstall $RELEASE_NAME -n $NAMESPACE
            echo -e "${GREEN}✅ Release uninstalled successfully${NC}"
            ;;
        "status")
            check_helm
            show_status
            ;;
        "test")
            test_deployment
            ;;
        "lint")
            check_helm
            lint_chart
            ;;
        "template")
            check_helm
            helm template $RELEASE_NAME $CHART_PATH
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
    
    if [[ "${1:-deploy}" == "deploy" ]]; then
        echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
        echo -e "${BLUE}Access your application at:${NC}"
        echo -e "${GREEN}  Frontend: http://localhost:8080${NC}"
        echo -e "${GREEN}  Backend:  http://localhost:3000${NC}"
        echo -e "\n${YELLOW}To manage your deployment:${NC}"
        echo -e "  helm status $RELEASE_NAME -n $NAMESPACE"
        echo -e "  helm upgrade $RELEASE_NAME $CHART_PATH -n $NAMESPACE"
        echo -e "  helm uninstall $RELEASE_NAME -n $NAMESPACE"
    fi
}

# Run main function
main "$@"
