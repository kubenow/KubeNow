variable name_prefix {}
variable public_key {}

resource "openstack_compute_keypair_v2" "main" {
  name = "${var.name_prefix}-keypair"
  public_key = "${file(var.public_key)}"
}

output "keypair_name" {
  value = "${openstack_compute_keypair_v2.main.name}"
}
