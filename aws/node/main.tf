variable name_prefix {}
variable image_id {}
variable instance_type {}
variable kubeadm_token {}
variable disk_size {}
variable disk_type { default = "gp2" }
variable availability_zone {}
variable ssh_user {}
variable ssh_keypair_name {}
variable subnet_id {}
variable count {}
variable security_group_id {}
variable master_ip { default="" }
variable extra_disk_size { default=0 }
variable extra_disk_type { default = "gp2" }
variable bootstrap_file {}
variable node_labels {}
variable node_taints {}


# Bootstrap
data "template_file" "instance_bootstrap" {
  template = "${file("${path.root}/../${ var.bootstrap_file }")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip = "${var.master_ip}"
    node_labels = "${var.node_labels}"
    node_taints = "${var.node_taints}"
  }
}

resource "aws_instance" "instance" {
  count = "${var.count}"
  ami = "${var.image_id}"
  availability_zone = "${var.availability_zone}"
  instance_type = "${var.instance_type}"
  associate_public_ip_address = true 
  key_name = "${var.ssh_keypair_name}" 
  vpc_security_group_ids = ["${var.security_group_id}"]
  subnet_id = "${var.subnet_id}"
  user_data = "${data.template_file.instance_bootstrap.rendered}"

  root_block_device {
    delete_on_termination = true
    volume_type = "${var.disk_type}"
    volume_size = "${var.disk_size}"
  }

  tags {
    Name = "${var.name_prefix}-node-${format("%03d", count.index)}"
    sshUser = "${var.ssh_user}"
  }
}

# Create extra disk (optional)
resource "aws_ebs_volume" "extra_disk" {
  count = "${var.extra_disk_size > 0 ? var.count : 0}"
  size  = "${var.extra_disk_size}"
  type  = "${var.extra_disk_type}"
  availability_zone = "${var.availability_zone}"
  tags {
    Name = "${var.name_prefix}-extra-disk-${format("%03d", count.index)}"
  }
}

# Attach extra disk (if created) Disk attaches as /dev/
resource "aws_volume_attachment" "attach_extra_disk" {
  count       = "${var.extra_disk_size > 0 ? var.count : 0}"
  device_name = "/dev/xvdh"
  volume_id   = "${element(aws_ebs_volume.extra_disk.*.id, count.index)}"
  instance_id = "${element(aws_instance.instance.*.id, count.index)}"
}



output "extra_disk_device" {
  value = ["${aws_volume_attachment.attach_extra_disk.*.device_name}"]
}

output "local_ip_v4" {
  value = ["${aws_instance.instance.*.private_ip}"]
}

output "public_ip" {
  value = ["${aws_instance.instance.*.public_ip}"]
}

output "hostnames" {
  value = ["${aws_instance.instance.*.tags.Name}"]
}

output "node_labels" {
  value = "${var.node_labels}"
}
