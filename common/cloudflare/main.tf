variable cloudflare_email {}
variable cloudflare_token {}
variable cloudflare_domain {}

variable record_text {
  default = "*"
}

variable record_count {
  default = 0
}

variable iplist {
  type = "list"
}

# Configure the Cloudflare provider
provider "cloudflare" {
  email = "${ var.cloudflare_email }"
  token = "${ var.cloudflare_token }"
}

resource "cloudflare_record" "rec" {
  count  = "${ var.record_count }"
  domain = "${ var.cloudflare_domain }"
  value  = "${ element(var.iplist, count.index) }"
  name   = "${ var.record_text }"
  type   = "A"
}
