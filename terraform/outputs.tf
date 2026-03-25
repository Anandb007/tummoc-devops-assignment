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
