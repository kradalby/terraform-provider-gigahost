resource "gigahost_dns_zone" "example" {
  name = "example.no"
  type = "NATIVE"
}

resource "gigahost_dns_redirect" "example" {
  zone_id    = gigahost_dns_zone.example.id
  source     = "@"
  target_url = "https://www.example.no"
}
