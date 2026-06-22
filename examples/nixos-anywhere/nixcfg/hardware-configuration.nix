# Hardware for a Gigahost KVM VPS: BIOS, virtio-scsi, single /dev/sda. No disko
# (disko only partitions at install). Identical for every Gigahost machine, so
# copy this into your own flake's machines/<host>/. Pair it with that host's
# static network (see the `host_config` Terraform output).
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # BIOS / MBR

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "ahci"
    "sd_mod"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/disk-main-root"; # GPT label set at install
    fsType = "ext4";
    autoResize = true; # grow ext4 after the partition grows
  };
  boot.growPartition = true; # extend the partition into a resized disk on boot

  nixpkgs.hostPlatform = "x86_64-linux";
}
