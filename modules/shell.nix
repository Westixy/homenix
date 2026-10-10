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

  # Nix brand palette, shared by the fzf and eza color themes.
  nixBlue = "5277c3";         # Nix snowflake blue
  nixBlueBright = "7aa2f7";   # lighter Nix blue
  nixFg = "cdd6f4";           # soft light foreground
  nixBgHighlight = "313244";  # selected-item background (dark)
in
{
  # Zsh as the default shell, with autosuggestions and syntax highlighting.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # Larger, shared, de-duplicated command history.
    histSize = 10000;
    setOptions = [
      "HIST_IGNORE_DUPS"
      "SHARE_HISTORY"
      "HIST_FCNTL_LOCK"
      "HIST_IGNORE_SPACE"
      "EXTENDED_HISTORY"
      "HIST_EXPIRE_DUPS_FIRST"
    ];

    # eza replaces ls.
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
    };

    interactiveShellInit = ''
      export NH_OS_FLAKE="$HOME/nixos"

      # Vi-style editing (Esc enters command mode; `v` edits the line in $EDITOR).
      bindkey -v
      autoload -Uz edit-command-line && zle -N edit-command-line
      bindkey -M vicmd 'v' edit-command-line

      # Fuzzy finder: Ctrl-R (history), Ctrl-T (files), Alt-C (cd), **<TAB> completion.
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      # Color themes — Nix blue accents.
      export FZF_DEFAULT_OPTS="--color=fg:#${nixFg},fg+:#ffffff,hl:#${nixBlueBright},hl+:#${nixBlueBright},prompt:#${nixBlue},pointer:#${nixBlue},marker:#${nixBlue},header:#${nixBlue},info:#${nixBlueBright},bg+:#${nixBgHighlight},border:#${nixBlue}"
      export EZA_COLORS="di=1;34:ln=1;36:ex=1;32:or=31:pi=35:so=35"

      # Dynamic funny MOTD — shown once per terminal (not in nested shells/panes).
      if [[ -z "''${_ZSH_FUN_MOTD_SHOWN:-}" ]]; then
        export _ZSH_FUN_MOTD_SHOWN=1
        if [[ $TERM != "dumb" ]]; then
          ${funMotd}/bin/fun-motd
        fi
      fi
    '';
  };

  # Neovim as the default editor (git commit, sudoedit, edit-command-line, ...).
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
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
