resource "gigahost_bgp_asn" "example" {
  asn = "AS212345"
}

# The IP IDs for the session come from the server's ips list.
data "gigahost_server" "web" {
  hostname = "web01"
}

# Create a peering session on an approved ASN. At least one of
# ipv4_ip_id / ipv6_ip_id is required.
resource "gigahost_bgp_session" "example" {
  asn_id        = gigahost_bgp_asn.example.id
  ipv4_ip_id    = data.gigahost_server.web.ips[0].id
  redundant     = true
  default_route = true
}
