# Cluster settings
variable cluster_prefix {}
variable KubeNow_image {}
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
  node_labels = ""
  node_taints = ""
  count = "1"
  disk_size = "${var.master_disk_size}"
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-master"
  image_name = "${var.KubeNow_image}"
  flavor_name = "${var.master_flavor}"
  network_name = "${module.network.network_name}"
  kubeadm_token = "${var.kubeadm_token}"
  zone = "${var.gce_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
  bootstrap_file = "bootstrap/master.sh"
  master_ip = ""
}

module "edge" {
  node_labels = "role=edge"
  node_taints = ""
  count = "${var.edge_count}"
  disk_size = "${var.edge_disk_size}"
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-edge"
  image_name = "${var.KubeNow_image}"
  flavor_name = "${var.edge_flavor}"
  network_name = "${module.network.network_name}"
  kubeadm_token = "${var.kubeadm_token}"
  zone = "${var.gce_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
  bootstrap_file = "bootstrap/node.sh"
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}

module "node" {
  node_labels = "role=node"
  node_taints = ""
  count = "${var.node_count}"
  disk_size = "${var.node_disk_size}"
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-node"
  image_name = "${var.KubeNow_image}"
  flavor_name = "${var.node_flavor}"
  network_name = "${module.network.network_name}"
  kubeadm_token = "${var.kubeadm_token}"
  zone = "${var.gce_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
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
