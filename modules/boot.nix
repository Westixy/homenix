{ config, pkgs, lib, ... }:

let
  # Gohu 8x14 bitmap font, converted to Limine's raw CP437 format.
  gohuLimineFont = pkgs.runCommand "gohu-limine-font"
    {
      nativeBuildInputs = [ pkgs.python3 ];
    } ''
    ${pkgs.python3}/bin/python3 ${../gohu-to-limine.py} \
      ${pkgs.gohufont.src}/gohufont-14.bdf $out
  '';
in
{
  # Bootloader: Limine (UEFI), Gohu font, binary-black wallpaper.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 30;
  boot.loader.limine = {
    enable = true;
    efiInstallAsRemovable = true;
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

  # Filesystems made available in the initrd and for mounting at boot.
  # NTFS uses ntfs-3g via FUSE; Btrfs is available for snapshots/compression.
  boot.supportedFilesystems = [ "ntfs" "btrfs" ];

  # Gohu 8x14 bitmap font on the virtual consoles (TTYs), matching the Limine
  # boot menu. gohufont ships ready-made PSF console fonts, so we point
  # console.font straight at the regular 8x14 PSF file. Apply it in the initrd
  # too so early boot messages also render in Gohu.
  console.font = "${pkgs.gohufont}/share/consolefonts/gohufont-14.psf";
  console.earlySetup = true;
}
