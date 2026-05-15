#!/usr/bin/env bash
# Fetch the pinned Chromium source tree and apply the ungoogled-chromium
# patch set. Idempotent: re-running on an already populated checkout
# detects the existing tree and skips the fetch.
#
# Reads the target tag from chromium-version.txt at the repo root. The
# Chromium milestone itself is read from ungoogled-chromium's own
# chromium_version.txt at the matching tag.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$REPO_ROOT/chromium-version.txt"
CHROMIUM_SRC="${CHROMIUM_SRC:-$HOME/chromium/src}"
CHROMIUM_PARENT="$(dirname "$CHROMIUM_SRC")"
UC_DIR="$HOME/chromium/ungoogled-chromium"

log() { printf '\033[1;34m[fetch]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[fetch]\033[0m %s\n' "$*" >&2; exit 1; }

SECONDS=0

[[ -f "$VERSION_FILE" ]] || fail "Missing $VERSION_FILE. Cannot determine pinned tag."

# First non-comment, non-empty line is the tag.
CHROMIUM_TAG="$(grep -v '^[[:space:]]*#' "$VERSION_FILE" | grep -v '^[[:space:]]*$' | head -n1 | tr -d '[:space:]')"
[[ -n "$CHROMIUM_TAG" ]] || fail "No tag found in $VERSION_FILE."
log "Pinned ungoogled-chromium tag: $CHROMIUM_TAG"

command -v fetch >/dev/null 2>&1 || fail "depot_tools 'fetch' not on PATH. Run scripts/bootstrap.sh and reopen the shell."
command -v gclient >/dev/null 2>&1 || fail "depot_tools 'gclient' not on PATH."

# Clone ungoogled-chromium first, since it tells us which Chromium milestone to check out.
if [[ ! -d "$UC_DIR/.git" ]]; then
  log "Cloning ungoogled-chromium into $UC_DIR at $CHROMIUM_TAG"
  mkdir -p "$(dirname "$UC_DIR")"
  git clone --branch "$CHROMIUM_TAG" --depth 1 \
    https://github.com/ungoogled-software/ungoogled-chromium.git "$UC_DIR"
else
  log "ungoogled-chromium already present, fetching tag $CHROMIUM_TAG"
  (cd "$UC_DIR" && git fetch --depth 1 origin "refs/tags/$CHROMIUM_TAG:refs/tags/$CHROMIUM_TAG" && git checkout "$CHROMIUM_TAG")
fi

UC_CHROMIUM_VERSION_FILE="$UC_DIR/chromium_version.txt"
[[ -f "$UC_CHROMIUM_VERSION_FILE" ]] || fail "ungoogled-chromium clone missing chromium_version.txt."
MILESTONE="$(tr -d '[:space:]' < "$UC_CHROMIUM_VERSION_FILE")"
log "ungoogled-chromium targets Chromium milestone: $MILESTONE"

if [[ -d "$CHROMIUM_SRC/.git" ]]; then
  log "Chromium source already present at $CHROMIUM_SRC, skipping fetch."
else
  log "Fetching Chromium into $CHROMIUM_SRC (this is the slow step)"
  mkdir -p "$CHROMIUM_PARENT"
  (
    cd "$CHROMIUM_PARENT"
    fetch --nohooks chromium
  )
  [[ -d "$CHROMIUM_SRC/.git" ]] || fail "fetch did not produce $CHROMIUM_SRC."
  log "Checking out Chromium milestone $MILESTONE"
  (
    cd "$CHROMIUM_SRC"
    git fetch --depth 1 origin "refs/tags/$MILESTONE:refs/tags/$MILESTONE"
    git checkout "$MILESTONE"
    gclient sync --with_branch_heads --with_tags --nohooks -D --revision="src@$MILESTONE"
    gclient runhooks
  )
fi

# Prune binaries the ungoogled project considers unsafe to keep, then apply patches.
log "Pruning binaries with ungoogled-chromium/utils/prune_binaries.py"
python3 "$UC_DIR/utils/prune_binaries.py" "$CHROMIUM_SRC" "$UC_DIR/pruning.list"

log "Applying ungoogled-chromium patch set with utils/patches.py"
python3 "$UC_DIR/utils/patches.py" apply "$CHROMIUM_SRC" "$UC_DIR/patches"

log "Chromium source ready at $CHROMIUM_SRC"
log "Elapsed: ${SECONDS}s"
