# Submit an ASN for BGP peering approval. Approval is performed out-of-band by
# Gigahost; the status attribute reflects progress.
resource "gigahost_bgp_asn" "example" {
  asn = "AS212345"
}

output "bgp_asn_status" {
  value = gigahost_bgp_asn.example.status
}
