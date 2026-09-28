resource "gigahost_dns_zone" "example" {
  name = "example.no"
  type = "NATIVE"
}

resource "gigahost_dns_dnssec" "example" {
  zone_id = gigahost_dns_zone.example.id
  enabled = true
}
