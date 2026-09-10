# Top-level NixOS configuration for `auberge` (desktop).
# Imports the per-area shared modules plus this system's hardware config and graphics.
#
# Shared modules in ../../modules/:
#   boot.nix       — Limine bootloader, console font, NTFS
#   system.nix     — NetworkManager, time zone, locale (no hostname)
#   desktop.nix    — COSMIC desktop + greeter + wallpaper
#   hardware.nix   — CUPS printing
#   audio.nix      — PipeWire sound
#   ollama.nix     — Ollama (local LLM server)
#   gaming.nix     — Steam
#   shell.nix      — Zsh, Starship, MOTD
#   users.nix      — user account + sudo
#   packages.nix   — system packages + fonts + genmgr
#   alacritty.nix  — Alacritty terminal (Nord theme)
#   mounts.nix     — persistent filesystem mounts

{ ... }:

{
  networking.hostName = "auberge";

  imports = [
    ./hardware-configuration.nix
    ./graphics.nix
    ../../modules/boot.nix
    ../../modules/system.nix
    ../../modules/desktop.nix
    ../../modules/hardware.nix
    ../../modules/audio.nix
    ../../modules/ollama.nix
    ../../modules/gaming.nix
    ../../modules/shell.nix
    ../../modules/users.nix
    ../../modules/packages.nix
    ../../modules/alacritty.nix
    ../../modules/mounts.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. It should stay at the release
  # version of the first install of this system.
  system.stateVersion = "26.05";
}