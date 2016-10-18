variable name_prefix {}
variable image_name {}
variable flavor_name {}
#variable keypair_name {}
variable network_name {}
variable kubeadm_token {}
variable master_ip {}
variable count {}
variable disk_size {}
variable zone {}
variable ssh_user {}
variable ssh_key {}


# create bootstrap script file from template
resource "template_file" "edge_bootstrap" {
  template = "${file("${path.root}/../bootstrap/node.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
    master_ip = "${var.master_ip}"
  }
}

resource "google_compute_instance" "edge" {
  name="${var.name_prefix}-edge-${format("%03d", count.index)}"
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
    user-data = "${template_file.edge_bootstrap.rendered}"
  } 

  count = "${var.count}"

}

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  provisioner "local-exec" {
    command =  "echo \"[edge]\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", google_compute_instance.edge.*.name, google_compute_instance.edge.*.network_interface.0.access_config.0.assigned_nat_ip))}\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"[master:vars]\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo 'edge_names=\"${lower(join(" ",formatlist("%s", google_compute_instance.edge.*.name)))}\"' >> inventory"
  }

}
