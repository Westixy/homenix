{ ... }:

{
  networking.hostName = "auberge"; # Change this to your preferred hostname.
  networking.networkmanager.enable = true;

  # Open the Vite dev server port (laqwiz) so other machines on the LAN can reach it.
  networking.firewall.allowedTCPPorts = [ 5173 ];

  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
}
