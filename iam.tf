#############################################
# ECS Task Execution Role
#############################################

resource "aws_iam_role" "ecs_execution" {

  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Action = "sts:AssumeRole"

        Principal = {

          Service = "ecs-tasks.amazonaws.com"

        }

      }

    ]

  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-execution-role"
    }
  )

}

#############################################
# Attach AWS Managed Execution Policy
#############################################

resource "aws_iam_role_policy_attachment" "ecs_execution" {

  role = aws_iam_role.ecs_execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}

#############################################
# ECS Task Role
#############################################

resource "aws_iam_role" "ecs_task" {

  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Action = "sts:AssumeRole"

        Principal = {

          Service = "ecs-tasks.amazonaws.com"

        }

      }

    ]

  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-task-role"
    }
  )

}

#############################################
# Custom Task Policy
#############################################

resource "aws_iam_policy" "ecs_task" {

  name        = "${local.name_prefix}-ecs-task-policy"

  description = "Permissions used by the application"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Action = [

          "logs:CreateLogStream",
          "logs:PutLogEvents"

        ]

        Resource = "*"

      }

    ]

  })

}

#############################################
# Attach Policy to Task Role
#############################################

resource "aws_iam_role_policy_attachment" "ecs_task" {

  role = aws_iam_role.ecs_task.name

  policy_arn = aws_iam_policy.ecs_task.arn

}