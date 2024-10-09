# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.service_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/ || exit 1"]
        interval    = 20
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.cloudwatch_log_group_name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.container_name
        }
      }      
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = data.aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count

  network_configuration {
    subnets          = data.aws_subnet.subnets[*].id
    security_groups  = [data.aws_security_group.ecs_instance_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener_rule.listener_rule]
}

# ALB Target Group
resource "aws_lb_target_group" "target_group" {
  name        = "${var.service_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = var.health_check_matcher
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.service_name}-tg"
  }
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = data.aws_lb_listener.listener.arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    path_pattern {
      values = [var.service_path_pattern]
    }
  }
}