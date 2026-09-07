{ config, pkgs, lib, ... }:

{
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
}
