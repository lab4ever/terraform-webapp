resource "aws_security_group" "loadbalancer_webapp" {
  name        = "loadbalancer_webapp"
  description = "Conexao da Internet para o loadbalancer webapp"
  vpc_id      = "${aws_vpc.webapp.id}"

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.webapp.id}",
    ]
  }

  tags = "${merge(merge(local.common_tags,
  map("Name", "loadbalancer_webapp")
  ))}"
}

resource "aws_alb" "webapp" {
  name               = "webapp-${var.tier}"
  internal           = "false"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.loadbalancer_webapp.id}"]

  subnets = [
    "${aws_subnet.public_subnet.*.id}",
  ]

  enable_deletion_protection = "false"
}

resource "aws_alb_listener" "webapp" {
  load_balancer_arn = "${aws_alb.webapp.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-2018-06"
  certificate_arn   = "${aws_acm_certificate..arn}"

  "default_action" {
    target_group_arn = "${aws_alb_target_group.webapp.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "webapp" {
  listener_arn = "${aws_alb_listener.webapp.arn}"
  priority     = 100

  action {
    target_group_arn = "${aws_alb_target_group.webapp.arn}"
    type             = "forward"
  }

  condition {
    field  = "host-header"
    values = ["${var.site}*"]
  }

  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
}

resource "aws_alb_target_group" "webapp" {
  name        = "webapp"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.webapp.id}"
  target_type = "instance"

  deregistration_delay = 120

  health_check {
    path                = "/healthcheck"
    protocol            = "HTTP"
    healthy_threshold   = 4
    port                = "80"
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
  }

  tags = "${local.common_tags}"
}
