resource "aws_ecr_repository" "tummoc_app_repo" {
  name                 = "tummoc-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "devops"
    Project     = "tummoc"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.tummoc_app_repo.repository_url
}
