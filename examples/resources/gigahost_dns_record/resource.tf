resource "gigahost_dns_zone" "example" {
  name = "example.no"
  type = "NATIVE"
}

resource "gigahost_dns_record" "www" {
  zone_id = gigahost_dns_zone.example.id
  name    = "www"
  type    = "A"
  value   = "185.125.168.166"
  ttl     = 3600
}

resource "gigahost_dns_record" "mx" {
  zone_id  = gigahost_dns_zone.example.id
  name     = "@"
  type     = "MX"
  value    = "mail.example.no"
  priority = 10
  ttl      = 3600
}
