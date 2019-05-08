variable "cidr_blocks" {}

variable "aws_account_id" {}

variable "organization" {}

variable "region" {}

variable "tier" {}

data "aws_availability_zones" "available" {}

locals {
  common_tags = {
    Terraform    = "true"
    Organization = "${var.organization}"
    Tier         = "${var.tier}"
  }
}
