output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

# output "external_dns_role_arn" {
#   value = module.external_dns.external_dns_role_arn
# }

output "github_actions_role_arn" {
  value = module.github_actions.github_actions_role_arn
}