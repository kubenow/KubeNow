variable name_prefix {}
variable secgroup_name {}

resource "openstack_compute_secgroup_v2" "created" {
  # create only if not specified in var.secgroup_name
  count       = "${var.secgroup_name == "" ? 1 : 0}"
  name        = "${var.name_prefix}-secgroup"
  description = "The automatically created secgroup for ${var.name_prefix}"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 1      # All internal tcp traffic
    to_port     = 65535
    ip_protocol = "tcp"
    self        = "true"
  }

  rule {
    from_port   = 1      # All internal udp traffic
    to_port     = 65535
    ip_protocol = "udp"
    self        = "true"
  }
}

output "secgroup_name" {
  # The join() hack is required because currently the ternary operator
  # evaluates the expressions on both branches of the condition before
  # returning a value. When providing and external VPC, the template VPC
  # resource gets a count of zero which triggers an evaluation error.
  #
  # This is tracked upstream: https://github.com/hashicorp/hil/issues/50
  #
  value = "${ var.secgroup_name == "" ? join(" ", openstack_compute_secgroup_v2.created.*.name) : var.secgroup_name }"
}
