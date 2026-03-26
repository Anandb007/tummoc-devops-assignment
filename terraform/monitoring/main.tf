terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "tummoc-terraform-state"
    key    = "monitoring/terraform.tfstate"
    region = "us-east-1"
  }
}

# Get existing infra state
data "terraform_remote_state" "existing_infra" {
  backend = "s3"
  config = {
    bucket = "tummoc-terraform-state"
    key    = "devops/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  monitoring_subnet_id = data.terraform_remote_state.existing_infra.outputs.public_subnet_id
  vpc_id               = data.terraform_remote_state.existing_infra.outputs.vpc_id
  iam_profile_name     = data.terraform_remote_state.existing_infra.outputs.iam_instance_profile_name
}

# Security Group
resource "aws_security_group" "monitoring_sg" {
  name   = "monitoring-sg"
  vpc_id = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-sg"
  }
}

# EC2 Instance(s)
resource "aws_instance" "monitoring" {
  count                      = var.monitoring_instance_count
  ami                        = "ami-0dc2d3e4c0f9ebd18" # Amazon Linux 2 / RHEL compatible
  instance_type              = var.monitoring_instance_type
  subnet_id                  = local.monitoring_subnet_id
  vpc_security_group_ids     = [aws_security_group.monitoring_sg.id]
  associate_public_ip_address = true
  key_name                   = var.key_name
  iam_instance_profile       = local.iam_profile_name

  lifecycle {
    prevent_destroy = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y wget tar

              # -------- Prometheus --------
              useradd --no-create-home --shell /bin/false prometheus
              cd /tmp
              wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
              tar xvf prometheus-2.47.0.linux-amd64.tar.gz
              mv prometheus-2.47.0.linux-amd64 /usr/local/prometheus
              chown -R prometheus:prometheus /usr/local/prometheus

              cp /usr/local/prometheus/prometheus.yml /usr/local/prometheus/prometheus.yml.bak
              cat <<EOT > /usr/local/prometheus/prometheus.yml
              global:
                scrape_interval: 15s
              scrape_configs:
                - job_name: 'node_exporter'
                  ec2_sd_configs:
                    - region: us-east-1
                      port: 9100
                      filters:
                        - name: "tag:Prometheus"
                          values: ["true"]
              EOT

              cat <<EOT > /etc/systemd/system/prometheus.service
              [Unit]
              Description=Prometheus
              Wants=network-online.target
              After=network-online.target

              [Service]
              User=prometheus
              ExecStart=/usr/local/prometheus/prometheus \
                --config.file=/usr/local/prometheus/prometheus.yml \
                --storage.tsdb.path=/usr/local/prometheus/data

              [Install]
              WantedBy=multi-user.target
              EOT

              systemctl daemon-reload
              systemctl enable prometheus
              systemctl start prometheus

              # -------- Grafana --------
              yum install -y https://dl.grafana.com/oss/release/grafana-9.4.7-1.x86_64.rpm
              systemctl enable grafana-server
              systemctl start grafana-server
              EOF

  tags = {
    Name       = "monitoring-ec2"
    Prometheus = "true"
  }
}
