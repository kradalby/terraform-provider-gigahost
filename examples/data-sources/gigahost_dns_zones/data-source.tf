data "gigahost_dns_zones" "all" {}

output "zone_names" {
  value = [for z in data.gigahost_dns_zones.all.zones : z.name]
}
