# Core settings
variable count {}
variable name_prefix {}
variable flavor_name {}
variable image_name {}
variable zone {}

# SSH settings
variable ssh_user {}
variable ssh_key {}

# Network settings
variable network_name {}

# Disk settings
variable disk_size {}
variable extra_disk_size { default=0 }
variable extra_disk_type { default="pd-ssd" }
variable extra_disk_name { default="extra-disk" }

# Bootstrap settings
variable bootstrap_file {}
variable kubeadm_token {}
variable node_labels {}
variable node_taints {}
variable master_ip { default="" }

# Bootstrap
data "template_file" "instance_bootstrap" {
  template = "${file("${path.root}/../${var.bootstrap_file }")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip     = "${var.master_ip}"
    node_labels   = "${var.node_labels}"
    node_taints   = "${var.node_taints}"
  }
}

# Create extra disk (always due to limitation with Terraform GCE modules)
resource "google_compute_disk" "extra_standard_disk" {
  count = "${var.count}"
  name = "${var.name_prefix}-extra-${format("%03d", count.index)}"
  type = "${var.extra_disk_type}"
  zone = "${var.zone}"
  size = "${var.extra_disk_size <= 0 ? 1 : var.extra_disk_size}"
}

# Instance with extra disk
resource "google_compute_instance" "instance" {
  count = "${var.count}"
  name = "${var.name_prefix}-${format("%03d", count.index)}"
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
    access_config {} # without this nodes don't get external ip and cannot reach the Internet
  }

  metadata {
    sshKeys = "${var.ssh_user}:${file(var.ssh_key)} ${var.ssh_user}"
    ssh_user = "${var.ssh_user}"
    user-data = "${data.template_file.instance_bootstrap.rendered}"
  }

  # Extra disk
  disk {
    disk = "${element(google_compute_disk.extra_standard_disk.*.name, count.index)}"
    device_name = "${var.extra_disk_name}"
    auto_delete = true
  }
}

# Module outputs
output "extra_disk_device" {
  value = ["${list("google-${var.extra_disk_name}")}"]
}
output "local_ip_v4" {
  value = ["${google_compute_instance.instance.*.network_interface.0.address}"]
}
output "public_ip" {
  value = ["${google_compute_instance.instance.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
output "hostnames" {
  value = ["${google_compute_instance.instance.*.name}"]
}
output "node_labels" {
  value = "${var.node_labels}"
}
