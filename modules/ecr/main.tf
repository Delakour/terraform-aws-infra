resource "aws_ecr_repository" "repo" {
  name                 = "${var.name}-ecr-backend-repo"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

    tags = merge(var.tags, {
    Name = "${var.name}-ecr-backend-repo"
  })

}

resource "aws_ecr_lifecycle_policy" "repo" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = { type = "expire" }
    }]
  })
}
