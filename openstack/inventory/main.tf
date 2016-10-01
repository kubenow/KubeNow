# Inspired by: https://rsmitty.github.io/Terraform-Ansible-Kubernetes/
variable master_inventory {}
variable node_inventory {}
variable etcd_inventory {}

resource "null_resource" "generate-inventory" {

  # Master entries
  provisioner "local-exec" {
    command =  "echo \"[kube-master]\" > ../kargo/inventory/inventory.cfg"
  }
  provisioner "local-exec" {
    command =  "echo \"${var.master_inventory}\" >> ../kargo/inventory/inventory.cfg"
  }

  # Node entries
  provisioner "local-exec" {
    command =  "echo \"\n[kube-node]\" >> ../kargo/inventory/inventory.cfg"
  }
  provisioner "local-exec" {
    command =  "echo \"${var.node_inventory}\" >> ../kargo/inventory/inventory.cfg"
  }

  # Master entries
  provisioner "local-exec" {
    command =  "echo \"\n[etcd]\" >> ../kargo/inventory/inventory.cfg"
  }
  provisioner "local-exec" {
    command =  "echo \"${var.etcd_inventory}\" >> ../kargo/inventory/inventory.cfg"
  }

  # Children entry
  provisioner "local-exec" {
    command =  "echo \"\n[k8s-cluster:children]\nkube-node\nkube-master\" >> ../kargo/inventory/inventory.cfg"
  }

}
