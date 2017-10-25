# Cluster settings
variable cluster_prefix {}

variable kubenow_image {
  default = "kubenow-v040b1"
}

variable kubeadm_token {}

variable aws_access_key_id {}
variable aws_secret_access_key {}
variable aws_region {}
variable availability_zone {}

variable ssh_user {
  default = "ubuntu"
}

variable ssh_key {
  default = "ssh_key.pub"
}

# Networking
variable vpc_id {
  default = ""
}

variable subnet_id {
  default = ""
}

variable additional_sec_group_ids {
  type = "list"

  default = []
}

# Master settings
variable master_count {
  default = 1
}

variable master_instance_type {}
variable master_disk_size {}

variable master_as_edge {
  default = "true"
}

# Nodes settings
variable node_count {}

variable node_instance_type {}
variable node_disk_size {}

# Edges settings
variable edge_count {
  default = 0
}

variable edge_instance_type {
  default = "nothing"
}

variable edge_disk_size {
  default = "nothing"
}

# Glusternode settings
variable glusternode_count {
  default = 0
}

variable glusternode_instance_type {
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
provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
}

# Upload ssh-key to be used for access to the nodes
module "keypair" {
  source      = "./keypair"
  public_key  = "${var.ssh_key}"
  name_prefix = "${var.cluster_prefix}"
}

# Networking - VPC
module "vpc" {
  vpc_id      = "${var.vpc_id}"
  name_prefix = "${var.cluster_prefix}"
  source      = "./vpc"
}

# Networking - subnet
module "subnet" {
  subnet_id         = "${var.subnet_id}"
  vpc_id            = "${module.vpc.id}"
  name_prefix       = "${var.cluster_prefix}"
  availability_zone = "${var.availability_zone}"
  source            = "./subnet"
}

# Networking - sec-group
module "security_group" {
  name_prefix = "${var.cluster_prefix}"
  vpc_id      = "${module.vpc.id}"
  source      = "./security_group"
}

# Lookup image-id of kubenow-image
data "aws_ami" "kubenow" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.kubenow_image}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "master" {
  # Core settings
  source            = "./node"
  count             = "${var.master_count}"
  name_prefix       = "${var.cluster_prefix}-master"
  instance_type     = "${var.master_instance_type}"
  image_id          = "${data.aws_ami.kubenow.id}"
  availability_zone = "${var.availability_zone}"

  # SSH settings
  ssh_user         = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  subnet_id          = "${module.subnet.id}"
  security_group_ids = "${concat(module.security_group.id, var.additional_sec_group_ids)}"

  # Disk settings
  disk_size       = "${var.master_disk_size}"
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
  source            = "./node"
  count             = "${var.node_count}"
  name_prefix       = "${var.cluster_prefix}-node"
  instance_type     = "${var.node_instance_type}"
  image_id          = "${data.aws_ami.kubenow.id}"
  availability_zone = "${var.availability_zone}"

  # SSH settings
  ssh_user         = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  subnet_id          = "${module.subnet.id}"
  security_group_ids = "${concat(module.security_group.id, var.additional_sec_group_ids)}"

  # Disk settings
  disk_size       = "${var.node_disk_size}"
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
  source            = "./node"
  count             = "${var.edge_count}"
  name_prefix       = "${var.cluster_prefix}-edge"
  instance_type     = "${var.edge_instance_type}"
  image_id          = "${data.aws_ami.kubenow.id}"
  availability_zone = "${var.availability_zone}"

  # SSH settings
  ssh_user         = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  subnet_id          = "${module.subnet.id}"
  security_group_ids = "${concat(module.security_group.id, var.additional_sec_group_ids)}"

  # Disk settings
  disk_size       = "${var.edge_disk_size}"
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
  source            = "./node"
  count             = "${var.glusternode_count}"
  name_prefix       = "${var.cluster_prefix}-glusternode"
  instance_type     = "${var.glusternode_instance_type}"
  image_id          = "${data.aws_ami.kubenow.id}"
  availability_zone = "${var.availability_zone}"

  # SSH settings
  ssh_user         = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  subnet_id          = "${module.subnet.id}"
  security_group_ids = "${concat(module.security_group.id, var.additional_sec_group_ids)}"

  # Disk settings
  disk_size       = "${var.glusternode_disk_size}"
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
  source             = "../common/inventory"
  cluster_prefix     = "${var.cluster_prefix}"
  domain             = "${ var.use_cloudflare == true ? module.cloudflare.domain_and_subdomain : format("%s.nip.io", element(concat(module.edge.public_ip, module.master.public_ip), 0))}"
  ssh_user           = "${var.ssh_user}"
  master_hostnames   = "${module.master.hostnames}"
  master_public_ip   = "${module.master.public_ip}"
  master_private_ip  = "${module.master.local_ip_v4}"
  master_as_edge     = "${var.master_as_edge}"
  edge_count         = "${var.edge_count}"
  edge_hostnames     = "${module.edge.hostnames}"
  edge_public_ip     = "${module.edge.public_ip}"
  edge_private_ip    = "${module.edge.local_ip_v4}"
  node_count         = "${var.node_count}"
  node_hostnames     = "${module.node.hostnames}"
  node_public_ip     = "${module.node.public_ip}"
  node_private_ip    = "${module.node.local_ip_v4}"
  glusternode_count  = "${var.glusternode_count}"
  gluster_volumetype = "${var.gluster_volumetype}"
  extra_disk_device  = "${element(concat(module.glusternode.extra_disk_device, list("")),0)}"
}
