variable name_prefix {}
variable entity_name {}
variable image_name {}
variable flavor_name {}
variable keypair_name {}
variable network_name {}
variable floating_ip_pool {}
variable count {}

# Allocate floating IPs
resource "openstack_compute_floatingip_v2" "floating_ip" {
  pool = "${var.floating_ip_pool}"
  count = "${var.count}"
}

# Create instances
resource "openstack_compute_instance_v2" "instance" {
  name="${var.name_prefix}-${var.entity_name}-${format("%03d", count.index)}"
  image_name = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  floating_ip = "${element(openstack_compute_floatingip_v2.floating_ip.*.address, count.index)}"
  key_pair = "${var.keypair_name}"
  network {
    name = "${var.network_name}"
  }
  count = "${var.count}"
}
