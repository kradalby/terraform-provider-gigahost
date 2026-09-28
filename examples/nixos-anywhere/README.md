# NixOS on Gigahost via nixos-anywhere

Deploy Debian and convert it to NixOS with `nixos-anywhere`
(kexec → disko → install → reboot). One server block and one deploy block,
`for_each` over a `machines` map, so 1..N hosts share the same config.

## Before you start

- **This costs money.** Every entry in `machines` deploys a real, hourly-billed
  server. `var.type` defaults to `performance`, which is not the cheapest tier.
  Run `tofu destroy` when you are finished; nothing here cleans up by itself.
- **Nix must be installed on the machine running tofu.** `build_on_remote` is
  `false`, so the closure is built locally and copied over.
- OpenTofu 1.6 or newer, or Terraform.
- `machines` and `ssh_key_name` have no defaults; set both.
- **Your SSH private key is read into Terraform state in cleartext**, because
  `nixos-anywhere` needs it to reach the target. Use encrypted remote state, or
  a throwaway key you rotate afterwards.

```hcl
module "nixos" {
  source       = "github.com/kradalby/terraform-provider-gigahost//examples/nixos-anywhere"
  ssh_key_name = "laptop"            # an SSH key already on the account
  machines = {
    web = {}                         # defaults: performance / 2c-4gb-40gb
    db  = { size = "4c-8gb-80gb" }
  }
}
```

```sh
export GIGAHOST_TOKEN=...
tofu init && tofu apply
```

Add a machine = add a map entry. Every machine installs the single
`nixcfg/nixosConfigurations.gigahost`; per-host values (hostname, static
network, key) are passed at install via the module's `special_args`.

## Networking

Gigahost is static-only (no DHCP/RA). The gateways (`.1` of the /24, `::1` of
the /118) are derived from each assigned address and baked into NixOS so the box
stays reachable across reboots. The stock nixos-images kexec installer restores
this on-link network across kexec, so no kexec flags are needed. The
all-in-one module must be `>= 1.11.0` (older builds an unusable flake URL).

## Adopting into your own flake

disko only runs at first install (`nixcfg/disk-config.nix`). The installed box
needs no disko — `nixcfg/hardware-configuration.nix` is disko-free and is what
you keep.

Terraform emits a ready per-host file (disko-free, grow enabled, IPs filled):

```sh
tofu output -json host_config | jq -r '.web' > machines/web/hardware-configuration.nix
```

Import it from your host config and rebuild:

```sh
nixos-rebuild switch --flake .#web --target-host root@<ip>
```

To install your own config from the start instead of `nixcfg/`, point
`var.flake` at your flake (exposing `nixosConfigurations.<host>` or adjust the
attr in `main.tf`).

## Notes

- `build_on_remote = false` builds locally and copies the closure; flip to build
  on the target.
