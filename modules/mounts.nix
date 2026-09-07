{ ... }:

{
  # Persistent filesystem mounts. `/dev/sda` is the whole 1.8T disk; the actual
  # Btrfs data lives on partition `/dev/sda1`. We reference it by UUID (stable
  # across reboots) rather than the bare /dev node, which can change order.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/c7a53521-0de0-41e5-bcaa-460d1a8b90b8";
    fsType = "btrfs";
  };
}
