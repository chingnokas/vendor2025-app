#!/bin/bash

echo "🚀 Full Stack Connection Test"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Rebuilding frontend with updated auth service...${NC}"
nerdctl compose build frontend

echo -e "${BLUE}Step 2: Restarting all services...${NC}"
nerdctl compose down
nerdctl compose up -d

echo -e "${BLUE}Step 3: Waiting for services to start...${NC}"
sleep 10

echo -e "${BLUE}Step 4: Checking service status...${NC}"
nerdctl compose ps

echo -e "${BLUE}Step 5: Testing backend health...${NC}"
HEALTH_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" http://localhost:3002/health)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
    exit 1
fi

echo -e "${BLUE}Step 6: Testing frontend accessibility...${NC}"
FRONTEND_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" http://localhost:8080)
FRONTEND_CODE=$(echo "$FRONTEND_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$FRONTEND_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Frontend is accessible${NC}"
else
    echo -e "${RED}❌ Frontend not accessible${NC}"
fi

echo -e "${BLUE}Step 7: Testing API registration...${NC}"
REG_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:3002/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "testpass123",
    "name": "Test User",
    "role": "user"
  }')

REG_CODE=$(echo "$REG_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$REG_CODE" = "201" ] || [ "$REG_CODE" = "400" ]; then
    echo -e "${GREEN}✅ Registration endpoint working${NC}"
else
    echo -e "${RED}❌ Registration failed (HTTP $REG_CODE)${NC}"
fi

echo -e "${BLUE}Step 8: Checking database...${NC}"
DB_RESULT=$(nerdctl exec auth-mariadb mysql -u root -proot -e "USE auth_db; SELECT COUNT(*) as user_count FROM users;" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database accessible${NC}"
    echo "$DB_RESULT"
else
    echo -e "${RED}❌ Database query failed${NC}"
fi

echo ""
echo -e "${YELLOW}🎯 Test Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Open your browser to http://localhost:8080"
echo "2. Open Developer Tools (F12) and go to Network tab"
echo "3. Try to sign up with a new user"
echo "4. Watch for HTTP requests to localhost:3002"
echo "5. Check Console tab for detailed logs"
echo ""
echo -e "${GREEN}🔍 What to look for in Network tab:${NC}"
echo "- POST request to http://localhost:3002/api/auth/register"
echo "- Status should be 201 (success) or 400 (user exists)"
echo "- Response should contain 'token' and 'userId'"
echo ""
echo -e "${YELLOW}📊 Backend logs:${NC}"
nerdctl compose logs --tail=5 backend
