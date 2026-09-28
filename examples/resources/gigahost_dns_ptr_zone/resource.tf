resource "gigahost_dns_ptr_zone" "example" {
  prefix     = "185.181.63"
  ip_version = "ipv4"
  zone_name  = "63.181.185.in-addr.arpa"
}
