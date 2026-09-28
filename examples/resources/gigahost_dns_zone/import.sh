# Find the zone ID (or use the zone name directly):
#   gigahost dns zones list
terraform import gigahost_dns_zone.example ZONE_ID
# ...or import by zone name:
terraform import gigahost_dns_zone.example example.no
