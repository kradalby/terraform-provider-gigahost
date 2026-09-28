data "gigahost_dns_zone" "example" {
  name = "example.no"
}

output "zone_id" {
  value = data.gigahost_dns_zone.example.id
}
