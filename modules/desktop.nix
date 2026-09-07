{ config, pkgs, lib, ... }:

let
  # COSMIC wallpaper image — the same `nineish-dark-gray` artwork used on the
  # Limine boot menu. Served at a stable /etc path so the per-user RON config
  # below never points at a garbage-collectable store path.
  wallpaperPath = "/etc/wallpapers/nineish-dark-gray.png";

  # COSMIC "wallpaper on all outputs" entry (RON, read by cosmic-bg).
  cosmicWallpaperEntry = pkgs.writeText "cosmic-wallpaper-entry" ''
    (
        output: "all",
        source: Path("${wallpaperPath}"),
        filter_by_theme: true,
        rotation_frequency: 3600,
        filter_method: Lanczos,
        scaling_mode: Zoom,
        sampling_method: Alphanumeric,
    )
  '';

  # Writes the COSMIC desktop + lock-screen wallpaper config. Both are backed by
  # the same `com.system76.CosmicBackground` entity; the lock screen reads the
  # "state" copy (per-output), which cosmic-bg keeps in sync from this entry.
  applyWallpaper = pkgs.writeShellScriptBin "apply-cosmic-wallpaper" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gnused ]}:$PATH"

    wallpaper="${wallpaperPath}"
    cfg_dir="$HOME/.config/cosmic/com.system76.CosmicBackground/v1"
    state_dir="$HOME/.local/state/cosmic/com.system76.CosmicBackground/v1"

    mkdir -p "$cfg_dir" "$state_dir"
    printf 'true\n' > "$cfg_dir/same-on-all"
    install -m 0644 ${cosmicWallpaperEntry} "$cfg_dir/all"

    # Point every output's background at the same image, keeping output names.
    if [ -f "$state_dir/wallpapers" ]; then
      sed -i "s#Path(\"[^\"]*\")#Path(\"$wallpaper\")#g" "$state_dir/wallpapers"
    fi
  '';
in
{
  # COSMIC desktop environment (Wayland-native).
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # Stable system path for the wallpaper referenced by the COSMIC config above.
  environment.etc."wallpapers/nineish-dark-gray.png".source =
    pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;

  # Re-apply the COSMIC wallpaper declaratively at each login. If you'd rather
  # manage the wallpaper from COSMIC Settings, delete this block.
  systemd.user.services.cosmic-wallpaper = {
    description = "Apply COSMIC desktop and lock-screen wallpaper";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${applyWallpaper}/bin/apply-cosmic-wallpaper";
    };
  };
}
