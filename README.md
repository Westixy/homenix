# homenix

NixOS configuration for **westixy's machine** — a flake-based, declarative
setup for a gaming + local-AI desktop running the COSMIC environment.

> Flake: `nixpkgs` on `nixos-26.05`, host `nixos` (`x86_64-linux`).

## What's configured

| Area | Details |
| --- | --- |
| **Bootloader** | Limine (UEFI) with a custom [Gohu 8x14](https://fontlibrary.org/en/font/gohufont) bitmap font, the `nineish-dark-gray` wallpaper, and a Catppuccin-themed boot menu |
| **Desktop** | COSMIC (Wayland-native) with the COSMIC greeter |
| **Wallpaper** | The `nineish-dark-gray` artwork (same as the boot menu) on both the desktop and lock screen, applied declaratively on login |
| **GPU** | NVIDIA GeForce GTX 1070 Ti (Pascal), `legacy_580` branch, modesetting for Wayland |
| **Local AI** | [Ollama](https://ollama.com) with the Vulkan backend (`ollama-vulkan`) and an 8192-token context window |
| **Gaming** | Steam (plus its 32-bit graphics, hardware, and firewall rules) |
| **Audio** | PipeWire (with ALSA + Pulse compatibility) via `rtkit` |
| **Shell** | Zsh as default, with autosuggestions, syntax highlighting, and a random fortune/cowsay/lolcat MOTD |
| **Prompt** | [Starship](https://starship.rs) with a Matrix/DevOps theme (`starship.toml`) |
| **Fonts** | Nerd Fonts (JetBrains Mono, Fira Code, Hack, Noto, Gohu) |
| **Browser** | [Zen Browser](https://zen-browser.app) via its community flake |
| **Misc** | NTFS read/write, CUPS printing, `git-lfs`, `nh` |
| **Sudo** | `westixy` runs `sudo` without a password (`NOPASSWD: ALL`) |

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

By default (and only when run interactively) it prompts for an optional commit
note, then switches and commits with a message like:

```
nixos: gen 16 at 2026-09-07 10:43:03 - <note>
```

For non-interactive/agent use, pass flags instead of relying on the prompt:

| Flag | Purpose |
| --- | --- |
| `-n, --note NOTE` | Supply the commit note non-interactively |
| `-b, --build-only` | Build the toplevel only — no switch, no commit (validate) |
| `--no-commit` | Switch but skip the git commit |
| `-h, --help` | Show usage |

```sh
genmgr --build-only                 # validate the config builds
genmgr --note "add foo"             # switch + commit with a note
genmgr --no-commit                  # switch without committing
```

Environment variables you can override:

| Variable | Default | Purpose |
| --- | --- | --- |
| `FLAKE_PATH` | `$NH_OS_FLAKE` → `~/nixos` | Path to the config flake |
| `HOST` | `$(hostname)` | Hostname in `nixosConfigurations` |

> `NH_OS_FLAKE` is exported to `$HOME/nixos` in `configuration.nix`.

### Wallpaper

The desktop and lock-screen wallpaper are both set to the same `nineish-dark-gray`
image used on the Limine boot menu. It is applied by a declarative
`cosmic-wallpaper` systemd user service on every login (both surfaces read the
same `com.system76.CosmicBackground` COSMIC config). To change it, edit the
`wallpaperPath` / `cosmicWallpaperEntry` bindings in `configuration.nix`; if you'd
rather manage the wallpaper interactively from COSMIC Settings, delete the
`systemd.user.services.cosmic-wallpaper` block.

## First-time setup

After cloning to `~/nixos` on a fresh machine:

```sh
# Regenerate hardware-configuration.nix if the hardware differs
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Build and switch into the configuration
sudo nixos-rebuild switch --flake ~/nixos#nixos
```
