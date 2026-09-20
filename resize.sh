#!/bin/bash
# resize.sh - Image processing script for pictrace
# Replaces gulpfile.js with pure bash + CLI tools
#
# Requirements:
#   apt install imagemagick libavif-bin libimage-exiftool-perl
#   bash 4.3+ (job pool via wait -n)
#
# Modes:
#   ./resize.sh                      # Interactive: process new originals in images/
#   ./resize.sh 2026 "Paris"         # Process originals for one location
#   ./resize.sh 2026 "Paris" -d      # ... and delete originals afterwards
#   ./resize.sh --backfill           # Create missing AVIF from published JPGs (all years)
#   ./resize.sh --backfill 2025      # ... one year ("Oberwiesenthal" etc. also match suffixes)
#   ./resize.sh --backfill --force   # Re-encode every AVIF in scope (after settings changes)
#   ./resize.sh --coverage           # AVIF coverage report only (changes nothing)
#
# Flags:
#   -d, --delete    Delete original images after successful processing (normal mode)
#   -v, --verbose   Note: avifenc output always goes to the log file (printed at end)
#   -j N            Parallel jobs (default: number of CPUs)
#   -f, --force     Backfill: re-encode existing AVIFs too ("rebuild all")
#   -y, --yes       Skip confirmation prompts
#   -h, --help      Show this help
#
# PT11 (2026-09-20): parallel job pool; --backfill/--coverage modes.
#
# EXIF DISCIPLINE - owner rule, must never regress:
#  * The JPGs are the masters: never strip or alter their EXIF (Orientation
#    drives display and the lightbox EXIF panel reads them).
#  * Every AVIF encode copies the source metadata (ICC/EXIF/XMP) - no
#    --ignore-* flags.
#  * A source with a non-normal Orientation tag (e.g. "Rotate 270 CW") is
#    auto-oriented before encoding, so the rotation is baked into the pixels
#    and the copied orientation tag is normalised ("Horizontal (normal)").
#    Viewers can never double-rotate; derivatives render exactly like the JPG.
#
# Note: not using 'set -e' - arithmetic + flaky tools caused surprise exits.

set -u

# ---------------------------------------------------------------- config
FULL_WIDTH=1024
THUMB_WIDTH=512
FULL_QUALITY=95                # JPG quality (fulls)
THUMB_QUALITY=80               # JPG quality (thumbs)

# AVIF quantizer (0-63, lower = better). Deliberately unchanged from the
# pre-PT11 pipeline (proven, and the sweep showed near-flat SSIM ~0.98 with
# 2-4% byte margin between settings). The PT11 wins are elsewhere: coverage,
# metadata-free output, from-JPG backfill.
AVIF_FULL_QMAX=14
AVIF_THUMB_QMAX=22
AVIF_SPEED=6                   # avifenc speed preset

IMAGES_DIR="images"
LOG_FILE="/tmp/resize_avif_$$.log"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ---------------------------------------------------------------- args
MODE="normal"
YEAR=""; LOCATION=""
DELETE_ORIGINALS=false
VERBOSE=false
FORCE=false
ASSUME_YES=false
JOBS=$(nproc 2>/dev/null || echo 4)

usage() { sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; }

args=("$@"); i=0
while [ $i -lt ${#args[@]} ]; do
  a="${args[$i]}"
  case "$a" in
    --backfill)  MODE="backfill" ;;
    --coverage)  MODE="coverage" ;;
    -d|--delete) DELETE_ORIGINALS=true ;;
    -v|--verbose) VERBOSE=true ;;
    -f|--force)  FORCE=true ;;
    -y|--yes)    ASSUME_YES=true ;;
    -h|--help)   usage; exit 0 ;;
    -j|--jobs)   i=$((i+1)); JOBS="${args[$i]:-}" ;;
    -j*)         JOBS="${a#-j}" ;;
    -*)          echo -e "${YELLOW}Warning: ignoring unknown option: $a${NC}" ;;
    *)
      if   [ -z "$YEAR" ];     then YEAR="$a"
      elif [ -z "$LOCATION" ]; then LOCATION="$a"
      else echo -e "${YELLOW}Warning: ignoring extra argument: $a${NC}"
      fi ;;
  esac
  i=$((i+1))
done

case "$JOBS" in
  ''|*[!0-9]*) echo -e "${RED}Error: -j needs a number${NC}"; exit 1 ;;
esac
[ "$JOBS" -lt 1 ] && JOBS=1
# keep avifenc from oversubscribing when many images run in parallel
AVIF_JOBS=$(( ($(nproc 2>/dev/null || echo 4) + JOBS - 1) / JOBS ))
[ "$AVIF_JOBS" -lt 1 ] && AVIF_JOBS=1

if [ "$MODE" != "coverage" ]; then
  for c in convert avifenc exiftool; do
    command -v "$c" >/dev/null 2>&1 || {
      echo -e "${RED}Error: '$c' not found. apt install imagemagick libavif-bin libimage-exiftool-perl${NC}"; exit 1; }
  done
fi

if [ "$MODE" = "normal" ] && [ -z "$YEAR" ]; then
  read -p "Enter the year: " YEAR
  read -p "Enter the location: " LOCATION
  read -p "Delete original images after processing? [y/N]: " DELETE_CONFIRM
  if [[ "$DELETE_CONFIRM" =~ ^[Yy]$ ]]; then DELETE_ORIGINALS=true; fi
fi

# ---------------------------------------------------------------- helpers
# next free index for a new location (normal mode)
get_indexed_location() {
  local year="$1" location="$2"
  local year_dir="$IMAGES_DIR/$year"
  if [ ! -d "$year_dir" ]; then
    mkdir -p "$year_dir"
    echo "01_$location"
    return
  fi
  local existing
  existing=$(find "$year_dir" -maxdepth 1 -type d -name "*_$location" 2>/dev/null | head -1)
  if [ -n "$existing" ]; then
    basename "$existing"
    return
  fi
  local highest_index=0 dir dirname idx
  for dir in "$year_dir"/*/; do
    [ -d "$dir" ] || continue
    dirname=$(basename "$dir")
    if [[ "$dirname" =~ ^([0-9]+)_ ]]; then
      idx=${BASH_REMATCH[1]}
      idx=$((10#$idx))
      [ $idx -gt $highest_index ] && highest_index=$idx
    fi
  done
  printf "%02d_%s" $((highest_index + 1)) "$location"
}

# resolve YEAR + LOCATION to an existing directory (location matches *_suffix)
resolve_location_dir() {
  local year="$1" location="$2"
  local year_dir="$IMAGES_DIR/$year"
  [ -d "$year_dir" ] || return 1
  [ -z "$location" ] && { echo "$year_dir"; return 0; }
  local d
  d=$(find "$year_dir" -maxdepth 1 -mindepth 1 -type d -name "*_${location}" 2>/dev/null | sort | head -1)
  [ -n "$d" ] || return 1
  echo "$d"
}

list_year_dirs() {
  if [ -n "$YEAR" ]; then
    [ -d "$IMAGES_DIR/$YEAR" ] && echo "$IMAGES_DIR/$YEAR"
  else
    for y in "$IMAGES_DIR"/*/; do
      [ -d "$y" ] || continue
      case "$(basename "$y")" in *[!0-9]*) continue ;; esac
      echo "$y"
    done
  fi
}

# JPG files (any extension case) directly under a dir
find_jpgs() {
  find "$1" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort
}

# ---------------------------------------------------------------- coverage
coverage_report() {
  local year year_dir loc_dir n fulls_avif thumbs_avif t
  local t_photos=0 t_fulls=0 t_thumbs=0 t_incomplete=0 y_photos y_fulls y_thumbs
  echo -e "${BLUE}AVIF coverage${NC} (scope: ${YEAR:-all years})"
  printf "%-44s %6s %7s %8s\n" "location (incomplete only)" "photos" "fulls%" "thumbs%"
  for year_dir in $(list_year_dirs); do
    year=$(basename "$year_dir")
    y_photos=0; y_fulls=0; y_thumbs=0
    for loc_dir in "$year_dir"/*/; do
      [ -d "$loc_dir" ] || continue
      n=0; fulls_avif=0; thumbs_avif=0
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        n=$((n+1))
        [ -f "${f%.*}.avif" ] && fulls_avif=$((fulls_avif+1))
        t="${f/\/fulls\//\/thumbs\/}"
        [ -f "${t%.*}.avif" ] && thumbs_avif=$((thumbs_avif+1))
      done < <(find_jpgs "$loc_dir/fulls")
      [ "$n" -eq 0 ] && continue
      y_photos=$((y_photos+n)); y_fulls=$((y_fulls+fulls_avif)); y_thumbs=$((y_thumbs+thumbs_avif))
      if [ "$fulls_avif" -lt "$n" ] || [ "$thumbs_avif" -lt "$n" ]; then
        printf "%-44s %6d %6d%% %7d%%\n" "$year/$(basename "$loc_dir")" "$n" \
          $((fulls_avif*100/n)) $((thumbs_avif*100/n))
        t_incomplete=$((t_incomplete+1))
      fi
    done
    printf -- "-- %s: %d photos, fulls AVIF %d%%, thumbs AVIF %d%%\n" "$year" "$y_photos" \
      $(( y_photos ? y_fulls*100/y_photos : 100 )) $(( y_photos ? y_thumbs*100/y_photos : 100 ))
    t_photos=$((t_photos+y_photos)); t_fulls=$((t_fulls+y_fulls)); t_thumbs=$((t_thumbs+y_thumbs))
  done
  echo "TOTAL: $t_photos photos - fulls AVIF $t_fulls ($(( t_photos ? t_fulls*100/t_photos : 100 ))%)," \
       "thumbs AVIF $t_thumbs ($(( t_photos ? t_thumbs*100/t_photos : 100 ))%)," \
       "incomplete locations: $t_incomplete"
}

# ---------------------------------------------------------------- workers
# normal mode: one original -> full JPG+AVIF, thumb JPG+AVIF
process_original() {
  local n="$1" total="$2" img="$3"
  local FILENAME BASENAME tmp_full tmp_thumb result stage detail
  FILENAME=$(basename "$img")
  BASENAME="${FILENAME%.*}"
  tmp_full="/tmp/resize_$$_${n}_full.png"
  tmp_thumb="/tmp/resize_$$_${n}_thumb.png"
  detail=""; stage=""

  if ! convert "$img" -auto-orient -resize "${FULL_WIDTH}x>" "$tmp_full" 2>/dev/null; then
    result=FAIL; stage="resize-full"
  elif ! convert "$img" -auto-orient -resize "${THUMB_WIDTH}x>" "$tmp_thumb" 2>/dev/null; then
    result=FAIL; stage="resize-thumb"
  elif ! convert "$tmp_full" -quality "$FULL_QUALITY" -interlace Plane "$FULLS_DIR/$BASENAME.jpg" 2>/dev/null; then
    result=FAIL; stage="jpg-full"
  else
    exiftool -overwrite_original -TagsFromFile "$img" \
      -Model -Make -FNumber -FocalLength -FocalLengthIn35mmFormat \
      -ExposureTime -ISOSpeedRatings -ISO -DateTimeOriginal \
      "$FULLS_DIR/$BASENAME.jpg" >/dev/null 2>&1
    avifenc --speed "$AVIF_SPEED" --jobs "$AVIF_JOBS" --yuv 420 --min 0 --max "$AVIF_FULL_QMAX" \
      -- "$tmp_full" "$FULLS_DIR/$BASENAME.avif" \
      >>"$LOG_FILE" 2>&1 || detail="${detail}avif-full-warn "
    if ! convert "$tmp_thumb" -quality "$THUMB_QUALITY" -interlace Plane "$THUMBS_DIR/$BASENAME.jpg" 2>/dev/null; then
      result=FAIL; stage="jpg-thumb"
    else
      exiftool -overwrite_original -TagsFromFile "$img" \
        -Model -Make -FNumber -FocalLength -FocalLengthIn35mmFormat \
        -ExposureTime -ISOSpeedRatings -ISO -DateTimeOriginal \
        "$THUMBS_DIR/$BASENAME.jpg" >/dev/null 2>&1
      avifenc --speed "$AVIF_SPEED" --jobs "$AVIF_JOBS" --yuv 420 --min 0 --max "$AVIF_THUMB_QMAX" \
        -- "$tmp_thumb" "$THUMBS_DIR/$BASENAME.avif" \
        >>"$LOG_FILE" 2>&1 || detail="${detail}avif-thumb-warn "
      result=OK
    fi
  fi
  rm -f "$tmp_full" "$tmp_thumb" 2>/dev/null

  if [ "$result" = OK ]; then
    printf "[%3d/%-3d] ${GREEN}OK${NC}   %s ${YELLOW}%s${NC}\n" "$n" "$total" "$FILENAME" "$detail"
    printf 'OK\toriginal\t%s\t%s\n' "$img" "$detail" >>"$RESULTS_FILE"
  else
    printf "[%3d/%-3d] ${RED}FAIL${NC} %s (%s)\n" "$n" "$total" "$FILENAME" "$stage"
    printf 'FAIL\toriginal\t%s\t%s\n' "$img" "$stage" >>"$RESULTS_FILE"
  fi
}

# backfill: one published JPG -> missing AVIF
process_backfill() {
  local n="$1" total="$2" jpg="$3"
  local avif="${jpg%.*}.avif" qmax orient src tmp_orient note
  case "$jpg" in
    */thumbs/*) qmax="$AVIF_THUMB_QMAX" ;;
    *)          qmax="$AVIF_FULL_QMAX" ;;
  esac
  # EXIF discipline: if the JPG carries a non-normal orientation, bake the
  # rotation into pixels first (the copied tag is normalised as a side effect)
  src="$jpg"; tmp_orient=""; note=""
  orient=$(exiftool -s3 -Orientation "$jpg" 2>/dev/null)
  if [ -n "$orient" ] && [ "$orient" != "Horizontal (normal)" ]; then
    tmp_orient="/tmp/resize_$$_${n}_orient.png"
    if ! convert "$jpg" -auto-orient "$tmp_orient" 2>/dev/null; then
      printf "[%3d/%-3d] ${RED}FAIL${NC} %s (auto-orient)\n" "$n" "$total" "${jpg#$IMAGES_DIR/}"
      printf 'FAIL\tbackfill\t%s\tauto-orient\n' "$jpg" >>"$RESULTS_FILE"
      rm -f "$tmp_orient"; return
    fi
    src="$tmp_orient"; note="[baked orientation]"
  fi
  if avifenc --speed "$AVIF_SPEED" --jobs "$AVIF_JOBS" --yuv 420 --min 0 --max "$qmax" \
      -- "$src" "$avif" >>"$LOG_FILE" 2>&1; then
    printf "[%3d/%-3d] ${GREEN}OK${NC}   %s%s\\n" "$n" "$total" "${jpg#$IMAGES_DIR/}" "${note:+ $note}"
    printf 'OK\tbackfill\t%s\t%s\n' "$jpg" "$note" >>"$RESULTS_FILE"
  else
    printf "[%3d/%-3d] ${RED}FAIL${NC} %s\n" "$n" "$total" "${jpg#$IMAGES_DIR/}"
    printf 'FAIL\tbackfill\t%s\tavifenc\n' "$jpg" >>"$RESULTS_FILE"
  fi
  rm -f "$tmp_orient"
}

# bounded job pool; workers ignore SIGINT (bash does this for async jobs
# anyway) so the current image finishes; the launcher stops handing out work
run_pool() {
  local -n tasks_ref=$1
  local total=${#tasks_ref[@]}
  local n=0 running=0 task kind path
  echo -e "${BLUE}Processing $total file(s) with $JOBS parallel job(s)${NC}"
  echo ""
  for task in "${tasks_ref[@]}"; do
    [ "$INTERRUPTED" = true ] && break
    IFS=$'\t' read -r kind path <<<"$task"
    n=$((n+1))
    ( process_"$kind" "$n" "$total" "$path" ) &
    running=$((running+1))
    if [ "$running" -ge "$JOBS" ]; then
      wait -n 2>/dev/null
      running=$((running-1))
    fi
  done
  wait
}

# ---------------------------------------------------------------- main
INTERRUPTED=false
trap 'INTERRUPTED=true; echo -e "\n${YELLOW}Interrupted - finishing in-flight images, no new work will start.${NC}"' INT

RESULTS_FILE=$(mktemp /tmp/resize_results.XXXXXX)
TASKS=()

case "$MODE" in
  coverage)
    coverage_report
    rm -f "$RESULTS_FILE"; exit 0 ;;

  backfill)
    scope_dirs=()
    if [ -n "$YEAR" ] && [ -n "$LOCATION" ]; then
      d=$(resolve_location_dir "$YEAR" "$LOCATION") || {
        echo -e "${RED}Error: no location matching '*_${LOCATION}' under $IMAGES_DIR/$YEAR${NC}"
        rm -f "$RESULTS_FILE"; exit 1; }
      scope_dirs=("$d")
    elif [ -n "$YEAR" ]; then
      [ -d "$IMAGES_DIR/$YEAR" ] || { echo -e "${RED}Error: $IMAGES_DIR/$YEAR not found${NC}"; rm -f "$RESULTS_FILE"; exit 1; }
      for d in "$IMAGES_DIR/$YEAR"/*/; do [ -d "$d" ] && scope_dirs+=("${d%/}"); done
    else
      for y in $(list_year_dirs); do
        for d in "$y"/*/; do [ -d "$d" ] && scope_dirs+=("${d%/}"); done
      done
    fi
    [ ${#scope_dirs[@]} -eq 0 ] && { echo -e "${RED}Error: no locations in scope${NC}"; rm -f "$RESULTS_FILE"; exit 1; }

    # thumbs first (first paint), then fulls; only missing AVIF unless --force
    for loc_dir in "${scope_dirs[@]}"; do
      for f in $(find_jpgs "$loc_dir/thumbs"); do
        if [ "$FORCE" = true ] || [ ! -f "${f%.*}.avif" ]; then
          TASKS+=("backfill"$'\t'"$f")
        fi
      done
    done
    for loc_dir in "${scope_dirs[@]}"; do
      for f in $(find_jpgs "$loc_dir/fulls"); do
        if [ "$FORCE" = true ] || [ ! -f "${f%.*}.avif" ]; then
          TASKS+=("backfill"$'\t'"$f")
        fi
      done
    done

    if [ "${#TASKS[@]}" -eq 0 ]; then
      echo -e "${GREEN}Nothing to do - every photo in scope already has AVIF coverage.${NC}"
      rm -f "$RESULTS_FILE"; exit 0
    fi

    echo -e "${BLUE}Backfill: ${#TASKS[@]} AVIF to create${NC} (from published JPGs, thumbs first)"
    if [ "$FORCE" = true ]; then
      n_existing=$(find "${scope_dirs[@]}" -maxdepth 2 -type f -iname '*.avif' 2>/dev/null | wc -l)
      echo -e "${YELLOW}--force: re-encodes $n_existing existing AVIF file(s) too${NC}"
      if [ "$ASSUME_YES" != true ]; then
        if [ -t 0 ]; then
          read -p "Re-encode ALL AVIF in scope (overwrites existing)? [y/N]: " CONFIRM
          [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; rm -f "$RESULTS_FILE"; exit 0; }
        else
          echo -e "${RED}Refusing --force without -y in non-interactive mode.${NC}"; rm -f "$RESULTS_FILE"; exit 1
        fi
      fi
    fi
    run_pool TASKS
    ;;

  normal)
    if [ -z "$YEAR" ] || [ -z "$LOCATION" ]; then
      echo -e "${RED}Error: Year and location are required${NC}"; rm -f "$RESULTS_FILE"; exit 1
    fi
    DIR=$(resolve_location_dir "$YEAR" "$LOCATION") || DIR=""
    if [ -z "$DIR" ]; then
      DIR="$IMAGES_DIR/$YEAR/$(get_indexed_location "$YEAR" "$LOCATION")"
    fi
    FULLS_DIR="$DIR/fulls"; THUMBS_DIR="$DIR/thumbs"
    mkdir -p "$FULLS_DIR" "$THUMBS_DIR"
    echo -e "${BLUE}Processing images for: $YEAR / $(basename "$DIR")${NC}"
    echo -e "Fulls: ${FULL_WIDTH}px JPG q$FULL_QUALITY + AVIF max $AVIF_FULL_QMAX | Thumbs: ${THUMB_WIDTH}px JPG q$THUMB_QUALITY + AVIF max $AVIF_THUMB_QMAX"

    shopt -s nullglob nocaseglob
    IMAGE_FILES=("$IMAGES_DIR"/*.{jpg,jpeg,png,tiff,tif,webp})
    shopt -u nullglob nocaseglob
    if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
      echo -e "${YELLOW}No images found in $IMAGES_DIR/${NC}"
      echo "Place your images in the '$IMAGES_DIR' directory and run again."
      rm -f "$RESULTS_FILE"; exit 0
    fi
    for img in "${IMAGE_FILES[@]}"; do
      [ -f "$img" ] && TASKS+=("original"$'\t'"$img")
    done
    run_pool TASKS
    ;;
esac

# ---------------------------------------------------------------- summary
PROCESSED=0; FAILED=0; WARNED=0; FAILURES=()
while IFS=$'\t' read -r status kind path detail; do
  case "$status" in
    OK)
      PROCESSED=$((PROCESSED+1))
      if [ "$MODE" = "normal" ] && [ -n "${detail:-}" ]; then WARNED=$((WARNED+1)); fi
      ;;
    FAIL) FAILED=$((FAILED+1)); FAILURES+=("[$kind] $path (${detail:-?})") ;;
  esac
done <"$RESULTS_FILE"

echo ""
echo -e "${GREEN}Done: $PROCESSED succeeded${NC}$( [ $FAILED -gt 0 ] && echo -e " ${RED}· $FAILED failed${NC}")$( [ $WARNED -gt 0 ] && echo -e " ${YELLOW}· $WARNED with avif warnings${NC}")"
if [ ${#FAILURES[@]} -gt 0 ]; then
  echo -e "${RED}Failures:${NC}"
  for f in "${FAILURES[@]}"; do echo "  - $f"; done
fi

# -d: delete only successfully processed originals, never after an interrupt
if [ "$MODE" = "normal" ] && [ "$DELETE_ORIGINALS" = true ]; then
  echo ""
  if [ "$INTERRUPTED" = true ]; then
    echo -e "${YELLOW}Run was interrupted - keeping all originals (nothing deleted).${NC}"
  else
    DELETED=0
    while IFS=$'\t' read -r status kind path detail; do
      if [ "$status" = OK ] && [ "$kind" = original ] && [ -f "$path" ]; then
        rm "$path"; DELETED=$((DELETED+1))
      fi
    done <"$RESULTS_FILE"
    if [ "$DELETED" -eq 0 ]; then
      echo -e "${YELLOW}No originals to delete - no image was processed successfully.${NC}"
    else
      echo -e "${GREEN}Deleted $DELETED original(s).${NC}"
    fi
  fi
fi

if [ "$MODE" = "backfill" ]; then
  echo ""
  coverage_report
fi

rm -f "$RESULTS_FILE"
if [ "$FAILED" -gt 0 ]; then exit 1; fi
exit 0
