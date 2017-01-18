variable name_prefix {}
variable image_name {}
variable flavor_name {}
variable flavor_id {}
variable keypair_name {}
variable network_name {}
variable floating_ip_pool {}
variable kubeadm_token {}
variable secgroup_name {}

# Allocate floating IPs
resource "openstack_compute_floatingip_v2" "master_ip" {
  pool = "${var.floating_ip_pool}"
}

# Bootstrap
resource "template_file" "master_bootstrap" {
  template = "${file("${path.root}/../bootstrap/master.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
  }
}

# Create instances
resource "openstack_compute_instance_v2" "master" {
  name="${var.name_prefix}-master"
  image_name = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  flavor_id = "${var.flavor_id}"
  floating_ip = "${openstack_compute_floatingip_v2.master_ip.address}"
  key_pair = "${var.keypair_name}"
  network {
    name = "${var.network_name}"
  }
  security_groups = ["${var.secgroup_name}"]
  user_data = "${template_file.master_bootstrap.rendered}"
}

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  provisioner "local-exec" {
    command =  "echo \"[master]\" > inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"${openstack_compute_instance_v2.master.0.name} ansible_ssh_host=${openstack_compute_floatingip_v2.master_ip.0.address} ansible_ssh_user=ubuntu\" >> inventory"
  }

}

output "ip_address" {
  value = "${openstack_compute_instance_v2.master.0.network.0.fixed_ip_v4}"
}
