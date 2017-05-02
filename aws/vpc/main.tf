variable name_prefix {}
variable availability_zone {}
variable subnet_id { default = "" }


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "${var.name_prefix}"
  }
}

resource "aws_subnet" "main" {
  # create subnet only if not specified in var.subnet_id
  count = "${ var.subnet_id == "" ? 1 : 0 }"
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${aws_vpc.main.cidr_block}"
  availability_zone = "${var.availability_zone}"
  tags {
    Name = "${var.name_prefix}"
  }
}

resource "aws_internet_gateway" "main" {
  # create only if subnet is being created
  count = "${ var.subnet_id == "" ? 1 : 0 }"
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.name_prefix}"
  }
}

resource "aws_route_table" "main" {
  # create only if subnet is being created
  count = "${ var.subnet_id == "" ? 1 : 0 }"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "${var.name_prefix}"
  }
}

resource "aws_main_route_table_association" "main" {
  # create only if subnet is being created
  count = "${ var.subnet_id == "" ? 1 : 0 }"
  vpc_id = "${aws_vpc.main.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route_table_association" "main" {
  # create only if subnet is being created
  count = "${ var.subnet_id == "" ? 1 : 0 }"
  subnet_id = "${ var.subnet_id == "" ? aws_subnet.main.id : var.subnet_id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_security_group" "main" {
  name = "${var.name_prefix}"
  description = "kubenow default security group"
  vpc_id = "${aws_vpc.main.id}"


  ingress { # SSH
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # HTTP
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # HTTPS
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress { # Allow ALL internal (self)
    from_port = 0
    to_port = 0
    protocol = -1
    self = true
  }
  
  egress { # Allow ALL outbound
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "subnet_id" {
  value = "${ var.subnet_id == "" ? aws_subnet.main.id : var.subnet_id }"
}

output "security_group_id" {
  value = "${aws_security_group.main.id}"
}
