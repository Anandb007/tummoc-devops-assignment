# VPC ID
output "vpc_id" {
  value = aws_vpc.tummoc_vpc.id
}

# Public Subnet ID
output "public_subnet_id" {
  value = aws_subnet.tummoc_public_subnet.id
}

# EC2 IAM Instance Profile
output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.tummoc_instance_profile.name
}
# Fetch all EC2 instances with tag App=tummoc-app
data "aws_instances" "tummoc_app_instances" {
  filter {
    name   = "tag:App"
    values = ["tummoc-app"]
  }
}

# Output all public IPs
output "app_ec2_public_ips" {
  value = data.aws_instances.tummoc_app_instances.public_ips
}
