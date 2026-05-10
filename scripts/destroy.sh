#!/bin/bash
set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="eks-devops-platform-dev"

if aws eks describe-cluster --region "$AWS_REGION" --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "Cluster exists, cleaning up LoadBalancer service..."
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
  kubectl delete svc -n ingress-nginx ingress-nginx-controller --wait=true --ignore-not-found
  echo "Waiting 60s for AWS to fully clean up the load balancer..."
  sleep 60
else
  echo "Cluster doesn't exist or unreachable, skipping LoadBalancer cleanup."
fi

echo "Running terraform destroy..."
cd infra/environments/dev
terraform destroy "$@"