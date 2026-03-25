resource "aws_ecr_repository" "tummoc_app_repo" {

  name = "tummoc-app"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = "Tummoc"
    Environment = "Dev"
  }
}
