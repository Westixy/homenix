#!/usr/bin/env bash
set -euo pipefail

# Configuration
#
# Path to the NixOS config flake. Defaults to NH_OS_FLAKE (exported in
# configuration.nix as "$HOME/nixos"), falling back to ~/nixos.
FLAKE_PATH="${FLAKE_PATH:-${NH_OS_FLAKE:-$HOME/nixos}}"

# Hostname selects the matching nixosConfigurations entry in flake.nix.
# Our flake only defines nixosConfigurations.nixos, and configuration.nix
# sets networking.hostName = "nixos", so this resolves to the same value.
HOST="${HOST:-$(hostname)}"

# Work inside the config repo so git operates on the right tree no matter
# where genmgr was invoked from.
cd "$FLAKE_PATH"

# Optional: ask for a human-readable label/comment (only when interactive).
GEN_NOTE=""
if [ -t 0 ]; then
  read -rp "Generation note (optional): " GEN_NOTE
fi

echo "Building and switching NixOS configuration with nh..."
nh os switch --hostname "$HOST" "$FLAKE_PATH"

echo "nh os switch succeeded, collecting generation metadata..."

# Identify the currently active system generation. `nixos-rebuild
# list-generations` prints a table whose last column ("Current") is True for
# the active generation.
current_gen=$(nixos-rebuild list-generations | awk '$8 == "True" { printf "gen %d at %s %s", $1, $2, $3; exit }')
if [ -z "$current_gen" ]; then
  current_gen="generation unknown"
fi

# Compose commit message:
# Example: "nixos: gen 16 at 2026-09-07 10:43:03 - <optional note>"
commit_msg="nixos: $current_gen"
if [ -n "$GEN_NOTE" ]; then
  commit_msg="$commit_msg - $GEN_NOTE"
fi

echo "Committing configuration changes with message:"
echo "  $commit_msg"

# Commit all tracked changes
git add -A
git commit -m "$commit_msg"

# Optional: push
# git push

echo "Done."