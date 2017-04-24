# Cluster settings
variable cluster_prefix {}
variable KubeNow_image {}
variable ssh_key {}
variable external_network_uuid {}
variable dns_nameservers { default="8.8.8.8,8.8.4.4" }
variable floating_ip_pool {}
variable kubeadm_token {}

# Master settings
variable master_count { default = 1 }
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
  node_labels = ""
  node_taints = ""
  count = "${var.master_count}"
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-master"
  flavor_name = "${var.master_flavor}"
  assign_floating_ip = "true"
  floating_ip_pool = "${var.floating_ip_pool}"
  image_name = "${var.KubeNow_image}"
  flavor_id = "${var.master_flavor_id}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file = "bootstrap/master.sh"
  master_ip = ""
}

module "edge" {
  node_labels = "role=edge"
  node_taints = ""
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-edge"
  count = "${var.edge_count}"
  flavor_name = "${var.edge_flavor}"
  flavor_id = "${var.edge_flavor_id}"
  assign_floating_ip = "true"
  floating_ip_pool = "${var.floating_ip_pool}"
  image_name = "${var.KubeNow_image}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file = "bootstrap/node.sh"
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}

module "node" {
  node_labels = "role=node"
  node_taints = ""
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-node"
  count = "${var.node_count}"
  flavor_name = "${var.node_flavor}"
  flavor_id = "${var.node_flavor_id}"
  assign_floating_ip = "false"
  floating_ip_pool = ""
  image_name = "${var.KubeNow_image}"
  keypair_name = "${module.keypair.keypair_name}"
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file = "bootstrap/node.sh"
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}


#
# The code below should be identical for all cloud providers
#

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  # Changes to any node ip rewrites inventory
  triggers {
    master_ips = "${join(",", module.master.local_ip_v4)}"
    node_ips = "${join(",", module.node.local_ip_v4)}"
    edge_ips = "${join(",", module.edge.local_ip_v4)}"
  }

  provisioner "local-exec" {
    command =  "echo \"[master]\" > inventory"
  }
  # output the lists formated
  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", module.master.hostnames, module.master.public_ip))}\" >> inventory"
  }
  
  provisioner "local-exec" {
    command =  "echo \"[edge]\" >> inventory"
  }
  # output the lists formated
  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", module.edge.hostnames, module.edge.public_ip))}\" >> inventory"
  }
  
  # Output some vars
  provisioner "local-exec" {
    command =  "echo \"[master:vars]\" >> inventory"
  }
  
  provisioner "local-exec" {
    command =  "echo \"nodes_count=${1 + var.edge_count + var.node_count} \" >> inventory"
  }
}
