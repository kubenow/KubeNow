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
  tags = "master"
  count = "1"
  extra_disk_size = "0"
  
  source = "./node"
  flavor_name = "${var.master_flavor}"
  assign_floating_ip = "true"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  flavor_id = "${var.master_flavor_id}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  floating_ip_pool = "${var.floating_ip_pool}"
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file_name = "master.sh"
  master_ip = ""
}

module "edge" {
  tags = "edge"
  extra_disk_size = "0"
  
  source = "./node"
  count = "${var.edge_count}"
  flavor_name = "${var.edge_flavor}"
  flavor_id = "${var.edge_flavor_id}"
  assign_floating_ip = "true"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file_name = "node.sh"
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}

module "node" {
  tags = "node"
  extra_disk_size = "0"
  
  source = "./node"
  count = "${var.node_count}"
  flavor_name = "${var.node_flavor}"
  flavor_id = "${var.node_flavor_id}"
  assign_floating_ip = "false"
  name_prefix = "${var.cluster_prefix}"
  image_name = "${var.KuberNow_image}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file_name = "node.sh"
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  provisioner "local-exec" {
    command =  "echo \"[Master]\" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", module.master.hostnames, module.master.floating_ip))}\" >> inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"[master:vars]\" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo 'edge_names=\"${lower(join(" ",formatlist("%s", module.edge.hostnames)))}\"' >> inventory"
  }
}
