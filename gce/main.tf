# Cluster settings
variable cluster_prefix {}
variable KuberNow_image {}
variable kubeadm_token {}
variable ssh_user { default = "ubuntu" }
variable ssh_key {}

# Google credentials
variable gce_project {}
variable gce_zone {}
variable gce_credentials_file {}

# Master settings
variable master_flavor {}
variable master_disk_size {}

# Nodes settings
variable node_count {}
variable node_flavor {}
variable node_disk_size {}

# Edges settings
variable edge_count {}
variable edge_flavor {}
variable edge_disk_size {}

# Provider
provider "google" {
  credentials = "${file("${var.gce_credentials_file}")}"
  project = "${var.gce_project}"
  region = "${var.gce_zone}"
}

# Here would be nice with condition: if private_network == "" then...
module "network" {
   source = "./network"
   network_name = "${var.cluster_prefix}"
}

module "master" {
  source = "./master"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.master_flavor}"
  network_name = "${module.network.network_name}"
  kubeadm_token = "${var.kubeadm_token}"
  zone = "${var.gce_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
  disk_size = "${var.master_disk_size}"
}

module "node" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.node_flavor}"
  network_name = "${module.network.network_name}"
  kubeadm_token = "${var.kubeadm_token}"
  master_ip = "${module.master.ip_address_internal}"
  count = "${var.node_count}"
  zone = "${var.gce_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
  disk_size = "${var.node_disk_size}"
}

module "edge" {
  source = "./edge"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.edge_flavor}"
  network_name = "${module.network.network_name}"
  kubeadm_token = "${var.kubeadm_token}"
  master_ip = "${module.master.ip_address_internal}"
  count = "${var.edge_count}"
  zone = "${var.gce_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
  disk_size = "${var.edge_disk_size}"
}
