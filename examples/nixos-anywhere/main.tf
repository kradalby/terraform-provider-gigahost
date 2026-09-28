provider "gigahost" {} # token from GIGAHOST_TOKEN

# Existing account key: .id injected into the bootstrap Debian, .public_key
# baked into NixOS. Named once here.
data "gigahost_ssh_key" "this" {
  name = var.ssh_key_name
}

# One server per machines entry (key = hostname).
resource "gigahost_server" "this" {
  for_each = var.machines

  hostname = each.key
  type     = each.value.type
  size     = each.value.size
  os       = "debian-12"
  region   = "sfj" # only region offered
  ssh_keys = [data.gigahost_ssh_key.this.id]
}

locals {
  # path: pins this exact dir as the flake; without it nix walks up to the
  # repo's own flake. Override var.flake with any flake ref (e.g. github:you/cfg).
  flake = coalesce(var.flake, "path:${abspath("${path.module}/nixcfg")}")
  priv  = file(pathexpand(var.ssh_private_key_path))

  # Static network per machine. Gigahost has no DHCP/RA; gateways are .1 of the
  # /24 and ::1 of the /118, derived from each assigned address.
  network = {
    for h, s in gigahost_server.this : h => {
      interface   = "ens18"
      ipv4Address = s.ip
      ipv4Prefix  = 24
      ipv4Gateway = cidrhost("${s.ip}/24", 1)
      ipv6Address = s.ipv6
      ipv6Prefix  = 118
      ipv6Gateway = cidrhost("${s.ipv6}/118", 1)
    }
  }
}

# nixos-anywhere per machine: kexec -> disko -> install -> reboot. Every machine
# reuses nixosConfigurations.gigahost; per-host values arrive via special_args.
module "deploy" {
  source   = "github.com/nix-community/nixos-anywhere//terraform/all-in-one?ref=1.13.0"
  for_each = gigahost_server.this

  nixos_system_attr      = "${local.flake}#nixosConfigurations.gigahost.config.system.build.toplevel"
  nixos_partitioner_attr = "${local.flake}#nixosConfigurations.gigahost.config.system.build.diskoScript"

  target_host = each.value.ip
  instance_id = each.value.id # rebuild when the server is replaced

  special_args = {
    sshKey   = data.gigahost_ssh_key.this.public_key
    network  = local.network[each.key]
    hostName = each.key
  }

  install_ssh_key    = local.priv
  deployment_ssh_key = local.priv
  build_on_remote    = false
}
