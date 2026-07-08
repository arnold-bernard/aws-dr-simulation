#!/bin/bash
set -e

echo "🚨 Starting AZ Failure Simulation..."

# 1. Get the current RDS primary AZ
echo "📊 Identifying RDS primary AZ..."
RDS_AZ=$(aws rds describe-db-instances \
    --db-instance-identifier dr-simulation-dev-postgres \
    --query 'DBInstances[0].AvailabilityZone' \
    --output text)
echo "   RDS Primary is in: $RDS_AZ"

# 2. Identify which ECS tasks are in that AZ
echo "📊 Identifying ECS tasks in AZ: $RDS_AZ..."
TASK_ARNS=$(aws ecs list-tasks \
    --cluster dr-simulation-dev-cluster \
    --service-name dr-simulation-dev-service \
    --query 'taskArns[]' \
    --output text)

for TASK_ARN in $TASK_ARNS; do
    TASK_AZ=$(aws ecs describe-tasks \
        --cluster dr-simulation-dev-cluster \
        --tasks $TASK_ARN \
        --query 'tasks[0].availabilityZone' \
        --output text)
    
    if [ "$TASK_AZ" == "$RDS_AZ" ]; then
        echo "   Task $TASK_ARN is in AZ: $TASK_AZ"
        TASK_TO_KILL=$TASK_ARN
    fi
done

# 3. Force RDS failover
echo "🔄 Forcing RDS failover..."
aws rds failover-db-instance \
    --db-instance-identifier dr-simulation-dev-postgres \
    --query 'DBInstance[0].AvailabilityZone' \
    --output text

# 4. Optionally: Force ECS tasks in that AZ to restart
if [ ! -z "$TASK_TO_KILL" ]; then
    echo "🔪 Stopping ECS task in AZ: $RDS_AZ"
    aws ecs stop-task \
        --cluster dr-simulation-dev-cluster \
        --task $TASK_TO_KILL
fi

echo "✅ Failure simulation initiated!"