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
  template = "${file("${path.root}/../${var.bootstrap_file }")}"

  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip     = "${var.master_ip}"
    node_labels   = "${join(",", var.node_labels)}"
    node_taints   = "${join(",", var.node_taints)}"
    ssh_user      = "${var.ssh_user}"
  }
}

# Instance without extra disk
resource "google_compute_instance" "instance" {
  count          = "${var.count}"
  name           = "${var.name_prefix}-${format("%03d", count.index)}"
  machine_type   = "${var.flavor_name}"
  zone           = "${var.zone}"
  can_ip_forward = false

  boot_disk {
    initialize_params {
      image = "${var.image_name}"
      size  = "${var.disk_size}"
    }

    auto_delete = true
  }

  network_interface {
    network       = "${var.network_name}"
    access_config = {}                    # without this nodes don't get external ip and cannot reach the Internet
  }

  metadata {
    sshKeys   = "${var.ssh_user}:${file(var.ssh_key)} ${var.ssh_user}"
    ssh_user  = "${var.ssh_user}"
    user-data = "${data.template_file.instance_bootstrap.rendered}"
  }
}

# Module outputs
output "extra_disk_device" {
  value = ["${list("none")}"]
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
