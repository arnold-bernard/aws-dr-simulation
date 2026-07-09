#!/bin/bash
set -e

# Get ALB URL from Terraform
ALB_URL="http://dr-simulation-dev-alb-1531759974.us-east-1.elb.amazonaws.com/"
HEALTH_ENDPOINT="$ALB_URL/health"

echo "📈 Starting RTO Measurement..."
echo "   ALB URL: $ALB_URL"
echo "   Monitoring: $HEALTH_ENDPOINT"
echo ""

# Variables
FAILURE_TIME=""
RECOVERY_TIME=""
RTO=0
CHECK_INTERVAL=5  # seconds
MAX_WAIT=900      # 15 minutes

# Function to check health
check_health() {
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_ENDPOINT)
    echo $HTTP_CODE
}

# Wait for failure
echo "⏳ Waiting for service to become unhealthy..."
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $MAX_WAIT ]; then
        echo "❌ Timeout: Service did not fail within $MAX_WAIT seconds"
        exit 1
    fi
    
    STATUS=$(check_health)
    if [ "$STATUS" != "200" ]; then
        FAILURE_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "💥 Service FAILED at: $FAILURE_TIME"
        echo "   HTTP Status: $STATUS"
        break
    fi
    
    echo "   Service still healthy... (${ELAPSED}s)"
    sleep $CHECK_INTERVAL
done

# Wait for recovery
echo ""
echo "⏳ Waiting for service to recover..."
RECOVERY_START=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    RECOVERY_ELAPSED=$((CURRENT_TIME - RECOVERY_START))
    
    if [ $ELAPSED -gt $MAX_WAIT ]; then
        echo "❌ Timeout: Service did not recover within $MAX_WAIT seconds"
        exit 1
    fi
    
    STATUS=$(check_health)
    if [ "$STATUS" == "200" ]; then
        RECOVERY_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "✅ Service RECOVERED at: $RECOVERY_TIME"
        echo "   HTTP Status: $STATUS"
        break
    fi
    
    echo "   Still recovering... (${RECOVERY_ELAPSED}s)"
    sleep $CHECK_INTERVAL
done

# Calculate RTO
FAILURE_EPOCH=$(date -d "$FAILURE_TIME" +%s 2>/dev/null || date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$FAILURE_TIME" +%s 2>/dev/null)
RECOVERY_EPOCH=$(date -d "$RECOVERY_TIME" +%s 2>/dev/null || date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$RECOVERY_TIME" +%s 2>/dev/null)
RTO=$((RECOVERY_EPOCH - FAILURE_EPOCH))

echo ""
echo "=========================================="
echo "📊 RTO MEASUREMENT COMPLETE"
echo "=========================================="
echo "Failure Time:  $FAILURE_TIME"
echo "Recovery Time: $RECOVERY_TIME"
echo "RTO:           ${RTO} seconds ($(($RTO / 60)) minutes and $(($RTO % 60)) seconds)"
echo "=========================================="