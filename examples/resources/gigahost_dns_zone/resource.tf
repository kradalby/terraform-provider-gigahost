resource "gigahost_dns_zone" "example" {
  name = "example.no"
  type = "NATIVE"
}

output "zone_id" {
  value = gigahost_dns_zone.example.id
}
