#!/bin/bash
set -e

# Variables
IMAGE_NAME=tummoc-app
ECR_URI=486408064722.dkr.ecr.us-east-1.amazonaws.com/$IMAGE_NAME

# Pass version as argument: ./build_push.sh v1
if [ -z "$1" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi
TAG=$1

# Build Docker image
docker build -t $IMAGE_NAME:$TAG -f docker/Dockerfile .

# Tag for ECR
docker tag $IMAGE_NAME:$TAG $ECR_URI:$TAG

# Login to ECR
aws ecr get-login-password --region us-east-1 \
| docker login --username AWS --password-stdin 486408064722.dkr.ecr.us-east-1.amazonaws.com

# Push to ECR
docker push $ECR_URI:$TAG

echo "✅ Image pushed: $ECR_URI:$TAG"
