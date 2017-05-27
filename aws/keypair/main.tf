variable name_prefix {}
variable public_key {}

resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}-keypair"
  public_key = "${file(var.public_key)}"
}

output "keypair_name" {
  value = "${aws_key_pair.main.key_name}"
}
