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
  value = "${ var.vpc_id != "" ? var.vpc_id : aws_vpc.created.id }"
}
