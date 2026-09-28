# Delegate example.no's DNS to Cloudflare while keeping the registrar
# at Gigahost. A minimum of two nameservers is required by Norid.
resource "gigahost_dns_zone" "example" {
  name = "example.no"
  type = "NATIVE"
}

resource "gigahost_dns_nameservers" "example" {
  zone_id = gigahost_dns_zone.example.id
  nameservers = [
    "ada.ns.cloudflare.com",
    "john.ns.cloudflare.com",
  ]
}
