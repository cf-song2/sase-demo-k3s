#!/bin/bash
set -e

echo "=== Installing k3s on Ubuntu Server ==="

# Update system
echo "Updating system packages..."
sudo apt update
sudo apt install -y curl

# Install k3s
echo "Installing k3s..."
curl -sfL https://get.k3s.io | sh -

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
sleep 10

# Setup kubectl for current user
echo "Setting up kubectl access..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

# Verify installation
echo "Verifying k3s installation..."
kubectl get nodes
kubectl get pods -A

echo ""
echo "=== k3s installation complete ==="
echo "You can now use kubectl to interact with the cluster"
