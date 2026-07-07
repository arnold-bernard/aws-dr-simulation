#############################################
# CloudWatch Log Group
#############################################

resource "aws_cloudwatch_log_group" "ecs" {

  name = "/ecs/${local.name_prefix}"

  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-logs"
    }
  )

}

#############################################
# Outputs
#############################################

output "cloudwatch_log_group_name" {

  description = "CloudWatch Log Group"

  value = aws_cloudwatch_log_group.ecs.name

}
