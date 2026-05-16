#!/bin/bash
set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="eks-devops-platform-dev"

if ! aws eks describe-cluster --region "$AWS_REGION" --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "Error: cluster '$CLUSTER_NAME' not found in region '$AWS_REGION'."
  echo "Run 'terraform apply' from infra/environments/dev first."
  exit 1
fi

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo ""
echo "Done. Cluster is managed by Argo CD."
echo ""
echo "Quick checks:"
echo "  kubectl get application -n argocd       # all Argo CD Applications (should be Synced/Healthy)"
echo "  kubectl get pods -A                     # all pods across namespaces"
echo "  kubectl get ingress                     # your app's ingress"
echo ""
echo "To view Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  open https://localhost:8080"
echo ""
echo "Get Argo CD admin password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"