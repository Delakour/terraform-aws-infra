data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
      Effect    = "Allow"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-ec2-role"
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy" "ec2_s3_upload" {
  name = "${var.name}-ec2-s3-upload"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${var.s3_brandbook_arn}/*",
          "${var.s3_local_folder_arn}/*",
          "${var.s3_story_portal_arn}/*",
          # "${var.s3_vectors_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = [
          "${var.s3_brandbook_arn}",
          "${var.s3_local_folder_arn}",
          "${var.s3_story_portal_arn}",
          # "${var.s3_vectors_arn}"
        ]
      }
    ]
  })
}

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    ENVIRONMENT = var.environment
  }))

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-app-ec2"
  })
}

resource "aws_ebs_volume" "vectors" {
  availability_zone = aws_instance.app.availability_zone
  size              = 100            # GB – adjust
  type              = "gp3"

  tags = merge(var.tags, {
    Name = "${var.name}-ebs-vectors"
  })
}

resource "aws_volume_attachment" "vectors" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.vectors.id
  instance_id = aws_instance.app.id
}
