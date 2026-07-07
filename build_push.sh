#!/bin/bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
REPO_NAME="dr-sim-app"
aws ecr create-repository --repository-name $REPO_NAME || true
docker build -t $REPO_NAME .
docker tag $REPO_NAME:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest

aws ecr create-repository --repository-name dr-sim-app
docker build -t dr-sim-app .

docker tag dr-sim-app:latest 381492121472.dkr.ecr.us-east-1.amazonaws.com/dr-sim-app:latest

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 381492121472.dkr.ecr.us-east-1 .amazonaws.com
docker push 381492121472.dkr.ecr.us-east-1.amazonaws.com/dr-sim-app:latest