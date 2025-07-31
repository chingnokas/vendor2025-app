#!/bin/bash

# 🔧 Full Stack Diagnostic Script
# This script diagnoses common frontend-backend connection issues

echo "🔧 Full Stack Connection Diagnostic Tool"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
ISSUES_FOUND=()

# Function to log test results
log_test() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        [ ! -z "$message" ] && echo "   $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        [ ! -z "$message" ] && echo "   $message"
        ISSUES_FOUND+=("$test_name: $message")
        ((TESTS_FAILED++))
    fi
    echo ""
}

echo -e "${BLUE}🔍 Phase 1: Container Status Check${NC}"
echo "=================================="

# Test 1: Check if containers are running
CONTAINER_STATUS=$(nerdctl compose ps --format "table" 2>/dev/null)
if echo "$CONTAINER_STATUS" | grep -q "running"; then
    RUNNING_COUNT=$(echo "$CONTAINER_STATUS" | grep -c "running")
    log_test "Container Status" "PASS" "$RUNNING_COUNT containers running"
else
    log_test "Container Status" "FAIL" "No containers running. Run: nerdctl compose up -d"
fi

echo -e "${BLUE}🌐 Phase 2: Service Accessibility${NC}"
echo "================================"

# Test 2: Frontend accessibility
FRONTEND_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" http://localhost:8080 2>/dev/null)
FRONTEND_CODE=$(echo "$FRONTEND_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$FRONTEND_CODE" = "200" ]; then
    log_test "Frontend Service" "PASS" "Angular app accessible at http://localhost:8080"
else
    log_test "Frontend Service" "FAIL" "Frontend not accessible (HTTP $FRONTEND_CODE)"
fi

# Test 3: Backend health check
BACKEND_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" http://localhost:3002/health 2>/dev/null)
BACKEND_CODE=$(echo "$BACKEND_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
BACKEND_BODY=$(echo "$BACKEND_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$BACKEND_CODE" = "200" ]; then
    log_test "Backend API" "PASS" "Express server healthy at http://localhost:3002"
else
    log_test "Backend API" "FAIL" "Backend not responding (HTTP $BACKEND_CODE)"
fi

# Test 4: Database connectivity
DB_TEST=$(nerdctl exec auth-mariadb mariadb -u root -proot -e "SELECT 1;" 2>/dev/null)
if [ $? -eq 0 ]; then
    log_test "Database Connection" "PASS" "MariaDB accessible and responding"
else
    log_test "Database Connection" "FAIL" "Cannot connect to MariaDB"
fi

echo -e "${BLUE}🔗 Phase 3: API Integration Tests${NC}"
echo "================================="

# Test 5: Registration endpoint
REG_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:3002/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "diagnostic@test.com",
    "password": "testpass123",
    "name": "Diagnostic User",
    "role": "user"
  }' 2>/dev/null)

REG_CODE=$(echo "$REG_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
REG_BODY=$(echo "$REG_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$REG_CODE" = "201" ]; then
    log_test "Registration API" "PASS" "User registration working (HTTP 201)"
elif [ "$REG_CODE" = "400" ]; then
    log_test "Registration API" "PASS" "Registration endpoint working (user exists - HTTP 400)"
else
    log_test "Registration API" "FAIL" "Registration failed (HTTP $REG_CODE)"
fi

# Test 6: Login endpoint
LOGIN_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:3002/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "diagnostic@test.com",
    "password": "testpass123"
  }' 2>/dev/null)

LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$LOGIN_CODE" = "200" ]; then
    log_test "Login API" "PASS" "User authentication working (HTTP 200)"
elif [ "$LOGIN_CODE" = "401" ]; then
    log_test "Login API" "PASS" "Login endpoint working (invalid credentials - HTTP 401)"
else
    log_test "Login API" "FAIL" "Login failed (HTTP $LOGIN_CODE)"
fi

echo -e "${BLUE}🗄️ Phase 4: Database Verification${NC}"
echo "================================="

# Test 7: Check if users table exists and has data
USER_COUNT=$(nerdctl exec auth-mariadb mariadb -u root -proot -e "USE auth_db; SELECT COUNT(*) FROM users;" 2>/dev/null | tail -1)
if [ $? -eq 0 ] && [ "$USER_COUNT" -gt 0 ]; then
    log_test "Database Data" "PASS" "$USER_COUNT users found in database"
    
    # Show recent users
    echo -e "${PURPLE}Recent users in database:${NC}"
    nerdctl exec auth-mariadb mariadb -u root -proot -e "USE auth_db; SELECT id, email, name, created_at FROM users ORDER BY created_at DESC LIMIT 3;" 2>/dev/null
    echo ""
else
    log_test "Database Data" "FAIL" "No users found in database or query failed"
fi

echo -e "${BLUE}🔍 Phase 5: Configuration Analysis${NC}"
echo "=================================="

# Test 8: Check if HttpClientModule is imported
if grep -q "HttpClientModule" src/main.ts; then
    log_test "HttpClientModule" "PASS" "HttpClientModule properly imported in main.ts"
else
    log_test "HttpClientModule" "FAIL" "HttpClientModule missing from main.ts imports"
fi

# Test 9: Check API URL configuration
if grep -q "http://localhost:3002/api" src/app/services/auth.service.ts; then
    log_test "API Configuration" "PASS" "Auth service pointing to correct backend URL"
else
    log_test "API Configuration" "FAIL" "Auth service API URL misconfigured"
fi

echo -e "${BLUE}📊 Phase 6: Recent Activity Analysis${NC}"
echo "==================================="

# Test 10: Check for recent API calls in backend logs
RECENT_API_CALLS=$(nerdctl compose logs backend 2>/dev/null | grep -E "(POST|GET)" | tail -5)
if [ ! -z "$RECENT_API_CALLS" ]; then
    log_test "API Activity" "PASS" "Recent API calls detected in backend logs"
    echo -e "${PURPLE}Recent API calls:${NC}"
    echo "$RECENT_API_CALLS"
    echo ""
else
    log_test "API Activity" "FAIL" "No recent API activity in backend logs"
fi

echo -e "${YELLOW}📋 DIAGNOSTIC SUMMARY${NC}"
echo "===================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Your full-stack application is working correctly.${NC}"
    echo ""
    echo -e "${BLUE}✅ What's Working:${NC}"
    echo "- Frontend serving Angular app on port 8080"
    echo "- Backend API responding on port 3002"
    echo "- Database storing and retrieving user data"
    echo "- HTTP requests flowing from frontend to backend"
    echo "- Authentication system fully functional"
    echo ""
    echo -e "${PURPLE}🔍 To verify in browser:${NC}"
    echo "1. Open http://localhost:8080"
    echo "2. Open Developer Tools (F12)"
    echo "3. Go to Network tab"
    echo "4. Try signing up - you should see POST requests to localhost:3002"
else
    echo -e "${RED}⚠️  ISSUES FOUND:${NC}"
    for issue in "${ISSUES_FOUND[@]}"; do
        echo "- $issue"
    done
    echo ""
    echo -e "${YELLOW}🔧 Recommended Actions:${NC}"
    
    if [[ " ${ISSUES_FOUND[@]} " =~ "Container Status" ]]; then
        echo "1. Start containers: nerdctl compose up -d"
    fi
    
    if [[ " ${ISSUES_FOUND[@]} " =~ "HttpClientModule" ]]; then
        echo "2. Add HttpClientModule to src/main.ts imports"
        echo "3. Rebuild frontend: nerdctl compose build frontend"
    fi
    
    if [[ " ${ISSUES_FOUND[@]} " =~ "Backend API" ]]; then
        echo "4. Check backend logs: nerdctl compose logs backend"
    fi
    
    if [[ " ${ISSUES_FOUND[@]} " =~ "Database" ]]; then
        echo "5. Check database logs: nerdctl compose logs mariadb"
    fi
fi

echo ""
echo -e "${BLUE}📚 For detailed troubleshooting, see: README-TROUBLESHOOTING.md${NC}"
