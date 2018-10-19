variable name_prefix {}
variable vpc_id {}

variable ingress_tcp_ports {
  type = "list"
}

resource "aws_security_group" "main" {
  name        = "${var.name_prefix}"
  description = "kubenow default security group"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "security_rule_allow_all_internal" {
  type      = "ingress"
  from_port = "0"
  to_port   = "0"
  protocol  = "-1"
  self      = true

  security_group_id = "${aws_security_group.main.id}"
}

resource "aws_security_group_rule" "security_rule_allow_all_outbound" {
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.main.id}"
}

resource "aws_security_group_rule" "security_rule_ingress_tcp_port" {
  count = "${length(var.ingress_tcp_ports)}"

  type        = "ingress"
  from_port   = "${element(var.ingress_tcp_ports, count.index)}"
  to_port     = "${element(var.ingress_tcp_ports, count.index)}"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.main.id}"
}

output "id" {
  value = ["${aws_security_group.main.id}"]
}
