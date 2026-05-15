#!/usr/bin/env bash
# Launch the most recent arcer build. Prefers arcer.app once branding
# patches land; falls back to the upstream Chromium.app bundle.
#
# Any arguments are forwarded to the bundle via `open --args`.
set -euo pipefail

CHROMIUM_SRC="${CHROMIUM_SRC:-$HOME/chromium/src}"
OUT_DIR="${ARCER_OUT_DIR:-$CHROMIUM_SRC/out/Release}"

log() { printf '\033[1;34m[run]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[run]\033[0m %s\n' "$*" >&2; exit 1; }

CANDIDATES=(
  "$OUT_DIR/arcer.app"
  "$OUT_DIR/Chromium.app"
)

bundle=""
for candidate in "${CANDIDATES[@]}"; do
  if [[ -d "$candidate" ]]; then
    bundle="$candidate"
    break
  fi
done

[[ -n "$bundle" ]] || fail "No app bundle found under $OUT_DIR. Run scripts/build-mac.sh first."

log "Launching $bundle"
if [[ $# -gt 0 ]]; then
  open -a "$bundle" --args "$@"
else
  open -a "$bundle"
fi
