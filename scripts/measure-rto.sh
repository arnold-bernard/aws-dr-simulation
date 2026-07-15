#!/bin/bash
# ----------------------------------------------------------------------
# Script: measure-rto.sh
# Purpose: Real-time RTO (Recovery Time Objective) measurement tool
#          for AWS Disaster Recovery and High Availability simulations.
# ----------------------------------------------------------------------
set -euo pipefail

# Configuration (Supports overriding via Environment Variables)
ALB_URL="http://dr-simulation-dev-alb-1492860742.us-east-1.elb.amazonaws.com"
HEALTH_ENDPOINT="${ALB_URL%/}/health" # Safe stripping of trailing slashes

CHECK_INTERVAL=5   # polling frequency in seconds
MAX_WAIT=1080       # 15-minute timeout window

# ANSI Color Codes for Rich CLI Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}📈 Starting RTO Measurement...${NC}"
echo -e "   ALB Endpoint : ${BOLD}$HEALTH_ENDPOINT${NC}"
echo -e "   Max Timeout  : ${BOLD}$((MAX_WAIT / 60)) minutes${NC}\n"

# Helper function to parse Unix Epoch cleanly across both GNU (Linux) and BSD (macOS)
format_epoch() {
    local epoch="$1"
    if date -d "@$epoch" +"%Y-%m-%dT%H:%M:%SZ" &>/dev/null; then
        date -u -d "@$epoch" +"%Y-%m-%dT%H:%M:%SZ" # Linux
    else
        date -u -r "$epoch" +"%Y-%m-%dT%H:%M:%SZ"   # macOS
    fi
}

# Core function to query health endpoint safely
check_health() {
    # --connect-timeout and --max-time ensure curl doesn't hang if the network drops.
    # "|| echo '000'" prevents 'set -e' from crashing the script when network connection fails completely.
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 2 \
        --max-time 4 \
        "$HEALTH_ENDPOINT" || echo "000")
    echo "$http_code"
}

# ----------------------------------------------------------------------
# PHASE 1: Wait for Failure
# ----------------------------------------------------------------------
echo -e "${YELLOW}⏳ Phase 1: Monitoring system health. Waiting for failure trigger...${NC}"
START_TIME=$(date +%s)
FAILURE_EPOCH=""

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if (( ELAPSED > MAX_WAIT )); then
        echo -e "${RED}❌ Timeout: Service remained healthy after $((MAX_WAIT / 60)) minutes. Simulation aborted.${NC}"
        exit 1
    fi
    
    STATUS=$(check_health)
    
    if [[ "$STATUS" != "200" ]]; then
        FAILURE_EPOCH=$(date +%s)
        FAILURE_TIME_ISO=$(format_epoch "$FAILURE_EPOCH")
        echo -e "\n${RED}💥 OUTAGE DETECTED at: $FAILURE_TIME_ISO${NC}"
        echo -e "   HTTP/Network Status: ${BOLD}$STATUS${NC}"
        break
    fi
    
    # Simple inline status update using carriage return (\r) to avoid terminal spam
    printf "   [Elapsed: %ds] Status: %s - System is operational...\r" "$ELAPSED" "$STATUS"
    sleep "$CHECK_INTERVAL"
done

# ----------------------------------------------------------------------
# PHASE 2: Wait for Recovery (Self-Healing)
# ----------------------------------------------------------------------
echo -e "\n${YELLOW}⏳ Phase 2: Monitoring system recovery. Waiting for self-healing...${NC}"
RECOVERY_START_EPOCH=$(date +%s)
RECOVERY_EPOCH=""

while true; do
    CURRENT_TIME=$(date +%s)
    TOTAL_ELAPSED=$((CURRENT_TIME - START_TIME))
    RECOVERY_ELAPSED=$((CURRENT_TIME - RECOVERY_START_EPOCH))
    
    if (( TOTAL_ELAPSED > MAX_WAIT )); then
        echo -e "${RED}❌ Timeout: Service failed to self-heal within $((MAX_WAIT / 60)) minutes. Recovery target missed.${NC}"
        exit 1
    fi
    
    STATUS=$(check_health)
    
    if [[ "$STATUS" == "200" ]]; then
        RECOVERY_EPOCH=$(date +%s)
        RECOVERY_TIME_ISO=$(format_epoch "$RECOVERY_EPOCH")
        echo -e "\n${GREEN}✅ SERVICE RECOVERED at: $RECOVERY_TIME_ISO${NC}"
        echo -e "   HTTP Status: ${BOLD}$STATUS${NC}"
        break
    fi
    
    printf "   [Outage Duration: %ds] Status: %s - Still recovering...\r" "$RECOVERY_ELAPSED" "$STATUS"
    sleep "$CHECK_INTERVAL"
done

# ----------------------------------------------------------------------
# PHASE 3: Calculate & Output RTO
# ----------------------------------------------------------------------
RTO_SECONDS=$((RECOVERY_EPOCH - FAILURE_EPOCH))
RTO_MINUTES=$((RTO_SECONDS / 60))
RTO_REMAINDER_SECONDS=$((RTO_SECONDS % 60))

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${BLUE}${BOLD}📊 RTO MEASUREMENT METRICS${NC}"
echo -e "${BLUE}==================================================${NC}"
echo -e " Outage Event (T1)  : $(format_epoch "$FAILURE_EPOCH")"
echo -e " Restore Event (T2) : $(format_epoch "$RECOVERY_EPOCH")"
echo -e " Calculated RTO     : ${BOLD}${GREEN}${RTO_SECONDS} seconds${NC} (${RTO_MINUTES}m ${RTO_REMAINDER_SECONDS}s)"
echo -e "${BLUE}==================================================${NC}"