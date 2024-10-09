provider "aws" {
  region = "us-west-1"
}

# get ecs security group id
data "aws_security_group" "ecs_instance_sg" {
  filter {
    name   = "tag:Name"
    values = ["ecs-instance-sg"]
  }
}

# get subnet id for ecs instance in us-west-1b
data "aws_subnet" "subnet-us-west-1-dev-main01-public-b" {
  filter {
    name   = "tag:Name"
    values = ["subnet-us-west-1-dev-main01-public-b"]
  }
}

# get subnet id for ecs instance in us-west-1c
data "aws_subnet" "subnet-us-west-1-dev-main01-public-c" {
  filter {
    name   = "tag:Name"
    values = ["subnet-us-west-1-dev-main01-public-c"]
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster01"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "ecs-cluster01"
  }
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_configuration" "ecs_instance" {
  name          = "ecs-instance-configuration01"

  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups      = [data.aws_security_group.ecs_instance_sg.id]

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
              EOF
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "ecs-autoscale-group-instance01"

  launch_configuration = aws_launch_configuration.ecs_instance.id
  termination_policies = ["OldestLaunchConfiguration", "Default"]
  vpc_zone_identifier  = [data.aws_subnet.subnet-us-west-1-dev-main01-public-b.id, data.aws_subnet.subnet-us-west-1-dev-main01-public-c.id]

  desired_capacity     = 1
  max_size             = 3
  min_size             = 1
  # protect_from_scale_in = true
  
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "ecs-autoscale-group-instance01"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/ecs-cluster01"
  retention_in_days = 7

  tags = {
    Name = "ecs-log-group"
  }
}

resource "aws_ecs_capacity_provider" "asg_capacity_provider" {
  name = "asg-capacity-provider01"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    # managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1000
    }
  }

  tags = {
    Name = "asg-capacity-provider01"
  }
}

# define cluster capacity providers
resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name              = aws_ecs_cluster.ecs_cluster.name

  capacity_providers   = [aws_ecs_capacity_provider.asg_capacity_provider.name]

  default_capacity_provider_strategy {
    base = 1
    weight = 100
    capacity_provider = aws_ecs_capacity_provider.asg_capacity_provider.name
  }
}