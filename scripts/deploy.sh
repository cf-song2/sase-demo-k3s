#!/bin/bash
set -e

echo "=== Deploying Zero Trust Demo Environment ==="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Check if credentials secret exists
echo "Checking for cloudflared credentials..."
if ! kubectl get secret cloudflared-creds -n demo &> /dev/null; then
    echo ""
    echo "Warning: cloudflared-creds secret not found"
    echo "Please create the secret first:"
    echo "  kubectl create namespace demo"
    echo "  kubectl create secret generic cloudflared-creds \\"
    echo "    --from-file=credentials.json=/path/to/credentials.json \\"
    echo "    -n demo"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Deploy using kustomize
echo "Deploying resources..."
kubectl apply -k k8s/

# Wait for deployments to be ready
echo ""
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/web \
  deployment/ssh \
  deployment/rdp \
  deployment/smb \
  deployment/cloudflared \
  -n demo

# Show status
echo ""
echo "=== Deployment Status ==="
kubectl get pods -n demo
echo ""
kubectl get svc -n demo

echo ""
echo "=== Deployment complete ==="
