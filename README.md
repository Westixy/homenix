# homenix

NixOS configuration for **westixy's machine** — a flake-based, declarative
setup for a gaming + local-AI desktop running the COSMIC environment.

> Flake: `nixpkgs` on `nixos-26.05`, host `nixos` (`x86_64-linux`).

## What's configured

| Area | Details |
| --- | --- |
| **Bootloader** | Limine (UEFI) with a custom [Gohu 8x14](https://fontlibrary.org/en/font/gohufont) bitmap font, the `nineish-dark-gray` wallpaper, and a Catppuccin-themed boot menu |
| **Desktop** | COSMIC (Wayland-native) with the COSMIC greeter |
| **GPU** | NVIDIA GeForce GTX 1070 Ti (Pascal), `legacy_580` branch, modesetting for Wayland |
| **Local AI** | [Ollama](https://ollama.com) with the Vulkan backend (`ollama-vulkan`) and an 8192-token context window |
| **Gaming** | Steam (plus its 32-bit graphics, hardware, and firewall rules) |
| **Audio** | PipeWire (with ALSA + Pulse compatibility) via `rtkit` |
| **Shell** | Zsh as default, with autosuggestions, syntax highlighting, and a random fortune/cowsay/lolcat MOTD |
| **Prompt** | [Starship](https://starship.rs) with a Matrix/DevOps theme (`starship.toml`) |
| **Fonts** | Nerd Fonts (JetBrains Mono, Fira Code, Hack, Noto, Gohu) |
| **Browser** | [Zen Browser](https://zen-browser.app) via its community flake |
| **Misc** | NTFS read/write, CUPS printing, `git-lfs`, `nh` |

## Repository layout

```
.
├── flake.nix                # Flake entry: nixosConfigurations.nixos
├── flake.lock               # Pinned input versions
├── configuration.nix        # Main system configuration
├── hardware-configuration.nix # Generated hardware config (disks, kernel modules)
├── genmgr.sh                # Build + switch + commit helper (installed as `genmgr`)
├── gohu-to-limine.py        # Converts the Gohu BDF font to Limine's raw CP437 format
├── starship.toml            # Starship prompt theme
└── .gitignore
```

## Usage

### Build & switch

The repo lives in `~/nixos`, and the flake exposes `nixosConfigurations.nixos`:

```sh
nh os switch ~/nixos
```

### `genmgr` — build, switch, and commit in one step

`genmgr` rebuilds the system with `nh`, captures the new generation, and
commits the config changes to git:

```sh
genmgr
```

It will prompt for an optional commit note (only when run interactively) and
produce a commit like:

```
nixos: gen 16 at 2026-09-07 10:43:03 - <note>
```

Environment variables you can override:

| Variable | Default | Purpose |
| --- | --- | --- |
| `FLAKE_PATH` | `$NH_OS_FLAKE` → `~/nixos` | Path to the config flake |
| `HOST` | `$(hostname)` | Hostname in `nixosConfigurations` |

> `NH_OS_FLAKE` is exported to `$HOME/nixos` in `configuration.nix`.

## First-time setup

After cloning to `~/nixos` on a fresh machine:

```sh
# Regenerate hardware-configuration.nix if the hardware differs
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Build and switch into the configuration
sudo nixos-rebuild switch --flake ~/nixos#nixos
```
