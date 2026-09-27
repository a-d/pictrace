#!/usr/bin/env bash
# Derive gallery-ready assets from a video: an ANIMATED AVIF (plays like a GIF,
# no autoplay policy, no JS) plus a still JPEG poster used as the <img> fallback.
#
# Usage: ./video.sh <source.mp4> <year> "<LocationName>" [basename]
#
# Outputs (mirroring the photo layout exactly, so the gallery needs no changes):
#   images/<year>/<NN>_<Location>/fulls/<base>.avif   animated, 1024px wide, 3:2
#   images/<year>/<NN>_<Location>/fulls/<base>.jpg    poster still (no-AVIF browsers)
#   images/<year>/<NN>_<Location>/thumbs/<base>.avif  animated, 512px wide, 3:2
#   images/<year>/<NN>_<Location>/thumbs/<base>.jpg   poster still
#
# The 3:2 aspect matches the regular photos (1024x683 / 512x342) so the video sits
# in the 4:3 grid tile with the same cropping as its neighbours instead of losing
# a quarter of its width. Scale-to-fill + centre-crop does that.
set -euo pipefail

FULL_WIDTH=1024
THUMB_WIDTH=512
FPS=30                       # 30 fps - matches the source and keeps motion smooth
AVIF_SPEED=6
AVIF_FULL_Q=${AVIF_FULL_Q:-65}
AVIF_THUMB_Q=${AVIF_THUMB_Q:-60}

if [ $# -lt 3 ]; then
  echo "usage: $0 <source.mp4> <year> \"<LocationName>\" [basename]" >&2
  exit 1
fi

SRC=$1
YEAR=$2
LOCATION=$3
BASE=${4:-$(basename "${SRC%.*}")}

[ -f "$SRC" ] || { echo "Error: no such file: $SRC" >&2; exit 1; }
for c in ffmpeg avifenc convert exiftool; do
  command -v "$c" >/dev/null 2>&1 || {
    echo "Error: '$c' not found. apt install ffmpeg imagemagick libavif-bin libimage-exiftool-perl" >&2
    exit 1
  }
done

IMG_DIR="images"
# resolve the location's NN_ prefix if it already exists
if [ -d "$IMG_DIR/$YEAR" ]; then
  existing=$(find "$IMG_DIR/$YEAR" -maxdepth 1 -type d -name "*_$LOCATION" -printf '%f\n' | head -1 || true)
else
  existing=""
fi
if [ -z "$existing" ]; then
  echo "Error: no existing location directory for '$LOCATION' under $IMG_DIR/$YEAR." >&2
  echo "       Create the photos for this location first, then re-run." >&2
  exit 1
fi

LOC_DIR="$IMG_DIR/$YEAR/$existing"
echo ">> target location dir: $LOC_DIR (basename: $BASE)"

# ffmpeg auto-applies any display-matrix rotation (baked into the pixels, the
# same rule resize.sh follows for EXIF Orientation) and we drop audio entirely -
# AVIF has no audio track and the source is effectively silent anyway.
scale_filter() { echo "scale=$1:$2:force_original_aspect_ratio=increase,crop=$1:$2,flags=lanczos"; }

for spec in "fulls:$FULL_WIDTH:1024x683:$AVIF_FULL_Q" "thumbs:$THUMB_WIDTH:512x342:$AVIF_THUMB_Q"; do
  sub=${spec%%:*}; rest=${spec#*:}
  W=${rest%%:*}; rest=${rest#*:}
  DIMS=${rest%%:*}; Q=${rest#*:}
  vf_anim="$(scale_filter "$W" "$DIMS"),fps=${FPS}"
  vf_still="$(scale_filter "$W" "$DIMS")"

  mkdir -p "$LOC_DIR/$sub"
  AVIF="$LOC_DIR/$sub/$BASE.avif"
  JPG="$LOC_DIR/$sub/$BASE.jpg"

  # Animated AVIF: frames are streamed to avifenc as a y4m image sequence, with
  # an infinite repetition count so the <img> loops without JS.
  echo ">> $sub: encoding animated AVIF (${DIMS}, ${FPS}fps, q=$Q, crop ${CROP_PCT}% top/right)"
  # NOTE: with --stdin avifenc accepts no other input, so the y4m stream must arrive
  # on stdin and -q/-s must follow it. Infinite repetition = loops without JS.
  ffmpeg -hide_banner -loglevel error -y -i "$SRC" -an \
    -vf "$vf_anim" -pix_fmt yuv420p -f yuv4mpegpipe - |
    avifenc --stdin -q "$Q" -s "$AVIF_SPEED" \
      --timescale "$FPS" --repetition-count infinite "$AVIF" >/dev/null

  # Poster still = the first frame, as the <img> fallback. Every browser that can
  # animate the AVIF ignores this; the rest show a clean still instead of a gap.
  echo ">> $sub: writing poster JPEG"
  ffmpeg -hide_banner -loglevel error -y -i "$SRC" -frames:v 1 \
    -vf "$vf_still" -q:v 2 "$JPG"

  # Carry the source's metadata across (resize.sh's rule: EXIF stays).
  exiftool -overwrite_original -tagsFromFile "$SRC" \
    -all:all -EXIF:all -XMP:all -IPTC:all -ICC_Profile:all "$JPG" >/dev/null 2>&1 || true

  printf '   %-8s avif %8s  jpg %8s\n' "$sub" \
    "$(du -h "$AVIF" | cut -f1)" "$(du -h "$JPG" | cut -f1)"
done

echo ">> verifying (avifdec: dims, frame count, loop)"
for f in "$LOC_DIR"/fulls/"$BASE".avif "$LOC_DIR"/thumbs/"$BASE".avif; do
  info=$(avifdec --info "$f" 2>&1)
  dims=$(printf '%s' "$info" | sed -n 's/.*Resolution *: *\([0-9x]*\).*/\1/p')
  frames=$(printf '%s' "$info" | sed -n 's/.*(\([0-9]*\) expected frames).*/\1/p')
  rep=$(printf '%s' "$info" | sed -n 's/.*Repeat Count *: *\([A-Za-z]*\).*/\1/p')
  printf '   %-7s %-9s %4s frames  repeat=%s\n' \
    "$(basename "$(dirname "$f")")" "$dims" "${frames:-?}" "${rep:-?}"
done
