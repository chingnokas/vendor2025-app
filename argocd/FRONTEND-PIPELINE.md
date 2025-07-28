# 🚀 Frontend-Only CI/CD Pipeline with ArgoCD

This document explains the frontend-focused GitOps pipeline that automatically deploys Angular frontend changes using GitHub Actions and ArgoCD.

## 🎯 Pipeline Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   GitHub        │    │   GitHub        │
│   Push Frontend │───►│   Repository    │───►│   Actions       │
│   Changes       │    │   (Source)      │    │   (Build)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                │                       ▼
                                │              ┌─────────────────┐
                                │              │   Container     │
                                │              │   Registry      │
                                │              │   (GHCR)        │
                                │              └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   ArgoCD        │    │   Updated       │
                       │   Auto-Pull     │◄───│   Manifests     │
                       │                 │    │   (Helm Values) │
                       └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Kubernetes    │
                       │   Frontend      │
                       │   Deployment    │
                       └─────────────────┘
```

## 🔧 How It Works

### 1. Frontend Change Detection
The GitHub Actions workflow only triggers on frontend-related changes:

```yaml
on:
  push:
    branches: [ main, develop ]
    paths:
      - 'src/**'           # Angular source code
      - 'package.json'     # Dependencies
      - 'package-lock.json'
      - 'angular.json'     # Angular config
      - 'tsconfig.json'    # TypeScript config
      - 'Dockerfile'       # Frontend container
```

### 2. Automated Build Process
When frontend changes are detected:

1. **Build Docker Image**: Creates new frontend container
2. **Multi-Architecture**: Supports AMD64 and ARM64
3. **Security Scan**: Trivy vulnerability scanning
4. **Push to Registry**: Uploads to GitHub Container Registry
5. **Update Manifests**: Modifies Helm values with new image tag
6. **Commit Changes**: Pushes updated manifests back to repository

### 3. ArgoCD Auto-Pull
ArgoCD continuously monitors the repository and:

1. **Detects Changes**: Notices updated Helm values
2. **Automatic Sync**: Pulls and applies changes
3. **Rolling Update**: Deploys new frontend pods
4. **Health Checks**: Verifies deployment success
5. **Self-Healing**: Corrects any configuration drift

## 🚀 Quick Start

### Setup the Pipeline
```bash
# 1. Install ArgoCD with frontend focus
./argocd/setup-frontend-argocd.sh

# 2. Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Visit: https://localhost:8080
```

### Test the Pipeline
```bash
# 1. Make a frontend change
echo "// Frontend pipeline test" >> src/main.ts

# 2. Commit and push
git add src/main.ts
git commit -m "test: frontend pipeline"
git push origin main

# 3. Watch the magic happen!
# - GitHub Actions builds new image
# - Helm values get updated
# - ArgoCD pulls and deploys automatically
```

## 📊 Monitoring the Pipeline

### GitHub Actions
- **URL**: https://github.com/chingnokas/vendor2025-app/actions
- **Workflow**: `Frontend CI/CD with ArgoCD Auto-Pull`
- **Triggers**: Only on frontend file changes

### ArgoCD Dashboard
```bash
# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Visit: https://localhost:8080

# CLI commands
argocd app get auth-stack-frontend
argocd app sync auth-stack-frontend
argocd app history auth-stack-frontend
```

### Kubernetes Resources
```bash
# Check frontend pods
kubectl get pods -n auth-app -l app=frontend

# View frontend service
kubectl get svc -n auth-app frontend-service

# Check deployment status
kubectl rollout status deployment/frontend-deployment -n auth-app

# View logs
kubectl logs -f -l app=frontend -n auth-app
```

## 🔍 Pipeline Components

### GitHub Actions Workflow
**File**: `.github/workflows/frontend-ci.yml`

**Key Features**:
- Frontend-only change detection
- Multi-architecture Docker builds
- Automatic manifest updates
- Security scanning with Trivy
- Deployment summaries

### ArgoCD Application
**File**: `argocd/frontend-application.yaml`

**Configuration**:
- **Auto-sync**: Enabled for immediate deployment
- **Self-healing**: Corrects configuration drift
- **Pruning**: Removes unused resources
- **Refresh**: Checks for changes every 30 seconds

### Helm Values Updates
The pipeline automatically updates:
```yaml
frontend:
  image:
    repository: ghcr.io/chingnokas/vendor2025-app/frontend
    tag: main-abc1234  # Updated with commit SHA
```

## 🧪 Testing Scenarios

### Test 1: Simple Frontend Change
```bash
# Add a console log
echo "console.log('Pipeline test');" >> src/app/app.component.ts
git add . && git commit -m "test: add console log" && git push
```

### Test 2: Component Update
```bash
# Modify a component
echo "// Updated component" >> src/app/components/home/home.component.ts
git add . && git commit -m "feat: update home component" && git push
```

### Test 3: Styling Changes
```bash
# Update styles
echo "/* New styles */" >> src/global_styles.css
git add . && git commit -m "style: update global styles" && git push
```

### Test 4: Configuration Changes
```bash
# Update Angular config
# Edit angular.json or package.json
git add . && git commit -m "config: update build settings" && git push
```

## 📈 Pipeline Benefits

### ✅ Advantages
- **Fast Deployment**: Frontend changes deploy in minutes
- **Automatic**: No manual intervention required
- **Secure**: Built-in vulnerability scanning
- **Reliable**: Self-healing and rollback capabilities
- **Efficient**: Only builds when frontend changes
- **Scalable**: Multi-architecture support

### 🎯 Use Cases
- **Feature Development**: Rapid frontend feature deployment
- **Bug Fixes**: Quick fixes to UI issues
- **Styling Updates**: Immediate design changes
- **Configuration**: Build and deployment settings
- **Dependencies**: Package updates and security patches

## 🔧 Customization

### Modify Trigger Paths
Edit `.github/workflows/frontend-ci.yml`:
```yaml
paths:
  - 'src/**'
  - 'public/**'      # Add public assets
  - '*.json'         # Add more config files
```

### Change ArgoCD Sync Frequency
Edit `argocd/frontend-application.yaml`:
```yaml
annotations:
  argocd.argoproj.io/refresh: "15s"  # Check every 15 seconds
```

### Update Image Repository
Modify the workflow environment:
```yaml
env:
  REGISTRY: docker.io
  IMAGE_NAME: your-username/frontend
```

## 🚨 Troubleshooting

### Pipeline Not Triggering
**Issue**: GitHub Actions not running on frontend changes

**Solution**:
1. Check file paths in workflow trigger
2. Verify repository permissions
3. Check GitHub Actions are enabled

### ArgoCD Not Syncing
**Issue**: ArgoCD not detecting changes

**Solution**:
```bash
# Force refresh
argocd app get auth-stack-frontend --refresh

# Manual sync
argocd app sync auth-stack-frontend --prune

# Check application status
argocd app get auth-stack-frontend
```

### Image Pull Errors
**Issue**: Kubernetes can't pull new image

**Solution**:
```bash
# Check image exists
docker pull ghcr.io/chingnokas/vendor2025-app/frontend:latest

# Verify registry credentials
kubectl get secret -n auth-app

# Check pod events
kubectl describe pod -l app=frontend -n auth-app
```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

## 🎉 Success!

Your frontend now has a complete GitOps pipeline:

1. **Push frontend changes** to the repository
2. **GitHub Actions builds** and pushes new image
3. **Helm values are updated** with new image tag
4. **ArgoCD automatically pulls** and deploys changes
5. **Frontend is live** with zero manual intervention!

**Frontend changes → Automatic deployment → Production ready!** 🚀
