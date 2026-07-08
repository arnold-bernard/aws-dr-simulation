#############################################
# Security Group - Application Load Balancer
#############################################

#############################################
# Security Group - ALB
#############################################
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # egress block removed – will be defined as separate rule below

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-alb-sg" }
  )
}

#############################################
# Security Group - ECS Tasks
#############################################
resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security group for ECS Tasks"
  vpc_id      = aws_vpc.main.id

  # ingress block referencing ALB removed – will be separate rule below

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-ecs-sg" }
  )
}

#############################################
# Separate Security Group Rules
#############################################

# Allow ALB to forward traffic to ECS tasks
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.ecs.id
  description              = "Forward traffic to ECS"
}

# Allow ECS tasks to receive traffic from ALB
resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB"
}

#############################################
# Security Group - PostgreSQL
#############################################

resource "aws_security_group" "rds" {

  name = "${local.name_prefix}-rds-sg"

  description = "Security Group for PostgreSQL"

  vpc_id = aws_vpc.main.id

  ###########################################
  # Inbound
  ###########################################

  ingress {

    description = "Allow ECS"

    from_port = 5432
    to_port   = 5432

    protocol = "tcp"

    security_groups = [
      aws_security_group.ecs.id
    ]

  }

  ###########################################
  # Outbound
  ###########################################

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]

  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-sg"
    }
  )

}