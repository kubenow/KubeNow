variable name_prefix {}
variable image_name {}
variable flavor_name {}
variable network_name {}
variable kubeadm_token {}
variable count {}
variable disk_size {}
variable zone {}
variable ssh_user {}
variable ssh_key {}

# Cloudflare settings
variable cloudflare_email { default="" }
variable cloudflare_token { default="" }
variable cloudflare_domain { default="" }

variable master_ip { default="" }
variable extra_disk_size { default=0 }
variable extra_disk_type { default="pd-ssd" } # local-ssd, pd-ssd, pd-standard
variable extra_disk_name { default="extra_disk" }
variable bootstrap_file {}
variable node_labels {}
variable node_taints {}


# Bootstrap
data "template_file" "instance_bootstrap" {
  template = "${file("${path.root}/../${ var.bootstrap_file }")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip     = "${var.master_ip}"
    node_labels   = "${var.node_labels}"
    node_taints   = "${var.node_taints}"
  }
}

#
# After lots of testing, I did not manage to do optional extra disk on google
# solution is to create a 1gb disk on nodes that are supposed not to have one
# and it will not get mounted anyway
#
# create disk (always due to limitation with google api)
resource "google_compute_disk" "extra_standard_disk" {
  count = "${var.count}"
  name = "${var.name_prefix}-extra-disk-${format("%03d", count.index)}"
  type = "${var.extra_disk_type}"
  zone = "${var.zone}"
  size = "${ var.extra_disk_size <= 0 ? 1 : var.extra_disk_size}" 
}

# with extra disk 
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
    access_config {} # without this nodes don't get external ip and can also not reach internet outbond either
  }

  metadata {
    sshKeys = "${var.ssh_user}:${file(var.ssh_key)} ${var.ssh_user}"
    ssh_user = "${var.ssh_user}"
    user-data = "${data.template_file.instance_bootstrap.rendered}"
  } 
  
  # extra disk
  disk {
    disk = "${element(google_compute_disk.extra_standard_disk.*.name, count.index)}"
    device_name = "${var.extra_disk_name}"
    auto_delete = true
  }
  
  ## extra disk ssd
  #disk {
  #  type = "local-ssd"
  #  scratch = true
  #  device_name = "${var.extra_disk_name}"
  ## size = "${var.extra_disk_size}"  
  #}
}

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


