# Resolve exactly one OS — errors when zero or several match.
data "gigahost_operating_system" "debian" {
  distribution = "debian"
  release      = "12"
}

resource "gigahost_server" "web" {
  type = "value"
  size = "2c-4gb-40gb"
  os   = data.gigahost_operating_system.debian.slug
}
