#!/bin/bash
set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="eks-devops-platform-dev"

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo "Done. Cluster is managed by Argo CD."
echo "To view Argo CD UI, run: kubectl port-forward svc/argocd-server -n argocd 8080:443"