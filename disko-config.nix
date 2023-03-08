{ lib, disk ? "/dev/vda", keyFile ? null, ... }: {
  disk = {
    vda = {
      type = "disk";
      device = disk;
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            type = "partition";
            name = "ESP";
            start = "1MiB";
            end = "512MiB";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "defaults"
              ];
            };
          }
          {
            type = "partition";
            name = "luks";
            start = "512MiB";
            end = "100%";
            content = {
              type = "luks";
              name = "crypted";
              keyFile = keyFile; # Only use keyFile to set password in initial installation
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                subvolumes = {
                  # Subvolume name is different from mountpoint
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                    postCreateHook = ''
                      mount -t btrfs /dev/mapper/enc /mnt
                      btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
                      umount /mnt
                    '';
                  };
                  # Mountpoints inferred from subvolume name
                  "/home" = {
                    mountOptions = [ "compress=zstd" "noatime" "nodiratime" "discard" ];
                  };
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" "nodiratime" "discard" ];
                  };
                  "/persist" = {
                    mountOptions = [ "compress=zstd" "noatime" "nodiratime" "discard" ];
                  };
                  "/log" = {
                    mountpoint = "/var/log"
                    mountOptions = [ "compress=zstd" "noatime" "nodiratime" "discard" ];
                  };
                  "/swap" = {
                    mountOptions = [ "noatime" ];
                    # postCreateHook = ''
                    #   btrfs filesystem mkswapfile --size ${memory} /mnt/swap/swapfile
                    #   swapon /mnt/swap/swapfile
                    # '';
                  };
                };
              };
            };
          }
        ];
      };
    };
  };
}
