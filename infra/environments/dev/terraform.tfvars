aws_region   = "us-east-1"
project_name = "eks-devops-platform"
cluster_name = "eks-devops-platform-dev"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24"
]

ecr_repository_name = "eks-devops-platform-app"

github_owner = "Hkadado"
github_repo  = "eks-devops-platform"