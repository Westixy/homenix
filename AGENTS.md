# AGENTS.md

Context for AI coding agents working on this repo. Read this **before** making
any changes so a new task can start fast without re-deriving the environment.

## TL;DR — quick facts

| | |
| --- | --- |
| **What this is** | NixOS flake config for `westixy`'s desktop (gaming + local AI), hostname `nixos` |
| **NixOS release** | 26.05 (`nixos-26.05`), `x86_64-linux` |
| **Repo path** | `~/nixos` (flake `nixosConfigurations.nixos`) |
| **Git** | remote `git@github.com:Westixy/homenix.git`, branch `master` |
| **User** | `westixy` (groups: `wheel`, `networkmanager`), shell `zsh` |
| **Desktop** | COSMIC + `cosmic-greeter` (Wayland) |
| **GPU** | NVIDIA GTX 1070 Ti, `legacy_580`, `open = false`, modesetting |
| **Bootloader** | Limine (UEFI), Gohu 8x14 font, `nineish-dark-gray` wallpaper, Catppuccin theme |
| **Sudo** | passwordless for `westixy` (`NOPASSWD: ALL`) — already active |
| **stateVersion** | `"25.05"` (do not change) |

## Repository layout

```
.
├── flake.nix                  # inputs + nixosConfigurations.nixos
├── flake.lock                 # pinned input versions (commit on input changes)
├── configuration.nix          # the whole system config (everything lives here)
├── hardware-configuration.nix # GENERATED — do not hand-edit
├── genmgr.sh                  # build + switch + commit helper (installed as `genmgr`)
├── gohu-to-limine.py          # converts Gohu BDF -> Limine raw CP437 font
├── starship.toml              # Starship prompt theme
├── README.md                  # human-oriented overview
└── .gitignore
```

## Core commands

```sh
# Rebuild + switch into the current config
nh os switch ~/nixos

# Build + switch + git-commit the changes (the normal workflow)
genmgr
#   - prompts for an optional commit note (interactive/TTY only)
#   - commit message: "nixos: gen <N> at <timestamp> - <note>"

# Agent-friendly genmgr variants:
genmgr --build-only                 # validate the config builds (no switch, no commit)
genmgr --note "add foo"             # non-interactive note, then switch + commit
genmgr --no-commit                  # switch without committing
genmgr --help                       # full usage

# Lower-level dry-run (equivalent to `genmgr --build-only`)
nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel

# Evaluate a single option to check a value
nix eval .#nixosConfigurations.nixos.config.system.stateVersion

# Verify passwordless sudo is working
sudo -n true
```

> `NH_OS_FLAKE` is exported to `$HOME/nixos` in `configuration.nix`, so `nh`
> and `genmgr` know the flake path. `genmgr` env overrides: `FLAKE_PATH`,
> `HOST` (defaults to `$(hostname)`).


## Configuration conventions

- `configuration.nix` signature is `{ config, pkgs, inputs, lib, ... }:` and has
  a `let ... in` block at the top for derived values.
- `inputs` is passed via `specialArgs` in `flake.nix` — that's how
  `inputs.zen-browser` is referenced (Zen Browser is not in nixpkgs anymore).
- Helper scripts use `pkgs.writeShellScriptBin`, then get added to
  `environment.systemPackages` (see `funMotd`, `genmgr`).
- Paths referenced inside scripts should be interpolated with `${...}` so they
  resolve to store paths at build time; use `${lib.makeBinPath [...]}` for PATH.
- Single source of truth for repeated values is a `let` binding (e.g.
  `wallpaperPath`, `cosmicWallpaperEntry`).
- `hardware-configuration.nix` is generated. If hardware changes, regenerate:
  `sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix`.

## Current system snapshot

- **Boot**: Limine, custom Gohu font (`term_font: boot():/limine/gohu-14.raw`),
  `nineish-dark-gray` wallpaper, Catppuccin palette.
- **Networking**: NetworkManager, `hostName = "nixos"`.
- **GPU**: NVIDIA `legacy_580` branch, closed modules (`open = false`),
  modesetting enabled (required for Wayland/COSMIC).
- **Ollama**: `ollama-vulkan` (Vulkan backend — the nixpkgs CUDA build targets
  `sm_75+`, which excludes this Pascal card), `OLLAMA_CONTEXT_LENGTH = "8192"`.
- **Audio**: PipeWire (ALSA + Pulse compat), `rtkit`.
- **Shell**: Zsh default, autosuggestions + syntax highlighting, `fun-motd`
  (random fortune/cow/lolcat) shown once per terminal. Starship prompt from
  `starship.toml`.
- **Packages** (`environment.systemPackages`): neovim, curl, git, git-lfs,
  discord, zellij, vscodium, fortune/cowsay/lolcat, zen-browser (community
  flake), nh, genmgr, funMotd.
- **Fonts**: Nerd Fonts (JetBrains Mono, Fira Code, Hack, Noto, Gohu).
- **Services**: Steam, CUPS printing, NTFS (`ntfs` filesystem), `allowUnfree`.

## Gotchas & important details

1. **COSMIC wallpaper is not a NixOS module option.** COSMIC reads RON config
   files, not nix options. The wallpaper is applied by the `cosmic-wallpaper`
   systemd *user* service (`oneshot`, `WantedBy=default.target`) which writes:
   - `~/.config/cosmic/com.system76.CosmicBackground/v1/{same-on-all,all}`
   - `~/.local/state/cosmic/com.system76.CosmicBackground/v1/wallpapers` (per-output)

   Desktop **and** lock screen share the same `com.system76.CosmicBackground`
   entity — the lock screen reads the "state" copy that `cosmic-bg` syncs from
   the `all` entry. To change the wallpaper, edit `wallpaperPath` /
   `cosmicWallpaperEntry` in `configuration.nix`.

2. **Use a stable `/etc` path for the wallpaper**, not a `/nix/store` path — a
   store path would break after `nix-collect-garbage`. Currently
   `/etc/wallpapers/nineish-dark-gray.png` (via `environment.etc`).

3. **Hostname consistency**: `hostName = "nixos"` must match the
   `nixosConfigurations.nixos` key in `flake.nix` and `genmgr`'s `HOST` default.
   If you rename the host, update all three.

4. **Passwordless sudo** is active. A *fresh* machine's first switch still needs
   a password because the `security.sudo.extraRules` rule only lands after the
   first successful switch.

5. **Dirty git tree warnings** from `nix` are harmless (it prints
   `warning: Git tree ... is dirty` when there are uncommitted changes).
   `genmgr` commits everything (`git add -A`) at the end of a switch.

6. **`stateVersion` must stay `"25.05"`** — it marks the first-install release
   and controls defaults for stateful data. Never bump it casually.

7. **`genmgr.sh` is the source of truth** for the `genmgr` binary; it's baked in
   via `pkgs.writeShellScriptBin "genmgr" (builtins.readFile ./genmgr.sh)`, so
   edits to `genmgr.sh` only take effect after a rebuild.

## Starting a new task — suggested prompt template

Paste something like this into a fresh chat:

> Work in `~/nixos` (a NixOS flake). Read `AGENTS.md` first, then
> `<describe the change>`. Validate with `genmgr --build-only` before you're
> done, and tell me exactly what you changed and any commands I need to run.

## Change checklist for agents

1. Read `AGENTS.md` + `configuration.nix` + `flake.nix`.
2. Make surgical edits to `configuration.nix` (or `genmgr.sh`, `starship.toml`, etc.).
3. Validate with the `nix build --no-link ...` dry-run.
4. If you touched `flake.lock` or inputs, mention it.
5. Report the switch command for the user: `genmgr --note "<note>"` to switch and
   commit, `genmgr --no-commit` to switch only, or `nh os switch ~/nixos`.
