#!/bin/bash

echo "🚀 Testing the complete authentication stack..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Test backend health endpoint
echo -e "\n${YELLOW}=== Testing Backend Health ===${NC}"
if check_service "http://localhost:3002/health" "Backend API"; then
    # Test backend registration
    echo -e "\n${YELLOW}=== Testing User Registration ===${NC}"
    TIMESTAMP=$(date +%s)
    REGISTER_RESPONSE=$(curl -s -X POST http://localhost:3002/api/auth/register \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"test${TIMESTAMP}@example.com\",
            \"password\": \"testpassword123\",
            \"name\": \"Test User\",
            \"role\": \"user\"
        }")
    
    if echo "$REGISTER_RESPONSE" | grep -q "token"; then
        echo -e "${GREEN}✅ User registration successful${NC}"
        
        # Extract token for login test
        TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        
        # Test login
        echo -e "\n${YELLOW}=== Testing User Login ===${NC}"
        LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3002/api/auth/login \
            -H "Content-Type: application/json" \
            -d "{
                \"email\": \"test${TIMESTAMP}@example.com\",
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
    echo -e "${RED}❌ Backend health check failed${NC}"
fi

# Test frontend
echo -e "\n${YELLOW}=== Testing Frontend ===${NC}"
if check_service "http://localhost:8080" "Frontend"; then
    # Check if Angular app loads
    FRONTEND_RESPONSE=$(curl -s http://localhost:8080)
    if echo "$FRONTEND_RESPONSE" | grep -q "app-root"; then
        echo -e "${GREEN}✅ Frontend Angular app is loading${NC}"
    else
        echo -e "${RED}❌ Frontend Angular app not detected${NC}"
    fi
else
    echo -e "${RED}❌ Frontend health check failed${NC}"
fi

# Test database connection (through backend)
echo -e "\n${YELLOW}=== Testing Database Connection ===${NC}"
DB_TEST_RESPONSE=$(curl -s http://localhost:3002/api/auth/register \
    -H "Content-Type: application/json" \
    -d '{
        "email": "dbtest@example.com",
        "password": "testpassword123",
        "name": "DB Test User"
    }')

if echo "$DB_TEST_RESPONSE" | grep -q "token\|already exists"; then
    echo -e "${GREEN}✅ Database connection working${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    echo "Response: $DB_TEST_RESPONSE"
fi

echo -e "\n${YELLOW}=== Stack Test Complete ===${NC}"
echo -e "${GREEN}Frontend: http://localhost:8080${NC}"
echo -e "${GREEN}Backend API: http://localhost:3002${NC}"
echo -e "${GREEN}Database: localhost:3306${NC}"
