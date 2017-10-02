# Cluster settings
variable cluster_prefix {}

variable kubenow_image {
  default = "kubenow-v040b1"
}

variable ssh_user {
  default = "ubuntu"
}

variable ssh_key {
  default = "ssh_key.pub"
}

variable external_network_uuid {}

variable dns_nameservers {
  default = "8.8.8.8,8.8.4.4"
}

variable floating_ip_pool {}
variable kubeadm_token {}

# Master settings
variable master_count {
  default = 1
}

variable master_flavor {}

variable master_flavor_id {
  default = ""
}

variable master_as_edge {
  default = "true"
}

# Nodes settings
variable node_count {}

variable node_flavor {}

variable node_flavor_id {
  default = ""
}

# Edges settings
variable edge_count {
  default = 0
}

variable edge_flavor {
  default = "nothing"
}

variable edge_flavor_id {
  default = ""
}

# Glusternode settings
variable glusternode_count {
  default = 0
}

variable glusternode_flavor {
  default = "nothing"
}

variable glusternode_flavor_id {
  default = ""
}

variable glusternode_extra_disk_size {
  default = "200"
}

# Cloudflare settings
variable use_cloudflare {
  default = "false"
}

variable cloudflare_email {
  default = "nothing"
}

variable cloudflare_token {
  default = "nothing"
}

variable cloudflare_domain {
  default = ""
}

variable cloudflare_proxied {
  default = "false"
}

variable cloudflare_record_texts {
  type    = "list"
  default = ["*"]
}

# Upload SSH key to OpenStack
module "keypair" {
  source      = "./keypair"
  public_key  = "${var.ssh_key}"
  name_prefix = "${var.cluster_prefix}"
}

# Network (here would be nice with condition)
module "network" {
  source            = "./network"
  external_net_uuid = "${var.external_network_uuid}"
  name_prefix       = "${var.cluster_prefix}"
  dns_nameservers   = "${var.dns_nameservers}"
}

module "master" {
  # Core settings
  source      = "./node"
  count       = "${var.master_count}"
  name_prefix = "${var.cluster_prefix}-master"
  flavor_name = "${var.master_flavor}"
  flavor_id   = "${var.master_flavor_id}"
  image_name  = "${var.kubenow_image}"

  # SSH settings
  ssh_user     = "${var.ssh_user}"
  keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  network_name       = "${module.network.network_name}"
  secgroup_name      = "${module.network.secgroup_name}"
  assign_floating_ip = "true"
  floating_ip_pool   = "${var.floating_ip_pool}"

  # Disk settings
  extra_disk_size = "0"

  # Bootstrap settings
  bootstrap_file = "bootstrap/master.sh"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = "${split(",", var.master_as_edge == "true" ? "role=edge" : "")}"
  node_taints    = [""]
  master_ip      = ""
}

module "node" {
  # Core settings
  source      = "./node"
  count       = "${var.node_count}"
  name_prefix = "${var.cluster_prefix}-node"
  flavor_name = "${var.node_flavor}"
  flavor_id   = "${var.node_flavor_id}"
  image_name  = "${var.kubenow_image}"

  # SSH settings
  ssh_user     = "${var.ssh_user}"
  keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  network_name       = "${module.network.network_name}"
  secgroup_name      = "${module.network.secgroup_name}"
  assign_floating_ip = "false"
  floating_ip_pool   = ""

  # Disk settings
  extra_disk_size = "0"

  # Bootstrap settings
  bootstrap_file = "bootstrap/node.sh"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["role=node"]
  node_taints    = [""]
  master_ip      = "${element(module.master.local_ip_v4, 0)}"
}

module "edge" {
  # Core settings
  source      = "./node"
  count       = "${var.edge_count}"
  name_prefix = "${var.cluster_prefix}-edge"
  flavor_name = "${var.edge_flavor}"
  flavor_id   = "${var.edge_flavor_id}"
  image_name  = "${var.kubenow_image}"

  # SSH settings
  ssh_user     = "${var.ssh_user}"
  keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  network_name       = "${module.network.network_name}"
  secgroup_name      = "${module.network.secgroup_name}"
  assign_floating_ip = "true"
  floating_ip_pool   = "${var.floating_ip_pool}"

  # Disk settings
  extra_disk_size = "0"

  # Bootstrap settings
  bootstrap_file = "bootstrap/node.sh"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["role=edge"]
  node_taints    = [""]
  master_ip      = "${element(module.master.local_ip_v4, 0)}"
}

module "glusternode" {
  # Core settings
  source      = "./node"
  count       = "${var.glusternode_count}"
  name_prefix = "${var.cluster_prefix}-glusternode"
  flavor_name = "${var.glusternode_flavor}"
  flavor_id   = "${var.glusternode_flavor_id}"
  image_name  = "${var.kubenow_image}"

  # SSH settings
  ssh_user     = "${var.ssh_user}"
  keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  network_name       = "${module.network.network_name}"
  secgroup_name      = "${module.network.secgroup_name}"
  assign_floating_ip = "false"
  floating_ip_pool   = "${var.floating_ip_pool}"

  # Disk settings
  extra_disk_size = "${var.glusternode_extra_disk_size}"

  # Bootstrap settings
  bootstrap_file = "bootstrap/node.sh"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["storagenode=glusterfs"]
  node_taints    = [""]
  master_ip      = "${element(module.master.local_ip_v4, 0)}"
}

# The code below (from here to end) should be identical for all cloud providers

# set cloudflare record (optional)
module "cloudflare" {
  # count values can not be dynamically computed, that's why we are using var.edge_count and not length(iplist)
  record_count      = "${var.use_cloudflare != true ? 0 : var.master_as_edge == true ? (var.edge_count + var.master_count) * length(var.cloudflare_record_texts) : var.edge_count * length(var.cloudflare_record_texts)}"
  source            = "../common/cloudflare"
  cloudflare_email  = "${var.cloudflare_email}"
  cloudflare_token  = "${var.cloudflare_token}"
  cloudflare_domain = "${var.cloudflare_domain}"

  # add cluster prefix to record names
  record_names = "${formatlist("%s.%s", var.cloudflare_record_texts, var.cluster_prefix)}"

  # terraform interpolation is limited and can not return list in conditionals, workaround: first join to string, then split)
  iplist  = "${split(",", var.master_as_edge == true ? join(",", concat(module.edge.public_ip, module.master.public_ip) ) : join(",", module.edge.public_ip) )}"
  proxied = "${var.cloudflare_proxied}"
}

# Generate Ansible inventory (identical for each cloud provider)
module "generate-inventory" {
  source            = "../common/inventory"
  master_hostnames  = "${module.master.hostnames}"
  master_public_ip  = "${module.master.public_ip}"
  edge_hostnames    = "${module.edge.hostnames}"
  edge_public_ip    = "${module.edge.public_ip}"
  master_as_edge    = "${var.master_as_edge}"
  edge_count        = "${var.edge_count}"
  node_count        = "${var.node_count}"
  glusternode_count = "${var.glusternode_count}"
  extra_disk_device = "${element(concat(module.glusternode.extra_disk_device, list("")),0)}"
  cluster_prefix    = "${var.cluster_prefix}"
  use_cloudflare    = "${var.use_cloudflare}"
  cloudflare_domain = "${var.cloudflare_domain}"
  ssh_user          = "${var.ssh_user}"
}
