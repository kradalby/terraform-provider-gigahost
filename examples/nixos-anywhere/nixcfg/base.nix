# Host config shared by every machine for the install. Per-host values come from
# the nixos-anywhere module's special_args. disk-config.nix is install-only;
# when adopting into your own flake you keep hardware-configuration.nix (+ the
# host's network from the host_config output) and drop disk-config.nix.
{ lib
, sshKey
, network
, hostName
, ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  users.users.root.openssh.authorizedKeys.keys = lib.optionals (sshKey != "") [ sshKey ];

  # Static networking: Gigahost has no DHCP/RA, so an unconfigured box is
  # unreachable after reboot. Gateways are on-link; NixOS adds the link route.
  networking = lib.mkMerge [
    { hostName = hostName; }
    (lib.mkIf (network != null) {
      useDHCP = false;
      interfaces.${network.interface} = {
        ipv4.addresses = [{ address = network.ipv4Address; prefixLength = network.ipv4Prefix; }];
        ipv6.addresses = [{ address = network.ipv6Address; prefixLength = network.ipv6Prefix; }];
      };
      defaultGateway = { address = network.ipv4Gateway; interface = network.interface; };
      defaultGateway6 = { address = network.ipv6Gateway; interface = network.interface; };
      nameservers = [ "1.1.1.1" "1.0.0.1" ];
    })
  ];

  system.stateVersion = "25.05";
}
