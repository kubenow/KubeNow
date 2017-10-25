# Cluster settings
variable cluster_prefix {}

variable kubenow_dir { default = "/tmp" } # to do fixme
variable kubenow_image { default = "kubenow-v031-26-g8b8c758-test.qcow2" } # to do fixme
variable ssh_key { default = "ssh_key.pub"}
variable ssh_user{ default = "ubuntu"}

variable kubeadm_token {}

variable volume_pool  { default = "default" }

variable network_mode  { default = "nat" }
variable bridge_name { default = "br0" }

# Master settings
variable master_count { default = 1 }
variable master_vcpu { default = 2 }
variable master_memory { default = 1024 }
variable master_as_edge { default = "true" }
variable master_extra_disk_size { default = "200" }

# Nodes settings
variable node_count { default = 0 }
variable node_vcpu { default = 2 }
variable node_memory { default = 1024 }

# Edges settings
variable edge_count { default = 0 }
variable edge_vcpu { default = 2 }
variable edge_memory { default = 1024 }

# Glusternode settings
variable glusternode_count { default = 0 }
variable glusternode_vcpu { default = 2 }
variable glusternode_memory { default = 1024 }
variable glusternode_extra_disk_size { default = "200" }
variable gluster_volumetype {
  default = "none:1"
}

# Cloudflare settings
variable use_cloudflare { default = "false" }
variable cloudflare_email { default = "nothing" }
variable cloudflare_token { default = "nothing" }
variable cloudflare_domain { default = "" }
variable cloudflare_proxied { default = "false" }
variable cloudflare_record_texts { type = "list" default = ["*"]}

# Provider
provider "libvirt" {
  uri = "qemu:///system"
}

# Network
resource "libvirt_network" "network" {
  name = "${var.cluster_prefix}-network"
  mode = "${var.network_mode}"
#  bridge = "${var.bridge_name}"
  domain = "k8s.local"
  addresses = ["10.0.0.0/16"]
}

# Create a template disk
resource "libvirt_volume" "template_volume" {
  name   = "${var.cluster_prefix}-template-volume"
  source = "${var.kubenow_dir}/${var.kubenow_image}"
  pool   = "${var.volume_pool}"
}

module "master" {
  # Core settings
  source          = "./node"
  count           = "${var.master_count}"
  name_prefix     = "${var.cluster_prefix}-master"
  vcpu            = "${var.master_vcpu}"
  memory          = "${var.master_memory}"
  template_vol_id = "${libvirt_volume.template_volume.id}"
  volume_pool     = "${var.volume_pool}"

  # Network settings
  network_id = "${libvirt_network.network.id}"
  ssh_key    = "${var.ssh_key}"
  ssh_user   = "${var.ssh_user}"

  # TO DO configure port rules in firewall

  # Disk settings
  extra_disk_size = "${var.master_extra_disk_size}"

  # Bootstrap settings
  bootstrap_file = "bootstrap/master.sh"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = "${split(",", var.master_as_edge == "true" ? "role=edge" : "")}"
  node_taints    = [""]
  master_ip      = ""
}

module "node" {
  # Core settings
  source          = "./node"
  count           = "${var.node_count}"
  name_prefix     = "${var.cluster_prefix}-node"
  vcpu            = "${var.node_vcpu}"
  memory          = "${var.node_memory}"
  template_vol_id = "${libvirt_volume.template_volume.id}"
  volume_pool     = "${var.volume_pool}"

  # Network settings
  network_id = "${libvirt_network.network.id}"
  ssh_key    = "${var.ssh_key}"
  ssh_user   = "${var.ssh_user}"

  # TO DO configure port rules in firewall

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
  source          = "./node"
  count           = "${var.edge_count}"
  name_prefix     = "${var.cluster_prefix}-edge"
  vcpu            = "${var.edge_vcpu}"
  memory          = "${var.edge_memory}"
  template_vol_id = "${libvirt_volume.template_volume.id}"
  volume_pool     = "${var.volume_pool}"

  # Network settings
  network_id = "${libvirt_network.network.id}"
  ssh_key    = "${var.ssh_key}"
  ssh_user   = "${var.ssh_user}"

  # TO DO configure port rules in firewall

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
  source          = "./node"
  count           = "${var.glusternode_count}"
  name_prefix     = "${var.cluster_prefix}-glusternode"
  vcpu            = "${var.glusternode_vcpu}"
  memory          = "${var.glusternode_memory}"
  template_vol_id = "${libvirt_volume.template_volume.id}"
  volume_pool     = "${var.volume_pool}"

  # Network settings
  network_id = "${libvirt_network.network.id}"
  ssh_key    = "${var.ssh_key}"
  ssh_user   = "${var.ssh_user}"

  # TO DO configure port rules in firewall

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
  # terraform interpolation is limited and can not return list in conditionals, workaround: first join to string, then split
  record_names = "${split(",", var.cloudflare_proxied == true ? join(",", formatlist("%s-%s", var.cloudflare_record_texts, var.cluster_prefix) ) : join(",", formatlist("%s.%s", var.cloudflare_record_texts, var.cluster_prefix)))}"

  # terraform interpolation is limited and can not return list in conditionals, workaround: first join to string, then split
  iplist  = "${split(",", var.master_as_edge == true ? join(",", concat(module.edge.public_ip, module.master.public_ip) ) : join(",", module.edge.public_ip) )}"
  proxied = "${var.cloudflare_proxied}"
}

# Generate Ansible inventory (identical for each cloud provider)
module "generate-inventory" {
  source             = "../common/inventory"
  master_hostnames   = "${module.master.hostnames}"
  master_public_ip   = "${module.master.public_ip}"
  edge_hostnames     = "${module.edge.hostnames}"
  edge_public_ip     = "${module.edge.public_ip}"
  master_as_edge     = "${var.master_as_edge}"
  edge_count         = "${var.edge_count}"
  node_count         = "${var.node_count}"
  glusternode_count  = "${var.glusternode_count}"
  gluster_volumetype = "${var.gluster_volumetype}"
  extra_disk_device  = "${element(concat(module.glusternode.extra_disk_device, list("")),0)}"
  cluster_prefix     = "${var.cluster_prefix}"
  use_cloudflare     = "${var.use_cloudflare}"
  cloudflare_domain  = "${var.cloudflare_proxied == true ? var.cloudflare_domain : format("%s.%s", var.cluster_prefix, var.cloudflare_domain)}"
}
