variable cluster_prefix {}
variable KuberNow_image {}
variable keypair_name {}

variable private_network {}
variable floating_ip_pool {}

variable master_count {}
variable master_flavor {}
variable master_volume_size {}

variable node_count {}
variable node_flavor {}
variable node_volume_size {}

variable etcd_count {}
variable etcd_flavor {}
variable etcd_volume_size {}

module "master" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  entity_name = "master"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.master_flavor}"
  keypair_name = "${var.keypair_name}"
  network_name = "${var.private_network}"
  floating_ip_pool = "${var.floating_ip_pool}"
  volume_size = "${var.master_volume_size}"
  count = "${var.master_count}"
}

module "node" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  entity_name = "node"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.node_flavor}"
  keypair_name = "${var.keypair_name}"
  network_name = "${var.private_network}"
  floating_ip_pool = "${var.floating_ip_pool}"
  volume_size = "${var.node_volume_size}"
  count = "${var.node_count}"
}

module "etcd" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  entity_name = "etcd"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.etcd_flavor}"
  keypair_name = "${var.keypair_name}"
  network_name = "${var.private_network}"
  floating_ip_pool = "${var.floating_ip_pool}"
  volume_size = "${var.etcd_volume_size}"
  count = "${var.etcd_count}"
}

module "inventory_gen" {
  source = "./inventory"
  master_inventory = "${module.master.inventory}"
  node_inventory = "${module.node.inventory}"
  etcd_inventory = "${module.etcd.inventory}"
}
