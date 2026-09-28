# Find the zone ID and record ID:
#   gigahost dns zones list
#   gigahost dns records list --zone ZONE
# The import ID is ZONE_ID/RECORD_ID; the zone part also accepts the zone name.
terraform import gigahost_dns_record.example ZONE_ID/RECORD_ID
# ...or import using the zone name as the first part:
terraform import gigahost_dns_record.example example.no/RECORD_ID
