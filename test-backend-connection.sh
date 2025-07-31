#!/bin/bash

echo "🔍 Testing Backend API Connection..."
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test 1: Check if backend container is running
echo -e "${BLUE}1. Checking container status...${NC}"
nerdctl compose ps
echo ""

# Test 2: Health Check
echo -e "${BLUE}2. Testing health endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" http://localhost:3002/health)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    echo "$HEALTH_BODY" | jq '.' 2>/dev/null || echo "$HEALTH_BODY"
else
    echo -e "${RED}❌ Health check failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $HEALTH_BODY"
fi
echo ""

# Test 3: Check backend logs
echo -e "${BLUE}3. Backend logs (last 10 lines):${NC}"
nerdctl compose logs --tail=10 backend
echo ""

# Test 4: Test registration endpoint
echo -e "${BLUE}4. Testing user registration...${NC}"
REGISTER_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:3002/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123",
    "name": "Test User",
    "role": "user"
  }')

REG_HTTP_CODE=$(echo "$REGISTER_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
REG_BODY=$(echo "$REGISTER_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

echo "Registration HTTP Code: $REG_HTTP_CODE"
echo "Registration Response:"
echo "$REG_BODY" | jq '.' 2>/dev/null || echo "$REG_BODY"
echo ""

# Test 5: Check database directly
echo -e "${BLUE}5. Checking database directly...${NC}"
DB_RESULT=$(nerdctl exec auth-mariadb mysql -u root -proot -e "USE auth_db; SELECT id, email, name, role, created_at FROM users;" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
    echo "$DB_RESULT"
else
    echo -e "${RED}❌ Database query failed${NC}"
fi
echo ""

# Test 6: Test login if registration was successful
if [ "$REG_HTTP_CODE" = "201" ] || [ "$REG_HTTP_CODE" = "400" ]; then
    echo -e "${BLUE}6. Testing login...${NC}"
    LOGIN_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:3002/api/auth/login \
      -H "Content-Type: application/json" \
      -d '{
        "email": "test@example.com",
        "password": "testpassword123"
      }')

    LOGIN_HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
    LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

    echo "Login HTTP Code: $LOGIN_HTTP_CODE"
    echo "Login Response:"
    echo "$LOGIN_BODY" | jq '.' 2>/dev/null || echo "$LOGIN_BODY"
fi

echo ""
echo -e "${YELLOW}🎯 Connection test complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "- Health endpoint: $([ "$HTTP_CODE" = "200" ] && echo -e "${GREEN}✅ Working${NC}" || echo -e "${RED}❌ Failed${NC}")"
echo "- Registration: $([ "$REG_HTTP_CODE" = "201" ] && echo -e "${GREEN}✅ Working${NC}" || [ "$REG_HTTP_CODE" = "400" ] && echo -e "${YELLOW}⚠️ User exists${NC}" || echo -e "${RED}❌ Failed${NC}")"
echo "- Database: $([ $? -eq 0 ] && echo -e "${GREEN}✅ Connected${NC}" || echo -e "${RED}❌ Failed${NC}")"
