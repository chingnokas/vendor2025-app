# Authentication Stack with Docker Compose

This project provides a complete authentication stack with:
- **Frontend**: Angular application (port 8080)
- **Backend**: Express.js API with JWT authentication (port 3001)
- **Database**: MariaDB (port 3306)

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Ports 3000, 3306, and 8080 available

### 1. Start the Stack
```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up --build -d
```

### 2. Test the Stack
```bash
# Run the automated test script
./test-stack.sh
```

### 3. Access the Applications
- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:3001
- **Database**: localhost:3306 (root/root)

## 📋 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh-token` - Refresh JWT token

### Password Recovery
- `POST /api/password/request-reset` - Request password reset
- `GET /api/password/verify-reset/:token` - Verify reset token
- `POST /api/password/reset-password` - Reset password

### Health Check
- `GET /health` - Backend health status

## 🧪 Testing the API

### Register a User
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe",
    "role": "user"
  }'
```

### Login
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

## 🔧 Development

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mariadb
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart backend
```

### Database Access
```bash
# Connect to MariaDB
docker-compose exec mariadb mysql -u root -p auth_db
# Password: root
```

## 🛑 Stop the Stack
```bash
# Stop services
docker-compose down

# Stop and remove volumes (⚠️ deletes database data)
docker-compose down -v
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Angular       │    │   Express.js    │    │   MariaDB       │
│   Frontend      │◄──►│   Backend       │◄──►│   Database      │
│   Port: 8080    │    │   Port: 3000    │    │   Port: 3306    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔐 Security Features

- JWT token-based authentication
- Password hashing with bcrypt
- CORS protection
- Helmet security headers
- Input validation
- SQL injection protection

## 📝 Environment Variables

The backend uses these environment variables (set in docker-compose.yml):
- `DB_HOST=mariadb`
- `DB_USER=root`
- `DB_PASSWORD=root`
- `DB_NAME=auth_db`
- `JWT_SECRET=your-super-secret-jwt-key-change-in-production`
- `PORT=3000`

## 🐛 Troubleshooting

### Services won't start
```bash
# Check if ports are in use
netstat -tulpn | grep -E ':(3000|3306|8080)'

# View detailed logs
docker-compose logs
```

### Database connection issues
```bash
# Check MariaDB health
docker-compose exec mariadb mysqladmin ping -h localhost -u root -p
```

### Frontend build issues
```bash
# Rebuild frontend only
docker-compose build frontend
docker-compose up frontend
```
