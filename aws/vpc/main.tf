variable vpc_id {}

variable vpc_cidr {
  default = "10.0.0.0/16"
}

variable name_prefix {}

resource "aws_vpc" "created" {
  # create vpc only if not specified in var.vpc_id
  count                = "${var.vpc_id == "" ? 1 : 0}"
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.name_prefix}"
  }
}

output "id" {
  # The join() hack is required because currently the ternary operator
  # evaluates the expressions on both branches of the condition before
  # returning a value. When providing and external VPC, the template VPC
  # resource gets a count of zero which triggers an evaluation error.
  #
  # This is tracked upstream: https://github.com/hashicorp/hil/issues/50
  #
  value = "${ var.vpc_id == "" ? join(" ", aws_vpc.created.*.id) : var.vpc_id }"
}
