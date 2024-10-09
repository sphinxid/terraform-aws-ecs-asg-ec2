data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_lb" "alb" {
  name = var.alb_name
}

data "aws_security_group" "ecs_instance_sg" {
  filter {
    name   = "tag:Name"
    values = [var.ecs_instance_sg_name]
  }
}

data "aws_subnet" "subnets" {
  count = length(var.subnet_names)
  filter {
    name   = "tag:Name"
    values = [var.subnet_names[count.index]]
  }
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.ecs_cluster_name
}

data "aws_lb_listener" "listener" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = var.alb_listener_port
}

data "aws_cloudwatch_log_group" "log_group" {
  name = var.cloudwatch_log_group_name
}