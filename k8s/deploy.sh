#!/bin/bash

# Kubernetes Deployment Script for Authentication Stack
# This script builds Docker images and deploys the complete stack to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="auth-app"
BACKEND_IMAGE="auth-backend:latest"
FRONTEND_IMAGE="angular-service-portal:latest"

echo -e "${BLUE}🚀 Kubernetes Authentication Stack Deployment${NC}"
echo "=================================================="

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ kubectl is available${NC}"
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker is available${NC}"
}

# Function to build Docker images
build_images() {
    echo -e "\n${YELLOW}🔨 Building Docker Images...${NC}"
    
    # Build backend image
    echo -e "${BLUE}Building backend image...${NC}"
    cd ../backend
    docker build -t $BACKEND_IMAGE .
    echo -e "${GREEN}✅ Backend image built: $BACKEND_IMAGE${NC}"
    
    # Build frontend image
    echo -e "${BLUE}Building frontend image...${NC}"
    cd ..
    docker build -t $FRONTEND_IMAGE .
    echo -e "${GREEN}✅ Frontend image built: $FRONTEND_IMAGE${NC}"
    
    cd k8s
}

# Function to deploy to Kubernetes
deploy_to_k8s() {
    echo -e "\n${YELLOW}☸️  Deploying to Kubernetes...${NC}"
    
    # Apply the deployment
    kubectl apply -f deployment.yml
    echo -e "${GREEN}✅ Kubernetes manifests applied${NC}"
    
    # Wait for namespace to be created
    echo -e "${BLUE}Waiting for namespace to be ready...${NC}"
    kubectl wait --for=condition=Ready --timeout=30s namespace/$NAMESPACE 2>/dev/null || true
    
    # Wait for MariaDB to be ready
    echo -e "${BLUE}Waiting for MariaDB to be ready...${NC}"
    kubectl wait --for=condition=Ready pod -l app=mariadb -n $NAMESPACE --timeout=300s
    echo -e "${GREEN}✅ MariaDB is ready${NC}"
    
    # Wait for backend to be ready
    echo -e "${BLUE}Waiting for backend to be ready...${NC}"
    kubectl wait --for=condition=Ready pod -l app=backend -n $NAMESPACE --timeout=300s
    echo -e "${GREEN}✅ Backend is ready${NC}"
    
    # Wait for frontend to be ready
    echo -e "${BLUE}Waiting for frontend to be ready...${NC}"
    kubectl wait --for=condition=Ready pod -l app=frontend -n $NAMESPACE --timeout=300s
    echo -e "${GREEN}✅ Frontend is ready${NC}"
}

# Function to show deployment status
show_status() {
    echo -e "\n${YELLOW}📊 Deployment Status${NC}"
    echo "===================="
    
    echo -e "\n${BLUE}Pods:${NC}"
    kubectl get pods -n $NAMESPACE
    
    echo -e "\n${BLUE}Services:${NC}"
    kubectl get svc -n $NAMESPACE
    
    echo -e "\n${BLUE}Ingress:${NC}"
    kubectl get ingress -n $NAMESPACE 2>/dev/null || echo "No ingress found"
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
    echo $FRONTEND_PID > /tmp/k8s-frontend-pf.pid
    echo $BACKEND_PID > /tmp/k8s-backend-pf.pid
    
    echo -e "\n${YELLOW}To stop port forwarding later, run:${NC}"
    echo "kill $FRONTEND_PID $BACKEND_PID"
    echo -e "${YELLOW}Or use: ./cleanup.sh${NC}"
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

# Main execution
main() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    check_kubectl
    check_docker
    
    # Parse command line arguments
    case "${1:-deploy}" in
        "build")
            build_images
            ;;
        "deploy")
            build_images
            deploy_to_k8s
            show_status
            setup_port_forwarding
            test_deployment
            ;;
        "status")
            show_status
            ;;
        "forward")
            setup_port_forwarding
            ;;
        "test")
            test_deployment
            ;;
        *)
            echo -e "${YELLOW}Usage: $0 [build|deploy|status|forward|test]${NC}"
            echo "  build   - Build Docker images only"
            echo "  deploy  - Build images and deploy to Kubernetes (default)"
            echo "  status  - Show deployment status"
            echo "  forward - Setup port forwarding"
            echo "  test    - Test the deployment"
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${BLUE}Access your application at:${NC}"
    echo -e "${GREEN}  Frontend: http://localhost:8080${NC}"
    echo -e "${GREEN}  Backend:  http://localhost:3000${NC}"
}

# Run main function
main "$@"
