#!/usr/bin/env bash
# One-shot environment setup for arcer development on macOS arm64.
# Idempotent: safe to re-run.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPS_DIR="${ARCER_DEPS_DIR:-$HOME/arcer-deps}"
CHROMIUM_SRC="${CHROMIUM_SRC:-$HOME/chromium/src}"

log() { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[bootstrap]\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || fail "This script targets macOS only."
[[ "$(uname -m)" == "arm64" ]] || fail "This script targets arm64 (Apple Silicon) only."

log "Checking Xcode command line tools"
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode command line tools (a GUI dialog will appear)"
  xcode-select --install || true
  fail "Re-run this script after the Xcode CLT install completes."
fi

log "Verifying disk space (need ~150 GB free for Chromium checkout + build)"
free_gb=$(df -g "$HOME" | awk 'NR==2{print $4}')
if [ "$free_gb" -lt 150 ]; then
  fail "Only ${free_gb} GB free in $HOME. Need at least 150 GB. Free some space and re-run."
fi

log "Verifying Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  fail "Homebrew not installed. Install from https://brew.sh and re-run."
fi

log "Installing build dependencies via Homebrew"
brew install --quiet git python@3.12 ninja cmake pkg-config

log "Setting up depot_tools at $DEPS_DIR/depot_tools"
mkdir -p "$DEPS_DIR"
if [ ! -d "$DEPS_DIR/depot_tools" ]; then
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git \
    "$DEPS_DIR/depot_tools"
else
  log "depot_tools already present, pulling latest"
  (cd "$DEPS_DIR/depot_tools" && git pull --ff-only)
fi

SHELL_RC="$HOME/.zshrc"
if ! grep -q 'arcer-deps/depot_tools' "$SHELL_RC" 2>/dev/null; then
  log "Adding depot_tools to PATH in $SHELL_RC"
  {
    echo ""
    echo "# arcer development"
    echo "export PATH=\"$DEPS_DIR/depot_tools:\$PATH\""
    echo "export CHROMIUM_SRC=\"$CHROMIUM_SRC\""
    echo "export ARCER_REPO=\"$REPO_ROOT\""
  } >> "$SHELL_RC"
  log "Restart your shell or 'source $SHELL_RC' before running fetch-chromium.sh"
fi

log "Spotlight indexing on $HOME/chromium will slow builds. Adding exclusion."
mkdir -p "$(dirname "$CHROMIUM_SRC")"
# Spotlight exclusion via plist is fiddly; the simplest reliable thing is a .metadata_never_index file.
touch "$(dirname "$CHROMIUM_SRC")/.metadata_never_index"

log "Bootstrap complete."
log "Next: open a new shell, then run ./scripts/fetch-chromium.sh"
