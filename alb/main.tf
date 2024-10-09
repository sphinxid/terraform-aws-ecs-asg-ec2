provider "aws" {
  region = "us-west-1"
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.ecs_lb.dns_name
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.ecs_lb.arn
}

############################################

# get vpc id
data "aws_vpc" "myvpc" {
  filter {
    name   = "tag:Name"
    values = ["vpc-us-west-1-dev-main01"]
  }
}

# get alb security group id
data "aws_security_group" "lb_security_group" {
  filter {
    name   = "tag:Name"
    values = ["alb-security-group"]
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

resource "aws_lb" "ecs_lb" {
  name               = "alb-us-west-1-dev-ecs-app01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.lb_security_group.id]
  subnets            = [
    data.aws_subnet.subnet-us-west-1-dev-main01-public-b.id,
    data.aws_subnet.subnet-us-west-1-dev-main01-public-c.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "alb-us-west-1-dev-ecs-app01"
  }
}

## ALB Target Group Port 80
# ALB Target Group
resource "aws_lb_target_group" "alb-target-group-port-80" {
  name     = "alb-target-group-port-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.myvpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "alb-target-group-port-80"
  }
}

# ALB Listener
resource "aws_lb_listener" "alb-ecs_listener-port-80" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }

  tags = {
    Name = "alb-ecs_listener-port-80"
  }
}