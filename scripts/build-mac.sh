#!/usr/bin/env bash
# Build the arcer Chromium target for macOS arm64. Runs `gn gen` with the
# arcer development arg set, then `autoninja -C out/Release chrome`.
set -euo pipefail

CHROMIUM_SRC="${CHROMIUM_SRC:-$HOME/chromium/src}"
OUT_DIR="out/Release"

log() { printf '\033[1;34m[build]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[build]\033[0m %s\n' "$*" >&2; exit 1; }

SECONDS=0

[[ -d "$CHROMIUM_SRC" ]] || fail "CHROMIUM_SRC not found at $CHROMIUM_SRC. Run scripts/fetch-chromium.sh first."
command -v gn >/dev/null 2>&1 || fail "'gn' not on PATH. depot_tools should provide it; reopen your shell."
command -v autoninja >/dev/null 2>&1 || fail "'autoninja' not on PATH. depot_tools should provide it."

GN_ARGS=$(cat <<'EOF'
is_debug=false
is_official_build=false
symbol_level=1
enable_nacl=false
blink_symbol_level=0
v8_symbol_level=0
use_remoteexec=false
chrome_pgo_phase=0
is_component_build=true
target_cpu="arm64"
EOF
)

log "Generating $OUT_DIR build files"
(cd "$CHROMIUM_SRC" && gn gen "$OUT_DIR" --args="$GN_ARGS")

log "Building chrome target (this is the slow step)"
(cd "$CHROMIUM_SRC" && autoninja -C "$OUT_DIR" chrome)

log "Build complete. Elapsed: ${SECONDS}s"
