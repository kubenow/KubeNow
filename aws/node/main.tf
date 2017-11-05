# Core settings
variable count {}

variable name_prefix {}
variable instance_type {}
variable image_id {}
variable availability_zone {}

# SSH settings
variable ssh_user {}

variable ssh_keypair_name {}

# Network settings
variable subnet_id {}

variable security_group_ids {
  type = "list"
}

# Disk settings
variable disk_size {}

variable disk_type {
  default = "gp2"
}

variable extra_disk_size {
  default = 0
}

variable extra_disk_type {
  default = "gp2"
}

# Bootstrap settings
variable bootstrap_file {}

#variable kubeadm_token {}

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
    master_ip   = "${var.master_ip}"
    node_labels = "${join(",", var.node_labels)}"
    node_taints = "${join(",", var.node_taints)}"
    ssh_user    = "${var.ssh_user}"
  }
}

resource "aws_instance" "instance" {
  count                       = "${var.count}"
  ami                         = "${var.image_id}"
  availability_zone           = "${var.availability_zone}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = true
  key_name                    = "${var.ssh_keypair_name}"
  vpc_security_group_ids      = ["${var.security_group_ids}"]
  subnet_id                   = "${var.subnet_id}"
  user_data                   = "${data.template_file.instance_bootstrap.rendered}"

  root_block_device {
    delete_on_termination = true
    volume_type           = "${var.disk_type}"
    volume_size           = "${var.disk_size}"
  }

  tags {
    Name    = "${var.name_prefix}-${format("%03d", count.index)}"
    sshUser = "${var.ssh_user}"
  }
}

# Create extra disk (optional)
resource "aws_ebs_volume" "extra_disk" {
  count             = "${var.extra_disk_size > 0 ? var.count : 0}"
  size              = "${var.extra_disk_size}"
  type              = "${var.extra_disk_type}"
  availability_zone = "${var.availability_zone}"

  tags {
    Name = "${var.name_prefix}-extra-${format("%03d", count.index)}"
  }
}

# Attach extra disk (if created)
resource "aws_volume_attachment" "attach_extra_disk" {
  count        = "${var.extra_disk_size > 0 ? var.count : 0}"
  device_name  = "/dev/xvdh"
  volume_id    = "${element(aws_ebs_volume.extra_disk.*.id, count.index)}"
  instance_id  = "${element(aws_instance.instance.*.id, count.index)}"
  force_detach = true
}

# Module outputs
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
  value = ["${split(" ", replace(join(" ",formatlist("ip-%s", aws_instance.instance.*.private_ip)),".","-"))}"]
}

output "node_labels" {
  value = "${var.node_labels}"
}
