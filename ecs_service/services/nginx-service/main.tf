module "ecs_service" {
  source = "../../modules/ecs_service"

  region                    = "us-west-1"
  vpc_name                  = "vpc-us-west-1-dev-main01"
  alb_name                  = "alb-us-west-1-dev-ecs-app01"
  ecs_instance_sg_name      = "ecs-instance-sg"
  subnet_names              = ["subnet-us-west-1-dev-main01-public-b", "subnet-us-west-1-dev-main01-public-c"]
  ecs_cluster_name          = "ecs-cluster01"
  cloudwatch_log_group_name = "/ecs/ecs-cluster01"

  service_name              = "nginx-service"
  container_name            = "nginx"
  container_image           = "nginx:latest"
  container_cpu             = 256
  container_memory          = 256
  container_port            = 80
  desired_count             = 1
  health_check_path         = "/"
  health_check_matcher      = "200,400-410"
  alb_listener_port         = 80
  alb_listener_rule_priority = 120
  service_path_pattern      = "/service-nginx/*"
}
