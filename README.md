# 🔐 Authentication Stack

A complete full-stack authentication system with Angular frontend, Express.js backend, and MariaDB database, deployable with both Docker Compose and Kubernetes.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Angular       │    │   Express.js    │    │   MariaDB       │
│   Frontend      │◄──►│   Backend       │◄──►│   Database      │
│   Port: 8080    │    │   Port: 3000    │    │   Port: 3306    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Features

### Frontend (Angular 20)
- Modern Angular application
- JWT token-based authentication
- Responsive design
- Development and production builds

### Backend (Express.js + Node.js)
- RESTful API with JWT authentication
- User registration and login
- Password recovery system
- Security middleware (Helmet, CORS)
- MariaDB integration

### Database (MariaDB 11.0)
- User management with roles
- Refresh token support
- Persistent storage
- Database initialization scripts

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

## 🐳 Docker Compose Deployment

### Quick Start
```bash
# Start the complete stack
docker-compose up --build -d

# Test the deployment
./test-stack.sh

# Access applications
# Frontend: http://localhost:8080
# Backend: http://localhost:3002
# Database: localhost:3306
```

### Commands
```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild specific service
docker-compose build backend
```

## ☸️ Kubernetes Deployment

### Prerequisites
- Kubernetes cluster (local or cloud)
- kubectl configured

### Deploy
```bash
# Deploy the complete stack
kubectl apply -f k8s/deployment.yml

# Check status
kubectl get all -n auth-app

# Port forwarding for local access
kubectl port-forward -n auth-app svc/frontend-service 8080:8080 &
kubectl port-forward -n auth-app svc/backend-service 3000:3000 &
```

### Automated Scripts
```bash
# Deploy with automation
./k8s/deploy.sh

# Test the deployment
./k8s/test-k8s-stack.sh

# Cleanup
./k8s/cleanup.sh
```

## 🧪 Testing

### Docker Compose
```bash
# Run comprehensive tests
./test-stack.sh

# Test specific components
curl http://localhost:3002/health
curl http://localhost:8080
```

### Kubernetes
```bash
# Run K8s-specific tests
./k8s/test-k8s-stack.sh

# Test individual components
./k8s/test-k8s-stack.sh api
./k8s/test-k8s-stack.sh frontend
./k8s/test-k8s-stack.sh database
```

## 🔧 Development

### Local Development
```bash
# Frontend development
npm install
npm start

# Backend development
cd backend
npm install
npm run dev
```

### Environment Variables
```bash
# Backend (.env)
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=root
DB_NAME=auth_db
JWT_SECRET=your-secret-key
PORT=3000
```

## 📁 Project Structure

```
├── src/                    # Angular frontend source
├── backend/               # Express.js backend
│   ├── src/
│   │   ├── routes/       # API routes
│   │   ├── models/       # Database models
│   │   ├── middleware/   # Auth middleware
│   │   └── config/       # Database config
│   └── Dockerfile
├── k8s/                  # Kubernetes manifests
│   ├── deployment.yml    # Complete K8s deployment
│   ├── deploy.sh        # Deployment script
│   ├── cleanup.sh       # Cleanup script
│   └── test-k8s-stack.sh # Testing script
├── docker-compose.yml    # Docker Compose configuration
├── test-stack.sh        # Docker testing script
└── README.md
```

## 🔐 Security Features

- JWT token-based authentication
- Password hashing with bcrypt
- CORS protection
- Helmet security headers
- Input validation
- SQL injection protection
- Environment variable configuration

## 🚀 Deployment Options

1. **Docker Compose** - Perfect for development and testing
2. **Kubernetes** - Production-ready with scaling and orchestration
3. **Local Development** - Individual service development

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Check the documentation in each deployment folder
- Review the test scripts for usage examples
