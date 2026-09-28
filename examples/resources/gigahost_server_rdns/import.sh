# Find the server ID and the IP ID or subnet ID:
#   gigahost servers list
#   gigahost servers ips SERVER_ID
# The import ID is SERVER_ID/IP_ID for IPv4 rDNS,
# or SERVER_ID/SUBNET_ID for IPv6 delegation.
terraform import gigahost_server_rdns.example SERVER_ID/IP_ID
# ...or for IPv6 delegation:
terraform import gigahost_server_rdns.example SERVER_ID/SUBNET_ID
