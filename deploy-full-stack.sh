#!/bin/bash

# 🚀 Complete Full-Stack Deployment Script
# Deploys infrastructure, monitoring, and applications in one go

echo "🚀 Complete Full-Stack Deployment"
echo "================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-staging}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_usage() {
    echo "Usage: $0 [ENVIRONMENT]"
    echo ""
    echo "Environments:"
    echo "  staging    - Deploy to staging environment (default)"
    echo "  production - Deploy to production environment"
    echo ""
    echo "This script will:"
    echo "  1. 🏗️  Deploy infrastructure with OpenTofu"
    echo "  2. 📊 Deploy monitoring stack (Prometheus + Grafana)"
    echo "  3. 🎯 Deploy auth-stack application"
    echo "  4. 🔍 Verify all deployments"
}

deploy_infrastructure() {
    echo -e "${BLUE}🏗️ Step 1: Deploying infrastructure...${NC}"
    
    ./manage-infrastructure.sh plan "$ENVIRONMENT"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Infrastructure planning failed${NC}"
        exit 1
    fi
    
    ./manage-infrastructure.sh apply "$ENVIRONMENT"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Infrastructure deployment failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"
}

deploy_monitoring() {
    echo -e "${BLUE}📊 Step 2: Deploying monitoring stack...${NC}"
    
    # Set kubeconfig
    export KUBECONFIG="infrastructure/kubeconfig-${ENVIRONMENT}.yaml"
    
    # Check cluster connectivity
    kubectl cluster-info --request-timeout=10s
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    
    # Deploy monitoring
    ./deploy-monitoring.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Monitoring deployment failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Monitoring stack deployed successfully${NC}"
}

deploy_applications() {
    echo -e "${BLUE}🎯 Step 3: Deploying applications...${NC}"
    
    # Set kubeconfig
    export KUBECONFIG="infrastructure/kubeconfig-${ENVIRONMENT}.yaml"
    
    # Deploy auth-stack with monitoring enabled
    helm upgrade --install auth-stack helm/auth-stack \
        --namespace auth-app \
        --create-namespace \
        --set monitoring.enabled=true \
        --set image.tag="latest" \
        --set environment="$ENVIRONMENT" \
        --wait \
        --timeout 10m
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Applications deployed successfully${NC}"
    else
        echo -e "${RED}❌ Application deployment failed${NC}"
        exit 1
    fi
}

verify_deployment() {
    echo -e "${BLUE}🔍 Step 4: Verifying deployment...${NC}"
    
    # Set kubeconfig
    export KUBECONFIG="infrastructure/kubeconfig-${ENVIRONMENT}.yaml"
    
    echo -e "${PURPLE}Checking cluster status...${NC}"
    kubectl get nodes
    
    echo ""
    echo -e "${PURPLE}Checking monitoring namespace...${NC}"
    kubectl get pods -n monitoring
    
    echo ""
    echo -e "${PURPLE}Checking auth-app namespace...${NC}"
    kubectl get pods -n auth-app
    
    echo ""
    echo -e "${PURPLE}Checking services...${NC}"
    kubectl get svc -n monitoring
    kubectl get svc -n auth-app
    
    # Check if all pods are running
    FAILED_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
    
    if [ "$FAILED_PODS" -eq 0 ]; then
        echo -e "${GREEN}✅ All pods are running successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Some pods are not running yet. This might be normal during initial deployment.${NC}"
        kubectl get pods --all-namespaces --field-selector=status.phase!=Running
    fi
}

show_access_info() {
    echo ""
    echo -e "${GREEN}🎉 Full-Stack Deployment Complete!${NC}"
    echo ""
    echo -e "${BLUE}🔗 Access Information for $ENVIRONMENT:${NC}"
    echo "============================================"
    echo ""
    echo -e "${YELLOW}📊 Grafana Dashboard:${NC}"
    echo "  kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3001:80"
    echo "  URL: http://localhost:3001"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo ""
    echo -e "${YELLOW}🔍 Prometheus:${NC}"
    echo "  kubectl port-forward -n monitoring svc/monitoring-stack-kube-prometheus-prometheus 9090:9090"
    echo "  URL: http://localhost:9090"
    echo ""
    echo -e "${YELLOW}🎯 Auth Application:${NC}"
    echo "  kubectl port-forward -n auth-app svc/frontend-service 8080:8080"
    echo "  URL: http://localhost:8080"
    echo ""
    echo -e "${YELLOW}🔧 Kubectl Configuration:${NC}"
    echo "  export KUBECONFIG=infrastructure/kubeconfig-${ENVIRONMENT}.yaml"
    echo ""
    echo -e "${BLUE}📋 Useful Commands:${NC}"
    echo "  kubectl get pods --all-namespaces"
    echo "  kubectl logs -n auth-app deployment/backend"
    echo "  kubectl logs -n monitoring deployment/monitoring-stack-grafana"
    echo ""
    echo -e "${PURPLE}🏗️ Infrastructure Management:${NC}"
    echo "  ./manage-infrastructure.sh status $ENVIRONMENT"
    echo "  ./manage-infrastructure.sh destroy $ENVIRONMENT  # To clean up"
    echo ""
    echo -e "${GREEN}🎊 Your full-stack application is ready!${NC}"
}

cleanup_on_error() {
    echo -e "${RED}❌ Deployment failed. Cleaning up...${NC}"
    
    # Optionally clean up on error
    read -p "Do you want to destroy the infrastructure to avoid charges? (y/N): " cleanup
    if [[ $cleanup =~ ^[Yy]$ ]]; then
        ./manage-infrastructure.sh destroy "$ENVIRONMENT"
    fi
}

# Main deployment flow
case $1 in
    -h|--help|help)
        show_usage
        exit 0
        ;;
    *)
        echo -e "${BLUE}🚀 Starting full-stack deployment for $ENVIRONMENT environment...${NC}"
        echo ""
        
        # Set error handling
        trap cleanup_on_error ERR
        
        # Execute deployment steps
        deploy_infrastructure
        sleep 30  # Wait for cluster to be fully ready
        deploy_monitoring
        sleep 10  # Wait for monitoring to be ready
        deploy_applications
        sleep 5   # Wait for applications to start
        verify_deployment
        show_access_info
        
        echo ""
        echo -e "${GREEN}🎉 Full-stack deployment completed successfully!${NC}"
        ;;
esac
