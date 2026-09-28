# Pick a size by hardware criteria instead of hardcoding a slug.
data "gigahost_server_size" "small" {
  memory_gb = 4
  cheapest  = true
}

resource "gigahost_server" "web" {
  type = data.gigahost_server_size.small.type
  size = data.gigahost_server_size.small.slug
  os   = "debian-12"
}
