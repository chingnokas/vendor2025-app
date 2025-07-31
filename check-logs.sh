#!/bin/bash

echo "📋 Checking All Service Logs"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🔍 Container Status:${NC}"
nerdctl compose ps
echo ""

echo -e "${BLUE}📊 Service Health Check:${NC}"
echo "Frontend (port 8080):"
curl -s -I http://localhost:8080 | head -1 || echo "❌ Frontend not responding"

echo "Backend (port 3002):"
curl -s http://localhost:3002/health || echo "❌ Backend not responding"

echo "Database (port 3306):"
nerdctl exec auth-mariadb mysqladmin -u root -proot ping 2>/dev/null || echo "❌ Database not responding"
echo ""

echo -e "${GREEN}🗄️ MariaDB Logs (last 20 lines):${NC}"
echo "================================================"
nerdctl compose logs --tail=20 mariadb
echo ""

echo -e "${YELLOW}🔧 Backend Logs (last 20 lines):${NC}"
echo "============================================="
nerdctl compose logs --tail=20 backend
echo ""

echo -e "${PURPLE}🎨 Frontend Logs (last 20 lines):${NC}"
echo "==============================================="
nerdctl compose logs --tail=20 frontend
echo ""

echo -e "${BLUE}🔍 Recent Error Analysis:${NC}"
echo "Checking for common issues..."

# Check for database connection errors
DB_ERRORS=$(nerdctl compose logs backend | grep -i "database\|mysql\|mariadb\|connection" | tail -5)
if [ ! -z "$DB_ERRORS" ]; then
    echo -e "${RED}Database Connection Issues Found:${NC}"
    echo "$DB_ERRORS"
else
    echo -e "${GREEN}✅ No database connection errors found${NC}"
fi

# Check for port binding errors
PORT_ERRORS=$(nerdctl compose logs | grep -i "port\|bind\|address" | tail -5)
if [ ! -z "$PORT_ERRORS" ]; then
    echo -e "${RED}Port Binding Issues Found:${NC}"
    echo "$PORT_ERRORS"
else
    echo -e "${GREEN}✅ No port binding errors found${NC}"
fi

# Check for startup errors
STARTUP_ERRORS=$(nerdctl compose logs | grep -i "error\|failed\|exception" | tail -10)
if [ ! -z "$STARTUP_ERRORS" ]; then
    echo -e "${RED}Startup Errors Found:${NC}"
    echo "$STARTUP_ERRORS"
else
    echo -e "${GREEN}✅ No startup errors found${NC}"
fi

echo ""
echo -e "${BLUE}📈 Live Log Monitoring:${NC}"
echo "To monitor logs in real-time, use:"
echo "  nerdctl compose logs -f backend    # Backend logs"
echo "  nerdctl compose logs -f frontend   # Frontend logs"
echo "  nerdctl compose logs -f mariadb    # Database logs"
echo "  nerdctl compose logs -f            # All logs"
echo ""

echo -e "${YELLOW}🧪 Quick API Test:${NC}"
echo "Testing backend API..."
curl -s -X POST http://localhost:3002/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User","role":"user"}' \
  | jq '.' 2>/dev/null || echo "API test failed or jq not installed"
