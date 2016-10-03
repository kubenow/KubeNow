variable cluster_prefix {}
variable KuberNow_image {}
variable keypair_name {}
variable private_network {}
variable floating_ip_pool {}
variable master_flavor {}
variable worker_count {}
variable worker_flavor {}
variable kubeadm_tocken {}

module "master" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  entity_name = "master"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.master_flavor}"
  keypair_name = "${var.keypair_name}"
  network_name = "${var.private_network}"
  floating_ip_pool = "${var.floating_ip_pool}"
  count = "1"
}

module "worker" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  entity_name = "worker"
  image_name = "${var.KuberNow_image}"
  flavor_name = "${var.worker_flavor}"
  keypair_name = "${var.keypair_name}"
  network_name = "${var.private_network}"
  floating_ip_pool = "${var.floating_ip_pool}"
  count = "${var.worker_count}"
}
