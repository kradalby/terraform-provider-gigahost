resource "gigahost_server" "example" {
  type     = "value"
  size     = "2c-4gb-40gb"
  os       = "debian-12"
  hostname = "web01"
}

# Set a descriptive label on the server. Destroying this resource resets the
# label to the server's auto-generated hostname.
resource "gigahost_server_name" "example" {
  server_id = gigahost_server.example.id
  name      = "my-web-server"
}
