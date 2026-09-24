#!/usr/bin/env bash
# minify.sh - regenerate assets/js/main.min.js from assets/js/main.js (terser).
#
# assets/js/main.js is the editable source; the layout loads main.min.js.
# After editing main.js: run ./minify.sh, then commit BOTH files
# (main.min.js is gitignored by the /assets/ rule - use: git add -f).
# Requires Node/npx (fetches the pinned terser on first run).
#
# --check  verify the committed main.min.js matches the current source
#          (exit 1 = stale; rerun ./minify.sh before committing).
set -euo pipefail
cd "$(dirname "$0")"

SRC=assets/js/main.js
OUT=assets/js/main.min.js
TERSER_VERSION=5.44.0
SRC_SHA=$(sha256sum "$SRC" | cut -d' ' -f1)

if [ "${1:-}" = "--check" ]; then
  if [ -f "$OUT" ] && head -1 "$OUT" | grep -q "src-sha256:$SRC_SHA"; then
    echo "minify.sh --check: OK - $OUT matches $SRC"
    exit 0
  fi
  echo "minify.sh --check: STALE - $OUT does not match $SRC; run ./minify.sh and commit both." >&2
  exit 1
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
npx --yes "terser@${TERSER_VERSION}" "$SRC" -c passes=2 -m --comments false -o "$TMP"
{ echo "/* src-sha256:${SRC_SHA} */"; cat "$TMP"; } > "$OUT"
echo "minify.sh: wrote $OUT ($(wc -c < "$OUT") bytes raw, $(gzip -9 -c "$OUT" | wc -c) bytes gzip)"
echo "minify.sh: remember to commit BOTH $SRC and $OUT (git add -f $OUT)."
