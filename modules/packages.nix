{ config, pkgs, inputs, lib, ... }:

let
  # Helper that rebuilds + switches via nh, then commits the config repo.
  genmgr = pkgs.writeShellScriptBin "genmgr" (builtins.readFile ../genmgr.sh);
in
{
  # Nerd fonts (icon-patched coding/terminal fonts).
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.noto
    nerd-fonts.gohufont
  ];

  # List packages installed in the system profile.
  environment.systemPackages = with pkgs; [
    neovim
    curl
    git
    git-lfs
    discord
    zellij
    vscodium
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    nh
    genmgr
    inkscape
    parted
    disktui
    alacritty
    vlc
  ];
}
