#!/usr/bin/env bash
# Apply the arcer patches listed in patches/series to $CHROMIUM_SRC, in
# order. Each patch is dry-run with `git apply --check` first; the real
# apply only runs if the dry-run succeeds. Aborts on the first failure.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERIES="$REPO_ROOT/patches/series"
PATCH_DIR="$REPO_ROOT/patches"
CHROMIUM_SRC="${CHROMIUM_SRC:-$HOME/chromium/src}"

log() { printf '\033[1;34m[apply-patches]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[apply-patches]\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f "$SERIES" ]] || fail "Missing $SERIES."
[[ -d "$CHROMIUM_SRC/.git" ]] || fail "CHROMIUM_SRC ($CHROMIUM_SRC) is not a git checkout. Run scripts/fetch-chromium.sh first."

applied=0
while IFS= read -r line || [[ -n "$line" ]]; do
  # Strip leading whitespace, then skip blanks and comments.
  trimmed="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$trimmed" ]] && continue
  [[ "$trimmed" == \#* ]] && continue

  patch_path="$PATCH_DIR/$trimmed"
  [[ -f "$patch_path" ]] || fail "Patch listed in series but not on disk: $trimmed"

  log "Checking $trimmed"
  (cd "$CHROMIUM_SRC" && git apply --check "$patch_path") \
    || fail "Dry-run failed for $trimmed. Aborting before any patch is applied to the tree."

  log "Applying $trimmed"
  (cd "$CHROMIUM_SRC" && git apply "$patch_path") \
    || fail "Apply failed for $trimmed after dry-run passed. Tree may be partially modified."

  applied=$((applied + 1))
done < "$SERIES"

log "Applied $applied patch(es) cleanly."
