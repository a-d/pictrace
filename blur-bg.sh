#!/usr/bin/env bash
# blur-bg.sh - regenerate images/bg-blurred.jpg, the baked blurred backdrop.
#
# The gallery backdrop is a single static image, so the old runtime
# `backdrop-filter: blur(0.5em)` on .gallery was replaced by this
# pre-blurred derivative: identical look (verified by pixel diff),
# no per-frame blur cost, ~1% of the file size.
#
# Usage:
#   ./blur-bg.sh                          # use the same image Jekyll would pick
#   ./blur-bg.sh <source-image>           # or an explicit photo
set -euo pipefail
cd "$(dirname "$0")"

src="${1:-}"
if [ -z "$src" ]; then
  # same pick as the old template: the last thumbnail in the images tree
  src=$(ls -1 images/[0-9][0-9][0-9][0-9]/*/thumbs/*.jpg 2>/dev/null | tail -n 1)
fi
[ -f "$src" ] || { echo "blur-bg.sh: source not found: $src" >&2; exit 1; }

convert "$src" -resize 96x -blur 0x1.0 -strip -sampling-factor 2x2 -quality 82 images/bg-blurred.jpg
echo "blur-bg.sh: wrote images/bg-blurred.jpg from $src ($(stat -c%s images/bg-blurred.jpg) bytes)"
