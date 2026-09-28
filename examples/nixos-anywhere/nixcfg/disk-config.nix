# Partition layout, used ONLY at first install (nixos-anywhere runs the disko
# script). enableConfig=false so disko provides just the partitioner; the
# resulting fileSystems + bootloader are declared in hardware-configuration.nix,
# which therefore needs no disko and is safe to copy into your own flake.
{
  disko.enableConfig = false;
  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # GRUB core for BIOS; not a /boot filesystem
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
