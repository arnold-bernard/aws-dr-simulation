#!/bin/bash
# ----------------------------------------------------------------------
# Script: simulate-az-failure.sh
# Purpose: Simulates an AZ failure by forcing an RDS failover and 
#          terminating associated ECS tasks in the impacted AZ.
# ----------------------------------------------------------------------
set -euo pipefail

DB_INSTANCE_ID="dr-simulation-dev-postgres"
CLUSTER_NAME="dr-simulation-dev-cluster"
SERVICE_NAME="dr-simulation-dev-service"

# Color Codes for Pretty Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🚨 Starting AZ Failure Simulation...${NC}\n"

# ----------------------------------------------------------------------
# 1. Fetch RDS details in a SINGLE API Call
# ----------------------------------------------------------------------
echo -e "${BLUE}📊 Fetching RDS instance details...${NC}"

RDS_DATA=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query 'DBInstances[0].[AvailabilityZone, to_string(MultiAZ), SecondaryAvailabilityZone]' \
    --output text 2>/dev/null) || {
        echo -e "${RED}❌ ERROR: Failed to describe RDS instance '$DB_INSTANCE_ID'.${NC}"
        exit 1
    }

read -r PRIMARY_AZ MULTI_AZ STANDBY_AZ <<< "$RDS_DATA"

MULTI_AZ_LOWER=$(echo "$MULTI_AZ" | tr '[:upper:]' '[:lower:]')
if [[ "$STANDBY_AZ" == "None" || "$STANDBY_AZ" == "none" || -z "$STANDBY_AZ" ]]; then
    STANDBY_AZ=""
fi

echo "   Primary AZ   : $PRIMARY_AZ"
echo "   Multi-AZ     : $MULTI_AZ_LOWER"
echo "   Standby AZ   : ${STANDBY_AZ:-"(none)"}"

# ----------------------------------------------------------------------
# 2. Validate Multi-AZ configuration
# ----------------------------------------------------------------------
if [[ "$MULTI_AZ_LOWER" != "true" ]]; then
    echo -e "${RED}❌ ERROR: DB instance is NOT Multi-AZ enabled.${NC}"
    exit 1
fi

if [[ -z "$STANDBY_AZ" ]]; then
    echo -e "${RED}❌ ERROR: No standby AZ found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Multi-AZ validated. Standby ready in: $STANDBY_AZ${NC}\n"

# ----------------------------------------------------------------------
# 3. Identify ECS tasks in the primary AZ
# ----------------------------------------------------------------------
echo -e "${BLUE}📊 Identifying ECS tasks in AZ: $PRIMARY_AZ...${NC}"

TASK_ARNS=$(aws ecs list-tasks \
    --cluster "$CLUSTER_NAME" \
    --service-name "$SERVICE_NAME" \
    --query 'taskArns' \
    --output text)

TASK_TO_KILL=""
if [[ -n "$TASK_ARNS" && "$TASK_ARNS" != "None" ]]; then
    echo "   🔍 Tasks found. Running batch evaluation..."
    TASK_TO_KILL=$(aws ecs describe-tasks \
        --cluster "$CLUSTER_NAME" \
        --tasks $TASK_ARNS \
        --query "tasks[?availabilityZone=='$PRIMARY_AZ'].taskArn | [0]" \
        --output text)
    
    if [[ -n "$TASK_TO_KILL" && "$TASK_TO_KILL" != "None" ]]; then
        echo -e "   ${GREEN}🎯 Identified target task to terminate: $TASK_TO_KILL (running in AZ $PRIMARY_AZ)${NC}"
    else
        echo "   ℹ️ No tasks from service are currently active in AZ $PRIMARY_AZ."
        TASK_TO_KILL=""
    fi
else
    echo -e "${YELLOW}⚠️ No active tasks found. Skipping target search.${NC}"
fi

# ----------------------------------------------------------------------
# 4. Force RDS failover & Robust Wait Loop
# ----------------------------------------------------------------------
echo -e "\n${BLUE}🔄 Forcing RDS failover (rebooting with --force-failover)...${NC}"
aws rds reboot-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --force-failover > /dev/null

echo -e "${GREEN}✅ RDS failover initiated! Monitoring instance and metadata recovery...${NC}"

MAX_ATTEMPTS=120
DELAY=5
ATTEMPT=1
DB_AVAILABLE=false
NEW_AZ=""

# Polling loop verifying both status AND AZ modification
while (( ATTEMPT <= MAX_ATTEMPTS )); do
    DB_INFO=$(aws rds describe-db-instances \
        --db-instance-identifier "$DB_INSTANCE_ID" \
        --query "DBInstances[0].[DBInstanceStatus, AvailabilityZone]" \
        --output text 2>/dev/null || echo "rebooting $PRIMARY_AZ")

    read -r STATUS CURRENT_AZ <<< "$DB_INFO"

    # Fallback default values if API fails temporarily
    if [[ -z "$STATUS" ]]; then
        STATUS="rebooting"
        CURRENT_AZ="$PRIMARY_AZ"
    fi

    # Exit ONLY when the DB is available AND the AZ has actually flipped in the API metadata
    if [[ "$STATUS" == "available" && "$CURRENT_AZ" != "$PRIMARY_AZ" ]]; then
        DB_AVAILABLE=true
        NEW_AZ="$CURRENT_AZ"
        break
    fi

    echo "   ⏳ [Attempt $ATTEMPT/$MAX_ATTEMPTS] Status: '$STATUS' | Current AZ: '$CURRENT_AZ'. Checking again in ${DELAY}s..."
    sleep "$DELAY"
    ((ATTEMPT++))
done

if [[ "$DB_AVAILABLE" != "true" ]]; then
    echo -e "${RED}❌ ERROR: Timeout waiting for RDS failover to complete and reflect in metadata.${NC}"
    exit 1
fi

# ----------------------------------------------------------------------
# 5. Verify the AZ has changed
# ----------------------------------------------------------------------
echo -e "\n${BLUE}📊 Confirming new primary AZ...${NC}"
echo "   New Primary AZ: $NEW_AZ"
echo -e "${GREEN}✅ AZ successfully transitioned from $PRIMARY_AZ to $NEW_AZ!${NC}"

# ----------------------------------------------------------------------
# 6. Terminate ECS task in the old AZ
# ----------------------------------------------------------------------
if [[ -n "$TASK_TO_KILL" ]]; then
    echo -e "\n${BLUE}🔪 Stopping ECS task $TASK_TO_KILL (killing process in old AZ $PRIMARY_AZ)...${NC}"
    aws ecs stop-task \
        --cluster "$CLUSTER_NAME" \
        --task "$TASK_TO_KILL" > /dev/null
    echo -e "${GREEN}✅ ECS task stopped! Service scheduler will spin up a healthy replacement task in the surviving AZ.${NC}"
else
    echo -e "\nℹ️ No active ECS task required termination in old AZ $PRIMARY_AZ."
fi

echo -e "\n${GREEN}🎉 AZ Failure Simulation Completed Successfully!${NC}"