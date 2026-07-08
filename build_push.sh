#!/bin/bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
REPO_NAME="dr-sim-app"

docker tag $REPO_NAME:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest



docker tag dr-simulation-dev-app:latest 789841106868.dkr.ecr.us-east-1.amazonaws.com/dr-simulation-dev-app

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 789841106868.dkr.ecr.us-east-1.amazonaws.com
docker push 789841106868.dkr.ecr.us-east-1.amazonaws.com/dr-simulation-dev-app

789841106868.dkr.ecr.us-east-1.amazonaws.com/dr-simulation-dev-app