resource "aws_pipes_pipe" "sqs_to_ecs" {
  name     = "${var.name}-rag-worker-pipe"
  role_arn = aws_iam_role.eventbridge_pipe.arn

  source = var.sqs_queue_arn

  source_parameters {
    sqs_queue_parameters {
      batch_size                         = 1
      maximum_batching_window_in_seconds = 0
    }
  }

  target = var.ecs_cluster_arn

  target_parameters {
    ecs_task_parameters {
      task_definition_arn = var.ecs_task_definition_arn
      launch_type         = "FARGATE"
      task_count          = 1

      network_configuration {
        aws_vpc_configuration {
          subnets          = var.private_subnet_ids
          security_groups  = [var.security_group_id]
          assign_public_ip = "DISABLED"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      target_parameters
    ]
  }

  tags = var.tags
}

resource "null_resource" "update_pipe_ecs_override" {
  depends_on = [aws_pipes_pipe.sqs_to_ecs]

  triggers = {
    pipe_name           = aws_pipes_pipe.sqs_to_ecs.name
    role_arn            = aws_iam_role.eventbridge_pipe.arn
    source_arn          = var.sqs_queue_arn
    target_arn          = var.ecs_cluster_arn
    task_definition_arn = var.ecs_task_definition_arn
    subnet_ids          = join(",", var.private_subnet_ids)
    security_group_id   = var.security_group_id
  }

provisioner "local-exec" {
  interpreter = ["PowerShell", "-Command"]

  command = <<EOT
    $payload = @{
      Name = "${aws_pipes_pipe.sqs_to_ecs.name}"
      RoleArn = "${aws_iam_role.eventbridge_pipe.arn}"
      SourceParameters = @{
        SqsQueueParameters = @{
          BatchSize = 1
        }
      }
      Target = "${var.ecs_cluster_arn}"
      TargetParameters = @{
        EcsTaskParameters = @{
          TaskDefinitionArn = "${var.ecs_task_definition_arn}"
          LaunchType = "FARGATE"
          TaskCount = 1
          NetworkConfiguration = @{
            awsvpcConfiguration = @{
              Subnets = @(${join(",", formatlist("\"%s\"", var.private_subnet_ids))})
              SecurityGroups = @("${var.security_group_id}")
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = @{
            ContainerOverrides = @(
              @{
                Name = "rag-worker"
                Command = @(
                  "sh",
                  "-c",
                  'python -m app.application.jobs.rag_worker --mode single --payload "$1"',
                  "_",
                  '$.body'
                )
              }
            )
          }
        }
      }
    }

    $json = $payload | ConvertTo-Json -Depth 20 -Compress
    $file = Join-Path $PWD "update-pipe-${aws_pipes_pipe.sqs_to_ecs.name}.json"
    $json | Set-Content -Path $file -Encoding ascii

    aws pipes update-pipe --cli-input-json "file://$file" --region ${var.region}

    Remove-Item -Path $file -Force
    EOT
}
}