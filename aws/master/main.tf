variable name_prefix {}
variable kubenow_image_id {}
variable instance_type {}
variable kubeadm_token {}
variable disk_size {}
variable availability_zone {}
variable ssh_user {}
variable ssh_keypair_name {}
variable subnet_id {}
variable security_group_id {}


# create bootstrap script file from template
resource "template_file" "master_bootstrap" {
  template = "${file("${path.root}/../bootstrap/master.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
  }
}

resource "aws_instance" "master" {
  ami = "${var.kubenow_image_id}"
  availability_zone = "${var.availability_zone}"
  instance_type = "${var.instance_type}"
  associate_public_ip_address = true 
  key_name = "${var.ssh_keypair_name}"  
  vpc_security_group_ids = ["${var.security_group_id}"]
  subnet_id = "${var.subnet_id}"
  user_data = "${template_file.master_bootstrap.rendered}"
  
  root_block_device {
    delete_on_termination = true
    volume_size = "${var.disk_size}"
  }

  tags {
    Name = "${var.name_prefix}-master"
    sshUser = "${var.ssh_user}"
  }
}

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  provisioner "local-exec" {
    command =  "echo \"[master]\" > inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"${aws_instance.master.0.tags.Name} ansible_ssh_host=${aws_instance.master.0.public_ip} ansible_ssh_user=ubuntu\" >> inventory"
  }
  
}

output "ip_address" {
  value = "${aws_instance.master.0.public_ip}"
}

output "ip_address_internal" {
  value = "${aws_instance.master.0.private_ip}"
}





