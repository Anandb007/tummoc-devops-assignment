resource "aws_vpc" "tummoc_vpc" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tummoc-vpc"
  }

}

resource "aws_subnet" "tummoc_public_subnet" {

  vpc_id = aws_vpc.tummoc_vpc.id

  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true

  availability_zone = "us-east-1a"

  tags = {
    Name = "tummoc-public-subnet"
  }

}

resource "aws_internet_gateway" "tummoc_igw" {

  vpc_id = aws_vpc.tummoc_vpc.id

  tags = {
    Name = "tummoc-igw"
  }

}

resource "aws_route_table" "tummoc_public_rt" {

  vpc_id = aws_vpc.tummoc_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.tummoc_igw.id

  }

  tags = {
    Name = "tummoc-public-rt"
  }

}

resource "aws_route_table_association" "tummoc_rt_assoc" {

  subnet_id = aws_subnet.tummoc_public_subnet.id

  route_table_id = aws_route_table.tummoc_public_rt.id

}
