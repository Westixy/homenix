set -euo pipefail

usage() {
  cat <<'EOF'
Usage: init-from-fresh-install <hostname>

Bootstrap a fresh NixOS install with the homenix configuration.

Arguments:
  hostname    One of: auberge, auberge-gpd

What it does:
  1. Clones github:westixy/homenix to ~/nixos (if not already present)
  2. Copies /etc/nixos/hardware-configuration.nix to
     systems/<hostname>/hardware-configuration.nix
  3. Runs nixos-rebuild switch --flake ~/nixos#<hostname>
EOF
}

HOST="${1:-}"

if [ -z "$HOST" ]; then
  echo "error: hostname argument is required" >&2
  usage >&2
  exit 1
fi

case "$HOST" in
  auberge|auberge-gpd) ;;
  *)
    echo "error: unknown hostname '$HOST' (expected 'auberge' or 'auberge-gpd')" >&2
    exit 1
    ;;
esac

NIXOS_DIR="$HOME/nixos"

# 1. Clone the repo.
if [ -d "$NIXOS_DIR/.git" ]; then
  echo "homenix repo already exists at $NIXOS_DIR, pulling latest..."
  git -C "$NIXOS_DIR" pull
else
  echo "Cloning homenix to $NIXOS_DIR..."
  git clone https://github.com/Westixy/homenix.git "$NIXOS_DIR"
fi

# 2. Copy hardware-configuration.nix.
HARDWARE_SRC="/etc/nixos/hardware-configuration.nix"
HARDWARE_DST="$NIXOS_DIR/systems/$HOST/hardware-configuration.nix"

if [ ! -f "$HARDWARE_SRC" ]; then
  echo "error: $HARDWARE_SRC not found — run nixos-generate-config first" >&2
  exit 1
fi

echo "Copying $HARDWARE_SRC to $HARDWARE_DST..."
mkdir -p "$(dirname "$HARDWARE_DST")"
cp "$HARDWARE_SRC" "$HARDWARE_DST"

# 3. Switch.
echo "Switching to $HOST configuration..."
sudo nixos-rebuild switch --flake "$NIXOS_DIR#$HOST"