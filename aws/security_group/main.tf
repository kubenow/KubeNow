variable name_prefix {}
variable vpc_id {}

resource "aws_security_group" "main" {
  name        = "${var.name_prefix}"
  description = "kubenow default security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22            # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80            # HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443           # HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0    # Allow ALL internal (self)
    to_port   = 0
    protocol  = -1
    self      = true
  }

  egress {
    from_port   = 0             # Allow ALL outbound
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "id" {
  value = ["${aws_security_group.main.id}"]
}
