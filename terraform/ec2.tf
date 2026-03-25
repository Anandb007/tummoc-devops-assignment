##########################################################
# EC2 Launch Template + Auto Scaling Group for Tummoc App
# Pulls latest Docker image from ECR and runs container
##########################################################

# -------------------------------
# Variables
# -------------------------------
variable "docker_image_tag" {
  description = "Docker image tag to deploy"
  default     = "latest"
}

variable "ecr_repository_uri" {
  description = "ECR repository URI"
  default     = "486408064722.dkr.ecr.us-east-1.amazonaws.com/tummoc-app"
}

# -------------------------------
# Launch Template
# -------------------------------
resource "aws_launch_template" "tummoc_app" {
  name_prefix   = "tummoc-app-"
  image_id      = "ami-02dfbd4ff395f2a1b"      # Replace with your preferred AMI
  instance_type = "t2.micro"
  key_name      = "tom"                         # Replace with your EC2 key pair

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

# Update system and install Docker
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Login to ECR
aws ecr get-login-password --region us-east-1 \
| docker login --username AWS --password-stdin 486408064722.dkr.ecr.us-east-1.amazonaws.com

# Pull and run latest Docker image
docker pull 486408064722.dkr.ecr.us-east-1.amazonaws.com/tummoc-app:latest
docker stop tummoc-app || true
docker rm tummoc-app || true
docker run -d --name tummoc-app --restart unless-stopped -p 5000:5000 486408064722.dkr.ecr.us-east-1.amazonaws.com/tummoc-app:latest
EOF
  )
}

# -------------------------------
# Auto Scaling Group
# -------------------------------
resource "aws_autoscaling_group" "tummoc_asg" {
  name                = "tummoc-app-asg"
  vpc_zone_identifier = [aws_subnet.tummoc_public_subnet.id]
  min_size            = 0
  max_size            = 1
  desired_capacity    = 0
  health_check_type   = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.tummoc_app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "tummoc-app-asg"
    propagate_at_launch = true
  }
}
