# 🎯 Authentication Stack Helm Chart

A comprehensive Helm chart for deploying the complete authentication stack with Angular frontend, Express.js backend, and MariaDB database.

## 📋 Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (for MariaDB persistence)

## 🚀 Installation

### Add the Chart Repository (if published)
```bash
helm repo add auth-stack https://chingnokas.github.io/vendor2025-app
helm repo update
```

### Install from Local Chart
```bash
# Clone the repository
git clone https://github.com/chingnokas/vendor2025-app.git
cd vendor2025-app

# Install the chart
helm install my-auth-stack ./helm/auth-stack

# Install with custom values
helm install my-auth-stack ./helm/auth-stack -f my-values.yaml

# Install in a specific namespace
helm install my-auth-stack ./helm/auth-stack --namespace auth-app --create-namespace
```

## ⚙️ Configuration

The following table lists the configurable parameters and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullSecrets` | Global Docker registry secret names | `[]` |
| `global.storageClass` | Global StorageClass for Persistent Volume(s) | `""` |

### Namespace Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.create` | Create namespace | `true` |
| `namespace.name` | Namespace name | `auth-app` |

### Frontend Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.enabled` | Enable frontend deployment | `true` |
| `frontend.replicaCount` | Number of frontend replicas | `2` |
| `frontend.image.repository` | Frontend image repository | `angular-service-portal` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.image.pullPolicy` | Frontend image pull policy | `IfNotPresent` |
| `frontend.service.type` | Frontend service type | `LoadBalancer` |
| `frontend.service.port` | Frontend service port | `8080` |
| `frontend.service.targetPort` | Frontend container port | `80` |
| `frontend.resources.limits.cpu` | Frontend CPU limit | `500m` |
| `frontend.resources.limits.memory` | Frontend memory limit | `512Mi` |
| `frontend.resources.requests.cpu` | Frontend CPU request | `250m` |
| `frontend.resources.requests.memory` | Frontend memory request | `256Mi` |

### Backend Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backend.enabled` | Enable backend deployment | `true` |
| `backend.replicaCount` | Number of backend replicas | `2` |
| `backend.image.repository` | Backend image repository | `chingnokas/b-app` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.image.pullPolicy` | Backend image pull policy | `IfNotPresent` |
| `backend.service.type` | Backend service type | `ClusterIP` |
| `backend.service.port` | Backend service port | `3000` |
| `backend.service.targetPort` | Backend container port | `3000` |
| `backend.env.NODE_ENV` | Node environment | `production` |
| `backend.env.PORT` | Backend port | `"3000"` |
| `backend.env.DB_HOST` | Database host | `mariadb-service` |
| `backend.env.DB_USER` | Database user | `root` |
| `backend.env.DB_NAME` | Database name | `auth_db` |
| `backend.secrets.dbPassword` | Database password | `root` |
| `backend.secrets.jwtSecret` | JWT secret key | `your-super-secret-jwt-key-change-in-production` |
| `backend.resources.limits.cpu` | Backend CPU limit | `500m` |
| `backend.resources.limits.memory` | Backend memory limit | `512Mi` |
| `backend.resources.requests.cpu` | Backend CPU request | `250m` |
| `backend.resources.requests.memory` | Backend memory request | `256Mi` |

### MariaDB Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mariadb.enabled` | Enable MariaDB deployment | `true` |
| `mariadb.replicaCount` | Number of MariaDB replicas | `1` |
| `mariadb.image.repository` | MariaDB image repository | `mariadb` |
| `mariadb.image.tag` | MariaDB image tag | `"11.0"` |
| `mariadb.image.pullPolicy` | MariaDB image pull policy | `IfNotPresent` |
| `mariadb.service.type` | MariaDB service type | `ClusterIP` |
| `mariadb.service.port` | MariaDB service port | `3306` |
| `mariadb.service.targetPort` | MariaDB container port | `3306` |
| `mariadb.auth.rootPassword` | MariaDB root password | `root` |
| `mariadb.auth.database` | MariaDB database name | `auth_db` |
| `mariadb.auth.username` | MariaDB user | `auth_user` |
| `mariadb.auth.password` | MariaDB user password | `auth_password` |
| `mariadb.persistence.enabled` | Enable persistence | `true` |
| `mariadb.persistence.storageClass` | Storage class | `""` |
| `mariadb.persistence.accessMode` | Access mode | `ReadWriteOnce` |
| `mariadb.persistence.size` | Storage size | `5Gi` |
| `mariadb.resources.limits.cpu` | MariaDB CPU limit | `500m` |
| `mariadb.resources.limits.memory` | MariaDB memory limit | `512Mi` |
| `mariadb.resources.requests.cpu` | MariaDB CPU request | `250m` |
| `mariadb.resources.requests.memory` | MariaDB memory request | `256Mi` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | Ingress TLS configuration | `[]` |

## 📝 Examples

### Basic Installation
```bash
helm install my-auth-stack ./helm/auth-stack
```

### Custom Values Example
```yaml
# custom-values.yaml
frontend:
  replicaCount: 3
  service:
    type: NodePort

backend:
  replicaCount: 3
  secrets:
    jwtSecret: "my-super-secret-jwt-key"

mariadb:
  auth:
    rootPassword: "my-secure-password"
  persistence:
    size: 10Gi

ingress:
  hosts:
    - host: my-auth-app.example.com
      paths:
        - path: /
          pathType: Prefix
          service: frontend-service
          port: 8080
        - path: /api
          pathType: Prefix
          service: backend-service
          port: 3000
```

```bash
helm install my-auth-stack ./helm/auth-stack -f custom-values.yaml
```

### Production Installation
```bash
helm install auth-stack ./helm/auth-stack \
  --set backend.secrets.jwtSecret="production-jwt-secret" \
  --set mariadb.auth.rootPassword="secure-db-password" \
  --set mariadb.persistence.size="20Gi" \
  --set frontend.replicaCount=3 \
  --set backend.replicaCount=3 \
  --namespace production \
  --create-namespace
```

## 🔧 Management

### Upgrade
```bash
helm upgrade my-auth-stack ./helm/auth-stack
```

### Rollback
```bash
helm rollback my-auth-stack 1
```

### Uninstall
```bash
helm uninstall my-auth-stack
```

### Status
```bash
helm status my-auth-stack
```

## 🧪 Testing

### Lint the Chart
```bash
helm lint ./helm/auth-stack
```

### Template Rendering
```bash
helm template my-auth-stack ./helm/auth-stack
```

### Dry Run
```bash
helm install my-auth-stack ./helm/auth-stack --dry-run --debug
```

## 🔒 Security Considerations

1. **Change Default Passwords**: Always change default passwords in production
2. **Use Secrets**: Store sensitive data in Kubernetes secrets
3. **Network Policies**: Enable network policies for additional security
4. **RBAC**: Configure appropriate RBAC permissions
5. **TLS**: Enable TLS for ingress in production

## 📚 Documentation

- [Chart Source](https://github.com/chingnokas/vendor2025-app)
- [Issues](https://github.com/chingnokas/vendor2025-app/issues)
- [Contributing](https://github.com/chingnokas/vendor2025-app/blob/main/CONTRIBUTING.md)

## 📄 License

This chart is licensed under the MIT License. See [LICENSE](https://github.com/chingnokas/vendor2025-app/blob/main/LICENSE) for details.
