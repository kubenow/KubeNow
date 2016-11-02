# Cluster settings
variable cluster_prefix {}
variable kubenow_image_id {}
variable kubeadm_token {}

variable aws_access_key_id {}
variable aws_secret_access_key {}
variable aws_region {}
variable availability_zone {}

variable ssh_user { default = "ubuntu" }
variable ssh_key {}

# Master settings
variable master_instance_type {}
variable master_disk_size {}

# Nodes settings
variable node_count {}
variable node_instance_type {}
variable node_disk_size {}

# Edges settings
variable edge_count {}
variable edge_instance_type {}
variable edge_disk_size {}

# Provider
provider "aws" {
  access_key = "${var.aws_access_key_id}" 
  secret_key = "${var.aws_secret_access_key}" 
  region = "${var.aws_region}" 
}

# Upload ssh-key to be used for access to the nodes
module "keypair" {
  source = "./keypair"
  public_key = "${var.ssh_key}"
  name_prefix = "${var.cluster_prefix}"
}

# VPC Virtual Private Cloud - Networking
module "vpc" {
  source = "./vpc"
  name_prefix = "${var.cluster_prefix}"
  availability_zone = "${var.availability_zone}" 
}

module "master" {
  source = "./master"
  name_prefix = "${var.cluster_prefix}"
  kubenow_image_id = "${var.kubenow_image_id}"
  instance_type = "${var.master_instance_type}"
  subnet_id = "${module.vpc.subnet_id}"
  security_group_id = "${module.vpc.security_group_id}"
  kubeadm_token = "${var.kubeadm_token}"
  availability_zone = "${var.availability_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  disk_size = "${var.master_disk_size}"
}

module "node" {
  source = "./node"
  name_prefix = "${var.cluster_prefix}"
  kubenow_image_id = "${var.kubenow_image_id}"
  instance_type = "${var.node_instance_type}"
  subnet_id = "${module.vpc.subnet_id}"
  security_group_id = "${module.vpc.security_group_id}"
  kubeadm_token = "${var.kubeadm_token}"
  master_ip = "${module.master.ip_address_internal}"
  count = "${var.node_count}"
  availability_zone = "${var.availability_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  disk_size = "${var.node_disk_size}"  
}

module "edge" {
  source = "./edge"
  name_prefix = "${var.cluster_prefix}"
  kubenow_image_id = "${var.kubenow_image_id}"
  instance_type = "${var.edge_instance_type}"
  subnet_id = "${module.vpc.subnet_id}"
  security_group_id = "${module.vpc.security_group_id}"
  kubeadm_token = "${var.kubeadm_token}"
  master_ip = "${module.master.ip_address_internal}"
  count = "${var.edge_count}"
  availability_zone = "${var.availability_zone}"
  ssh_user = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  disk_size = "${var.edge_disk_size}" 
}
