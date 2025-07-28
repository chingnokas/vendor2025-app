#!/bin/bash

# Kubernetes Cleanup Script for Authentication Stack
# This script removes the deployed stack and cleans up resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="auth-app"

echo -e "${BLUE}🧹 Kubernetes Authentication Stack Cleanup${NC}"
echo "============================================="

# Function to stop port forwarding
stop_port_forwarding() {
    echo -e "\n${YELLOW}🔌 Stopping Port Forwarding...${NC}"
    
    # Kill frontend port forwarding
    if [ -f /tmp/k8s-frontend-pf.pid ]; then
        FRONTEND_PID=$(cat /tmp/k8s-frontend-pf.pid)
        if kill $FRONTEND_PID 2>/dev/null; then
            echo -e "${GREEN}✅ Stopped frontend port forwarding (PID: $FRONTEND_PID)${NC}"
        fi
        rm -f /tmp/k8s-frontend-pf.pid
    fi
    
    # Kill backend port forwarding
    if [ -f /tmp/k8s-backend-pf.pid ]; then
        BACKEND_PID=$(cat /tmp/k8s-backend-pf.pid)
        if kill $BACKEND_PID 2>/dev/null; then
            echo -e "${GREEN}✅ Stopped backend port forwarding (PID: $BACKEND_PID)${NC}"
        fi
        rm -f /tmp/k8s-backend-pf.pid
    fi
    
    # Kill any remaining kubectl port-forward processes
    pkill -f "kubectl port-forward.*$NAMESPACE" 2>/dev/null || true
    echo -e "${GREEN}✅ All port forwarding processes stopped${NC}"
}

# Function to delete Kubernetes resources
delete_k8s_resources() {
    echo -e "\n${YELLOW}☸️  Deleting Kubernetes Resources...${NC}"
    
    # Check if namespace exists
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        echo -e "${BLUE}Deleting resources in namespace: $NAMESPACE${NC}"
        
        # Delete using the deployment file
        if [ -f deployment.yml ]; then
            kubectl delete -f deployment.yml --ignore-not-found=true
            echo -e "${GREEN}✅ Resources deleted using deployment.yml${NC}"
        else
            # Fallback: delete namespace directly
            kubectl delete namespace $NAMESPACE --ignore-not-found=true
            echo -e "${GREEN}✅ Namespace $NAMESPACE deleted${NC}"
        fi
        
        # Wait for namespace to be fully deleted
        echo -e "${BLUE}Waiting for namespace to be fully deleted...${NC}"
        kubectl wait --for=delete namespace/$NAMESPACE --timeout=60s 2>/dev/null || true
        echo -e "${GREEN}✅ Namespace cleanup completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Namespace $NAMESPACE does not exist${NC}"
    fi
}

# Function to clean up Docker images (optional)
cleanup_docker_images() {
    echo -e "\n${YELLOW}🐳 Docker Image Cleanup (Optional)${NC}"
    
    read -p "Do you want to remove the Docker images? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Removing Docker images...${NC}"
        
        # Remove backend image
        if docker image inspect auth-backend:latest &> /dev/null; then
            docker rmi auth-backend:latest
            echo -e "${GREEN}✅ Removed auth-backend:latest${NC}"
        fi
        
        # Remove frontend image
        if docker image inspect angular-service-portal:latest &> /dev/null; then
            docker rmi angular-service-portal:latest
            echo -e "${GREEN}✅ Removed angular-service-portal:latest${NC}"
        fi
        
        # Clean up dangling images
        docker image prune -f
        echo -e "${GREEN}✅ Cleaned up dangling images${NC}"
    else
        echo -e "${YELLOW}⏭️  Skipping Docker image cleanup${NC}"
    fi
}

# Function to show cleanup status
show_cleanup_status() {
    echo -e "\n${YELLOW}📊 Cleanup Status${NC}"
    echo "=================="
    
    # Check if namespace still exists
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        echo -e "${RED}❌ Namespace $NAMESPACE still exists${NC}"
        kubectl get all -n $NAMESPACE
    else
        echo -e "${GREEN}✅ Namespace $NAMESPACE has been removed${NC}"
    fi
    
    # Check for running port-forward processes
    if pgrep -f "kubectl port-forward.*$NAMESPACE" &> /dev/null; then
        echo -e "${RED}❌ Some port-forward processes are still running${NC}"
        pgrep -f "kubectl port-forward.*$NAMESPACE"
    else
        echo -e "${GREEN}✅ No port-forward processes running${NC}"
    fi
}

# Function to show help
show_help() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Options:"
    echo "  --all, -a       Complete cleanup (resources + Docker images)"
    echo "  --k8s-only      Only cleanup Kubernetes resources"
    echo "  --port-forward  Only stop port forwarding"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Interactive cleanup"
    echo "  $0 --all        # Complete cleanup without prompts"
    echo "  $0 --k8s-only   # Only remove Kubernetes resources"
}

# Main execution
main() {
    case "${1:-interactive}" in
        "--all"|"-a")
            stop_port_forwarding
            delete_k8s_resources
            # Force Docker cleanup without prompt
            echo -e "${BLUE}Removing Docker images...${NC}"
            docker rmi auth-backend:latest 2>/dev/null || true
            docker rmi angular-service-portal:latest 2>/dev/null || true
            docker image prune -f
            echo -e "${GREEN}✅ Docker images cleaned up${NC}"
            ;;
        "--k8s-only")
            stop_port_forwarding
            delete_k8s_resources
            ;;
        "--port-forward")
            stop_port_forwarding
            ;;
        "--help"|"-h")
            show_help
            exit 0
            ;;
        "interactive")
            stop_port_forwarding
            delete_k8s_resources
            cleanup_docker_images
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
    
    show_cleanup_status
    
    echo -e "\n${GREEN}🎉 Cleanup completed!${NC}"
    echo -e "${BLUE}All authentication stack resources have been removed.${NC}"
}

# Run main function
main "$@"
