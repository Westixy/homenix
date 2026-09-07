{ config, pkgs, lib, ... }:

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
    settings = builtins.fromTOML (builtins.readFile ../starship.toml);
  };

  # Shell-related tools: the MOTD script plus its runtime deps (kept on PATH
  # so they can also be run directly).
  environment.systemPackages = [ funMotd pkgs.fortune pkgs.cowsay pkgs.lolcat ];
}
