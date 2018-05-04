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

variable node_count {}

variable node_hostnames {
  type    = "list"
  default = [""]
}

variable node_public_ip {
  type    = "list"
  default = [""]
}

variable node_private_ip {
  type    = "list"
  default = [""]
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
variable gluster_extra_disk_dev {}

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

  edge_hostnames  = "${split(",", length(var.edge_hostnames) == 0 ? join(",", list("")) : join(",", var.edge_hostnames))}"
  edge_public_ip  = "${split(",", length(var.edge_public_ip) == 0 ? join(",", list("")) : join(",", var.edge_public_ip))}"
  edge_private_ip = "${split(",", length(var.edge_private_ip) == 0 ? join(",", list("")) : join(",", var.edge_private_ip))}"

  # Format list of different node types
  masters    = "${join("\n",formatlist("%s ansible_host=%s ansible_user=%s", local.master_hostnames , local.master_public_ip, var.ssh_user ))}"
  nodes      = "${join("\n",formatlist("%s ansible_host=%s ansible_user=%s", local.node_hostnames , local.node_public_ip, var.ssh_user))}"
  pure_edges = "${join("\n",formatlist("%s ansible_host=%s ansible_user=%s", local.edge_hostnames , local.edge_public_ip, var.ssh_user))}"

  # Add master to edges if that is the case
  edges = "${var.master_as_edge == true ? "${format("%s\n%s", local.masters, local.pure_edges)}" : local.pure_edges}"

  nodes_count = "${1 + var.edge_count + var.node_count + var.glusternode_count}"
}

# Generate inventory from template file
data "template_file" "inventory" {
  template = "${file("${path.root}/../${ var.inventory_template }")}"

  vars {
    masters                = "${local.masters}"
    nodes                  = "${local.nodes}"
    edges                  = "${local.edges}"
    nodes_count            = "${local.nodes_count}"
    domain                 = "${var.domain}"
    gluster_extra_disk_dev = "${var.gluster_extra_disk_dev}"
    glusternode_count      = "${var.glusternode_count}"
    gluster_volumetype     = "${var.gluster_volumetype}"
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
