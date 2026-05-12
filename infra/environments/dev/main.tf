module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  cluster_name         = var.cluster_name
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

  project_name      = var.project_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.oidc_issuer_url
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.ecr_repository_name
}

module "github_actions" {
  source = "../../modules/github-actions"

  project_name       = var.project_name
  github_owner       = var.github_owner
  github_repo        = var.github_repo
  ecr_repository_arn = module.ecr.repository_arn
}

module "argocd" {
  source = "../../modules/argocd"

  depends_on = [
    module.eks,
  ]
}