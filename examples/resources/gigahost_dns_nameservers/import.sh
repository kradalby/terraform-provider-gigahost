# Find the zone ID (or use the zone name directly):
#   gigahost dns zones list
# NOTE: the nameservers attribute cannot be read back from the API after import.
# The first apply after import will re-push the nameservers configured in your
# Terraform configuration to the registrar.
terraform import gigahost_dns_nameservers.example ZONE_ID
# ...or import by zone name:
terraform import gigahost_dns_nameservers.example example.no
