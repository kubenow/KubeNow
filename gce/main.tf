# Cluster settings
variable cluster_prefix {}

variable kubenow_image {
  default = "kubenow-v020"
}

variable kubeadm_token {}

variable ssh_user {
  default = "ubuntu"
}

variable ssh_key {
  default = "ssh_key.pub"
}

# Google credentials
variable gce_project {}

variable gce_zone {}

variable gce_credentials_file {
  default = "service-account.json"
}

# Master settings
variable master_count {
  default = 1
}

variable master_flavor {}
variable master_disk_size {}

variable master_as_edge {
  default = "true"
}

# Nodes settings
variable node_count {}

variable node_flavor {}
variable node_disk_size {}

# Edges settings
variable edge_count {
  default = 0
}

variable edge_flavor {
  default = "nothing"
}

variable edge_disk_size {
  default = "nothing"
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

variable record_names {
  type    = "list"
  default = ["*"]
}

# Provider
provider "google" {
  credentials = "${file("${var.gce_credentials_file}")}"
  project     = "${var.gce_project}"
  region      = "${var.gce_zone}"
}

# Network (here would be nice with condition)
module "network" {
  source       = "./network"
  network_name = "${var.cluster_prefix}"
}

module "master" {
  # Core settings
  source      = "./node"
  count       = "1"
  name_prefix = "${var.cluster_prefix}-master"
  flavor_name = "${var.master_flavor}"
  image_name  = "${var.kubenow_image}"
  zone        = "${var.gce_zone}"

  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key  = "${var.ssh_key}"

  # Network settings
  network_name = "${module.network.network_name}"

  # Disk settings
  disk_size = "${var.master_disk_size}"

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
  image_name  = "${var.kubenow_image}"
  zone        = "${var.gce_zone}"

  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key  = "${var.ssh_key}"

  # Network settings
  network_name = "${module.network.network_name}"

  # Disk settings
  disk_size = "${var.node_disk_size}"

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
  image_name  = "${var.kubenow_image}"
  zone        = "${var.gce_zone}"

  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key  = "${var.ssh_key}"

  # Network settings
  network_name = "${module.network.network_name}"

  # Disk settings
  disk_size = "${var.edge_disk_size}"

  # Bootstrap settings
  bootstrap_file = "bootstrap/node.sh"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["role=edge"]
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
  cloudflare_record_texts = "${formatlist("%s.%s", var.cloudflare_record_texts, var.cluster_prefix)}"

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
  cluster_prefix    = "${var.cluster_prefix}"
  use_cloudflare    = "${var.use_cloudflare}"
  cloudflare_domain = "${var.cloudflare_domain}"
}
