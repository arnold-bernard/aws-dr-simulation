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

TASK_TO_KILL=""
for TASK_ARN in $TASK_ARNS; do
    TASK_AZ=$(aws ecs describe-tasks \
        --cluster dr-simulation-dev-cluster \
        --tasks $TASK_ARN \
        --query 'tasks[0].availabilityZone' \
        --output text)
    
    if [ "$TASK_AZ" == "$RDS_AZ" ]; then
        echo "   ✅ Found task $TASK_ARN in AZ: $TASK_AZ"
        TASK_TO_KILL=$TASK_ARN
        break
    fi
done

if [ -z "$TASK_ARNS" ]; then
    echo "⚠️ No tasks found for service dr-simulation-dev-service. Skipping task termination."
fi

# 3. Force RDS failover (CORRECT COMMAND)
echo "🔄 Forcing RDS failover (reboot with --force-failover)..."
aws rds reboot-db-instance \
    --db-instance-identifier dr-simulation-dev-postgres \
    --force-failover

echo "✅ RDS failover initiated!"

# 4. Force ECS tasks in that AZ to restart (if found)
if [ ! -z "$TASK_TO_KILL" ]; then
    echo "🔪 Stopping ECS task in AZ: $RDS_AZ"
    aws ecs stop-task \
        --cluster dr-simulation-dev-cluster \
        --task $TASK_TO_KILL
    echo "✅ ECS task stopped!"
else
    echo "ℹ️ No ECS task found in AZ $RDS_AZ to terminate."
fi

echo ""
echo "✅ Failure simulation initiated!"
echo "   - RDS is failing over to standby AZ"
echo "   - ECS task in $RDS_AZ has been stopped"
echo "   - Watch your RTO measurement script!"