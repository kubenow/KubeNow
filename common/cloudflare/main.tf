variable cloudflare_email {}
variable cloudflare_token {}
variable cloudflare_domain {}

variable record_count {
  default = 0
}

variable iplist {
  type = "list"
}

variable record_names {
  type = "list"
}

variable proxied {}

# Configure the Cloudflare provider
provider "cloudflare" {
  version = "0.1.0"
  email   = "${ var.cloudflare_email }"
  token   = "${ var.cloudflare_token }"
}

# record_count is length(var.record_names) * length(var.iplist)
# with the arithmetic of / and % records with all combinations of var.iplist and var.record_names will be created
resource "cloudflare_record" "rec" {
  count   = "${ var.record_count }"
  domain  = "${ var.cloudflare_domain }"
  value   = "${ element(var.iplist, count.index / length(var.record_names) ) }"
  name    = "${ element(var.record_names, count.index % length(var.record_names) ) }"
  type    = "A"
  proxied = "${ var.proxied }"
}
