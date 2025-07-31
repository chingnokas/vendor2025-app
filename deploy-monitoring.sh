#!/bin/bash

# 📊 Deploy Monitoring Stack (Prometheus + Grafana) with Helm
# This script deploys comprehensive monitoring for your auth-stack application

echo "📊 Deploying Monitoring Stack with Helm"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
MONITORING_NAMESPACE="monitoring"
AUTH_NAMESPACE="auth-app"
HELM_RELEASE_NAME="monitoring-stack"

echo -e "${BLUE}🔧 Step 1: Setting up prerequisites...${NC}"

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespaces
echo "Creating namespaces..."
kubectl create namespace $MONITORING_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $AUTH_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}🏗️ Step 2: Installing monitoring dependencies...${NC}"

# Update Helm dependencies
cd helm/monitoring-stack
helm dependency update
cd ../..

echo -e "${BLUE}📊 Step 3: Deploying Prometheus and Grafana...${NC}"

# Deploy monitoring stack
helm upgrade --install $HELM_RELEASE_NAME helm/monitoring-stack \
  --namespace $MONITORING_NAMESPACE \
  --create-namespace \
  --wait \
  --timeout 10m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Monitoring stack deployed successfully!${NC}"
else
    echo -e "${RED}❌ Failed to deploy monitoring stack${NC}"
    exit 1
fi

echo -e "${BLUE}🎯 Step 4: Deploying auth-stack with monitoring enabled...${NC}"

# Deploy auth-stack with monitoring
helm upgrade --install auth-stack helm/auth-stack \
  --namespace $AUTH_NAMESPACE \
  --set monitoring.enabled=true \
  --wait \
  --timeout 10m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Auth-stack deployed with monitoring enabled!${NC}"
else
    echo -e "${RED}❌ Failed to deploy auth-stack with monitoring${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Step 5: Getting access information...${NC}"

# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl get secret --namespace $MONITORING_NAMESPACE monitoring-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

# Get service information
echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo ""
echo -e "${BLUE}📊 Access Information:${NC}"
echo "===================="

# Grafana access
GRAFANA_SERVICE=$(kubectl get svc -n $MONITORING_NAMESPACE -l "app.kubernetes.io/name=grafana" -o jsonpath='{.items[0].metadata.name}')
GRAFANA_PORT=$(kubectl get svc -n $MONITORING_NAMESPACE $GRAFANA_SERVICE -o jsonpath='{.spec.ports[0].port}')

echo -e "${YELLOW}Grafana Dashboard:${NC}"
echo "  URL: http://localhost:3001 (via port-forward)"
echo "  Username: admin"
echo "  Password: $GRAFANA_PASSWORD"
echo ""
echo "  To access Grafana:"
echo "  kubectl port-forward -n $MONITORING_NAMESPACE svc/$GRAFANA_SERVICE 3001:$GRAFANA_PORT"

# Prometheus access
PROMETHEUS_SERVICE=$(kubectl get svc -n $MONITORING_NAMESPACE -l "app.kubernetes.io/name=prometheus" -o jsonpath='{.items[0].metadata.name}')
PROMETHEUS_PORT=$(kubectl get svc -n $MONITORING_NAMESPACE $PROMETHEUS_SERVICE -o jsonpath='{.spec.ports[0].port}')

echo ""
echo -e "${YELLOW}Prometheus:${NC}"
echo "  URL: http://localhost:9090 (via port-forward)"
echo ""
echo "  To access Prometheus:"
echo "  kubectl port-forward -n $MONITORING_NAMESPACE svc/$PROMETHEUS_SERVICE 9090:$PROMETHEUS_PORT"

# AlertManager access
ALERTMANAGER_SERVICE=$(kubectl get svc -n $MONITORING_NAMESPACE -l "app.kubernetes.io/name=alertmanager" -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$ALERTMANAGER_SERVICE" ]; then
    ALERTMANAGER_PORT=$(kubectl get svc -n $MONITORING_NAMESPACE $ALERTMANAGER_SERVICE -o jsonpath='{.spec.ports[0].port}')
    echo ""
    echo -e "${YELLOW}AlertManager:${NC}"
    echo "  URL: http://localhost:9093 (via port-forward)"
    echo ""
    echo "  To access AlertManager:"
    echo "  kubectl port-forward -n $MONITORING_NAMESPACE svc/$ALERTMANAGER_SERVICE 9093:$ALERTMANAGER_PORT"
fi

echo ""
echo -e "${BLUE}📈 Monitoring Features:${NC}"
echo "====================="
echo "✅ Prometheus metrics collection"
echo "✅ Grafana dashboards"
echo "✅ AlertManager for notifications"
echo "✅ Node Exporter for system metrics"
echo "✅ Kube State Metrics for Kubernetes metrics"
echo "✅ Custom auth-stack application metrics"
echo "✅ Pre-configured dashboards"
echo "✅ Alert rules for your application"

echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "=============="
echo "1. Access Grafana and explore the dashboards"
echo "2. Check Prometheus targets are being scraped"
echo "3. Configure alert notifications (Slack, email, etc.)"
echo "4. Customize dashboards for your specific needs"
echo "5. Set up log aggregation with Loki (optional)"

echo ""
echo -e "${GREEN}🎊 Your monitoring stack is ready!${NC}"
