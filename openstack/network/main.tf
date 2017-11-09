variable name_prefix {}

variable network_name {}

variable subnet_cidr {
  default = "10.0.0.0/16"
}

variable external_net_uuid {}
variable dns_nameservers {}

resource "openstack_networking_network_v2" "created" {
  # create only if not specified in var.network_name
  count          = "${var.network_name == "" ? 1 : 0}"
  name           = "${var.name_prefix}-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "created" {
  # create only if not specified in var.network_name
  count      = "${var.network_name == "" ? 1 : 0}"
  name       = "${var.name_prefix}-subnet"
  network_id = "${openstack_networking_network_v2.created.id}"
  cidr       = "${var.subnet_cidr}"
  ip_version = 4

  dns_nameservers = ["${compact(split(",", var.dns_nameservers))}"]
  enable_dhcp     = true
}

resource "openstack_networking_router_v2" "created" {
  # create only if not specified in var.network_name
  count            = "${var.network_name == "" ? 1 : 0}"
  name             = "${var.name_prefix}-router"
  external_gateway = "${var.external_net_uuid}"
}

resource "openstack_networking_router_interface_v2" "created" {
  # create only if not specified in var.network_name
  count     = "${var.network_name == "" ? 1 : 0}"
  router_id = "${openstack_networking_router_v2.created.id}"
  subnet_id = "${openstack_networking_subnet_v2.created.id}"
}

output "network_name" {
  # The join() hack is required because currently the ternary operator
  # evaluates the expressions on both branches of the condition before
  # returning a value. When providing and external Network, the template Network
  # resource gets a count of zero which triggers an evaluation error.
  #
  # This is tracked upstream: https://github.com/hashicorp/hil/issues/50
  #
  value = "${ var.network_name == "" ? join(" ", openstack_networking_network_v2.created.*.name) : var.network_name }"
}
