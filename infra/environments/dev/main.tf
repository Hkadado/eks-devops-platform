module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
}

module "eks" {
  source = "../../modules/eks"

  project_name     = var.project_name
  cluster_name     = var.cluster_name
  subnet_ids       = module.vpc.private_subnet_ids
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn
}

module "external_dns" {
  source = "../../modules/external-dns"

  project_name = var.project_name
  cluster_name = module.eks.cluster_name
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.ecr_repository_name
}