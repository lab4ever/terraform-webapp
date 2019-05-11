data "aws_ami" "webapp" {
  most_recent = "true"

  owners = ["${var.aws_account_id}"]

  filter {
    name   = "name"
    values = ["webapp*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "tag:OS_Version"
    values = ["Ubuntu*"]
  }
}

resource "aws_security_group" "webapp" {
  name        = "webapp"
  description = "Security Group Webapp"
  vpc_id      = "${aws_vpc.webapp.id}"

  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = "${merge(merge(local.common_tags, map("Name", "webapp")))}"
}

data "tls_public_key" "webapp" {
  private_key_pem = "${tls_private_key.webapp.private_key_pem}"
}

resource "tls_private_key" "webapp" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "webapp" {
  key_name_prefix = "webapp"
  public_key      = "${data.tls_public_key.webapp.public_key_openssh}"
}

resource "aws_launch_configuration" "webapp" {
  name_prefix = "webapp"

  key_name = "${aws_key_pair.webapp.key_name}"

  user_data = <<EOF
  #!/bin/bash
  apt-get update
  echo welcome-${var.tier} > /var/www/html/lab4ever/index.html
  EOF

  root_block_device {
    volume_size           = 8
    volume_type           = "gp2"
    delete_on_termination = true
  }

  ebs_optimized               = false
  instance_type               = "t2.micro"
  image_id                    = "${data.aws_ami.webapp.id}"
  security_groups             = ["${aws_security_group.webapp.id}"]
  associate_public_ip_address = false

  depends_on = [
    "aws_security_group.webapp",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webapp" {
  name                      = "webapp-${var.tier}"
  desired_capacity          = "0"
  max_size                  = "0"
  min_size                  = "0"
  health_check_type         = "EC2"
  health_check_grace_period = 180
  force_delete              = true

  termination_policies = "${local.termination_policies}"

  target_group_arns = [
    "${aws_alb_target_group.webapp.arn}",
  ]

  vpc_zone_identifier = [
    "${aws_subnet.private_subnet.*.id}",
  ]

  launch_configuration = "${aws_launch_configuration.webapp.name}"

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    "${concat(local.asg_common_tags,list(
          map("key", "Name","propagate_at_launch", "true","value", "webapp-${var.tier}"),
          map("key", "Application", "propagate_at_launch", "true", "value", "webapp-${var.tier}")
     ))}",
  ]
}
