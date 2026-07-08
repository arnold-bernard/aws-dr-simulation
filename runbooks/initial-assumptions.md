# Initial DR Runbook (Assumptions)

## Assumed RTO: 15 minutes

## Assumed Failure Sequence:
1. RDS Primary in AZ-A fails.
2. RDS Multi-AZ automatically promotes standby in AZ-B (estimated: 60 seconds).
3. ECS tasks in AZ-A become unhealthy.
4. ALB detects unhealthy tasks (estimated: 30 seconds).
5. ALB routes traffic to ECS tasks in AZ-B/C.
6. Application recovers.

## Assumed Recovery Time: ~2-3 minutes