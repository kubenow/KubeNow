variable cluster_prefix {}
variable ssh_user {}
variable domain {}

variable master_as_edge {}

variable master_hostnames {
  type = "list"
}

variable master_public_ip {
  type = "list"
}

variable master_private_ip {
  type = "list"
}

variable edge_count {}

variable edge_hostnames {
  type = "list"
}

variable edge_public_ip {
  type = "list"
}

variable edge_private_ip {
  type = "list"
}

variable node_count {}

variable node_hostnames {
  type = "list"
}

variable node_public_ip {
  type = "list"
}

variable node_private_ip {
  type = "list"
}

variable glusternode_count {}
variable gluster_volumetype {}
variable extra_disk_device {}

variable inventory_template_file {
  default = "inventory-openshift-template"
}

variable inventory_output_file {
  default = "inventory-openshift"
}

## Generates a list of hostnames (azurerm_virtual_machine does not output them)
#data "null_data_source" "node_hostnames" {
#
#  inputs = {
#    hostname = "${split(",", join(",",var.node_private_ip ) ) }"
#  }
#}

# Generate inventory from template file
data "template_file" "inventory" {
  template = "${file("${path.root}/../${ var.inventory_template_file }")}"

  vars {
    masters                  = "${join("\n",formatlist("%s openshift_public_ip=%s", var.master_hostnames , var.master_public_ip))}"
    nodes                    = "${join("\n",formatlist("%s openshift_node_labels=\"{'\"'region'\"': '\"'infra'\"','\"'zone'\"': '\"'default'\"'}\" openshift_schedulable=true", var.node_hostnames))}"
    edges
    ansible_ssh_user         = "${var.ssh_user}"
    master-hostname-private  = "${var.master_hostnames[0]}"
    master_hostname_public   = "${var.domain}"
    master_default_subdomain = "${var.domain}"
  }
}

resource "null_resource" "local" {
  # Trigger rewrite of inventory, uuid() generates a random string everytime it is called
  triggers {
    uuid = "${uuid()}"
  }

  triggers {
    template = "${data.template_file.inventory.rendered}"
  }

  provisioner "local-exec" {
    command = "echo -e '${data.template_file.inventory.rendered}' > \"${path.root}/../${var.inventory_output_file}\""
  }
}
