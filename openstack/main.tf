# Cluster settings
variable cluster_prefix {}
variable KuberNow_image {}
variable keypair_name {}
variable private_network {}
variable kubeadm_token {}

# Master settings
variable master_flavor {}
variable floating_ip_pool {}

# Nodes settings
variable node_count {}
variable node_flavor {}

# Edges settings
variable edge_count {}
variable edge_flavor {}

module "master" {
  source = "./master"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.master_flavor}"
  keypair_name = "${var.keypair_name}"
  network_name = "${var.private_network}"
  floating_ip_pool = "${var.floating_ip_pool}"
  kubeadm_token = "${var.kubeadm_token}"
  node_count = "${var.node_count}"
}

module "node" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.node_flavor}"
  keypair_name = "${var.keypair_name}"
  network_name = "${var.private_network}"
  kubeadm_token = "${var.kubeadm_token}"
  master_ip = "${module.master.ip_address}"
  count = "${var.node_count}"
}

module "edge" {
  source = "./edge"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.edge_flavor}"
  keypair_name = "${var.keypair_name}"
  network_name = "${var.private_network}"
  kubeadm_token = "${var.kubeadm_token}"
  floating_ip_pool = "${var.floating_ip_pool}"
  master_ip = "${module.master.ip_address}"
  count = "${var.edge_count}"
}
