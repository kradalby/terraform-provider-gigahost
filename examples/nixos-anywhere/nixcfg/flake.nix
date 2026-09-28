{
  description = "NixOS base for Gigahost KVM VPS (install via nixos-anywhere)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, disko, ... }:
    {
      # One config reused by every machine; per-host values (sshKey, network,
      # hostName) come from the nixos-anywhere module's special_args. The
      # defaults keep `nix flake check` and standalone eval working.
      nixosConfigurations.gigahost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          sshKey = "";
          network = null;
          hostName = "gigahost";
        };
        modules = [
          disko.nixosModules.disko
          ./base.nix
        ];
      };
    };
}
