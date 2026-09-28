# Find the zone ID and the redirect source:
#   gigahost dns zones list
#   gigahost dns redirects list --zone ZONE
# The import ID is ZONE_ID/SOURCE; the zone part also accepts the zone name.
# Use "@" as the source for the zone apex redirect.
terraform import gigahost_dns_redirect.example ZONE_ID/SOURCE
# ...or import using the zone name as the first part:
terraform import gigahost_dns_redirect.example example.no/@
