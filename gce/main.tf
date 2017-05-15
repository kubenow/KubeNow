# Cluster settings
variable cluster_prefix {}
variable kubenow_image {}
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
variable use_master_as_edge { default="true" }

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

# Network (here would be nice with condition)
module "network" {
   source = "./network"
   network_name = "${var.cluster_prefix}"
}

module "master" {
  # Core settings
  source = "./node"
  count = "1"
  name_prefix = "${var.cluster_prefix}-master"
  flavor_name = "${var.master_flavor}"
  image_name = "${var.kubenow_image}"
  zone = "${var.gce_zone}"
  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
  # Network settings
  network_name = "${module.network.network_name}"
  # Disk settings
  disk_size = "${var.master_disk_size}"
  # Bootstrap settings
  bootstrap_file = "bootstrap/master.sh"
  kubeadm_token = "${var.kubeadm_token}"
  node_labels = "${split(",", var.use_master_as_edge == "true" ? "role=edge" : "")}"
  node_taints = [""]
  master_ip = ""
}

module "node" {
  # Core settings
  source = "./node"
  count = "${var.node_count}"
  name_prefix = "${var.cluster_prefix}-node"
  flavor_name = "${var.node_flavor}"
  image_name = "${var.kubenow_image}"
  zone = "${var.gce_zone}"
  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
  # Network settings
  network_name = "${module.network.network_name}"
  # Disk settings
  disk_size = "${var.node_disk_size}"
  # Bootstrap settings
  bootstrap_file = "bootstrap/node.sh"
  kubeadm_token = "${var.kubeadm_token}"
  node_labels = ["role=node"]
  node_taints = [""]
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}

module "edge" {
  # Core settings
  source = "./node"
  count = "${var.edge_count}"
  name_prefix = "${var.cluster_prefix}-edge"
  flavor_name = "${var.edge_flavor}"
  image_name = "${var.kubenow_image}"
  zone = "${var.gce_zone}"
  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key = "${var.ssh_key}"
  # Network settings
  network_name = "${module.network.network_name}"
  # Disk settings
  disk_size = "${var.edge_disk_size}"
  # Bootstrap settings
  bootstrap_file = "bootstrap/node.sh"
  kubeadm_token = "${var.kubeadm_token}"
  node_labels = ["role=edge"]
  node_taints = [""]
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}

# Generate Ansible inventory (identical for each cloud provider)
resource "null_resource" "generate-inventory" {

  # Changes to any node IP trigger inventory rewrite
  triggers {
    master_ips = "${join(",", module.master.local_ip_v4)}"
    node_ips = "${join(",", module.node.local_ip_v4)}"
    edge_ips = "${join(",", module.edge.local_ip_v4)}"
  }

  # Write master
  provisioner "local-exec" {
    command =  "echo \"[master]\" > inventory"
  }
  # output the lists formated
  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", module.master.hostnames, module.master.public_ip))}\" >> inventory"
  }

  # Write edges
  provisioner "local-exec" {
    command =  "echo \"[edge]\" >> inventory"
  }
  # output the lists formated
  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", concat(module.master.hostnames, module.edge.hostnames), concat(module.master.public_ip, module.edge.public_ip)))}\" >> inventory"
  }

  # Write other variables
  provisioner "local-exec" {
    command =  "echo \"[master:vars]\" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo \"nodes_count=${1 + var.edge_count + var.node_count} \" >> inventory"
  }

}
