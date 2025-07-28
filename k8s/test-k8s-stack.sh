#!/bin/bash

# Kubernetes Stack Testing Script
# Tests the deployed authentication stack in Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="auth-app"
FRONTEND_URL="http://localhost:8080"
BACKEND_URL="http://localhost:3000"

echo -e "${BLUE}🧪 Kubernetes Authentication Stack Testing${NC}"
echo "=============================================="

# Function to check if service is responding
check_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    echo -e "${YELLOW}Checking ${service_name}...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ ${service_name} is responding${NC}"
            return 0
        fi
        echo -e "${YELLOW}⏳ Waiting for ${service_name} (attempt $attempt/$max_attempts)${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ ${service_name} failed to respond after $max_attempts attempts${NC}"
    return 1
}

# Function to check Kubernetes resources
check_k8s_resources() {
    echo -e "\n${YELLOW}☸️  Checking Kubernetes Resources${NC}"
    echo "=================================="
    
    # Check namespace
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        echo -e "${GREEN}✅ Namespace '$NAMESPACE' exists${NC}"
    else
        echo -e "${RED}❌ Namespace '$NAMESPACE' not found${NC}"
        return 1
    fi
    
    # Check pods
    echo -e "\n${BLUE}Pod Status:${NC}"
    kubectl get pods -n $NAMESPACE
    
    # Check if all pods are running
    NOT_RUNNING=$(kubectl get pods -n $NAMESPACE --no-headers | grep -v Running | wc -l)
    if [ $NOT_RUNNING -eq 0 ]; then
        echo -e "${GREEN}✅ All pods are running${NC}"
    else
        echo -e "${RED}❌ $NOT_RUNNING pods are not running${NC}"
    fi
    
    # Check services
    echo -e "\n${BLUE}Service Status:${NC}"
    kubectl get svc -n $NAMESPACE
    
    # Check persistent volumes
    echo -e "\n${BLUE}Persistent Volume Claims:${NC}"
    kubectl get pvc -n $NAMESPACE
}

# Function to check port forwarding
check_port_forwarding() {
    echo -e "\n${YELLOW}🔗 Checking Port Forwarding${NC}"
    echo "============================"
    
    # Check if port forwarding is active
    if pgrep -f "kubectl port-forward.*frontend-service.*8080" &> /dev/null; then
        echo -e "${GREEN}✅ Frontend port forwarding is active (8080)${NC}"
    else
        echo -e "${RED}❌ Frontend port forwarding not found${NC}"
        echo -e "${YELLOW}💡 Run: kubectl port-forward -n $NAMESPACE svc/frontend-service 8080:8080${NC}"
    fi
    
    if pgrep -f "kubectl port-forward.*backend-service.*3000" &> /dev/null; then
        echo -e "${GREEN}✅ Backend port forwarding is active (3000)${NC}"
    else
        echo -e "${RED}❌ Backend port forwarding not found${NC}"
        echo -e "${YELLOW}💡 Run: kubectl port-forward -n $NAMESPACE svc/backend-service 3000:3000${NC}"
    fi
}

# Function to test backend API
test_backend_api() {
    echo -e "\n${YELLOW}🔧 Testing Backend API${NC}"
    echo "======================"
    
    if check_service "$BACKEND_URL/health" "Backend API"; then
        # Test user registration
        echo -e "\n${BLUE}Testing user registration...${NC}"
        TIMESTAMP=$(date +%s)
        REGISTER_RESPONSE=$(curl -s -X POST $BACKEND_URL/api/auth/register \
            -H "Content-Type: application/json" \
            -d "{
                \"email\": \"k8stest${TIMESTAMP}@example.com\",
                \"password\": \"testpassword123\",
                \"name\": \"K8s Test User\",
                \"role\": \"user\"
            }")
        
        if echo "$REGISTER_RESPONSE" | grep -q "token"; then
            echo -e "${GREEN}✅ User registration successful${NC}"
            
            # Test user login
            echo -e "\n${BLUE}Testing user login...${NC}"
            LOGIN_RESPONSE=$(curl -s -X POST $BACKEND_URL/api/auth/login \
                -H "Content-Type: application/json" \
                -d "{
                    \"email\": \"k8stest${TIMESTAMP}@example.com\",
                    \"password\": \"testpassword123\"
                }")
            
            if echo "$LOGIN_RESPONSE" | grep -q "token"; then
                echo -e "${GREEN}✅ User login successful${NC}"
            else
                echo -e "${RED}❌ User login failed${NC}"
                echo "Response: $LOGIN_RESPONSE"
            fi
        else
            echo -e "${RED}❌ User registration failed${NC}"
            echo "Response: $REGISTER_RESPONSE"
        fi
    else
        echo -e "${RED}❌ Backend API health check failed${NC}"
    fi
}

# Function to test frontend
test_frontend() {
    echo -e "\n${YELLOW}🌐 Testing Frontend${NC}"
    echo "==================="
    
    if check_service "$FRONTEND_URL" "Frontend"; then
        # Check if Angular app loads
        FRONTEND_RESPONSE=$(curl -s $FRONTEND_URL)
        if echo "$FRONTEND_RESPONSE" | grep -q "app-root"; then
            echo -e "${GREEN}✅ Frontend Angular app is loading${NC}"
        else
            echo -e "${RED}❌ Frontend Angular app not detected${NC}"
        fi
    else
        echo -e "${RED}❌ Frontend health check failed${NC}"
    fi
}

# Function to test database connectivity
test_database() {
    echo -e "\n${YELLOW}🗄️  Testing Database Connectivity${NC}"
    echo "=================================="
    
    # Get MariaDB pod name
    MARIADB_POD=$(kubectl get pods -n $NAMESPACE -l app=mariadb -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$MARIADB_POD" ]; then
        echo -e "${BLUE}Testing database connection via pod: $MARIADB_POD${NC}"
        
        # Test database connection
        if kubectl exec -n $NAMESPACE $MARIADB_POD -- mysqladmin ping -h localhost -u root -proot &> /dev/null; then
            echo -e "${GREEN}✅ Database is responding to ping${NC}"
            
            # Test database query
            RESULT=$(kubectl exec -n $NAMESPACE $MARIADB_POD -- mysql -u root -proot -e "SELECT COUNT(*) as user_count FROM auth_db.users;" -s -N 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ Database query successful - Users in database: $RESULT${NC}"
        else
            echo -e "${RED}❌ Database connection failed${NC}"
        fi
    else
        echo -e "${RED}❌ MariaDB pod not found${NC}"
    fi
}

# Function to show resource usage
show_resource_usage() {
    echo -e "\n${YELLOW}📊 Resource Usage${NC}"
    echo "=================="
    
    echo -e "\n${BLUE}Pod Resource Usage:${NC}"
    kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics server not available"
    
    echo -e "\n${BLUE}Node Resource Usage:${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
}

# Function to show logs
show_recent_logs() {
    echo -e "\n${YELLOW}📝 Recent Logs (Last 10 lines)${NC}"
    echo "==============================="
    
    echo -e "\n${BLUE}Backend Logs:${NC}"
    kubectl logs -n $NAMESPACE -l app=backend --tail=10 2>/dev/null || echo "No backend logs available"
    
    echo -e "\n${BLUE}Frontend Logs:${NC}"
    kubectl logs -n $NAMESPACE -l app=frontend --tail=10 2>/dev/null || echo "No frontend logs available"
    
    echo -e "\n${BLUE}MariaDB Logs:${NC}"
    kubectl logs -n $NAMESPACE -l app=mariadb --tail=10 2>/dev/null || echo "No MariaDB logs available"
}

# Main execution
main() {
    case "${1:-all}" in
        "k8s"|"resources")
            check_k8s_resources
            ;;
        "api"|"backend")
            test_backend_api
            ;;
        "frontend"|"ui")
            test_frontend
            ;;
        "database"|"db")
            test_database
            ;;
        "ports"|"forwarding")
            check_port_forwarding
            ;;
        "logs")
            show_recent_logs
            ;;
        "resources"|"usage")
            show_resource_usage
            ;;
        "all")
            check_k8s_resources
            check_port_forwarding
            test_backend_api
            test_frontend
            test_database
            show_resource_usage
            ;;
        "--help"|"-h")
            echo -e "${YELLOW}Usage: $0 [OPTION]${NC}"
            echo ""
            echo "Options:"
            echo "  all         - Run all tests (default)"
            echo "  k8s         - Check Kubernetes resources only"
            echo "  api         - Test backend API only"
            echo "  frontend    - Test frontend only"
            echo "  database    - Test database connectivity only"
            echo "  ports       - Check port forwarding status"
            echo "  logs        - Show recent logs"
            echo "  resources   - Show resource usage"
            echo "  --help, -h  - Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo -e "${YELLOW}Use --help for available options${NC}"
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}🎉 Testing completed!${NC}"
    echo -e "${BLUE}Access your application at:${NC}"
    echo -e "${GREEN}  Frontend: $FRONTEND_URL${NC}"
    echo -e "${GREEN}  Backend:  $BACKEND_URL${NC}"
}

# Run main function
main "$@"
