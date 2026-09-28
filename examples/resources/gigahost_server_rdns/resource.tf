resource "gigahost_server" "example" {
  type     = "value"
  size     = "2c-4gb-40gb"
  os       = "debian-12"
  hostname = "web01"
}

resource "gigahost_server_rdns" "example" {
  server_id = gigahost_server.example.id
  ip_id     = gigahost_server.example.primary_ip_id
  dns       = "web01.example.com"
}
