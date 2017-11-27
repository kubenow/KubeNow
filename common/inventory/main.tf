variable cluster_prefix {}
variable ssh_user {}
variable domain {}

variable master_as_edge {}

variable master_hostnames {
  type    = "list"
  default = [""]
}

variable master_public_ip {
  type    = "list"
  default = [""]
}

variable master_private_ip {
  type    = "list"
  default = [""]
}

variable master_labels {
  default = "{'zone': 'default'}"
}

variable node_count {}

variable node_hostnames {
  type    = "list"
  default = [""]
}

variable node_labels {
  default = "{'zone': 'default'}"
}

variable node_public_ip {
  type    = "list"
  default = [""]
}

variable node_private_ip {
  type    = "list"
  default = [""]
}

variable infra_count {}

variable infra_hostnames {
  type    = "list"
  default = [""]
}

variable infra_labels {
  default = "{'region': 'primary', 'zone': 'default'}"
}

variable infra_public_ip {
  type    = "list"
  default = [""]
}

variable infra_private_ip {
  type    = "list"
  default = [""]
}

variable bastion_count {}

variable bastion_hostnames {
  type    = "list"
  default = [""]
}

variable bastion_public_ip {
  type    = "list"
  default = [""]
}

variable bastion_private_ip {
  type    = "list"
  default = [""]
}

variable bastion_labels {
  default = ""
}

variable edge_count {}

variable edge_hostnames {
  type    = "list"
  default = [""]
}

variable edge_public_ip {
  type    = "list"
  default = [""]
}

variable edge_private_ip {
  type    = "list"
  default = [""]
}

variable glusternode_count {}
variable gluster_volumetype {}
variable extra_disk_device {}

variable inventory_template {}

variable inventory_output_file {
  default = "inventory"
}

# create variables
locals {
  master_hostnames  = "${split(",", length(var.master_hostnames) == 0 ? join(",", list("")) : join(",", var.master_hostnames))}"
  master_public_ip  = "${split(",", length(var.master_public_ip) == 0 ? join(",", list("")) : join(",", var.master_public_ip))}"
  master_private_ip = "${split(",", length(var.master_private_ip) == 0 ? join(",", list("")) : join(",", var.master_private_ip))}"

  node_hostnames  = "${split(",", length(var.node_hostnames) == 0 ? join(",", list("")) : join(",", var.node_hostnames))}"
  node_public_ip  = "${split(",", length(var.node_public_ip) == 0 ? join(",", list("")) : join(",", var.node_public_ip))}"
  node_private_ip = "${split(",", length(var.node_private_ip) == 0 ? join(",", list("")) : join(",", var.node_private_ip))}"

  bastion_hostnames = "${split(",", length(var.bastion_hostnames) == 0 ? join(",", list("")) : join(",", var.bastion_hostnames))}"
  bastion_public_ip = "${split(",", length(var.bastion_public_ip) == 0 ? join(",", list("")) : join(",", var.bastion_public_ip))}"

  infra_hostnames  = "${split(",", length(var.infra_hostnames) == 0 ? join(",", list("")) : join(",", var.infra_hostnames))}"
  infra_public_ip  = "${split(",", length(var.infra_public_ip) == 0 ? join(",", list("")) : join(",", var.infra_public_ip))}"
  infra_private_ip = "${split(",", length(var.infra_private_ip) == 0 ? join(",", list("")) : join(",", var.infra_private_ip))}"

  # Format list of different node types
  masters = "${join("\n",formatlist("%s ansible_host=%s ansible_user=%s openshift_public_ip=%s openshift_node_labels=\"'\"'\"%s\"'\"'\"", local.master_hostnames , local.master_public_ip, var.ssh_user, local.master_public_ip, var.master_labels ))}"

  nodes = "${join("\n",formatlist("%s ansible_host=%s ansible_user=%s openshift_public_ip=%s openshift_node_labels=\"'\"'\"%s\"'\"'\"", local.node_hostnames , local.node_public_ip, var.ssh_user, local.node_public_ip, var.node_labels ))}"

  infras = "${join("\n",formatlist("%s ansible_host=%s ansible_user=%s openshift_public_ip=%s openshift_node_labels=\"'\"'\"%s\"'\"'\"", local.infra_hostnames , local.infra_public_ip, var.ssh_user, local.infra_public_ip, var.infra_labels ))}"

  bastions = "${join("\n",formatlist("%s ansible_host=%s ansible_user=%s openshift_public_ip=%s openshift_node_labels=\"'\"'\"%s\"'\"'\"", local.bastion_hostnames , local.bastion_public_ip, var.ssh_user, local.bastion_public_ip, var.bastion_labels ))}"

  master_hostname_private = "${element(concat(var.master_hostnames, list("")),0)}"

}

# Generate inventory from template file
data "template_file" "inventory" {
  template = "${file("${path.root}/../${ var.inventory_template }")}"

  vars {
    masters  = "${local.masters}"
    workers  = "${local.nodes}"
    infras   = "${local.infras}"
    bastions = "${local.bastions}"

    ansible_user         = "${var.ssh_user}"
    master_hostname_public   = "${local.master_hostname_private}.${var.domain}"
    master_default_subdomain = "${var.domain}"
    master_hostname_private  = "${local.master_hostname_private}"
  }
}

# Write the template to a file
resource "null_resource" "local" {
  # Trigger rewrite of inventory, uuid() generates a random string everytime it is called
  triggers {
    uuid = "${uuid()}"
  }

  triggers {
    template = "${data.template_file.inventory.rendered}"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.inventory.rendered}\" > \"${path.root}/../${var.inventory_output_file}\""
  }
}
