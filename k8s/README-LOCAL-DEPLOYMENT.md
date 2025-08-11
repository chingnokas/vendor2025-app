# Kubernetes Local Deployment Guide

This guide explains how to deploy and run the Auth Stack application locally using Kubernetes with kubectl commands.

## Prerequisites

- **Kubernetes Cluster**: Rancher Desktop, Docker Desktop, minikube, or kind
- **kubectl**: Kubernetes command-line tool
- **Local Kubernetes Context**: Ensure you're connected to your local cluster

## Quick Start

### 1. Verify Kubernetes Cluster

```bash
# Check if kubectl is installed
kubectl version --client

# Check cluster connection
kubectl cluster-info

# Verify you're using the correct context (should be local)
kubectl config current-context

# Switch to local context if needed (examples)
kubectl config use-context rancher-desktop
# or
kubectl config use-context docker-desktop
# or
kubectl config use-context minikube
```

### 2. Deploy the Application

```bash
# Deploy the complete auth stack
kubectl apply -f k8s/deployment-local.yml

# Verify deployment
kubectl get all -n auth-app
```

### 3. Monitor Deployment Progress

```bash
# Watch pods starting up
kubectl get pods -n auth-app -w

# Check pod logs if needed
kubectl logs -n auth-app deployment/mariadb-deployment
kubectl logs -n auth-app deployment/backend-deployment
kubectl logs -n auth-app deployment/frontend-deployment
```

### 4. Access the Application

#### Option A: Port Forwarding (Recommended)

```bash
# Forward frontend service to localhost
kubectl port-forward -n auth-app svc/frontend-service 8080:8080

# In another terminal, forward backend service
kubectl port-forward -n auth-app svc/backend-service 3000:3000

# Access the application
curl http://localhost:8080
```

#### Option B: LoadBalancer External IP (if supported)

```bash
# Get external IP
kubectl get svc -n auth-app frontend-service

# Access via external IP (replace with actual IP)
curl http://192.168.5.15:8080
```

## Detailed Commands

### Deployment Management

```bash
# Apply deployment
kubectl apply -f k8s/deployment-local.yml

# Update deployment (after making changes)
kubectl apply -f k8s/deployment-local.yml

# Delete deployment
kubectl delete -f k8s/deployment-local.yml

# Or delete namespace (removes everything)
kubectl delete namespace auth-app
```

### Monitoring and Debugging

```bash
# Get all resources in auth-app namespace
kubectl get all -n auth-app

# Describe specific resources
kubectl describe pod -n auth-app <pod-name>
kubectl describe svc -n auth-app frontend-service

# Check logs
kubectl logs -n auth-app deployment/mariadb-deployment
kubectl logs -n auth-app deployment/backend-deployment -c backend
kubectl logs -n auth-app deployment/backend-deployment -c wait-for-db

# Execute commands in pods
kubectl exec -n auth-app deployment/mariadb-deployment -- mariadb -u auth_user -pauthpass123 -e "SHOW DATABASES;"
kubectl exec -it -n auth-app deployment/backend-deployment -- /bin/sh
```

### Database Operations

```bash
# Connect to MariaDB
kubectl exec -it -n auth-app deployment/mariadb-deployment -- mariadb -u auth_user -pauthpass123 auth_db

# Check database schema
kubectl exec -n auth-app deployment/mariadb-deployment -- mariadb -u auth_user -pauthpass123 auth_db -e "SHOW TABLES;"

# View table structure
kubectl exec -n auth-app deployment/mariadb-deployment -- mariadb -u auth_user -pauthpass123 auth_db -e "DESCRIBE users;"
```

### Scaling Operations

```bash
# Scale frontend replicas
kubectl scale -n auth-app deployment/frontend-deployment --replicas=3

# Scale backend replicas
kubectl scale -n auth-app deployment/backend-deployment --replicas=2

# Check scaling status
kubectl get pods -n auth-app
```

## Application Components

### Services Deployed

| Service | Type | Port | Description |
|---------|------|------|-------------|
| `frontend-service` | LoadBalancer | 8080 | Web frontend interface |
| `backend-service` | ClusterIP | 3000 | API backend service |
| `mariadb-service` | ClusterIP | 3306 | Database service |

### Secrets and Configuration

The deployment includes:
- **MariaDB credentials**: Stored in `mariadb-secret`
- **JWT secret**: Stored in `jwt-secret`
- **Database initialization**: ConfigMap with schema
- **Persistent storage**: 5Gi PVC for MariaDB data

### Resource Limits

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| MariaDB | 250m | 256Mi | 500m | 512Mi |
| Backend | 250m | 256Mi | 500m | 512Mi |
| Frontend | 100m | 128Mi | 250m | 256Mi |

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**
   ```bash
   kubectl describe pod -n auth-app <pod-name>
   # Check for resource constraints or PVC issues
   ```

2. **Backend init container waiting**
   ```bash
   kubectl logs -n auth-app deployment/backend-deployment -c wait-for-db
   # Should show "MariaDB is ready!" when complete
   ```

3. **Database connection issues**
   ```bash
   # Test database connectivity
   kubectl exec -n auth-app deployment/mariadb-deployment -- mariadb -u auth_user -pauthpass123 -e "SELECT 1;"
   ```

4. **Port forwarding not working**
   ```bash
   # Kill existing port-forward processes
   pkill -f "kubectl port-forward"
   
   # Start fresh port-forward
   kubectl port-forward -n auth-app svc/frontend-service 8080:8080
   ```

### Cleanup Commands

```bash
# Stop port forwarding
pkill -f "kubectl port-forward"

# Delete the application
kubectl delete namespace auth-app

# Or delete specific resources
kubectl delete -f k8s/deployment-local.yml

# Verify cleanup
kubectl get all -n auth-app
```

## Development Workflow

### Making Changes

1. **Update the manifest**:
   ```bash
   # Edit deployment-local.yml
   vim k8s/deployment-local.yml
   ```

2. **Apply changes**:
   ```bash
   kubectl apply -f k8s/deployment-local.yml
   ```

3. **Monitor rollout**:
   ```bash
   kubectl rollout status -n auth-app deployment/backend-deployment
   kubectl rollout status -n auth-app deployment/frontend-deployment
   ```

### Building Custom Images

To use your own backend/frontend images:

1. **Build and tag images**:
   ```bash
   docker build -t my-auth-backend:latest ./backend
   docker build -t my-auth-frontend:latest ./frontend
   ```

2. **Update deployment-local.yml**:
   ```yaml
   # Replace placeholder images
   image: my-auth-backend:latest
   image: my-auth-frontend:latest
   ```

3. **Apply updated deployment**:
   ```bash
   kubectl apply -f k8s/deployment-local.yml
   ```

## Security Notes

- Default passwords are used for local development only
- In production, use proper secret management
- The deployment uses basic security contexts
- Network policies can be added for additional security

## Next Steps

- Deploy monitoring stack: `kubectl apply -f k8s/monitoring-stack.yml`
- Set up ingress controller for domain-based access
- Implement proper CI/CD pipeline
- Add horizontal pod autoscaling (HPA)

## Support

For issues or questions:
1. Check pod logs: `kubectl logs -n auth-app <pod-name>`
2. Describe resources: `kubectl describe <resource-type> -n auth-app <resource-name>`
3. Verify cluster status: `kubectl cluster-info`