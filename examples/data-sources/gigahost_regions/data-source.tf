# List all deploy regions; same data as `gigahost deploy regions`.
data "gigahost_regions" "all" {}

output "region_slugs" {
  value = data.gigahost_regions.all.regions[*].slug
}
