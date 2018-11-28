# Cluster settings
variable cluster_prefix {}

variable bootstrap_script {
  default = "bootstrap/bootstrap-default.sh"
}

variable inventory_template {
  default = "inventory-template"
}

variable inventory_output_file {
  default = "inventory"
}

variable ssh_user {
  default = "ubuntu"
}

variable ssh_key {
  default = "ssh_key.pub"
}

variable kubeadm_token {
  default = "0123456.0123456789abcdef"
}
# Image settings
variable boot_image {}
variable image_dir { default = "/tmp" } # to do fixme
variable volume_pool  { default = "images" }

# Network settings
variable network_mode  { default = "nat" }
variable bridge_name { default = "br0" }

# Master settings
variable master_count { default = 1 }
variable master_vcpu { default = 2 }
variable master_memory { default = 1024 }
variable master_as_edge { default = "true" }
variable master_extra_disk_size { default = "200" }
variable master_ip_if1{
  type    = "list"
  default = ["130.238.44.20"]
}
variable master_ip_if2{
  type    = "list"
  default = ["10.10.0.20"]
}

# Nodes settings
variable node_count { default = 0 }
variable node_vcpu { default = 2 }
variable node_memory { default = 1024 }
variable node_ip_if1{
  type    = "list"
  default = ["130.238.44.30"]
}
variable node_ip_if2{
  type    = "list"
  default = ["10.10.0.30"]
}

# Edges settings
variable edge_count { default = 0 }
variable edge_vcpu { default = 2 }
variable edge_memory { default = 1024 }
variable edge_ip_if1{
  type    = "list"
  default = ["x.x.x.x"]
}
variable edge_ip_if2{
  type    = "list"
  default = ["x.x.x.x"]
}

# Glusternode settings
variable glusternode_count { default = 0 }
variable glusternode_vcpu { default = 2 }
variable glusternode_memory { default = 1024 }
variable glusternode_extra_disk_size { default = "200" }
variable glusternode_ip_if1{
  type    = "list"
  default = ["x.x.x.x"]
}
variable glusternode_ip_if2{
  type    = "list"
  default = ["x.x.x.x"]
}
variable gluster_volumetype {
  default = "none:1"
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

variable cloudflare_subdomain {
  default = ""
}

variable cloudflare_proxied {
  default = "false"
}

variable cloudflare_record_texts {
  type    = "list"
  default = ["*"]
}

# Provider
provider "libvirt" {
  uri = "qemu:///system"
}

# Network
resource "libvirt_network" "network" {
  name  = "${var.cluster_prefix}-network"
  mode  = "${var.network_mode}"
#  bridge = "${var.bridge_name}-another"
  domain = "k8s.local"
  addresses = ["10.0.0.0/24"]
  dhcp {
    enabled = "true"
  }
  autostart = "true"
}

# Create a template disk
resource "libvirt_volume" "template_volume" {
  name   = "${var.cluster_prefix}-template-volume"
  source = "${var.image_dir}/${var.boot_image}.qcow2"
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
  network_id      = "${libvirt_network.network.id}"
  ip_if1          = "${var.master_ip_if1}"
  ip_if2          = "${var.master_ip_if2}"
  ssh_key         = "${var.ssh_key}"
  ssh_user        = "${var.ssh_user}"

  # TO DO configure port rules in firewall

  # Disk settings
  extra_disk_size = "${var.master_extra_disk_size}"

  # Bootstrap settings
  bootstrap_file = "${var.bootstrap_script}"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = "${split(",", var.master_as_edge == "true" ? "role=master,role=edge" : "role=master")}"
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
  network_id      = "${libvirt_network.network.id}"
  ip_if1          = "${var.node_ip_if1}"
  ip_if2          = "${var.node_ip_if2}"
  ssh_key         = "${var.ssh_key}"
  ssh_user        = "${var.ssh_user}"

  # TO DO configure port rules in firewall

  # Disk settings
  extra_disk_size = "0"

  # Bootstrap settings
  bootstrap_file = "${var.bootstrap_script}"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["role=node","role=bajs"]
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
  network_id      = "${libvirt_network.network.id}"
  ip_if1          = "${var.edge_ip_if1}"
  ip_if2          = "${var.edge_ip_if2}"
  ssh_key         = "${var.ssh_key}"
  ssh_user        = "${var.ssh_user}"

  # TO DO configure port rules in firewall

  # Disk settings
  extra_disk_size = "0"

  # Bootstrap settings
  bootstrap_file = "${var.bootstrap_script}"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["role=edge","role=bajs"]
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
  network_id      = "${libvirt_network.network.id}"
  ip_if1          = "${var.glusternode_ip_if1}"
  ip_if2          = "${var.glusternode_ip_if2}"
  ssh_key         = "${var.ssh_key}"
  ssh_user        = "${var.ssh_user}"

  # TO DO configure port rules in firewall

  # Disk settings
  extra_disk_size = "${var.glusternode_extra_disk_size}"

  # Bootstrap settings
  bootstrap_file = "${var.bootstrap_script}"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["storagenode=glusterfs","role=bajs"]
  node_taints    = [""]
  master_ip      = "${element(module.master.local_ip_v4, 0)}"
}

# The code below (from here to end) should be identical for all cloud providers

# set cloudflare record (optional)
module "cloudflare" {
  # count values can not be dynamically computed, that's why we are using var.edge_count and not length(iplist)
  record_count         = "${var.use_cloudflare != true ? 0 : var.master_as_edge == true ? (var.edge_count + var.master_count) * length(var.cloudflare_record_texts) : var.edge_count * length(var.cloudflare_record_texts)}"
  source               = "../common/cloudflare"
  cloudflare_email     = "${var.cloudflare_email}"
  cloudflare_token     = "${var.cloudflare_token}"
  cloudflare_domain    = "${var.cloudflare_domain}"
  cloudflare_subdomain = "${var.cloudflare_subdomain}"

  # add optional subdomain to record names
  # terraform interpolation is limited and can not return list in conditionals, workaround: first join to string, then split
  record_names = "${split(",", var.cloudflare_subdomain != "" ? join(",", formatlist("%s.%s", var.cloudflare_record_texts, var.cloudflare_subdomain)) : join(",", var.cloudflare_record_texts ) )}"

  # terraform interpolation is limited and can not return list in conditionals, workaround: first join to string, then split
  iplist  = "${split(",", var.master_as_edge == true ? join(",", concat(module.edge.public_ip, module.master.public_ip) ) : join(",", module.edge.public_ip) )}"
  proxied = "${var.cloudflare_proxied}"
}

# Generate Ansible inventory (identical for each cloud provider)
module "generate-inventory" {
  source                 = "../common/inventory"
  cluster_prefix         = "${var.cluster_prefix}"
  domain                 = "${var.use_cloudflare == true ? module.cloudflare.domain_and_subdomain : format("%s.nip.io", element(concat(module.edge.public_ip, module.master.public_ip, list("")), 0))}"
  ssh_user               = "${var.ssh_user}"
  master_hostnames       = "${module.master.hostnames}"
  master_public_ip       = "${module.master.public_ip}"
  master_private_ip      = "${module.master.local_ip_v4}"
  master_as_edge         = "${var.master_as_edge}"
  edge_count             = "${var.edge_count}"
  edge_hostnames         = "${module.edge.hostnames}"
  edge_public_ip         = "${module.edge.public_ip}"
  edge_private_ip        = "${module.edge.local_ip_v4}"
  node_count             = "${var.node_count}"
  node_hostnames         = "${module.node.hostnames}"
  node_public_ip         = "${module.node.public_ip}"
  node_private_ip        = "${module.node.local_ip_v4}"
  glusternode_count      = "${var.glusternode_count}"
  gluster_volumetype     = "${var.gluster_volumetype}"
  gluster_extra_disk_dev = "${element(concat(module.glusternode.extra_disk_device, list("")),0)}"
  inventory_template     = "${var.inventory_template}"
  inventory_output_file  = "${var.inventory_output_file}"
}
