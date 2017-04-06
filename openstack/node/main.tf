variable name_prefix {}
variable image_name {}
variable flavor_name {}
variable flavor_id {}
variable keypair_name {}
variable network_name {}
variable kubeadm_token {}
variable count {}
variable secgroup_name {}
variable master_ip { default="" }

variable bootstrap_file_name { default="node.sh" }
variable extra_disk_size { default=20 }
variable tags { default="node" }
variable floating_ip_pool { default="ext-net" }
variable assign_floating_ip { default=false }

# Bootstrap
data "template_file" "instance_bootstrap" {

  template = "${file("${path.root}/../bootstrap/${ var.bootstrap_file_name }")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip = "${var.master_ip}"
  }
}

# Create instances
resource "openstack_compute_instance_v2" "instance" {
  count = "${var.count}"
  name="${var.name_prefix}-${var.tags}-${format("%03d", count.index)}"
  image_name = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  flavor_id = "${var.flavor_id}"
  
  key_pair = "${var.keypair_name}"
  network {
    name = "${var.network_name}"
  }
  security_groups = ["${var.secgroup_name}"]
  user_data = "${data.template_file.instance_bootstrap.rendered}"
}

# Allocate floating IPs (optional)
resource "openstack_compute_floatingip_v2" "floating_ip" {
  count= "${var.assign_floating_ip ? var.count : 0}"
  pool = "${var.floating_ip_pool}"
}

# Associate floating IPs (if created)
resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
  count= "${var.assign_floating_ip ? var.count : 0}"
  floating_ip = "${element(openstack_compute_floatingip_v2.floating_ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
}

# Create extra disk (optional)
resource "openstack_blockstorage_volume_v2" "extra_disk" {
  count       = "${var.extra_disk_size > 0 ? var.count : 0}"
  name        = "${var.name_prefix}-extra-disk-${format("%03d", count.index)}"
  size        = "${var.extra_disk_size}"
}

# Attach extra disk (if created) Disk attaches as /dev/
resource "openstack_compute_volume_attach_v2" "attach_extra_disk" {
  count       = "${var.extra_disk_size > 0 ? var.count : 0}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
  volume_id   = "${element(openstack_blockstorage_volume_v2.extra_disk.*.id, count.index)}"
}

# TODO Export openstack_compute_volume_attach_v2.device (to be handed to heketi)

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  provisioner "local-exec" {
    command =  "echo \"[${ var.tags }]\" >> inventory"
  }
  
  # Echo access ip:s
  provisioner "local-exec" {
    command =  "echo \"${var.assign_floating_ip ? join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", openstack_compute_instance_v2.instance.*.name, openstack_compute_floatingip_v2.floating_ip.*.address)) : "" }\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"[master:vars]\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo '${ var.tags }_names=\"${lower(join(" ",formatlist("%s", openstack_compute_instance_v2.instance.*.name)))}\"' >> inventory"
  }
}

# internal network ip-address
output "ip_addresses" {
  value = ["${openstack_compute_instance_v2.instance.*.network.0.fixed_ip_v4}"]
}
