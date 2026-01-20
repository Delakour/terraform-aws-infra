
resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-ecs-cluster"
  })
}
