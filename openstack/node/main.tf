variable name_prefix {}
variable image_name {}
variable flavor_name {}
variable keypair_name {}
variable network_name {}
variable kubeadm_token {}
variable master_ip {}
variable count {}

# Bootstrap
resource "template_file" "node_bootstrap" {
  template = "${file("${path.root}/../bootstrap/node.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip = "${var.master_ip}"
  }
}

# Create instances
resource "openstack_compute_instance_v2" "node" {
  name="${var.name_prefix}-node-${format("%03d", count.index)}"
  image_name = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  key_pair = "${var.keypair_name}"
  network {
    name = "${var.network_name}"
  }
  user_data = "${template_file.node_bootstrap.rendered}"
  count = "${var.count}"
}
