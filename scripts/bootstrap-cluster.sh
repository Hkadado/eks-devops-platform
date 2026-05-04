#!/bin/bash
set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="eks-devops-platform-dev"
DOMAIN="hasankadado.com"
EXTERNAL_DNS_ROLE_ARN=$(cd infra/environments/dev && terraform output -raw external_dns_role_arn)

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo "Installing ingress-nginx..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

echo "Installing cert-manager..."
helm upgrade --install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.20.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

echo "Waiting for cert-manager..."
kubectl rollout status deployment cert-manager -n cert-manager

echo "Applying ClusterIssuer..."
kubectl apply -f k8s/platform/cert-manager/cluster-issuer.yaml

echo "Installing ExternalDNS..."
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update
helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns \
  --create-namespace \
  --set provider.name=aws \
  --set 'env[0].name=AWS_DEFAULT_REGION' \
  --set "env[0].value=$AWS_REGION" \
  --set 'sources[0]=ingress' \
  --set 'sources[1]=service' \
  --set "domainFilters[0]=$DOMAIN" \
  --set txtOwnerId=external-dns \
  --set policy=sync \
  --set serviceAccount.create=true \
  --set serviceAccount.name=external-dns \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$EXTERNAL_DNS_ROLE_ARN"

echo "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD server..."
kubectl rollout status deployment argocd-server -n argocd

echo "Applying ArgoCD Application..."
kubectl apply -f argocd/app.yaml

echo "Bootstrap complete."