# Cluster settings
variable cluster_prefix {}
variable KuberNow_image {}
variable ssh_key {}
variable external_network_uuid {}
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

# Storage settings
variable storage_count {}
variable storage_flavor {}

# Upload ssh-key to be used for access to the nodes
module "keypair" {
  source = "./keypair"
  public_key = "${var.ssh_key}"
  name_prefix = "${var.cluster_prefix}"
}

# Create a network (and security group) with an externally attached router
module "network" {
  source = "./network"
  external_net_uuid = "${var.external_network_uuid}"
  name_prefix = "${var.cluster_prefix}"
}

module "master" {
  source = "./master"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.master_flavor}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  floating_ip_pool = "${var.floating_ip_pool}"
  kubeadm_token = "${var.kubeadm_token}"
}

module "node" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.node_flavor}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  master_ip = "${module.master.ip_address}"
  count = "${var.node_count}"
}

module "edge" {
  source = "./edge"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.edge_flavor}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  floating_ip_pool = "${var.floating_ip_pool}"
  master_ip = "${module.master.ip_address}"
  count = "${var.edge_count}"
}

module "storage" {
  source = "./storage"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.storage_flavor}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  master_ip = "${module.master.ip_address}"
  count = "${var.storage_count}"
}
