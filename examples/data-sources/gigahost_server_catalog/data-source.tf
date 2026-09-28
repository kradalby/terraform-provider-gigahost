# The full deploy catalog: every tier, product, and region.
data "gigahost_server_catalog" "all" {}

output "product_names" {
  value = flatten([for t in data.gigahost_server_catalog.all.tiers : [for p in t.products : p.name]])
}
