resource "gigahost_server" "web" {
  type     = "value"
  size     = "2c-4gb-40gb"
  os       = "debian-12"
  hostname = "web01"
}

# Take a point-in-time snapshot of the server. Destroying this resource deletes
# the snapshot. The name is stored as the snapshot's display name.
resource "gigahost_server_snapshot" "checkpoint" {
  server_id = gigahost_server.web.id
  name      = "pre-change-checkpoint"
}
