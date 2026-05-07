resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30

  tags = {
    Name = "${var.cluster_name}-eks-logs"
  }
}

resource "aws_eks_cluster" "main" {
  # checkov:skip=CKV_AWS_58: KMS secrets encryption not configured for personal project; default etcd encryption sufficient at this scope
  # checkov:skip=CKV_AWS_38: Public endpoint required for kubectl access from local machine; protected by IAM and RBAC. Personal project.
  # checkov:skip=CKV_AWS_39: Same as above. Disabling public endpoint would require VPN/bastion infrastructure not justified at this scope.
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = "1.33"

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [aws_cloudwatch_log_group.eks]

  tags = {
    Name = var.cluster_name
  }
}

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_eks_cluster.main
  ]

  tags = {
    Name = "${var.project_name}-node-group"
  }
}