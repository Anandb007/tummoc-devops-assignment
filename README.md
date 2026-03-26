# Tummoc DevOps Assignment

## Overview

This project demonstrates a complete **DevOps pipeline** for a sample **Flask web application**. It showcases CI/CD automation, containerization, infrastructure as code, and monitoring.

The goal is to transform a manually deployed application into an automated, scalable, and production-ready environment.

**Key Features:**

* CI/CD pipeline using GitHub Actions
* Application containerization using Docker
* Infrastructure provisioning using Terraform
* Docker image storage in Amazon ECR
* Deployment to Amazon EC2 via AWS SSM
* Monitoring with Prometheus and Grafana
* Code quality validation using Linting (flake8) and Unit Tests (pytest)

---

## Architecture

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

### Monitoring Architecture

```
Terraform Monitoring Infrastructure
        │
        ├── EC2 Instance for Monitoring
        ├── Prometheus (Port 9090)
        └── Grafana (Port 3000)
```

---

## Project Structure

```
tummoc-devops/
│
├── app/
│   ├── app.py               # Flask application
│   ├── requirements.txt     # Python dependencies
│   └── __init__.py
│
├── docker/
│   └── Dockerfile           # Container definition
│
├── terraform/
│   ├── backend.tf           # Remote Terraform state configuration
│   ├── provider.tf          # AWS provider configuration
│   ├── vpc.tf               # VPC, Subnet, IGW, Routes
│   ├── security-group.tf    # Security Group definition
│   ├── iam.tf               # IAM roles, policies, instance profile
│   ├── ecr.tf               # ECR repository
│   ├── ec2.tf               # Application EC2 instance
│   └── monitoring/          # Monitoring infrastructure (Prometheus & Grafana)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── tests/
│   └── test_app.py          # Pytest unit test
│
├── build_push.sh            # Optional helper script for local Docker build
│
└── .github/
    └── workflows/
        └── ci-cd.yml       # GitHub Actions CI/CD pipeline
```

---

## Application

**Location:** `app/`
**Files:**

* `app.py` – Flask web application exposing a root endpoint `/`
* `requirements.txt` – Python dependencies

  * `flask` → Web framework
  * `flake8` → Linting
  * `pytest` → Unit testing

**Port:** 5000
**Response Example:**

```
Hello Tummoc DevOps Assignment
```

---

## Docker Configuration

**Location:** `docker/Dockerfile`

**Build Stages:**

* **Builder Stage:** Install dependencies in an isolated environment
* **Runtime Stage:** Copy only required packages and app code

**Exposed Port:** 5000
**Container Start Command:**

```bash
python app.py
```

---

## Infrastructure as Code (Terraform)

**Location:** `terraform/`

### Backend

* **File:** `backend.tf`
* **State Storage:** S3 bucket `tummoc-terraform-state`
* **State Locking:** DynamoDB table `terraform-locks`
* **Purpose:** Centralized state management, prevents concurrent runs

### AWS Resources Provisioned

| Resource                    | File              | Description                                          |
| --------------------------- | ----------------- | ---------------------------------------------------- |
| VPC, Subnet, IGW, Routes    | vpc.tf            | Network infrastructure                               |
| Security Group              | security-group.tf | Allows SSH (22) & Flask App (5000)                   |
| IAM Role & Instance Profile | iam.tf            | Allows EC2 to pull Docker images, run SSM commands   |
| ECR Repository              | ecr.tf            | Stores Docker images, image scanning enabled         |
| EC2 Instance                | ec2.tf            | Runs Flask app container, SSM-enabled for deployment |

---

### Monitoring Infrastructure

* Separate EC2 instance for monitoring
* **Prometheus:** Port 9090
* **Grafana:** Port 3000

---

## CI/CD Pipeline

**Location:** `.github/workflows/ci-cd.yml`
**Triggers:** Push to `master` branch

**Pipeline Stages:**

1. **Checkout Repository:** Clone project code
2. **Install Dependencies:** `pip install -r app/requirements.txt`
3. **Lint Stage:** `flake8 app/`
4. **Test Stage:** `pytest tests/test_app.py`
5. **Configure AWS Credentials:** GitHub OIDC role assumption
6. **Terraform Deployment:** `init`, `plan`, `apply` for infrastructure
7. **Docker Build:** Tag image with commit SHA
8. **Push Image to ECR:** Repository: `tummoc-app`
9. **Deploy to EC2 via SSM:** Runs `/home/ec2-user/deploy.sh <IMAGE_TAG>`
10. **Monitoring Terraform Deployment:** Separate Terraform apply for monitoring EC2
11. **Output EC2 IPs:** App and Monitoring IPs exported as environment variables

---

## Accessing the Application

**App URL:**
App EC2 IP is automatically retrieved via Terraform outputs in the pipeline.
```
http://<APP_EC2_PUBLIC_IP>:5000
```

**Response:**

```
Hello Tummoc DevOps Assignment
```

**Monitoring URLs:**

* **Grafana:** `http://<MONITORING_EC2_PUBLIC_IP>:3000`
* **Prometheus:** `http://<MONITORING_EC2_PUBLIC_IP>:9090`

---

## Deployment Script

**File:** `deploy.sh`
**Location:** `/home/ec2-user/` on EC2

**Steps:**

1. Login to ECR
2. Pull latest Docker image
3. Stop running container
4. Start new container with updated image

---

## Auto Scaling Configuration

**Current:**

```
min_size = 0
desired_capacity = 0
max_size = 0
```

**Recommended for production:**

```
min_size = 1
desired_capacity = 1
max_size = 2
```

---

## Technologies Used

| Tool / Service | Purpose                      |
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
| Prometheus     | Metrics monitoring           |
| Grafana        | Visualization dashboard      |
