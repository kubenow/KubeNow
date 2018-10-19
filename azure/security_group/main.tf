variable name_prefix {}
variable location {}
variable resource_group_name {}

variable ingress_tcp_ports {
  type = "list"
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.name_prefix}-secgroup"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "security_rule_ingress_tcp_port" {
  count = "${length(var.ingress_tcp_ports)}"

  name                       = "${var.name_prefix}-secrule-${format("%03d", count.index)}"
  description                = "Automatically created security rule by-${var.name_prefix}"
  priority                   = "${100 + count.index}"
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "${element(var.ingress_tcp_ports, count.index)}"
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.main.name}"
}

output "id" {
  value = "${azurerm_network_security_group.main.id}"
}
