# Cluster settings
variable cluster_prefix {}
variable kubenow_image {}
variable kubeadm_token {}

variable aws_access_key_id {}
variable aws_secret_access_key {}
variable aws_region {}
variable availability_zone {}

variable ssh_user { default = "ubuntu" }
variable ssh_key {}

# Networking
variable vpc_id {default = ""}
variable subnet_id {default = ""}
variable additional_sec_group_ids {type="list" default = []}

# Master settings
variable master_count { default = 1 }
variable master_instance_type {}
variable master_disk_size {}
variable master_as_edge { default="true" }

# Nodes settings
variable node_count {}
variable node_instance_type {}
variable node_disk_size {}

# Edges settings
variable edge_count {}
variable edge_instance_type {}
variable edge_disk_size {}

# Cloudflare settings
variable use_cloudflare { default="false" }
variable cloudflare_email { default="nothing" }
variable cloudflare_token { default="nothing" }
variable cloudflare_domain { default="" }

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

# Networking - VPC
module "vpc" {
  vpc_id = "${var.vpc_id}"
  name_prefix = "${var.cluster_prefix}"
  source = "./vpc"
}

# Networking - subnet
module "subnet" {
  subnet_id = "${var.subnet_id}"
  vpc_id = "${module.vpc.id}"
  name_prefix = "${var.cluster_prefix}"
  availability_zone = "${var.availability_zone}"
  source = "./subnet"
}

# Networking - sec-group
module "security_group" {
  name_prefix = "${var.cluster_prefix}"
  vpc_id = "${module.vpc.id}"
  source = "./security_group"
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
  source = "./node"
  count = "${var.master_count}"
  name_prefix = "${var.cluster_prefix}-master"
  instance_type = "${var.master_instance_type}"
  image_id = "${data.aws_ami.kubenow.id}"
  availability_zone = "${var.availability_zone}"
  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  # Network settings
  subnet_id = "${module.subnet.id}"
  security_group_ids = "${concat(module.security_group.id, var.additional_sec_group_ids)}"
  # Disk settings
  disk_size = "${var.master_disk_size}"
  extra_disk_size = "0"
  # Bootstrap settings
  bootstrap_file = "bootstrap/master.sh"
  kubeadm_token = "${var.kubeadm_token}"
  node_labels = "${split(",", var.master_as_edge == "true" ? "role=edge" : "")}"
  node_taints = [""]
  master_ip = ""
}

module "node" {
  # Core settings
  source = "./node"
  count = "${var.node_count}"
  name_prefix = "${var.cluster_prefix}-node"
  instance_type = "${var.node_instance_type}"
  image_id = "${data.aws_ami.kubenow.id}"
  availability_zone = "${var.availability_zone}"
  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  # Network settings
  subnet_id = "${module.subnet.id}"
  security_group_ids = "${concat(module.security_group.id, var.additional_sec_group_ids)}"
  # Disk settings
  disk_size = "${var.node_disk_size}"
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
  instance_type = "${var.edge_instance_type}"
  image_id = "${data.aws_ami.kubenow.id}"
  availability_zone = "${var.availability_zone}"
  # SSH settings
  ssh_user = "${var.ssh_user}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  # Network settings
  subnet_id = "${module.subnet.id}"
  security_group_ids = "${concat(module.security_group.id, var.additional_sec_group_ids)}"
  # Disk settings
  disk_size = "${var.edge_disk_size}"
  extra_disk_size = "0"
  # Bootstrap settings
  bootstrap_file = "bootstrap/node.sh"
  kubeadm_token = "${var.kubeadm_token}"
  node_labels = ["role=edge"]
  node_taints = [""]
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}

# The code below (from here to end) should be identical for all cloud providers

# set cloudflare record (optional)
module "cloudflare" {
  # count values can not be dynamically computed, that's why we are using var.edge_count and not length(iplist)
  record_count = "${var.use_cloudflare != true ? 0 : var.master_as_edge == true ? var.edge_count + var.master_count : var.edge_count}"
  source = "../common/cloudflare"
  cloudflare_email = "${var.cloudflare_email}"
  cloudflare_token = "${var.cloudflare_token}"
  cloudflare_domain = "${var.cloudflare_domain}"
  record_text = "*.${var.cluster_prefix}"
  # concat lists (record_count is limiting master_ip:s from being added to cloudflare if var.master_as_edge=false)
  # terraform interpolation is limited and can not return list in conditionals
  iplist = "${concat(module.edge.public_ip, module.master.public_ip)}"
}

# Generate Ansible inventory (identical for each cloud provider)
resource "null_resource" "generate-inventory" {

  # Trigger rewrite of inventory always, uuid() generates a random string everytime it is called
  triggers {
    uuid = "${uuid()}"
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
    command =  "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", module.edge.hostnames, module.edge.public_ip))}\" >> inventory"
  }
  # only output if master is edge
  provisioner "local-exec" {
    command =  "echo \"${var.master_as_edge != true ? "" : join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu", module.master.hostnames, module.master.public_ip))}\" >> inventory"
  }

  # Write other variables
  provisioner "local-exec" {
    command =  "echo \"[master:vars]\" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo \"nodes_count=${1 + var.edge_count + var.node_count} \" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo \"node_count=${var.node_count} \" >> inventory"
  }
  # If cloudflare domain is set, output that domain, otherwise output a nip.io domain (with the first edge ip)
  provisioner "local-exec" {
    command =  "echo \"domain=${ var.use_cloudflare == true ? format("%s.%s", var.cluster_prefix, var.cloudflare_domain) : format("%s.nip.io", element(concat(module.edge.public_ip, module.master.public_ip), 0))}\" >> inventory"
  }
  provisioner "local-exec" {
    command =  "echo \"use_cloudflare=${var.use_cloudflare}\" >> inventory"
  }
}
