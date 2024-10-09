provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "vpc-us-west-1-dev-main01" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-us-west-1-dev-main01"
  }
}

# Public Subnets
resource "aws_subnet" "subnet-us-west-1-dev-main01-public-b" {
  vpc_id                  = aws_vpc.vpc-us-west-1-dev-main01.id
  cidr_block              = "10.10.100.0/24"
  availability_zone       = "us-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-us-west-1-dev-main01-public-b"
  }
}

resource "aws_subnet" "subnet-us-west-1-dev-main01-public-c" {
  vpc_id                  = aws_vpc.vpc-us-west-1-dev-main01.id
  cidr_block              = "10.10.101.0/24"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-us-west-1-dev-main01-public-c"
  }
}

# Private Subnets
resource "aws_subnet" "subnet-us-west-1-dev-main01-private-b" {
  vpc_id            = aws_vpc.vpc-us-west-1-dev-main01.id
  cidr_block        = "10.10.102.0/24"
  availability_zone = "us-west-1b"

  tags = {
    Name = "subnet-us-west-1-dev-main01-private-b"
  }
}

resource "aws_subnet" "subnet-us-west-1-dev-main01-private-c" {
  vpc_id            = aws_vpc.vpc-us-west-1-dev-main01.id
  cidr_block        = "10.10.103.0/24"
  availability_zone = "us-west-1c"

  tags = {
    Name = "subnet-us-west-1-dev-main01-private-c"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw-us-west-1-dev-main01" {
  vpc_id = aws_vpc.vpc-us-west-1-dev-main01.id

  tags = {
    Name = "igw-us-west-1-dev-main01"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "rt-us-west-1-dev-main01-public" {
  vpc_id = aws_vpc.vpc-us-west-1-dev-main01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-us-west-1-dev-main01.id
  }

  tags = {
    Name = "rt-us-west-1-dev-main01-public"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "rta-us-west-1-dev-main01-public-b" {
  subnet_id      = aws_subnet.subnet-us-west-1-dev-main01-public-b.id
  route_table_id = aws_route_table.rt-us-west-1-dev-main01-public.id
}

resource "aws_route_table_association" "rta-us-west-1-dev-main01-public-c" {
  subnet_id      = aws_subnet.subnet-us-west-1-dev-main01-public-c.id
  route_table_id = aws_route_table.rt-us-west-1-dev-main01-public.id
}

# NAT Gateway
resource "aws_eip" "eip-us-west-1-dev-main01-natgw" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.igw-us-west-1-dev-main01]
}

resource "aws_nat_gateway" "natgw-us-west-1-dev-main01" {
  allocation_id = aws_eip.eip-us-west-1-dev-main01-natgw.id
  subnet_id     = aws_subnet.subnet-us-west-1-dev-main01-public-b.id

  tags = {
    Name = "natgw-us-west-1-dev-main01"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "rt-us-west-1-dev-main01-private" {
  vpc_id = aws_vpc.vpc-us-west-1-dev-main01.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw-us-west-1-dev-main01.id
  }

  tags = {
    Name = "rt-us-west-1-dev-main01-private"
  }
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "rta-us-west-1-dev-main01-private-b" {
  subnet_id      = aws_subnet.subnet-us-west-1-dev-main01-private-b.id
  route_table_id = aws_route_table.rt-us-west-1-dev-main01-private.id
}

resource "aws_route_table_association" "rta-us-west-1-dev-main01-private-c" {
  subnet_id      = aws_subnet.subnet-us-west-1-dev-main01-private-c.id
  route_table_id = aws_route_table.rt-us-west-1-dev-main01-private.id
}