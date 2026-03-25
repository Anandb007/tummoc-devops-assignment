# Tummoc DevOps Assignment

## Overview

This project demonstrates a **minimal DevOps pipeline implementation** for a sample Flask web application.
The goal is to show how a manually deployed application can be transformed into an **automated CI/CD-driven infrastructure using DevOps best practices**.

The solution includes:

* CI/CD pipeline using **GitHub Actions**
* Application containerization using **Docker**
* Infrastructure provisioning using **Terraform**
* Image storage using **Amazon ECR**
* Deployment to **Amazon EC2 using AWS SSM**
* Code quality validation using **Linting and Testing**

---

# Architecture

```
Developer Push Code
        │
        ▼
GitHub Repository
        │
        ▼
GitHub Actions CI/CD Pipeline
        │
        ├── Lint Code (flake8)
        ├── Run Tests (pytest)
        ├── Terraform Infrastructure Provisioning
        ├── Build Docker Image
        ├── Push Image to Amazon ECR
        └── Deploy to EC2 via AWS SSM
                │
                ▼
            EC2 Instance
                │
                ▼
         Docker Container Running Flask App
```

---

# Project Structure

```
tummoc-devops-assignment
│
├── app
│   ├── app.py
│   ├── requirements.txt
│   └── __init__.py
│
├── docker
│   └── Dockerfile
│
├── terraform
│   ├── backend.tf
│   ├── provider.tf
│   ├── vpc.tf
│   ├── security-group.tf
│   ├── iam.tf
│   ├── ecr.tf
│   └── ec2.tf
│
├── tests
│   └── test_app.py
│
├── build_push.sh
│
└── .github
    └── workflows
        └── ci-cd.yml
```

---

# Application

Location:

```
app/
```

### Files

**app.py**

Simple Flask web application exposing a root endpoint.

Endpoint:

```
/
```

Response:

```
Hello Tummoc DevOps Assignment
```

The application runs on:

```
Port: 5000
```

---

**requirements.txt**

Defines Python dependencies:

```
flask
flake8
pytest
```

* `Flask` → Web framework
* `Flake8` → Code linting
* `Pytest` → Unit testing

---

# Docker Configuration

Location:

```
docker/Dockerfile
```

The application is containerized using **multi-stage Docker builds**.

### Stage 1 – Builder

* Installs Python dependencies
* Keeps build dependencies isolated

### Stage 2 – Runtime

* Copies only required packages
* Copies application code
* Runs Flask application

Exposed Port:

```
5000
```

Container startup command:

```
python app.py
```

---

# Infrastructure as Code (Terraform)

Location:

```
terraform/
```

Terraform provisions the AWS infrastructure required to run the application.

---

## Terraform Backend

File:

```
backend.tf
```

Terraform state is stored remotely in:

```
S3 Bucket: tummoc-terraform-state
```

State locking is enabled using:

```
DynamoDB Table: terraform-locks
```

Benefits:

* Prevents concurrent Terraform runs
* Centralized state management

---

# AWS Resources Created

Terraform provisions the following infrastructure:

### VPC

File:

```
vpc.tf
```

Creates:

* VPC
* Public subnet
* Internet Gateway
* Route table
* Route table association

CIDR Block:

```
10.0.0.0/16
```

---

### Security Group

File:

```
security-group.tf
```

Allows:

| Port | Purpose           |
| ---- | ----------------- |
| 22   | SSH access        |
| 5000 | Flask application |

Outbound traffic is fully allowed.

---

### IAM Role

File:

```
iam.tf
```

Creates:

* IAM Role
* Instance Profile

Used by the EC2 instance to access AWS services.

Attached permissions include:

* AmazonEC2ContainerRegistryFullAccess
* AmazonSSMManagedInstanceCore
* AmazonS3FullAccess
* DynamoDB access
* EC2 access

This allows EC2 to:

* Pull Docker images from ECR
* Receive SSM commands
* Access Terraform state if needed

---

### Amazon ECR

File:

```
ecr.tf
```

Creates container registry:

```
Repository Name: tummoc-app
```

Features enabled:

* Image scanning
* Immutable image tags

Docker images are pushed here during CI/CD.

---

### EC2 Instance

File:

```
ec2.tf
```

Creates an EC2 instance where the application runs.

Important attributes:

```
Instance Type: t2.micro
AMI: Amazon Linux
Subnet: Public subnet
Security Group: tummoc-sg
```

The instance is configured with:

```
SSM agent
IAM Instance Profile
```

This allows deployment via **AWS Systems Manager** instead of SSH.

---

# CI/CD Pipeline

Location:

```
.github/workflows/ci-cd.yml
```

The CI/CD pipeline automatically runs on:

```
Push to master branch
```

Pipeline stages:

### 1. Checkout Repository

Downloads project code.

---

### 2. Install Dependencies

Installs Python packages from:

```
app/requirements.txt
```

---

### 3. Lint Stage

Tool used:

```
flake8
```

Ensures Python code follows proper formatting and style rules.

---

### 4. Test Stage

Tool used:

```
pytest
```

Runs automated test:

```
tests/test_app.py
```

Test verifies:

```
HTTP response from "/" endpoint
```

---

### 5. Configure AWS Credentials

GitHub uses **OIDC authentication** to assume an IAM role in AWS.

Secret required:

```
AWS_ROLE_ARN
AWS_REGION
```

---

### 6. Terraform Infrastructure Deployment

Commands executed:

```
terraform init
terraform plan
terraform apply
```

Infrastructure is automatically provisioned or updated.

---

### 7. Docker Image Build

Image tag generated from commit SHA.

Example:

```
tummoc-app:8f1a2c3
```

---

### 8. Push Image to ECR

Docker image pushed to:

```
486408064722.dkr.ecr.us-east-1.amazonaws.com/tummoc-app
```

---

### 9. Deployment via AWS SSM

Pipeline sends a command to EC2 using:

```
aws ssm send-command
```

SSM runs:

```
/home/ec2-user/deploy.sh <IMAGE_TAG>
```

The script pulls the new Docker image and restarts the container.

---

# Auto Scaling Configuration

Currently:

```
min_size = 0
desired_capacity = 0
max_size = 0
```

This means no instances will run.

### Recommended Values

Update Terraform to:

```
min_size         = 1
desired_capacity = 1
max_size         = 2
```

This ensures at least **one instance is always running**.

---

# How to Access the Application

After deployment:

1. Navigate to the **AWS EC2 Console**

2. Copy the **Public IP address** of the EC2 instance.

Example:

```
http://<EC2_PUBLIC_IP>:5000
```

Example:

```
http://54.xx.xx.xx:5000
```

You should see:

```
Hello Tummoc DevOps Assignment
```

---

# Deployment Script

EC2 executes:

```
deploy.sh
```

The script performs:

1. Login to ECR
2. Pull latest image
3. Stop running container
4. Start new container

---

# Technologies Used

| Tool           | Purpose                      |
| -------------- | ---------------------------- |
| GitHub Actions | CI/CD pipeline               |
| Docker         | Application containerization |
| Terraform      | Infrastructure provisioning  |
| AWS EC2        | Application hosting          |
| AWS ECR        | Container registry           |
| AWS SSM        | Remote deployment            |
| Flask          | Sample web application       |
| Pytest         | Unit testing                 |
| Flake8         | Code linting                 |

---

# Future Improvements

Possible enhancements:

* Kubernetes deployment
* Blue/Green deployments
* Load balancer integration
* Prometheus + Grafana monitoring
* Secure IAM policies using least privilege
* Docker non-root user
* GitHub Actions caching for faster builds

---

# Conclusion

This project demonstrates how a manually deployed application can be transformed into a **fully automated DevOps workflow** using modern cloud and automation practices.

The pipeline ensures:

* Automated testing
* Infrastructure as code
* Containerized deployments
* Continuous delivery to AWS infrastructure

This provides a **reliable, repeatable, and scalable deployment process**.
