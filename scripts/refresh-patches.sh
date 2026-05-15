#!/usr/bin/env bash
# Regenerate each patch in patches/series by diffing the current state of
# $CHROMIUM_SRC against the ungoogled-chromium baseline tag. Only the
# files declared in each patch's "Files:" header are diffed, so unrelated
# in-tree changes do not bleed across patches.
#
# If a patch's declared files have no changes against the baseline, the
# patch file on disk is left untouched.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERIES="$REPO_ROOT/patches/series"
PATCH_DIR="$REPO_ROOT/patches"
VERSION_FILE="$REPO_ROOT/chromium-version.txt"
CHROMIUM_SRC="${CHROMIUM_SRC:-$HOME/chromium/src}"
UC_DIR="${UC_DIR:-$HOME/chromium/ungoogled-chromium}"

log() { printf '\033[1;34m[refresh]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[refresh]\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f "$SERIES" ]] || fail "Missing $SERIES."
[[ -f "$VERSION_FILE" ]] || fail "Missing $VERSION_FILE."
[[ -d "$CHROMIUM_SRC/.git" ]] || fail "CHROMIUM_SRC ($CHROMIUM_SRC) is not a git checkout."
[[ -f "$UC_DIR/chromium_version.txt" ]] || fail "ungoogled-chromium clone not found at $UC_DIR. Run scripts/fetch-chromium.sh first."

MILESTONE="$(tr -d '[:space:]' < "$UC_DIR/chromium_version.txt")"
log "Baseline Chromium milestone: $MILESTONE"

# Confirm the baseline tag is actually reachable in the Chromium checkout.
(cd "$CHROMIUM_SRC" && git rev-parse --verify --quiet "refs/tags/$MILESTONE" >/dev/null) \
  || fail "Tag $MILESTONE not present in $CHROMIUM_SRC. Did fetch-chromium.sh complete?"

extract_files() {
  # Print each path listed under a 'Files:' header in the given patch.
  # The header may be a single line ('Files: a b c') or span multiple
  # indented continuation lines until the next header or a blank line.
  local patch="$1"
  awk '
    /^Files:[[:space:]]*/ {
      sub(/^Files:[[:space:]]*/, "")
      in_block = 1
    }
    in_block && /^[A-Za-z-]+:/ && !/^Files:/ { in_block = 0 }
    in_block && /^$/ { in_block = 0 }
    in_block {
      for (i = 1; i <= NF; i++) print $i
    }
  ' "$patch" | sort -u
}

refreshed=0
unchanged=0
while IFS= read -r line || [[ -n "$line" ]]; do
  trimmed="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$trimmed" ]] && continue
  [[ "$trimmed" == \#* ]] && continue

  patch_path="$PATCH_DIR/$trimmed"
  [[ -f "$patch_path" ]] || fail "Patch listed in series but not on disk: $trimmed"

  mapfile -t files < <(extract_files "$patch_path")
  if [[ ${#files[@]} -eq 0 ]]; then
    fail "Patch $trimmed has no 'Files:' header. Add one listing the paths the patch touches."
  fi

  # Diff the declared files against the baseline tag.
  new_diff="$(cd "$CHROMIUM_SRC" && git diff --no-color --no-ext-diff "refs/tags/$MILESTONE" -- "${files[@]}")"

  if [[ -z "$new_diff" ]]; then
    log "Unchanged: $trimmed"
    unchanged=$((unchanged + 1))
    continue
  fi

  # Preserve the existing header block (everything up to the first 'diff --git'
  # line) and append the freshly generated diff.
  header="$(awk '/^diff --git/{exit} {print}' "$patch_path")"
  {
    printf '%s\n' "$header"
    printf '%s\n' "$new_diff"
  } > "$patch_path.new"
  mv "$patch_path.new" "$patch_path"
  log "Refreshed: $trimmed"
  refreshed=$((refreshed + 1))
done < "$SERIES"

log "Done. Refreshed: $refreshed, unchanged: $unchanged."
