##########################################################
# EC2 Launch Template + Auto Scaling Group
# Used for running Tummoc App container
##########################################################

variable "docker_image_tag" {
  description = "Docker image tag"
  default     = "latest"
}

variable "ecr_repository_uri" {
  description = "ECR repository URI"
  default     = "486408064722.dkr.ecr.us-east-1.amazonaws.com/tummoc-app"
}

##########################################################
# Launch Template
##########################################################

resource "aws_launch_template" "tummoc_app" {

  name_prefix   = "tummoc-app-"
  image_id      = "ami-02dfbd4ff395f2a1b"
  instance_type = "t2.micro"
  key_name      = "tom"

  iam_instance_profile {
    name = aws_iam_instance_profile.tummoc_instance_profile.name
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [aws_security_group.tummoc_sg.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e

# Update packages
yum update -y

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Install SSM agent
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install AWS CLI
yum install -y aws-cli

##################################################
# Create deployment script
##################################################

cat <<SCRIPT > /home/ec2-user/deploy.sh
#!/bin/bash

TAG=\$1
REGION="us-east-1"
ECR="486408064722.dkr.ecr.us-east-1.amazonaws.com"
IMAGE="tummoc-app"

echo "Deploying version: \$TAG"

aws ecr get-login-password --region \$REGION | \
docker login --username AWS --password-stdin \$ECR

# Save previous image for rollback
PREVIOUS_IMAGE=\$(docker inspect --format='{{.Config.Image}}' tummoc-app 2>/dev/null || true)

echo "Previous image: \$PREVIOUS_IMAGE"

docker pull \$ECR/\$IMAGE:\$TAG

docker stop tummoc-app || true
docker rm tummoc-app || true

docker run -d \
--name tummoc-app \
-p 5000:5000 \
--restart unless-stopped \
\$ECR/\$IMAGE:\$TAG

sleep 10

# Health check
curl -f http://localhost:5000 || {

echo "Deployment failed. Rolling back..."

docker stop tummoc-app
docker rm tummoc-app

docker run -d \
--name tummoc-app \
-p 5000:5000 \
--restart unless-stopped \
\$PREVIOUS_IMAGE

}

SCRIPT

chmod +x /home/ec2-user/deploy.sh

EOF
  )

}

##########################################################
# Auto Scaling Group
##########################################################

resource "aws_autoscaling_group" "tummoc_asg" {

  name                = "tummoc-app-asg"
  vpc_zone_identifier = [aws_subnet.tummoc_public_subnet.id]

  min_size         = 0
  max_size         = 0
  desired_capacity = 1

  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.tummoc_app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "tummoc-app-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = "tummoc-app"
    propagate_at_launch = true
  }

}
