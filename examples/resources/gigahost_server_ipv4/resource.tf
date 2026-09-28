resource "gigahost_server" "web" {
  type = "value"
  size = "2c-4gb-40gb"
  os   = "debian-12"
}

# Order two additional routed (l3) IPv4 addresses.
resource "gigahost_server_ipv4" "extra" {
  count     = 2
  server_id = gigahost_server.web.id
  type      = "l3"

  # The Gigahost API cannot release an IP, so destroy keeps the address
  # allocated and only drops it from state (with a warning). Use
  # deletion_policy = "error" to refuse destroy instead.
  deletion_policy = "retain"
}

# Each ordered IP exposes its id, ready to wire into reverse DNS.
resource "gigahost_server_rdns" "extra" {
  count     = 2
  server_id = gigahost_server.web.id
  ip_id     = gigahost_server_ipv4.extra[count.index].id
  dns       = "node${count.index}.example.com"
}
