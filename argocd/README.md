# 🚀 ArgoCD GitOps Deployment for Authentication Stack

This directory contains ArgoCD configurations for GitOps-based deployment of the authentication stack. The setup provides automated deployment triggered by GitHub Actions when code changes are pushed.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub        │    │   GitHub        │    │   ArgoCD        │
│   Repository    │───►│   Actions       │───►│   Application   │
│   (Source)      │    │   (CI/CD)       │    │   (Deployment)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       ▼
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │   Container     │    │   Kubernetes    │
         │              │   Registry      │    │   Cluster       │
         │              │   (GHCR)        │    │   (Target)      │
         │              └─────────────────┘    └─────────────────┘
         │                                              │
         └──────────────────────────────────────────────┘
                        GitOps Pull Model
```

## 📋 Prerequisites

- Kubernetes cluster (1.19+)
- kubectl configured
- ArgoCD installed (or use the setup script)
- GitHub repository with Actions enabled
- Container registry access (GitHub Container Registry)

## 🚀 Quick Start

### 1. Install ArgoCD and Setup Application
```bash
# Run the automated setup script
./argocd/setup-argocd.sh

# Or install manually
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Configure GitHub Actions
The GitHub Actions workflow (`.github/workflows/ci.yml`) is already configured to:
- Build Docker images on code changes
- Push images to GitHub Container Registry
- Update Helm values with new image tags
- Trigger ArgoCD sync (optional)

### 3. Access ArgoCD UI
```bash
# Port forward to ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access UI at https://localhost:8080
# Username: admin
# Password: (from above command)
```

## 📁 File Structure

```
argocd/
├── 📖 README.md                    # This documentation
├── 🚀 setup-argocd.sh             # Automated setup script
├── 📋 application.yaml             # ArgoCD Application definition
├── 🏗️ project.yaml                # ArgoCD Project definition
├── ⚙️ values-production.yaml       # Production Helm values override
└── 🔧 values-staging.yaml          # Staging Helm values override (optional)
```

## ⚙️ Configuration Files

### Application Configuration (`application.yaml`)
Defines the ArgoCD application with:
- **Source**: GitHub repository and Helm chart path
- **Destination**: Target Kubernetes cluster and namespace
- **Sync Policy**: Automated sync with self-healing
- **Health Checks**: Application health monitoring

### Project Configuration (`project.yaml`)
Defines the ArgoCD project with:
- **Source Repositories**: Allowed Git repositories
- **Destinations**: Allowed clusters and namespaces
- **Resource Whitelist**: Permitted Kubernetes resources
- **RBAC**: Role-based access control

### Production Values (`values-production.yaml`)
Production-specific overrides including:
- **Scaling**: Higher replica counts
- **Resources**: Production resource limits
- **Security**: Enhanced security contexts
- **Persistence**: Production storage configuration
- **Ingress**: TLS and domain configuration

## 🔄 GitOps Workflow

### 1. Code Changes
When you push changes to the frontend or backend:

```bash
git add .
git commit -m "feat: update frontend component"
git push origin main
```

### 2. GitHub Actions Pipeline
The CI/CD pipeline automatically:
1. **Detects Changes**: Identifies which components changed
2. **Builds Images**: Creates new Docker images
3. **Pushes to Registry**: Uploads to GitHub Container Registry
4. **Updates Manifests**: Modifies Helm values with new image tags
5. **Commits Changes**: Pushes updated manifests back to repo

### 3. ArgoCD Sync
ArgoCD automatically:
1. **Detects Changes**: Monitors repository for manifest updates
2. **Syncs Application**: Applies changes to Kubernetes cluster
3. **Health Checks**: Verifies application health
4. **Self-Healing**: Corrects any configuration drift

## 🧪 Testing the Pipeline

### Test Frontend Changes
```bash
# Make a change to frontend code
echo "console.log('Pipeline test');" >> src/main.ts

# Commit and push
git add src/main.ts
git commit -m "test: trigger frontend pipeline"
git push origin main

# Watch GitHub Actions
# Check ArgoCD UI for sync status
```

### Test Backend Changes
```bash
# Make a change to backend code
echo "// Pipeline test" >> backend/src/index.js

# Commit and push
git add backend/src/index.js
git commit -m "test: trigger backend pipeline"
git push origin main
```

## 📊 Monitoring and Observability

### ArgoCD Application Status
```bash
# Check application status
argocd app get auth-stack

# View sync history
argocd app history auth-stack

# Check application health
argocd app get auth-stack --show-params
```

### Kubernetes Resources
```bash
# Check deployed resources
kubectl get all -n auth-app

# View pod logs
kubectl logs -f -l app=frontend -n auth-app
kubectl logs -f -l app=backend -n auth-app
kubectl logs -f -l app=mariadb -n auth-app
```

### GitHub Actions Status
- Visit: https://github.com/chingnokas/vendor2025-app/actions
- Monitor workflow runs and build status
- Check container registry for new images

## 🔧 Management Commands

### Sync Application Manually
```bash
# Sync the application
argocd app sync auth-stack

# Sync and prune unused resources
argocd app sync auth-stack --prune

# Hard refresh (ignore cache)
argocd app sync auth-stack --force
```

### Rollback Application
```bash
# View history
argocd app history auth-stack

# Rollback to previous version
argocd app rollback auth-stack

# Rollback to specific revision
argocd app rollback auth-stack --revision 5
```

### Update Configuration
```bash
# Edit application configuration
kubectl edit application auth-stack -n argocd

# Update Helm values
# Edit helm/auth-stack/values.yaml and push changes
```

## 🔒 Security Considerations

### Image Security
- Images are scanned with Trivy in GitHub Actions
- Use specific image tags instead of `latest` in production
- Enable image signature verification

### Access Control
- Configure RBAC in ArgoCD project
- Use service accounts with minimal permissions
- Enable audit logging

### Network Security
- Configure network policies
- Use TLS for all communications
- Implement ingress security headers

## 🚨 Troubleshooting

### Common Issues

#### Application Out of Sync
```bash
# Check diff between desired and actual state
argocd app diff auth-stack

# Force sync
argocd app sync auth-stack --force
```

#### Image Pull Errors
```bash
# Check image registry credentials
kubectl get secret ghcr-secret -n auth-app -o yaml

# Verify image exists
docker pull ghcr.io/chingnokas/vendor2025-app/frontend:latest
```

#### Health Check Failures
```bash
# Check pod status
kubectl describe pod -l app=frontend -n auth-app

# View application events
kubectl get events -n auth-app --sort-by='.lastTimestamp'
```

### Debug Commands
```bash
# ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd

# Application controller logs
kubectl logs -f deployment/argocd-application-controller -n argocd

# Repository server logs
kubectl logs -f deployment/argocd-repo-server -n argocd
```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Helm Charts](https://helm.sh/docs/)
- [GitHub Actions](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Make changes to the application code
2. Test locally with Docker Compose
3. Push changes to trigger the pipeline
4. Monitor ArgoCD for deployment status
5. Verify application functionality

The GitOps pipeline ensures that your authentication stack is always in sync with your Git repository! 🚀
