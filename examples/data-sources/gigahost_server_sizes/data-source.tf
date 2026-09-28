# List every deployable size; same data as `gigahost deploy sizes`.
data "gigahost_server_sizes" "all" {}

data "gigahost_server_sizes" "value" {
  type = "value"
}

output "value_size_slugs" {
  value = data.gigahost_server_sizes.value.sizes[*].slug
}
