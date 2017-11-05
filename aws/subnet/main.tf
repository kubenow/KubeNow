variable vpc_id {}
variable subnet_id {}

variable subnet_cidr {
  default = "10.0.0.0/16"
}

variable availability_zone {}
variable name_prefix {}

resource "aws_subnet" "created" {
  # create subnet only if not specified in var.subnet_id
  count             = "${var.subnet_id == "" ? 1 : 0}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.subnet_cidr}"
  availability_zone = "${var.availability_zone}"

  tags {
    Name = "${var.name_prefix}"
  }
}

resource "aws_internet_gateway" "main" {
  # create subnet only if not specified in var.subnet_id
  count  = "${var.subnet_id == "" ? 1 : 0}"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name_prefix}"
  }
}

resource "aws_route_table" "main" {
  # create subnet only if not specified in var.subnet_id
  count  = "${var.subnet_id == "" ? 1 : 0}"
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "${var.name_prefix}"
  }
}

resource "aws_main_route_table_association" "main" {
  # create subnet only if not specified in var.subnet_id
  count          = "${var.subnet_id == "" ? 1 : 0}"
  vpc_id         = "${var.vpc_id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route_table_association" "main" {
  # create subnet only if not specified in var.subnet_id
  count          = "${var.subnet_id == "" ? 1 : 0}"
  subnet_id      = "${var.subnet_id != "" ? var.subnet_id : aws_subnet.created.id }"
  route_table_id = "${aws_route_table.main.id}"
}

output "id" {
  # The join() hack is required because currently the ternary operator
  # evaluates the expressions on both branches of the condition before
  # returning a value. When providing and external VPC, the template VPC
  # resource gets a count of zero which triggers an evaluation error.
  #
  # This is tracked upstream: https://github.com/hashicorp/hil/issues/50
  #
  value = "${ var.subnet_id == "" ? join(" ", aws_subnet.created.*.id) : var.subnet_id }"
}
