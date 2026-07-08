#############################################
# ECS Cluster
#############################################

resource "aws_ecs_cluster" "main" {

  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cluster"
    }
  )

}

#############################################
# ECS Task Definition
#############################################

resource "aws_ecs_task_definition" "app" {

  family = "${local.name_prefix}-task"

  requires_compatibilities = ["FARGATE"]

  network_mode = "awsvpc"

  cpu = var.ecs_cpu

  memory = var.ecs_memory

  execution_role_arn = aws_iam_role.ecs_execution.arn

  task_role_arn = aws_iam_role.ecs_task.arn

  runtime_platform {

    operating_system_family = "LINUX"

    cpu_architecture = "X86_64"

  }

  container_definitions = jsonencode([

    {

      name = "web"

      image = "${aws_ecr_repository.app.repository_url}:latest"

      essential = true

      portMappings = [

        {

          containerPort = var.container_port

          hostPort = var.container_port

          protocol = "tcp"

        }

      ]

      environment = [

        {

          name = "DB_HOST"

          value = aws_db_instance.main.address

        },

        {

          name = "DB_PORT"

          value = "5432"

        },

        {

          name = "DB_NAME"

          value = aws_db_instance.main.db_name

        },

        {

          name = "DB_USER"

          value = aws_db_instance.main.username

        } ,
        {
          name  = "DB_PASSWORD"
          value = random_password.db.result 
        },
         {
          name  = "AWS_REGION"
          value = var.aws_region
        }

      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {

          awslogs-group = aws_cloudwatch_log_group.ecs.name

          awslogs-region = var.aws_region

          awslogs-stream-prefix = "ecs"

        }

      }

      healthCheck = {

        command = [

          "CMD-SHELL",

          "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"

        ]

        interval = 30

        timeout = 5

        retries = 3

        startPeriod = 60

      }

    }

  ])

}

#############################################
# ECS Service
#############################################

resource "aws_ecs_service" "app" {

  name = "${local.name_prefix}-service"

  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.app.arn

  desired_count = var.desired_task_count

  launch_type = "FARGATE"

  enable_execute_command = true

  deployment_minimum_healthy_percent = 50

  deployment_maximum_percent = 200

  deployment_circuit_breaker {

    enable = true

    rollback = true

  }

  network_configuration {

    assign_public_ip = false

    subnets = aws_subnet.private[*].id

    security_groups = [

      aws_security_group.ecs.id

    ]

  }

  load_balancer {

    target_group_arn = aws_lb_target_group.app.arn

    container_name = "web"

    container_port = var.container_port

  }

  depends_on = [

    aws_lb_listener.http

  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-service"
    }
  )

}