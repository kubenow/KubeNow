variable name_prefix {}
variable kubenow_image_id {}
variable instance_type {}
variable kubeadm_token {}
variable disk_size {}
variable availability_zone {}
variable ssh_user {}
variable ssh_keypair_name {}
variable master_ip {}
variable subnet_id {}
variable count {}
variable security_group_id {}


# create bootstrap script file from template
resource "template_file" "node_bootstrap" {
  template = "${file("${path.root}/../bootstrap/node.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip = "${var.master_ip}"
  }
}

resource "aws_instance" "node" {
  count = "${var.count}"
  ami = "${var.kubenow_image_id}"
  availability_zone = "${var.availability_zone}"
  instance_type = "${var.instance_type}"
  associate_public_ip_address = true 
  key_name = "${var.ssh_keypair_name}" 
  vpc_security_group_ids = ["${var.security_group_id}"]
  subnet_id = "${var.subnet_id}"
  user_data = "${template_file.node_bootstrap.rendered}"

  root_block_device {
    delete_on_termination = true
    volume_size = "${var.disk_size}"
  }

  tags {
    Name = "${var.name_prefix}-node-${format("%03d", count.index)}"
    sshUser = "${var.ssh_user}"
  }
}
