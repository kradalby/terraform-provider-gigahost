output "ips" {
  value = { for h, s in gigahost_server.this : h => s.ip }
}

# Per-host hardware-configuration.nix (disko-free, grow, IPs filled). Copy into
# your own flake to manage the box after install, e.g.:
#   tofu output -raw host_config | ...   # single machine
#   tofu output -json host_config        # all machines
output "host_config" {
  value = {
    for h, n in local.network : h => templatefile("${path.module}/templates/host.nix.tftpl", {
      hostname    = h
      interface   = n.interface
      ipv4        = n.ipv4Address
      ipv4_prefix = n.ipv4Prefix
      ipv4_gw     = n.ipv4Gateway
      ipv6        = n.ipv6Address
      ipv6_prefix = n.ipv6Prefix
      ipv6_gw     = n.ipv6Gateway
    })
  }
}
