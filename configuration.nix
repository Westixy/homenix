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

  # Gohu 8x14 bitmap font, converted to Limine's raw CP437 format.
  gohuLimineFont = pkgs.runCommand "gohu-limine-font"
    {
      nativeBuildInputs = [ pkgs.python3 ];
    } ''
    ${pkgs.python3}/bin/python3 ${./gohu-to-limine.py} \
      ${pkgs.gohufont.src}/gohufont-14.bdf $out
  '';

  # Helper that rebuilds + switches via nh, then commits the config repo.
  genmgr = pkgs.writeShellScriptBin "genmgr" (builtins.readFile ./genmgr.sh);

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
  imports =
    [
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader: Limine (UEFI), Gohu font, binary-black wallpaper.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 30;
  boot.loader.limine = {
    enable = true;
    # Keep only the latest 10 generations in the boot menu. Old boot files
    # (kernel/initrd) are pruned from the ESP automatically at every switch.
    maxGenerations = 10;
    # Custom Gohu 8x14 font (Limine has no `term_font` option, so inject it
    # via extraConfig and ship the file via additionalFiles).
    extraConfig = ''
      term_font: boot():/limine/gohu-14.raw
      term_font_size: 8x14
    '';
    additionalFiles."gohu-14.raw" = gohuLimineFont;
    style = {
      wallpapers = [ pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath ];
      wallpaperStyle = "centered";
      interface = {
        branding = "NixOS";
        brandingColor = "89B4FA"; # Catppuccin blue
      };
      graphicalTerminal = {
        font.scale = "1x1";
        foreground = "CDD6F4"; # Catppuccin text
        palette = "1E1E2E;F38BA8;A6E3A1;F9E2AF;89B4FA;CBA6F7;94E2D5;6C7086";
        brightPalette = "313244;F38BA8;A6E3A1;F9E2AF;89B4FA;CBA6F7;94E2D5;CDD6F4";
      };
    };
  };

  # NTFS read/write support (ntfs-3g via FUSE).
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "auberge"; # Change this to your preferred hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Gohu 8x14 bitmap font on the virtual consoles (TTYs), matching the Limine
  # boot menu. gohufont ships ready-made PSF console fonts, so we point
  # console.font straight at the regular 8x14 PSF file. Apply it in the initrd
  # too so early boot messages also render in Gohu.
  console.font = "${pkgs.gohufont}/share/consolefonts/gohufont-14.psf";
  console.earlySetup = true;

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

  # Ollama — local LLM server. Vulkan backend so it uses the NVIDIA GPU:
  # nixpkgs' CUDA build targets sm_75+ only, which excludes this Pascal card.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    environmentVariables = {
      # Raise the serving context window from Ollama's 4096 default.
      # 8192 keeps both 7–8B models fully resident in 8 GiB of VRAM.
      OLLAMA_CONTEXT_LENGTH = "8192";
    };
  };

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
      export NH_OS_FLAKE="$HOME/nixos"
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

  # Allow westixy to run sudo without a password prompt.
  security.sudo.extraRules = [
    {
      users = [ "westixy" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

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

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

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
    funMotd
    fortune
    cowsay
    lolcat
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    nh
    genmgr
    inkscape
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. It should stay at the release
  # version of the first install of this system.
  system.stateVersion = "26.05";
}
