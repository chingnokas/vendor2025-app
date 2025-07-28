# Kubernetes Deployment for Authentication Stack

This directory contains Kubernetes manifests to deploy the complete authentication stack with:
- **Frontend**: Angular application
- **Backend**: Express.js API with JWT authentication  
- **Database**: MariaDB with persistent storage

## 🚀 Prerequisites

- Kubernetes cluster (local or cloud)
- kubectl configured to access your cluster
- Docker images built locally or pushed to a registry

## 📦 Build Docker Images

Before deploying to Kubernetes, build the required Docker images:

```bash
# Build backend image
cd backend
docker build -t auth-backend:latest .

# Build frontend image  
cd ..
docker build -t angular-service-portal:latest .
```

## 🔧 Deploy to Kubernetes

### 1. Deploy the Complete Stack
```bash
# Apply all manifests
kubectl apply -f k8s/deployment.yml

# Check deployment status
kubectl get all -n auth-app
```

### 2. Wait for Services to be Ready
```bash
# Watch pod status
kubectl get pods -n auth-app -w

# Check service endpoints
kubectl get svc -n auth-app
```

### 3. Access the Application

#### Option A: Using LoadBalancer (if supported)
```bash
# Get external IP
kubectl get svc frontend-service -n auth-app

# Access via external IP
curl http://<EXTERNAL-IP>:8080
```

#### Option B: Using Port Forwarding
```bash
# Forward frontend port
kubectl port-forward -n auth-app svc/frontend-service 8080:8080

# Forward backend port (for direct API access)
kubectl port-forward -n auth-app svc/backend-service 3000:3000

# Access applications
# Frontend: http://localhost:8080
# Backend API: http://localhost:3000
```

#### Option C: Using Ingress (requires Ingress Controller)
```bash
# Add to /etc/hosts
echo "127.0.0.1 auth-app.local" | sudo tee -a /etc/hosts

# Access via domain
# Frontend: http://auth-app.local
# Backend API: http://auth-app.local/api
```

## 🧪 Test the Deployment

### Test Backend API
```bash
# Health check
curl http://localhost:3000/health

# Register a user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User",
    "role": "user"
  }'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com", 
    "password": "password123"
  }'
```

### Test Frontend
```bash
# Check if Angular app loads
curl http://localhost:8080
```

## 📊 Monitoring and Debugging

### View Logs
```bash
# All pods in namespace
kubectl logs -f -l app=backend -n auth-app
kubectl logs -f -l app=frontend -n auth-app  
kubectl logs -f -l app=mariadb -n auth-app

# Specific pod
kubectl logs -f <pod-name> -n auth-app
```

### Debug Pods
```bash
# Describe pod for events
kubectl describe pod <pod-name> -n auth-app

# Execute into pod
kubectl exec -it <pod-name> -n auth-app -- /bin/bash

# Check service endpoints
kubectl get endpoints -n auth-app
```

### Database Access
```bash
# Connect to MariaDB
kubectl exec -it <mariadb-pod-name> -n auth-app -- mysql -u root -p auth_db
# Password: root
```

## 🔐 Security Configuration

### Secrets Management
The deployment uses Kubernetes secrets for sensitive data:
- `mariadb-secret`: Database credentials
- `jwt-secret`: JWT signing key

### Update Secrets
```bash
# Update JWT secret
kubectl create secret generic jwt-secret \
  --from-literal=secret='your-new-jwt-secret' \
  --namespace=auth-app \
  --dry-run=client -o yaml | kubectl apply -f -

# Update database password
kubectl create secret generic mariadb-secret \
  --from-literal=root-password='new-password' \
  --from-literal=database='auth_db' \
  --from-literal=username='auth_user' \
  --from-literal=password='new-auth-password' \
  --namespace=auth-app \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 📈 Scaling

### Scale Deployments
```bash
# Scale backend
kubectl scale deployment backend-deployment --replicas=3 -n auth-app

# Scale frontend  
kubectl scale deployment frontend-deployment --replicas=3 -n auth-app

# Check scaling status
kubectl get deployments -n auth-app
```

## 🗑️ Cleanup

### Remove the Complete Stack
```bash
# Delete all resources
kubectl delete -f k8s/deployment.yml

# Or delete namespace (removes everything)
kubectl delete namespace auth-app
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   LoadBalancer  │    │   LoadBalancer  │
│   Controller    │    │   Frontend      │    │   Backend       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Frontend      │    │   Backend       │
│   Service       │◄──►│   Pods (x2)     │◄──►│   Pods (x2)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   MariaDB       │
                                               │   Service       │
                                               └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   MariaDB       │
                                               │   Pod + PVC     │
                                               └─────────────────┘
```

## 🔧 Configuration Details

- **Namespace**: `auth-app`
- **Persistent Storage**: 5Gi for MariaDB data
- **Resource Limits**: 512Mi memory, 500m CPU per pod
- **Health Checks**: Configured for all services
- **Init Containers**: Database readiness check for backend
