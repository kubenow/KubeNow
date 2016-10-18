variable name_prefix {}
variable image_name {}
variable flavor_name {}
variable network_name {}
variable kubeadm_token {}
variable disk_size {}
variable zone {}
variable ssh_user {}
variable ssh_key {}


# create bootstrap script file from template
resource "template_file" "master_bootstrap" {
  template = "${file("${path.root}/../bootstrap/master.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
  }
}

resource "google_compute_instance" "master" {
  name="${var.name_prefix}-master"
  machine_type = "${var.flavor_name}"
  zone = "${var.zone}"
  can_ip_forward = false

  disk {
    image = "${var.image_name}"
    size = "${var.disk_size}"
    auto_delete = true
  }

  network_interface {
    network = "${var.network_name}"
    access_config {}
  }

  metadata {
    sshKeys = "${var.ssh_user}:${file(var.ssh_key)} ${var.ssh_user}"
    ssh_user = "${var.ssh_user}"
    user-data = "${template_file.master_bootstrap.rendered}"
  } 
}

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  provisioner "local-exec" {
    command =  "echo \"[master]\" > inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"${google_compute_instance.master.0.name} ansible_ssh_host=${google_compute_instance.master.0.network_interface.0.access_config.0.assigned_nat_ip} ansible_ssh_user=ubuntu\" >> inventory"
  }

}

output "ip_address" {
  value = "${google_compute_instance.master.0.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "ip_address_internal" {
  value = "${google_compute_instance.master.0.network_interface.0.address}"
}


