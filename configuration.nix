# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, inputs, lib, ... }:

let
  # Dynamic funny MOTD: a random fortune told by a random cow, rainbow-colored.
  funMotd = pkgs.writeShellScriptBin "fun-motd" ''
    set -u
    export PATH="${lib.makeBinPath [ pkgs.fortune pkgs.cowsay pkgs.lolcat pkgs.coreutils pkgs.gnused ]}:$PATH"
    cow=$(cowsay -l 2>/dev/null | sed '/^[[:space:]]*$/d' | shuf -n1)
    [ -z "$cow" ] && cow="default"
    fortune -s | cowsay -f "$cow" | lolcat
  '';
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Change this to your preferred hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # COSMIC desktop environment (Wayland-native).
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # NVIDIA GPU (GeForce GTX 1070 Ti, Pascal).
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # Pascal cards are not supported by the open kernel modules.
    open = false;
    # Long-lived 580 (LTSB) branch — the one for GeForce GTX 9xx–10xx.
    branch = "legacy_580";
    # Kernel modesetting; required for Wayland compositors like COSMIC.
    modesetting.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Steam (also enables 32-bit graphics, steam-hardware, and firewall rules).
  programs.steam.enable = true;

  # Enable sound with PipeWire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Zsh as the default shell, with autosuggestions and syntax highlighting.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    interactiveShellInit = ''
      # Dynamic funny MOTD — shown once per terminal (not in nested shells/panes).
      if [[ -z "''${_ZSH_FUN_MOTD_SHOWN:-}" ]]; then
        export _ZSH_FUN_MOTD_SHOWN=1
        if [[ $TERM != "dumb" ]]; then
          ${funMotd}/bin/fun-motd
        fi
      fi
    '';
  };

  # Fancy Matrix/DevOps prompt (uses Nerd Font icons).
  programs.starship = {
    enable = true;
    presets = [ "nerd-font-symbols" ];
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  # Define a user account. Don't forget to set a password with `passwd`.
  users.users.westixy = {
    isNormalUser = true;
    description = "westixy";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # Nerd fonts (icon-patched coding/terminal fonts).
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.noto
  ];

  # List packages installed in the system profile.
  environment.systemPackages = with pkgs; [
    neovim
    curl
    git
    discord
    zellij
    funMotd
    fortune
    cowsay
    lolcat
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. It should stay at the release
  # version of the first install of this system.
  system.stateVersion = "25.05";
}
