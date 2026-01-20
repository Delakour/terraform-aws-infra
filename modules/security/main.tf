# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-sg-alb"
  description = "Allow https from outside"

  vpc_id = var.vpc_id

  # HTTPS
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg-alb"
  })
}

# Backend EC2 security group – only ALB can reach port 8000
# resource "aws_security_group" "backend" {
#   name        = "${var.name}-backend-sg"
#   description = "Security group for backend"
#   vpc_id      = var.vpc_id

#   ingress {
#     description     = "Allow all traffic from linked SG"
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   ingress {
#     description = "SSH access"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [var.allowed_ssh_cidr]
#   }

#   egress {
#     description = "Allow all outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(var.tags, {
#     Name = "${var.name}-sg-backend"
#   })
# }

resource "aws_security_group" "backend_tasks" {
  name        = "${var.name}-backend-tasks-sg"
  description = "Security group for ECS backend tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow ALB to reach backend"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow outbound to DB, Qdrant, APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg-backend-tasks"
  })
}
