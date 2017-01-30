# Cluster settings
variable cluster_prefix {}
variable KuberNow_image {}
variable ssh_key {}
variable external_network_uuid {}
variable dns_nameservers { default="8.8.8.8,8.8.4.4" }
variable floating_ip_pool {}
variable kubeadm_token {}

# Master settings
variable master_flavor {}
variable master_flavor_id { default = ""}

# Nodes settings
variable node_count {}
variable node_flavor {}
variable node_flavor_id { default = ""}

# Edges settings
variable edge_count {}
variable edge_flavor {}
variable edge_flavor_id { default = ""}

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
  dns_nameservers = "${var.dns_nameservers}"
}

module "master" {
  source = "./master"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.master_flavor}"
  flavor_id = "${var.master_flavor_id}"
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
  flavor_id = "${var.node_flavor_id}"
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
  flavor_id = "${var.edge_flavor_id}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  floating_ip_pool = "${var.floating_ip_pool}"
  master_ip = "${module.master.ip_address}"
  count = "${var.edge_count}"
}
