variable name_prefix {}
variable public_key {}

resource "random_id" "suffix" {
  byte_length = 12
}

resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.name_prefix}-keypair-${random_id.suffix.hex}"
  public_key = "${file(var.public_key)}"
}

output "keypair_name" {
  value = "${openstack_compute_keypair_v2.main.name}"
}
