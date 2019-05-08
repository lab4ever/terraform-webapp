provider "aws" {
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/role-instance-jenkins"
    session_name = "terraform"
  }

  region = "${var.region}"
}