###
# AWS LB - Key Retrieval
###

resource "aws_lb_target_group" "covidportal" {
  name                 = "covidportal"
  port                 = 8000
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = aws_vpc.covidportal.id

  health_check {
    enabled             = true
    interval            = 10
    path                = "/status/"
    port                = 8000
    matcher             = "301,200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name                  = "covidportal"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_lb_target_group" "covidportal_2" {
  name                 = "covidportal-2"
  port                 = 8000
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = aws_vpc.covidportal.id

  health_check {
    enabled             = true
    interval            = 10
    port                = 8000
    path                = "/status/"
    matcher             = "301,200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name                  = "covidportal-2"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_lb" "covidportal" {
  name               = "covidportal"
  internal           = false #tfsec:ignore:AWS005
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.covidportal_load_balancer.id
  ]
  subnets = aws_subnet.covidportal_public.*.id

  tags = {
    Name                  = "covidportal"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_lb_listener" "covidportal_https" {
  depends_on = [
    aws_acm_certificate.covidportal_staging
  ]

  load_balancer_arn = aws_lb.covidportal.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  certificate_arn   = aws_acm_certificate.covidportal_staging.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.covidportal.arn
  }

  lifecycle {
    ignore_changes = [
      default_action # updated by codedeploy
    ]
  }
}

resource "aws_lb_listener" "covidportal_http" {
  load_balancer_arn = aws_lb.covidportal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  lifecycle {
    ignore_changes = [
      default_action # updated by codedeploy
    ]
  }
}
