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
resource "template_file" "edge_bootstrap" {
  template = "${file("${path.root}/../bootstrap/node.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip = "${var.master_ip}"
  }
}

resource "aws_instance" "edge" {
  count = "${var.count}"
  ami = "${var.kubenow_image_id}"
  availability_zone = "${var.availability_zone}"
  instance_type = "${var.instance_type}"
  associate_public_ip_address = true
  key_name = "${var.ssh_keypair_name}"
  vpc_security_group_ids = ["${var.security_group_id}"]
  subnet_id = "${var.subnet_id}"
  user_data = "${template_file.edge_bootstrap.rendered}"

  root_block_device {
    delete_on_termination = true
    volume_size = "${var.disk_size}"
  }

  tags {
    Name = "${var.name_prefix}-edge-${format("%02d", count.index)}"
    sshUser = "${var.ssh_user}"
  }
}

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  provisioner "local-exec" {
    command =  "echo \"[edge]\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", aws_instance.edge.*.tags.Name, aws_instance.edge.*.public_ip))}\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"[master:vars]\" >> inventory"
  }

  provisioner "local-exec" {
    # generates aws hostnames (ip-000-111-222-333) from ip-numbers
    command =  "echo 'edge_names=\"${replace(join(" ",formatlist("ip-%s", aws_instance.edge.*.private_ip)),".","-")}\"' >> inventory"
  }
}
