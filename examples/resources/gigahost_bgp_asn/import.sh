# Find your ASN from the BGP overview:
#   gigahost bgp show
# Both bare numeric and AS-prefixed forms are accepted.
terraform import gigahost_bgp_asn.example 212345
# ...or with AS prefix:
terraform import gigahost_bgp_asn.example AS212345
