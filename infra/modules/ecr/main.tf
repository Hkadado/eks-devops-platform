resource "aws_ecr_repository" "app" {
    # checkov:skip=CKV_AWS_136: AES-256 default encryption sufficient for personal project; KMS CMK adds cost without meaningful security benefit at this scope
  name         = var.repository_name
  image_tag_mutability = "IMMUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.repository_name
  }
}