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

## ⎈ Helm Deployment

### Prerequisites
- Kubernetes cluster
- Helm 3.2.0+

### Deploy
```bash
# Install the Helm chart
helm install my-auth-stack ./helm/auth-stack

# Install with custom values
helm install my-auth-stack ./helm/auth-stack -f custom-values.yaml

# Upgrade existing deployment
helm upgrade my-auth-stack ./helm/auth-stack
```

### Automated Helm Deployment
```bash
# Deploy with automation script
./helm/deploy-helm.sh

# Upgrade deployment
./helm/deploy-helm.sh upgrade

# Check status
./helm/deploy-helm.sh status

# Uninstall
./helm/deploy-helm.sh uninstall
```

## 🔄 GitOps CI/CD Pipeline

### Automated Deployment with GitHub Actions + ArgoCD

The repository includes a complete CI/CD pipeline that automatically builds and deploys your application when code changes are pushed.

#### Setup ArgoCD
```bash
# Install ArgoCD and configure the application
./argocd/setup-argocd.sh

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Visit: https://localhost:8080
```

#### How it Works
1. **Push Code Changes** → Triggers GitHub Actions
2. **Build & Push Images** → Updates container registry
3. **Update Manifests** → Commits new image tags
4. **ArgoCD Sync** → Deploys to Kubernetes automatically

#### Trigger Deployment
```bash
# Make changes to frontend
echo "console.log('New feature');" >> src/main.ts
git add . && git commit -m "feat: add new feature" && git push

# Make changes to backend
echo "// New API endpoint" >> backend/src/index.js
git add . && git commit -m "feat: add new API" && git push
```

#### Monitor Deployment
- **GitHub Actions**: https://github.com/chingnokas/vendor2025-app/actions
- **ArgoCD UI**: https://localhost:8080 (after port-forward)
- **Application Status**: `argocd app get auth-stack`

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
├── helm/                 # Helm chart
│   ├── auth-stack/      # Helm chart directory
│   │   ├── Chart.yaml   # Chart metadata
│   │   ├── values.yaml  # Default values
│   │   └── templates/   # Kubernetes templates
│   ├── deploy-helm.sh   # Helm deployment script
│   └── README.md        # Helm documentation
├── argocd/              # GitOps configuration
│   ├── application.yaml # ArgoCD application
│   ├── project.yaml     # ArgoCD project
│   ├── setup-argocd.sh  # ArgoCD setup script
│   ├── values-production.yaml # Production values
│   └── README.md        # GitOps documentation
├── .github/             # GitHub Actions
│   └── workflows/       # CI/CD workflows
│       └── ci.yml       # Main CI/CD pipeline
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
3. **Helm Chart** - Advanced Kubernetes deployment with easy configuration
4. **GitOps with ArgoCD** - Automated CI/CD pipeline with GitHub Actions
5. **Local Development** - Individual service development

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
