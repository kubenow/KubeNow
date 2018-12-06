# Core settings
variable count {}

variable name_prefix {}
variable flavor_name {}
variable flavor_id {}
variable image_name {}

# SSH settings
variable ssh_user {}

variable keypair_name {}

# Network settings
variable network_name {}

variable external_network_uuid {
  default = ""
}

variable secgroup_name {}

variable assign_public_ip {
  default = false
}

variable floating_ip_pool {}

variable use_floating_IPs {
  default = true
}

# Disk settings
variable extra_disk_size {
  default = 0
}

# Bootstrap settings
variable bootstrap_file {}

variable kubeadm_token {}

variable node_labels {
  type = "list"
}

variable node_taints {
  type = "list"
}

variable master_ip {
  default = ""
}

# Bootstrap
data "template_file" "instance_bootstrap" {
  template = "${file("${path.root}/../${ var.bootstrap_file }")}"

  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip     = "${var.master_ip}"
    node_labels   = "${join(",", var.node_labels)}"
    node_taints   = "${join(",", var.node_taints)}"
    ssh_user      = "${var.ssh_user}"
    use_external_net = "${!var.use_floating_IPs && var.assign_public_ip}"
  }
}

# Create instances
resource "openstack_compute_instance_v2" "instance" {
  count       = "${!var.assign_public_ip || var.use_floating_IPs ? var.count : 0}"
  name        = "${var.name_prefix}-${format("%03d", count.index)}"
  image_name  = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  flavor_id   = "${var.flavor_id}"
  key_pair    = "${var.keypair_name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = ["${var.secgroup_name}"]
  user_data       = "${data.template_file.instance_bootstrap.rendered}"
}

resource "openstack_compute_instance_v2" "instance_ext" {
  count       = "${var.assign_public_ip && !var.use_floating_IPs ? var.count : 0}"
  name        = "${var.name_prefix}-${format("%03d", count.index)}"
  image_name  = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  flavor_id   = "${var.flavor_id}"
  key_pair    = "${var.keypair_name}"

  network {
    name = "${var.network_name}"
  }

  network {
    uuid = "${var.external_network_uuid}"
  }

  security_groups = ["${var.secgroup_name}"]
  user_data       = "${data.template_file.instance_bootstrap.rendered}"
}

# Allocate floating IPs (optional)
resource "openstack_compute_floatingip_v2" "floating_ip" {
  count = "${var.assign_public_ip && var.use_floating_IPs ? var.count : 0}"
  pool  = "${var.floating_ip_pool}"
}

# Associate floating IPs (if created)
resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
  count       = "${var.assign_public_ip && var.use_floating_IPs ? var.count : 0}"
  floating_ip = "${element(openstack_compute_floatingip_v2.floating_ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
}

# Create extra disk (optional)
resource "openstack_blockstorage_volume_v2" "extra_disk" {
  count = "${var.extra_disk_size > 0 ? var.count : 0}"
  name  = "${var.name_prefix}-extra-${format("%03d", count.index)}"
  size  = "${var.extra_disk_size}"
}

# Attach extra disk (if created) Disk attaches as /dev/
resource "openstack_compute_volume_attach_v2" "attach_extra_disk" {
  count       = "${var.extra_disk_size > 0 ? var.count : 0}"
  # The concat() hack is needed beacause the HIL (the interpolation language) 
  # doesn't lazy evaluate the branches of the if statement yet.
  instance_id = "${var.assign_public_ip && !var.use_floating_IPs ? element(concat(openstack_compute_instance_v2.instance_ext.*.id, list("")), count.index) : element(concat(openstack_compute_instance_v2.instance.*.id, list("")), count.index)}"
  volume_id   = "${element(openstack_blockstorage_volume_v2.extra_disk.*.id, count.index)}"
}

# Module outputs
output "extra_disk_device" {
  value = ["${openstack_compute_volume_attach_v2.attach_extra_disk.*.device}"]
}

output "local_ip_v4" {
  value = ["${openstack_compute_instance_v2.instance.*.network.0.fixed_ip_v4}", "${openstack_compute_instance_v2.instance_ext.*.network.0.fixed_ip_v4}"]
}

output "public_ip" {    
  value = ["${openstack_compute_floatingip_v2.floating_ip.*.address}", "${openstack_compute_instance_v2.instance_ext.*.network.1.fixed_ip_v4}"]
}

output "hostnames" {
  value = ["${openstack_compute_instance_v2.instance.*.name}", "${openstack_compute_instance_v2.instance_ext.*.name}"]
}

output "node_labels" {
  value = "${var.node_labels}"
}
