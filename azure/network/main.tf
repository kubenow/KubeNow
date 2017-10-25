variable resource_group_name {}
variable location {}
variable name_prefix {}

variable "address_space" {
  default = "10.0.0.0/16"
}

variable "subnet_prefix" {
  default = "10.0.10.0/24"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-network"
  location            = "${var.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.name_prefix}-subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${var.resource_group_name}"
  address_prefix       = "${var.subnet_prefix}"
}

output "subnet_id" {
  value = "${azurerm_subnet.subnet.id}"
}
