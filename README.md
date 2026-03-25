# Architecture Diagram

Below is the high-level architecture of the implemented solution.

```
                +---------------------+
                |     Developer      |
                |  Push Code to Git  |
                +----------+----------+
                           |
                           v
                +---------------------+
                |   GitHub Repository |
                +----------+----------+
                           |
                           v
                +-----------------------------+
                |     GitHub Actions CI/CD    |
                |                             |
                | 1. Checkout Code            |
                | 2. Install Dependencies     |
                | 3. Lint (flake8)            |
                | 4. Run Tests (pytest)       |
                | 5. Terraform Apply          |
                | 6. Build Docker Image       |
                | 7. Push Image to ECR        |
                | 8. Deploy via AWS SSM       |
                +-------------+---------------+
                              |
                              v
                 +----------------------------+
                 |       Amazon ECR           |
                 |  Docker Image Repository   |
                 +-------------+--------------+
                               |
                               v
                     +------------------+
                     |      EC2         |
                     |  Docker Runtime  |
                     +---------+--------+
                               |
                               v
                      +----------------+
                      | Flask Web App  |
                      | Port : 5000    |
                      +----------------+
```

---

# End-to-End Deployment Flow

The deployment process works as follows:

### Step 1 – Code Commit

A developer pushes code changes to the **GitHub repository**.

Example:

```
git push origin master
```

This automatically triggers the **GitHub Actions CI/CD pipeline**.

---

### Step 2 – CI Validation

Before deployment, the pipeline validates code quality.

Two checks run:

**Linting**

```
flake8
```

Ensures:

* proper Python formatting
* no syntax issues
* clean code standards

**Testing**

```
pytest
```

Validates application functionality.

Example test:

```
GET /
```

Expected response:

```
Hello Tummoc DevOps Assignment
```

If linting or tests fail → **deployment stops**.

---

### Step 3 – Infrastructure Provisioning

The pipeline runs Terraform commands:

```
terraform init
terraform plan
terraform apply
```

This provisions infrastructure in AWS including:

* VPC
* Subnet
* Security group
* IAM roles
* EC2 instance
* ECR repository

Infrastructure is fully defined as **Infrastructure as Code**.

Benefits:

* repeatable deployments
* version-controlled infrastructure
* easy rollback

---

### Step 4 – Container Image Build

The application is packaged into a **Docker image**.

Example build command:

```
docker build -t tummoc-app .
```

The image includes:

* Python runtime
* Flask application
* required dependencies

---

### Step 5 – Push Image to ECR

The Docker image is pushed to **Amazon Elastic Container Registry (ECR)**.

Example image path:

```
486408064722.dkr.ecr.us-east-1.amazonaws.com/tummoc-app
```

Benefits:

* secure container storage
* versioned images
* integration with AWS services

---

### Step 6 – Deployment to EC2

Instead of SSH, the pipeline uses **AWS Systems Manager (SSM)**.

Deployment command executed via pipeline:

```
aws ssm send-command
```

This triggers the script:

```
deploy.sh
```

on the EC2 instance.

---

### Step 7 – Container Update

The deployment script performs:

```
docker pull <latest-image>
docker stop container
docker rm container
docker run -d -p 5000:5000 <latest-image>
```

Result:

* EC2 runs the **latest version of the application container**.

---

# Security Best Practices Implemented

The project follows several security best practices:

### 1. OIDC Authentication

GitHub Actions uses:

```
OIDC → IAM Role
```

instead of storing AWS credentials.

Benefits:

* no static access keys
* short-lived credentials
* secure pipeline authentication

---

### 2. IAM Roles for EC2

The EC2 instance uses an **IAM instance profile** instead of hardcoded credentials.

Permissions include:

* ECR image pull
* SSM access
* limited AWS API access

---

### 3. Remote Terraform State

Terraform state is stored in:

```
S3 bucket
```

with locking using:

```
DynamoDB
```

This prevents:

* state corruption
* concurrent infrastructure updates

---

# Observability (Possible Future Improvement)

Currently basic deployment is implemented.

Future improvements may include:

### Monitoring

```
Prometheus
Grafana
CloudWatch Metrics
```

Track:

* CPU usage
* container health
* response latency

---

### Logging

Centralized logging using:

```
CloudWatch Logs
ELK Stack
```

---

### Auto Scaling

Implement:

```
Application Load Balancer
Auto Scaling Group
```

for high availability.

---

# Production-Ready Enhancements (Recommended)

To make this architecture production-ready:

1. Add **Application Load Balancer**
2. Enable **Auto Scaling Group**
3. Add **Docker non-root user**
4. Implement **Blue/Green deployments**
5. Add **GitHub Actions environment approvals**
6. Enable **container vulnerability scanning**
7. Add **health checks and monitoring**

---

# Summary

This project demonstrates a **complete DevOps workflow** including:

* automated testing
* infrastructure provisioning
* containerized deployments
* CI/CD automation
* AWS integration

The system ensures that **every code change automatically goes through validation, build, and deployment**, enabling a reliable and scalable delivery pipeline.
