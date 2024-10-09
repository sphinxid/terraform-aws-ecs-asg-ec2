provider "aws" {
  region = "us-west-1"
}

# get vpc id
data "aws_vpc" "myvpc" {
  filter {
    name   = "tag:Name"
    values = ["vpc-us-west-1-dev-main01"]
  }
}

# Get ALB by tag Name
data "aws_lb" "alb_by_name" {
    name = "alb-us-west-1-dev-ecs-app01"
}

# get alb security group id
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

# get ecs cluster id
data "aws_ecs_cluster" "ecs_cluster" {
    cluster_name = "ecs-cluster01"
}

# get listener arn
data "aws_lb_listener" "ecs_listener-port-80" {
  load_balancer_arn = data.aws_lb.alb_by_name.arn
  port              = "80"
}

# get cloudwatch log group
data "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/ecs-cluster01"
}

# ECS Task Definition for Apache
resource "aws_ecs_task_definition" "apache_task" {
  family                   = "apache-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "apache"
      image     = "rtsp/lighttpd"  # Official Apache HTTP Server image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 20
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = data.aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "us-west-1"
          "awslogs-stream-prefix" = "apache"
        }
      }
    }
  ])
}

# ECS Service for Apache
resource "aws_ecs_service" "apache_service" {
  name            = "apache-service"
  cluster         = data.aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.apache_task.arn
  desired_count   = 1
  # launch_type     = "EC2"

  network_configuration {
    subnets          = [data.aws_subnet.subnet-us-west-1-dev-main01-public-b.id, data.aws_subnet.subnet-us-west-1-dev-main01-public-c.id]
    security_groups  = [data.aws_security_group.ecs_instance_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb-target-group-apache-80.arn
    container_name   = "apache"
    container_port   = 80
  }

  depends_on = [aws_lb_listener_rule.apache_listener_rule]
}

# ALB Target Group apache
resource "aws_lb_target_group" "alb-target-group-apache-80" {
  name     = "alb-target-group-apache-80"
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
    matcher             = "200,400-410"
  }

  # Set deregistration delay to 30 seconds for fast draining
  deregistration_delay = 30

  tags = {
    Name = "alb-target-group-apache-80"
  }
}

# ALB Listener Rule for Apache
resource "aws_lb_listener_rule" "apache_listener_rule" {
  listener_arn = data.aws_lb_listener.ecs_listener-port-80.arn
  priority     = 110  # Make sure this is different from the nginx rule priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group-apache-80.arn
  }

  condition {
    path_pattern {
      values = ["/service-apache/*"]
    }
  }
}