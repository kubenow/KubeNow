# Cluster settings
variable cluster_prefix {}
variable kubenow_image {}
variable ssh_key {}
variable external_network_uuid {}
variable dns_nameservers { default="8.8.8.8,8.8.4.4" }
variable floating_ip_pool {}
variable kubeadm_token {}

# Master settings
variable master_count { default = 1 }
variable master_flavor {}
variable master_flavor_id { default = ""}
variable master_is_edge { default="true" }

# Nodes settings
variable node_count {}
variable node_flavor {}
variable node_flavor_id { default = ""}

# Edges settings
variable edge_count {}
variable edge_flavor {}
variable edge_flavor_id { default = ""}

# Upload SSH key to OpenStack
module "keypair" {
  source = "./keypair"
  public_key = "${var.ssh_key}"
  name_prefix = "${var.cluster_prefix}"
}

# Network (here would be nice with condition)
module "network" {
  source = "./network"
  external_net_uuid = "${var.external_network_uuid}"
  name_prefix = "${var.cluster_prefix}"
  dns_nameservers = "${var.dns_nameservers}"
}

module "master" {
  # Core settings
  source = "./node"
  count = "${var.master_count}"
  name_prefix = "${var.cluster_prefix}-master"
  flavor_name = "${var.master_flavor}"
  flavor_id = "${var.master_flavor_id}"
  image_name = "${var.kubenow_image}"
  # SSH settings
  keypair_name = "${module.keypair.keypair_name}"
  # Network settings
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  assign_floating_ip = "true"
  floating_ip_pool = "${var.floating_ip_pool}"
  # Disk settings
  extra_disk_size = "0"
  # Bootstrap settings
  bootstrap_file = "bootstrap/master.sh"
  kubeadm_token = "${var.kubeadm_token}"
  node_labels = "${split(",", var.master_is_edge == "true" ? "role=edge" : "")}"
  node_taints = [""]
  master_ip = ""
}

module "node" {
  # Core settings
  source = "./node"
  count = "${var.node_count}"
  name_prefix = "${var.cluster_prefix}-node"
  flavor_name = "${var.node_flavor}"
  flavor_id = "${var.node_flavor_id}"
  image_name = "${var.kubenow_image}"
  # SSH settings
  keypair_name = "${module.keypair.keypair_name}"
  # Network settings
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  assign_floating_ip = "false"
  floating_ip_pool = ""
  # Disk settings
  extra_disk_size = "0"
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
  flavor_id = "${var.edge_flavor_id}"
  image_name = "${var.kubenow_image}"
  # SSH settings
  keypair_name = "${module.keypair.keypair_name}"
  # Network settings
  network_name = "${module.network.network_name}"
  secgroup_name = "${module.network.secgroup_name}"
  assign_floating_ip = "true"
  floating_ip_pool = "${var.floating_ip_pool}"
   # Disk settings
  extra_disk_size = "0"
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
