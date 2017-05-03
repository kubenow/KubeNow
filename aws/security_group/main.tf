variable name_prefix {}
variable vpc_id {}

resource "aws_security_group" "main" {
  name = "${var.name_prefix}"
  description = "kubenow default security group"
  vpc_id = "${var.vpc_id}"

  ingress { # SSH
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # HTTP
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # HTTPS
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress { # Allow ALL internal (self)
    from_port = 0
    to_port = 0
    protocol = -1
    self = true
  }
  
  egress { # Allow ALL outbound
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "id" {
  value = ["${aws_security_group.main.id}"]
}
