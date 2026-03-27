#!/bin/bash

TAG=$1
REGION="us-east-1"
ECR="486408064722.dkr.ecr.us-east-1.amazonaws.com"
IMAGE="tummoc-app"

if [ -z "$TAG" ]; then
  echo "ERROR: Image tag not provided"
  exit 1
fi

echo "Deploying image: $ECR/$IMAGE:$TAG"

aws ecr get-login-password --region $REGION \
| docker login --username AWS --password-stdin $ECR

PREVIOUS_IMAGE=$(docker inspect --format='{{.Config.Image}}' tummoc-app 2>/dev/null)

docker pull $ECR/$IMAGE:$TAG

docker stop tummoc-app 2>/dev/null || true
docker rm tummoc-app 2>/dev/null || true

docker run -d \
--name tummoc-app \
-p 5000:5000 \
--restart unless-stopped \
$ECR/$IMAGE:$TAG

sleep 10

curl -f http://localhost:5000 || {

echo "Health check failed. Rolling back..."

docker stop tummoc-app
docker rm tummoc-app

docker run -d \
--name tummoc-app \
-p 5000:5000 \
--restart unless-stopped \
$PREVIOUS_IMAGE

}
