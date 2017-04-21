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

# Cloudflare settings
variable cloudflare_email { default="nothing" }
variable cloudflare_token { default="nothing" }
variable cloudflare_domain { default="" }

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

# Gluster settings
variable glusternode_count {default = 0}
variable glusternode_flavor {}
variable glusternode_disk_size {}

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
  node_labels = "role=master,role=edge"
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

module "glusternode" {
  node_labels = "storagenode=glusterfs"
  node_taints = "dedicated=fileserver:NoSchedule"
  count = "${var.glusternode_count}"
  disk_size = "${var.glusternode_disk_size}"
  extra_disk_size = "200"

  source = "./node"
  name_prefix = "${var.cluster_prefix}-glusternode"
  image_name = "${var.KubeNow_image}"
  flavor_name = "${var.glusternode_flavor}"
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

# set cloudflare record (optional): only if var.cloudflare_domain != "" 
# currentlty this is always including master as edge - but instead should probably be called twice
# once for master (if role=edge) and once for edges
module "cloudflare" {
  # count values can not be dynamically computed, that's why using
  # var.edge_count and not length(iplist)
  record_count = "${var.cloudflare_domain == "" ? 0 : var.master_is_edge ? var.edge_count + var.master_count : var.edge_count}"
  source = "./cloudflare"
  cloudflare_email = "${var.cloudflare_email}"
  cloudflare_token = "${var.cloudflare_token}"
  cloudflare_domain = "${var.cloudflare_domain}"
  record_text = "*.${var.cluster_prefix}"
  # concat lists (record_count is limiting master_ip:s from being added to cloudflare if they are not supposed to)
  # terraform interpolation is limited and can not return list in conditionals
  iplist = "${concat(module.edge.public_ip, module.master.public_ip)}"
}

# Generate ansible inventory
resource "null_resource" "generate-inventory" {

  # Changes to master_ip or glusternodes of the cluster rewrites inventory
  triggers {
    master_ips = "${join(",", module.master.local_ip_v4)}"
    glusternode_ips = "${join(",", module.glusternode.local_ip_v4)}"
  }

  provisioner "local-exec" {
    command =  "echo \"[master]\" > inventory"
  }
  # output the lists formated
  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", module.master.hostnames, module.master.public_ip))}\" >> inventory"
  }
  
  # Output some vars
  provisioner "local-exec" {
    command =  "echo \"[master:vars]\" >> inventory"
  }
  # Add an extra empty ("") element on list so it is never empty (i.e. if there are no glusternodes)
  provisioner "local-exec" {
    command =  "echo \"extra_disk_device=${element(concat(module.glusternode.extra_disk_device, list("")),0)}\" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo \"domain=${ format("%s.%s", var.cluster_prefix, var.cloudflare_domain) }\" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo \"nodes_count=${1 + var.edge_count + var.node_count + var.glusternode_count} \" >> inventory"
  }
}
