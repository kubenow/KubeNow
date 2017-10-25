# Core settings
variable count {}
variable name_prefix {}
variable vcpu {}
variable memory {}
variable volume_pool {}

# SSH settings
variable ssh_key {}
variable ssh_user {}

# Network settings
variable network_id {}

# Disk settings
variable template_vol_id {}
variable extra_disk_size { default = 0 }

# Bootstrap settings
variable bootstrap_file {}
variable kubeadm_token {}
variable node_labels { type = "list" }
variable node_taints { type = "list" }
variable master_ip { default = "" }

# Bootstrap
data "template_file" "instance_bootstrap" {
  count    = "${var.count > 0 ? 1 : 0}"
  template = "${file("${path.root}/../${ var.bootstrap_file }")}"

  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip     = "${var.master_ip}"
    node_labels   = "${join(",", var.node_labels)}"
    node_taints   = "${join(",", var.node_taints)}"
    ssh_user      = "${var.ssh_user}"
  }
}

# Create cloud-init iso image
resource "libvirt_cloudinit" "clouddrive" {
  count              = "${var.count > 0 ? 1 : 0}"
  name               = "${var.name_prefix}-cloud-init.iso"
  ssh_authorized_key = "${file(var.ssh_key)}"
  pool               = "${var.volume_pool}"

  # create a cloud config yaml
  user_data = <<EOF
write_files:
  - path: /tmp/bootstrap.sh
    encoding: base64
    content: "${base64encode(data.template_file.instance_bootstrap.rendered)}"
    permissions: '755'
runcmd:
  - /tmp/bootstrap.sh
EOF
}

# Create root volume
resource "libvirt_volume" "root_volume" {
  count          = "${var.count}"
  name           = "${var.name_prefix}-vol-${format("%03d", count.index)}"
  base_volume_id = "${var.template_vol_id}"
  pool           = "${var.volume_pool}"
}

# Create extra volume
resource "libvirt_volume" "extra_disk" {
  count = "${var.count}"
  name  = "${var.name_prefix}-extra-vol-${format("%03d", count.index)}"
  size  = "${var.extra_disk_size * 1024 * 1024 * 1024}"
  pool  = "${var.volume_pool}"
}

# Create instances
resource "libvirt_domain" "instance" {
  count       = "${var.count}"
  name        = "${var.name_prefix}-${format("%03d", count.index)}"
  vcpu        = "${var.vcpu}"
  memory      = "${var.memory}"

  cloudinit   = "${libvirt_cloudinit.clouddrive.id}"

  disk = [
    {
      volume_id = "${element(libvirt_volume.root_volume.*.id, count.index)}"
    },
    {
      volume_id = "${element(libvirt_volume.extra_disk.*.id, count.index)}"
    }
  ]

  network_interface {
    hostname       = "${var.name_prefix}-${format("%03d", count.index)}"
    network_id     = "${var.network_id}"
    #addresses     = ["10.10.10.1"]
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  ## TODO this is always mounted
  #filesystem {
  #  source   = "/data"
  #  target   = "data"
  #  readonly = false
  #}
}

# Module outputs
output "extra_disk_device" {
  value = ["/dev/vdb"]
}

output "local_ip_v4" {
  value = ["${libvirt_domain.instance.*.network_interface.0.addresses.0}"]
}

output "public_ip" {
  # TODO same as internal until creating second network
  value = ["${libvirt_domain.instance.*.network_interface.0.addresses.0}"]
}

output "hostnames" {
  value = ["${libvirt_domain.instance.*.name}"]
}

output "node_labels" {
  value = "${var.node_labels}"
}
