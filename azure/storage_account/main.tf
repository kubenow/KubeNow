variable storage_account_name {}
variable storage_account_type {}
variable resource_group_name {}
variable location {}
variable name_prefix {}

resource "random_string" "suffix" {
  length  = 10
  lower   = true
  number  = false
  upper   = false
  special = false
}

# Generates a storage account name
data "null_data_source" "generated_name" {
  inputs = {
    # the name is created by: lower the case in "cluster-prefix", join a 10 char random string suffix, replace all chars that
    # are not a-z or 0-9, finally cut result to max 24 chars
    name = "${substr(replace(format("%s%s", lower(var.name_prefix),random_string.suffix.result), "[^a-z0-9]", ""),0,23)}"
  }
}

resource "azurerm_storage_account" "stor" {
  # create stor only if not specified in var.storage_account_name
  count               = "${var.storage_account_name == "" ? 1 : 0}"
  name                = "${data.null_data_source.generated_name.*.inputs.name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  account_type        = "${var.storage_account_type}"
}

output "name" {
  value = "${ var.storage_account_name != "" ? var.storage_account_name : data.null_data_source.generated_name.*.inputs.name }"
}
