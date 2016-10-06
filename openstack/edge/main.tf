variable name_prefix {}
variable image_name {}
variable flavor_name {}
variable keypair_name {}
variable network_name {}
variable floating_ip_pool {}
variable kubeadm_token {}
variable master_ip {}
variable count {}

# Allocate floating IPs
resource "openstack_compute_floatingip_v2" "edge_ip" {
  pool = "${var.floating_ip_pool}"
  count = "${var.count}"
}

# Bootstrap
resource "template_file" "edge_bootstrap" {
  template = "${file("${path.root}/../bootstrap/node.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip = "${var.master_ip}"
  }
}

# Create instances
resource "openstack_compute_instance_v2" "edge" {
  name="${var.name_prefix}-edge-${format("%02d", count.index)}"
  image_name = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  key_pair = "${var.keypair_name}"
  floating_ip = "${element(openstack_compute_floatingip_v2.edge_ip.*.address, count.index)}"
  network {
    name = "${var.network_name}"
  }
  user_data = "${template_file.edge_bootstrap.rendered}"
  count = "${var.count}"
}

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  provisioner "local-exec" {
    command =  "echo \"[edge]\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", openstack_compute_instance_v2.edge.*.name, openstack_compute_floatingip_v2.edge_ip.*.address))}\" >> inventory"
  }

}
