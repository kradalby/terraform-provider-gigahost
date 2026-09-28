# PTR zones appear in the standard zone list alongside forward zones.
# Find the zone ID or arpa zone name:
#   gigahost dns zones list
terraform import gigahost_dns_ptr_zone.example ZONE_ID
# ...or import by arpa zone name:
terraform import gigahost_dns_ptr_zone.example 63.181.185.in-addr.arpa
