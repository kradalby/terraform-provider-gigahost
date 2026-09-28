# Look up a region by slug, name, or short name.
data "gigahost_region" "sfj" {
  name = "sfj"
}

resource "gigahost_server" "web" {
  type   = "value"
  size   = "2c-4gb-40gb"
  os     = "debian-12"
  region = data.gigahost_region.sfj.slug
}
