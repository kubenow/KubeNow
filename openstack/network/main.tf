variable name_prefix {}
variable subnet_cidr { default = "10.0.0.0/16"}
variable external_net_uuid {}
variable dns_nameservers {}

resource "openstack_networking_network_v2" "main" {
  name = "${var.name_prefix}-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "main" {
  name = "${var.name_prefix}-subnet"
  network_id = "${openstack_networking_network_v2.main.id}"
  cidr = "${var.subnet_cidr}"
  ip_version = 4
  dns_nameservers = ["${compact(split(",", var.dns_nameservers))}"]
  enable_dhcp = true
}

resource "openstack_networking_router_v2" "main" {
  name = "${var.name_prefix}-router"
  external_gateway = "${var.external_net_uuid}"
}

resource "openstack_networking_router_interface_v2" "main" {
  router_id = "${openstack_networking_router_v2.main.id}"
  subnet_id = "${openstack_networking_subnet_v2.main.id}"
}

resource "openstack_compute_secgroup_v2" "main" {
  name = "${var.name_prefix}-secgroup"
  description = "The automatically created secgroup for ${var.name_prefix}"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 80
    to_port = 80
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 443
    to_port = 443
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0" 
  }
  rule { # All internal tcp traffic
    from_port = 1
    to_port = 65535
    ip_protocol = "tcp"
    self = "true"
  }
  rule { # All internal udp traffic
    from_port = 1
    to_port = 65535
    ip_protocol = "udp"
    self = "true"
  }
}

output "network_name" {
  value = "${openstack_networking_network_v2.main.name}"
}

output "secgroup_name" {
  value = "${openstack_compute_secgroup_v2.main.name}"
}
