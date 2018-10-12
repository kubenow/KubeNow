variable name_prefix {}
variable secgroup_name {}

variable ingress_tcp_ports {
  default = ["22", "80", "443"]
}

resource "openstack_networking_secgroup_v2" "created" {
  # create only if not specified in var.secgroup_name
  count       = "${var.secgroup_name == "" ? 1 : 0}"
  name        = "${var.name_prefix}-secgroup"
  description = "The automatically created secgroup for ${var.name_prefix}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_allow_all_internal_tcp" {
  # create only if not specified in var.secgroup_name
  count = "${var.secgroup_name == "" ? 1 : 0}"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "1"
  port_range_max    = "64535"
  remote_group_id   = "${openstack_networking_secgroup_v2.created.id}"
  security_group_id = "${openstack_networking_secgroup_v2.created.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_allow_all_internal_udp" {
  # create only if not specified in var.secgroup_name
  count = "${var.secgroup_name == "" ? 1 : 0}"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = "1"
  port_range_max    = "64535"
  remote_group_id   = "${openstack_networking_secgroup_v2.created.id}"
  security_group_id = "${openstack_networking_secgroup_v2.created.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_ingress_tcp_port" {
  # create only if not specified in var.secgroup_name
  count = "${var.secgroup_name == "" ? length(var.ingress_tcp_ports) : 0}"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "${element(var.ingress_tcp_ports, count.index)}"
  port_range_max    = "${element(var.ingress_tcp_ports, count.index)}"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.created.id}"
}

output "secgroup_name" {
  # The join() hack is required because currently the ternary operator
  # evaluates the expressions on both branches of the condition before
  # returning a value. When providing and external VPC, the template VPC
  # resource gets a count of zero which triggers an evaluation error.
  #
  # This is tracked upstream: https://github.com/hashicorp/hil/issues/50
  #
  value = "${ var.secgroup_name == "" ? join(" ", openstack_networking_secgroup_v2.created.*.name) : var.secgroup_name }"
}
