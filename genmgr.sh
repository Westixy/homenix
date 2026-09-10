#!/usr/bin/env bash
set -euo pipefail

# genmgr — build, switch, and commit the NixOS configuration in one step.
#
# Designed to be equally usable by a human at a prompt and by an agent in a
# non-interactive shell. Everything optional is controlled by flags, so there
# is no reliance on stdin being a TTY.

usage() {
  cat <<'EOF'
Usage: genmgr [options]

Rebuild and switch the NixOS configuration with nh, then commit the
configuration changes to git (unless --no-commit).

Options:
  -n, --note NOTE      Commit note appended to the commit message
                       (non-interactive; no prompt is shown when given)
      --no-commit      Switch, but do not create a git commit
  -b, --build-only     Build the toplevel only — no switch, no commit.
                       Useful for validating a config before switching.
  -h, --help           Show this help and exit

Environment:
  FLAKE_PATH           Path to the config flake (default: $NH_OS_FLAKE, else ~/nixos)
  HOST                 Hostname selecting nixosConfigurations.<HOST> (default: current hostname)

Examples:
  genmgr                              # interactive note prompt (TTY only), then switch + commit
  genmgr --note "add foo"             # non-interactive note, then switch + commit
  genmgr --build-only                 # just validate the config builds
  genmgr --no-commit                  # switch without committing
EOF
}

# --- Parse arguments ------------------------------------------------------

NOTE=""
COMMIT=1
BUILD_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--note|--message)
      if [ $# -lt 2 ]; then
        echo "genmgr: option '$1' requires an argument" >&2
        usage >&2
        exit 2
      fi
      NOTE="$2"
      shift 2
      ;;
    --note=*|--message=*)
      NOTE="${1#*=}"
      shift
      ;;
    --no-commit)
      COMMIT=0
      shift
      ;;
    -b|--build-only|--check)
      BUILD_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "genmgr: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# --- Configuration --------------------------------------------------------

# Path to the NixOS config flake. Defaults to NH_OS_FLAKE (exported in
# configuration.nix as "$HOME/nixos"), falling back to ~/nixos.
FLAKE_PATH="${FLAKE_PATH:-${NH_OS_FLAKE:-$HOME/nixos}}"

# Hostname selects the matching nixosConfigurations entry in flake.nix.
# Our flake only defines nixosConfigurations.auberge, and configuration.nix
# sets networking.hostName = "auberge", so this resolves to the same value.
HOST="${HOST:-$(hostname)}"

# Work inside the config repo so git operates on the right tree no matter
# where genmgr was invoked from.
cd "$FLAKE_PATH"

# --- Build-only mode (validate without switching) -------------------------

if [ "$BUILD_ONLY" -eq 1 ]; then
  echo "Building NixOS configuration (no switch, no commit)..."
  nh os build --hostname "$HOST" "$FLAKE_PATH"
  echo "Build succeeded."
  exit 0
fi

# --- Optional note (interactive only, and only when committing) -----------

if [ "$COMMIT" -eq 1 ] && [ -z "$NOTE" ] && [ -t 0 ]; then
  read -rp "Generation note (optional): " NOTE
fi

# --- Build + switch -------------------------------------------------------

echo "Building and switching NixOS configuration with nh..."
nh os switch --hostname "$HOST" "$FLAKE_PATH"

if [ "$COMMIT" -eq 0 ]; then
  echo "Switch succeeded (--no-commit: skipping git commit)."
  exit 0
fi

# --- Commit ---------------------------------------------------------------

echo "nh os switch succeeded, collecting generation metadata..."

# Identify the currently active system generation. `nixos-rebuild
# list-generations` prints a table whose last column ("Current") is True for
# the active generation.
current_gen=$(nixos-rebuild list-generations | awk '$8 == "True" { printf "gen %d at %s %s", $1, $2, $3; exit }')
if [ -z "$current_gen" ]; then
  current_gen="generation unknown"
fi

# Compose commit message:
# Example: "auberge: gen 16 at 2026-09-07 10:43:03 - <optional note>"
commit_msg="$HOST: $current_gen"
if [ -n "$NOTE" ]; then
  commit_msg="$commit_msg - $NOTE"
fi

# Nothing changed? Don't fail; just report and exit cleanly.
if [ -z "$(git status --porcelain)" ]; then
  echo "No configuration changes to commit."
  exit 0
fi

echo "Committing configuration changes with message:"
echo "  $commit_msg"

git add -A
git commit -m "$commit_msg"

echo "Done."