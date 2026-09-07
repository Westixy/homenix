# Top-level NixOS configuration for `auberge`. This file is just the glue that
# imports the per-area modules below (plus the generated hardware config).
# See the individual files for the actual settings:
#
#   modules/boot.nix       — Limine bootloader, console font, NTFS
#   modules/system.nix     — hostname, NetworkManager, time zone, locale
#   modules/desktop.nix    — COSMIC desktop + greeter + wallpaper
#   modules/hardware.nix   — NVIDIA GPU, CUPS printing
#   modules/audio.nix      — PipeWire sound
#   modules/ollama.nix     — Ollama (local LLM server)
#   modules/gaming.nix     — Steam
#   modules/shell.nix      — Zsh, Starship, MOTD
#   modules/users.nix      — user account + sudo
#   modules/packages.nix   — system packages + fonts + genmgr
#   modules/alacritty.nix  — Alacritty terminal (Nord theme)

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/system.nix
    ./modules/desktop.nix
    ./modules/hardware.nix
    ./modules/audio.nix
    ./modules/ollama.nix
    ./modules/gaming.nix
    ./modules/shell.nix
    ./modules/users.nix
    ./modules/packages.nix
    ./modules/alacritty.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. It should stay at the release
  # version of the first install of this system.
  system.stateVersion = "26.05";
}
