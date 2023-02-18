resource "aws_lb" "default" {
  name                       = "${local.projectname}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["${aws_security_group.alb_sg.id}"]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = true
  tags                       = merge(var.tags, { Name = "${local.projectname}-ecsalb" })
}


# Consumer web TG and Listeners Rules
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.default.arn
  port              = var.lb_listnerport
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

######################
### Backend TG   ####
######################

resource "aws_lb_target_group" "backend_tg" {
  name                 = "${local.projectname}-backend-tg"
  port                 = var.manticore_be_service_config["container_port"]
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    port                = var.manticore_be_service_config["container_port"]
    unhealthy_threshold = "2"
  }

  tags = merge(var.tags, { Name = "${local.projectname}-backend-tg" })

  lifecycle {
    create_before_destroy = true
  }
}