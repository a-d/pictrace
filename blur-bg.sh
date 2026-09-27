#!/usr/bin/env bash
# blur-bg.sh - regenerate bg-blurred.jpg, the baked blurred backdrop.
#
# The gallery backdrop is a single static image, so the old runtime
# `backdrop-filter: blur(0.5em)` on .gallery was replaced by this
# pre-blurred derivative: identical look (verified by pixel diff),
# no per-frame blur cost, ~1% of the file size.
#
# It lives in the project root, NOT in images/ - that directory is the
# drop folder resize.sh scans for new originals (images/*.{jpg,jpeg,...}),
# so a stray file there would be imported as a photo.
#
# Usage:
#   ./blur-bg.sh                          # use the same image Jekyll would pick
#   ./blur-bg.sh <source-image>           # or an explicit photo
#
# Needs ImageMagick - run it in the README's tooling container (same as resize.sh).
set -euo pipefail

if ! command -v convert >/dev/null 2>&1; then
  echo "blur-bg.sh: ImageMagick (convert) not found." >&2
  echo "  Run it in the README's tooling container (same environment as resize.sh). One-shot:" >&2
  echo "  docker run --rm -v \"\$PWD:/work\" -w /work debian bash -lc 'apt-get update -qq && apt-get install -y -qq imagemagick && ./blur-bg.sh'" >&2
  exit 1
fi

cd "$(dirname "$0")"

src="${1:-}"
if [ -z "$src" ]; then
  # same pick as the old template: the last thumbnail in the images tree
  src=$(ls -1 images/[0-9][0-9][0-9][0-9]/*/thumbs/*.jpg 2>/dev/null | tail -n 1)
fi
[ -f "$src" ] || { echo "blur-bg.sh: source not found: $src" >&2; exit 1; }

convert "$src" -resize 96x -blur 0x1.0 -strip -sampling-factor 2x2 -quality 82 bg-blurred.jpg
echo "blur-bg.sh: wrote bg-blurred.jpg from $src ($(stat -c%s bg-blurred.jpg) bytes)"
