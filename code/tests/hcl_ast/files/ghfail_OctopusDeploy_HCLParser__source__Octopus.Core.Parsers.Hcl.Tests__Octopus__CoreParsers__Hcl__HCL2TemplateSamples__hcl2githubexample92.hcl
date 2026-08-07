data "template_file" "user_data" {
  template = file("${path.module}/userdata.sh")
}
/*
resource "aws_instance" "web_1" {
  ami = var.ami_id
  instance_type = var.instance_type
  user_data = data.template_file.user_data.rendered
  network_interface {
   device_index = 0
   network_interface_id = var.eni[0]
 }
  tags = merge(var.tags, map("Name", format("%s-web1", var.name)))
}
resource "aws_instance" "web_2" {
  ami = var.ami_id
  instance_type = var.instance_type
  user_data = data.template_file.user_data.rendered
  network_interface {
    device_index = 0
    network_interface_id = var.eni[1]
  }
  tags = merge(var.tags, map("Name", format("%s-web2", var.name)))
}
resource "aws_eip" "eip" {
  instance = aws_instance.web_1.id
  vpc = true
}
resource "aws_lb" "lb" {
  name = "sangyul-test-alb"
  internal = false
  load_balancer_type = "application"
  subnets = flatten(var.subnet[*])
  tags = merge(var.tags, map("Name", format("%s-lb", var.name)))
}
resource "aws_lb_target_group" "alb-target-a" {
  name = "alb-target-1"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  health_check {
    interval = 30
    path = "/"
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
  tags = merge(var.tags, map("Name", format("%s-web1", var.name)))
}
resource "aws_lb_target_group" "alb-target-b" {
  name = "alb-target-2"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  health_check {
    interval = 30
    path = "/"
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
  tags = merge(var.tags, map("Name", format("%s-web2", var.name)))
}
resource "aws_lb_target_group_attachment" "alb-attach-a" {
  target_group_arn = aws_lb_target_group.alb-target-a.arn
  target_id = aws_instance.web_1.id
  port  = 80
}
resource "aws_lb_target_group_attachment" "alb-attach-b" {
  target_group_arn = aws_lb_target_group.alb-target-b.arn
  target_id = aws_instance.web_2 .id
  port  = 80
}
resource "aws_lb_listener" "alb-listner" {
  load_balancer_arn = aws_lb.lb.arn
  port = 80
  default_action {
    target_group_arn = aws_lb_target_group.alb-target-a.arn
    type = "forward"
  }
}
*/

resource "aws_launch_configuration" "launch_config" {
  name = "sangyul-test"
  image_id        = var.ami_id
  instance_type   = var.instance_type
  security_groups = [var.sg]
  user_data       = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "auto_group" {
  name = "sangyul-test"
  launch_configuration = aws_launch_configuration.launch_config.id
  #availability_zones   = var.azs
  vpc_zone_identifier  = flatten(var.subnet[*])
  load_balancers       = [aws_elb.elb.name]
  health_check_type    = "ELB"

  min_size = 2
  max_size = 4

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }
}

resource "aws_elb" "elb" {
  name               = var.name
  #availability_zones = var.azs
  security_groups    = [var.sg]
  subnets = flatten(var.subnet[*])

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "http:80/"
  }
}