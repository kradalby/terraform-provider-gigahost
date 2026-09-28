# Look up a server by hostname (or by id).
data "gigahost_server" "example" {
  hostname = "web01"
}

output "server_ip" {
  value = data.gigahost_server.example.primary_ip
}

# The ips list carries the IP and subnet IDs needed by
# gigahost_server_rdns and gigahost_bgp_session.
output "first_ip_id" {
  value = data.gigahost_server.example.ips[0].id
}
