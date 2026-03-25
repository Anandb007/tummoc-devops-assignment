output "monitoring_ec2_public_ip" {
  value = [for i in aws_instance.monitoring : i.public_ip]
}

output "monitoring_sg_id" {
  value = aws_security_group.monitoring_sg.id
}
