resource "aws_ecr_repository" "app" {
  name         = var.repository_name
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.repository_name
  }
}