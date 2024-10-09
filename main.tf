terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.70.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "vpc-us-west-1-dev-main01" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "vpc-us-west-1-dev-main01"
  }
}

resource "aws_subnet" "subnet-us-west-1-dev-main01-nat" {
  vpc_id     = aws_vpc.vpc-us-west-1-dev-main01.id
  cidr_block = "10.10.100.0/23"
  availability_zone = "us-west-1a"

  tags = {
    Name = "subnet-us-west-1-dev-main01-nat"
  }
}

resource "aws_subnet" "subnet-us-west-1-dev-main01-default" {
  vpc_id     = aws_vpc.vpc-us-west-1-dev-main01.id
  cidr_block = "10.10.10.0/20"
  availability_zone = "us-west-1a"

  tags = {
    Name = "subnet-us-west-1-dev-main01-default"
  }
}
