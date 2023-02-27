{ disks ? [ "/dev/nvme0n1" ], ... }: {
  disk = {
    nvme0n1 = {
      type = "disk";
      device = builtins.elemAt disks 0;
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
              #keyFile = "/tmp/secret.key";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                subvolumes = {
                  # Subvolume name is different from mountpoint
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                    postCreateHook = "btrfs subvolume snapshot -r /root /root-blank"
                  };
                  # Mountpoints inferred from subvolume name
                  "/home" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/log" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/swap" = {
                    mountOptions = [ "noatime" ];
                    postCreateHook = ''
                      btrfs filesystem mkswapfile --size 32G /swap/swapfile
                      swapon /swap/swapfile
                    ''
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
