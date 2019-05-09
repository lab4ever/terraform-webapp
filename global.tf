variable "cidr_blocks" {}

variable "aws_account_id" {}

variable "organization" {}

variable "region" {}

variable "tier" {}

variable "site" {
  type = "map"

  default = {
    production = "www.lab4ever.com"
    staging    = "www-s.lab4ever.com"
    develop    = "www-d.lab4ever.com"
  }
}

variable "domain" {
  type    = "string"
  default = "lab4ever.com"
}

data "aws_availability_zones" "available" {}

locals {
  common_tags = {
    Terraform    = "true"
    Organization = "${var.organization}"
    Tier         = "${var.tier}"
  }

  asg_common_tags = [
    {
      key                 = "Terraform"
      propagate_at_launch = "true"
      value               = "true"
    },
    {
      key                 = "Organization"
      propagate_at_launch = "true"
      value               = "${var.organization}"
    },
    {
      key                 = "Tier"
      propagate_at_launch = "true"
      value               = "${var.organization}"
    },
  ]

  termination_policies = [
    "OldestLaunchConfiguration",
    "OldestInstance",
  ]
}
