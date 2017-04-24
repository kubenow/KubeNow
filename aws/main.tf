# Cluster settings
variable cluster_prefix {}
variable KubeNow_image {}
variable kubeadm_token {}

variable aws_access_key_id {}
variable aws_secret_access_key {}
variable aws_region {}
variable availability_zone {}

variable ssh_user { default = "ubuntu" }
variable ssh_key {}

# Cloudflare settings
variable cloudflare_email { default="nothing" }
variable cloudflare_token { default="nothing" }
variable cloudflare_domain { default="" }

# Master settings
variable master_count { default = 1}
variable master_instance_type {}
variable master_disk_size {}
variable master_is_edge { default = "true" }

# Nodes settings
variable node_count {}
variable node_instance_type {}
variable node_disk_size {}

# Edges settings
variable edge_count {}
variable edge_instance_type {}
variable edge_disk_size {}

# Gluster settings
variable glusternode_count {default = 0}
variable glusternode_instance_type {}
variable glusternode_disk_size {}

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

# Lookup image-id of kubenow-image
data "aws_ami" "kubenow" {
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.KubeNow_image}"]
  } 
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "master" {
  node_labels = "${var.master_is_edge ? "role=master,role=edge" : "role=master" }"
  node_taints = ""
  disk_size = "${var.master_disk_size}"
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-master"
  count = "${var.master_count}"
  instance_type = "${var.master_instance_type}"
  image_id = "${data.aws_ami.kubenow.id}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  ssh_user = "${var.ssh_user}"
  subnet_id = "${module.vpc.subnet_id}"
  security_group_id = "${module.vpc.security_group_id}"
  availability_zone = "${var.availability_zone}"  
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file = "bootstrap/master.sh"
  master_ip = ""
}

module "edge" {
  node_labels = "role=edge"
  node_taints = ""
  disk_size = "${var.edge_disk_size}"
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-edge"
  count = "${var.edge_count}"
  instance_type = "${var.edge_instance_type}"
  image_id = "${data.aws_ami.kubenow.id}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  ssh_user = "${var.ssh_user}"
  subnet_id = "${module.vpc.subnet_id}"
  security_group_id = "${module.vpc.security_group_id}"
  availability_zone = "${var.availability_zone}"  
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file = "bootstrap/node.sh"
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}


module "node" {
  node_labels = "role=node"
  node_taints = ""
  disk_size = "${var.node_disk_size}"
  extra_disk_size = "0"
  
  source = "./node"
  name_prefix = "${var.cluster_prefix}-node"
  count = "${var.node_count}"
  instance_type = "${var.node_instance_type}"
  image_id = "${data.aws_ami.kubenow.id}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  ssh_user = "${var.ssh_user}"
  subnet_id = "${module.vpc.subnet_id}"
  security_group_id = "${module.vpc.security_group_id}"
  availability_zone = "${var.availability_zone}"  
  kubeadm_token = "${var.kubeadm_token}"
  bootstrap_file = "bootstrap/node.sh"
  master_ip = "${element(module.master.local_ip_v4, 0)}"
}

module "glusternode" {
  node_labels = "storagenode=glusterfs"
  node_taints = "dedicated=fileserver:NoSchedule"
  disk_size = "${var.glusternode_disk_size}"
  extra_disk_size = "200"

  source = "./node"
  name_prefix = "${var.cluster_prefix}-glusternode"
  count = "${var.glusternode_count}"
  instance_type = "${var.glusternode_instance_type}"
  image_id = "${data.aws_ami.kubenow.id}"
  ssh_keypair_name = "${module.keypair.keypair_name}"
  ssh_user = "${var.ssh_user}"
  subnet_id = "${module.vpc.subnet_id}"
  security_group_id = "${module.vpc.security_group_id}"
  availability_zone = "${var.availability_zone}"  
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
