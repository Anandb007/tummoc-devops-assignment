resource "aws_instance" "tummoc_ec2" {

  ami = "ami-02dfbd4ff395f2a1b"

  instance_type = "t2.micro"

  subnet_id = aws_subnet.tummoc_public_subnet.id

  vpc_security_group_ids = [aws_security_group.tummoc_sg.id]

  iam_instance_profile = aws_iam_instance_profile.tummoc_instance_profile.name

  associate_public_ip_address = true

  key_name = "tom"

  user_data = <<-EOF
#!/bin/bash

yum update -y

yum install docker -y

systemctl start docker

systemctl enable docker

aws ecr get-login-password --region us-east-1 \
| docker login --username AWS --password-stdin 486408064722.dkr.ecr.us-east-1.amazonaws.com

docker pull 486408064722.dkr.ecr.us-east-1.amazonaws.com/tummoc-app:latest

docker run -d -p 5000:5000 486408064722.dkr.ecr.us-east-1.amazonaws.com/tummoc-app:latest

EOF

  tags = {

    Name = "tummoc-app-server"

  }

}
