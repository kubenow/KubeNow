# Cluster settings
variable cluster_prefix {}
variable KubeNow_image {}
variable ssh_key {}
variable external_network_uuid {}
variable dns_nameservers { default="8.8.8.8,8.8.4.4" }
variable floating_ip_pool {}
variable kubeadm_token {}

# Cloudflare settings
variable cloudflare_email { default="nothing" }
variable cloudflare_token { default="nothing" }
variable cloudflare_domain { default="" }

# Master settings
variable master_count { default = 1 }
variable master_flavor {}
variable master_flavor_id { default = ""}
variable master_is_edge { default = "true" }

# Nodes settings
variable node_count {}
variable node_flavor {}
variable node_flavor_id { default = ""}

# Edges settings
variable edge_count {}
variable edge_flavor {}
variable edge_flavor_id { default = ""}

# Gluster settings
variable glusternode_count {default = 0}
variable glusternode_flavor {}
variable glusternode_flavor_id { default = ""}

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
  node_labels = "${var.master_is_edge ? "role=master,role=edge" : "role=master" }"
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

module "glusternode" {
  node_labels = "storagenode=glusterfs"
  node_taints = "dedicated=fileserver:NoSchedule"
  extra_disk_size = "200"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-glusternode"
  count = "${var.glusternode_count}"
  flavor_name = "${var.glusternode_flavor}"
  flavor_id = "${var.glusternode_flavor_id}"
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
  # If cloudflare domain is set, output that domain, otherwise output a nip.io domain with the first edge ip
  provisioner "local-exec" {
    command =  "echo \"domain=${ var.cloudflare_domain != "" ? format("%s.%s", var.cluster_prefix, var.cloudflare_domain) : format("%s.nip.io", element(concat(module.edge.public_ip, module.master.public_ip), 0))}\" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo \"nodes_count=${1 + var.edge_count + var.node_count + var.glusternode_count} \" >> inventory"
  }
}
