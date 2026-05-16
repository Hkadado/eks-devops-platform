#!/bin/bash
set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="eks-devops-platform-dev"

if aws eks describe-cluster --region "$AWS_REGION" --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "Cluster exists, cleaning up cluster resources before destroy..."
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

  echo "Stopping ArgoCD reconciliation to prevent it from recreating resources during teardown..."
  # Scale down ArgoCD's controllers so they stop syncing from Git
  kubectl scale deployment -n argocd argocd-applicationset-controller --replicas=0 || true
  kubectl scale statefulset -n argocd argocd-application-controller --replicas=0 || true
  kubectl scale deployment -n argocd argocd-repo-server --replicas=0 || true
  echo "  Waiting 10s for ArgoCD to stop reconciling..."
  sleep 10

  echo "Deleting all Ingresses..."
  kubectl delete ingress --all-namespaces --all --wait=true --ignore-not-found || true

  echo "Deleting LoadBalancer services..."
  kubectl delete svc -n ingress-nginx ingress-nginx-controller --wait=true --ignore-not-found || true
else
  echo "Cluster doesn't exist, skipping cluster cleanup."
fi

VPC_ID=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=*${CLUSTER_NAME%-dev}*" \
  --query 'Vpcs[].VpcId' --output text)

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  echo "Found VPC: $VPC_ID"

  echo "Waiting for load balancers to fully deprovision..."
  for i in {1..30}; do
    CLB_NAMES=$(aws elb describe-load-balancers --region "$AWS_REGION" \
      --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" \
      --output text 2>/dev/null)
    NLB_ARNS=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
      --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" \
      --output text 2>/dev/null)

    if [ -z "$CLB_NAMES" ] && [ -z "$NLB_ARNS" ]; then
      echo "  All load balancers gone."
      break
    fi

    # After ~60s, force-delete any stragglers (K8s cloud provider not cleaning them up)
    if [ "$i" -gt 6 ]; then
      for LB in $CLB_NAMES; do
        echo "  Force-deleting stuck CLB: $LB"
        aws elb delete-load-balancer --region "$AWS_REGION" --load-balancer-name "$LB" 2>/dev/null || true
      done
      for LB_ARN in $NLB_ARNS; do
        echo "  Force-deleting stuck LB: $LB_ARN"
        aws elbv2 delete-load-balancer --region "$AWS_REGION" --load-balancer-arn "$LB_ARN" 2>/dev/null || true
      done
    fi

    CLB_COUNT=$(echo $CLB_NAMES | wc -w | tr -d ' ')
    NLB_COUNT=$(echo $NLB_ARNS | wc -w | tr -d ' ')
    echo "  Attempt $i/30: CLBs=$CLB_COUNT NLBs/ALBs=$NLB_COUNT, waiting 10s..."
    sleep 10
  done

  echo "Waiting for orphaned k8s-elb security groups to be deletable..."
  for i in {1..30}; do
    ORPHAN_SGS=$(aws ec2 describe-security-groups --region "$AWS_REGION" \
      --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=k8s-elb-*" \
      --query 'SecurityGroups[].GroupId' --output text)

    if [ -z "$ORPHAN_SGS" ]; then
      echo "  No orphan SGs found."
      break
    fi

    ALL_DELETED=true
    for SG_ID in $ORPHAN_SGS; do
      if aws ec2 delete-security-group --region "$AWS_REGION" --group-id "$SG_ID" 2>/dev/null; then
        echo "  Deleted SG: $SG_ID"
      else
        ALL_DELETED=false
      fi
    done

    if [ "$ALL_DELETED" = "true" ]; then
      break
    fi

    echo "  Attempt $i/30: SG still has dependencies, waiting 10s..."
    sleep 10
  done
fi

echo "Running terraform destroy..."
cd infra/environments/dev
terraform destroy "$@"