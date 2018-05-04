# Cluster settings
variable cluster_prefix {}

# This var is for KubeNow boot image version
# leave empty if public image is specified
variable boot_image {
  default = ""
}

# This var is for any Azure boot image
# leave empty if KubeNow image is specified
variable boot_image_public {
  type = "map"

  default = {
    publisher = ""
    offer     = ""
    sku       = ""
    version   = ""
  }
}

variable bootstrap_script {
  default = "bootstrap/bootstrap-default.sh"
}

variable inventory_template {
  default = "inventory-template"
}

variable image_resource_group_prefix {
  default = "kubenow-images-rg"
}

variable kubeadm_token {
  default = ""
}

variable subscription_id {}
variable client_id {}
variable client_secret {}
variable tenant_id {}
variable location {}

variable ssh_user {
  default = "ubuntu"
}

variable ssh_key {
  default = "ssh_key.pub"
}

# Master settings
variable master_count {
  default = 1
}

variable master_vm_size {}

variable master_as_edge {
  default = "true"
}

# Nodes settings
variable node_count {}

variable node_vm_size {}

# Edges settings
variable edge_count {
  default = 0
}

variable edge_vm_size {
  default = "nothing"
}

# Glusternode settings
variable glusternode_count {
  default = 0
}

variable glusternode_vm_size {
  default = "nothing"
}

variable glusternode_disk_size {
  default = "nothing"
}

variable glusternode_extra_disk_size {
  default = "200"
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
provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

# Data-lookup, subscriptin_id etc.
data "azurerm_client_config" "current" {}

# This is for KubeNow boot image only
# Generates image resource group name by adding location as suffix (without spaces)
data "null_data_source" "image_rg" {
  inputs = {
    name = "${var.image_resource_group_prefix}-${replace(var.location, " " , "")}"
  }
}

# This is for KubeNow boot image only
# Generates KubeNow image_id
data "null_data_source" "private_img" {
  inputs = {
    image_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.null_data_source.image_rg.inputs.name}/providers/Microsoft.Compute/images/${var.boot_image}"
  }
}

# This is for KubeNow boot image only
# Sets image_id to KubeNow image id if KubeNow image is specified otherwise ""
data "null_data_source" "boot_image_private_id_lookup" {
  inputs = {
    image_id = "${var.boot_image == "" ? "" : data.null_data_source.private_img.inputs.image_id}"
  }
}

# Resource-group
resource "azurerm_resource_group" "rg" {
  name     = "${var.cluster_prefix}-rg"
  location = "${var.location}"
}

# Security-group
module "security_group" {
  source              = "./security_group"
  name_prefix         = "${var.cluster_prefix}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

# Network (here would be nice with condition)
module "network" {
  source              = "./network"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  name_prefix         = "${var.cluster_prefix}"
}

module "master" {
  # Core settings
  source                = "./node"
  count                 = "${var.master_count}"
  name_prefix           = "${var.cluster_prefix}-master"
  vm_size               = "${var.master_vm_size}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  boot_image_public     = "${var.boot_image_public}"
  boot_image_private_id = "${data.null_data_source.boot_image_private_id_lookup.inputs.image_id}"
  location              = "${var.location}"

  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key  = "${var.ssh_key}"

  # Network settings
  subnet_id          = "${module.network.subnet_id}"
  assign_floating_ip = "true"
  security_group_id  = "${module.security_group.id}"

  # Bootstrap settings
  bootstrap_file = "${var.bootstrap_script}"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = "${split(",", var.master_as_edge == "true" ? "role=master,role=edge" : "role=master")}"
  node_taints    = [""]
  master_ip      = ""
}

module "node" {
  # Core settings
  source                = "./node"
  count                 = "${var.node_count}"
  name_prefix           = "${var.cluster_prefix}-node"
  vm_size               = "${var.node_vm_size}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  boot_image_public     = "${var.boot_image_public}"
  boot_image_private_id = "${data.null_data_source.boot_image_private_id_lookup.inputs.image_id}"
  location              = "${var.location}"

  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key  = "${var.ssh_key}"

  # Network settings
  subnet_id          = "${module.network.subnet_id}"
  assign_floating_ip = "true"
  security_group_id  = "${module.security_group.id}"

  # Bootstrap settings
  bootstrap_file = "${var.bootstrap_script}"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["role=node"]
  node_taints    = [""]
  master_ip      = "${element(module.master.local_ip_v4, 0)}"
}

module "edge" {
  # Core settings
  source                = "./node"
  count                 = "${var.edge_count}"
  name_prefix           = "${var.cluster_prefix}-edge"
  vm_size               = "${var.node_vm_size}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  boot_image_public     = "${var.boot_image_public}"
  boot_image_private_id = "${data.null_data_source.boot_image_private_id_lookup.inputs.image_id}"
  location              = "${var.location}"

  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key  = "${var.ssh_key}"

  # Network settings
  subnet_id          = "${module.network.subnet_id}"
  assign_floating_ip = "true"
  security_group_id  = "${module.security_group.id}"

  # Bootstrap settings
  bootstrap_file = "${var.bootstrap_script}"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["role=edge"]
  node_taints    = [""]
  master_ip      = "${element(module.master.local_ip_v4, 0)}"
}

module "glusternode" {
  # Core settings
  source                = "./node-extra-disk"
  count                 = "${var.glusternode_count}"
  name_prefix           = "${var.cluster_prefix}-glusternode"
  vm_size               = "${var.glusternode_vm_size}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  boot_image_public     = "${var.boot_image_public}"
  boot_image_private_id = "${data.null_data_source.boot_image_private_id_lookup.inputs.image_id}"
  location              = "${var.location}"

  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_key  = "${var.ssh_key}"

  # Network settings
  subnet_id          = "${module.network.subnet_id}"
  assign_floating_ip = "true"
  security_group_id  = "${module.security_group.id}"

  # Disk settings
  extra_disk_size = "${var.glusternode_extra_disk_size}"

  # Bootstrap settings
  bootstrap_file = "${var.bootstrap_script}"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["storagenode=glusterfs"]
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
}
