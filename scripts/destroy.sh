#!/bin/bash
set -e

AWS_REGION="us-east-1"
CLUSTER_NAME="eks-devops-platform-dev"

if aws eks describe-cluster --region "$AWS_REGION" --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "Cluster exists, cleaning up cluster resources before destroy..."
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

  echo "Deleting all Ingresses..."
  kubectl delete ingress --all-namespaces --all --wait=true --ignore-not-found || true
  sleep 60

  echo "Deleting LoadBalancer services..."
  kubectl delete svc -n ingress-nginx ingress-nginx-controller --wait=true --ignore-not-found || true
  sleep 60
else
  echo "Cluster doesn't exist, skipping cluster cleanup."
fi

VPC_ID=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=*${CLUSTER_NAME%-dev}*" \
  --query 'Vpcs[].VpcId' --output text)

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  echo "Found VPC: $VPC_ID"

  echo "Checking for orphaned Classic Load Balancers..."
  for LB in $(aws elb describe-load-balancers --region "$AWS_REGION" \
                --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" \
                --output text); do
    echo "  Deleting orphan CLB: $LB"
    aws elb delete-load-balancer --region "$AWS_REGION" --load-balancer-name "$LB"
  done

  echo "Checking for orphaned Network/Application Load Balancers..."
  for LB_ARN in $(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
                    --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" \
                    --output text); do
    echo "  Deleting orphan LB: $LB_ARN"
    aws elbv2 delete-load-balancer --region "$AWS_REGION" --load-balancer-arn "$LB_ARN"
  done

  echo "Waiting 30s for LB deletions to propagate..."
  sleep 30

  echo "Checking for orphaned k8s-elb security groups..."
  for SG_ID in $(aws ec2 describe-security-groups --region "$AWS_REGION" \
                   --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=k8s-elb-*" \
                   --query 'SecurityGroups[].GroupId' --output text); do
    echo "  Deleting orphan SG: $SG_ID"
    aws ec2 delete-security-group --region "$AWS_REGION" --group-id "$SG_ID" || true
  done
fi

echo "Running terraform destroy..."
cd infra/environments/dev
terraform destroy "$@"