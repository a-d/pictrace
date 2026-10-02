#!/usr/bin/env bash
# mklocations.sh - (re)generate the per-location and per-year page stubs in
# _locations/ and _years/ (PT16/PT20), and check them for drift (PT30).
#
# Each stub is a tiny front-matter file; the actual page is rendered by
# _layouts/location.html resp. _layouts/year.html via _includes/iterator.html
# (a single-location / single-year scope).
# Run this after adding a new location (or any time - it rewrites all stubs).
#
# PT30 - why this matters: the site's location links are enumerated from the
# *images*, so a location directory without its stub is a live 404 (the links
# nav, the year quick-links and the sitemap point at the missing page). And a
# stub that exists on disk but was never committed is *still* a 404 once
# pushed. Helpers:
#   ./mklocations.sh              (re)write all stubs; flags stubs not in git HEAD
#   ./mklocations.sh --check      report missing/stale stubs, exit 1 on drift (no writes)
#   ./mklocations.sh --expected   print the expected stub paths (for tooling/guards)
# resize.sh runs this at the end of a run; mkcommit.sh auto-includes stubs that
# are missing from HEAD in the commit it is about to make.
set -euo pipefail
cd "$(dirname "$0")"

MODE=write
case "${1:-}" in
  --check)    MODE=check ;;
  --expected) MODE=expected ;;
  "")         ;;
  *) echo "mklocations.sh: unknown option: $1 (supported: --check, --expected)" >&2; exit 2 ;;
esac

mkdir -p _locations _years

expected=()
count=0
years=0
for year_dir in images/[0-9][0-9][0-9][0-9]; do
  [ -d "$year_dir" ] || continue
  year=$(basename "$year_dir")
  year_count=0
  for loc_dir in "$year_dir"/*/; do
    dir=$(basename "$loc_dir")
    [ -d "${loc_dir}fulls" ] || continue
    locnum=${dir%%_*}
    name=${dir#*_}
    expected+=("_locations/${year}-${dir}.html")
    if [ "$MODE" = write ]; then
      cat > "_locations/${year}-${dir}.html" <<EOF
---
layout: location
title: "${name} — ${year}"
year: "${year}"
locdir: "${dir}"
locname: "${name}"
locnum: "${locnum}"
permalink: /${year}/${dir}/
---
EOF
    fi
    count=$((count+1))
    year_count=$((year_count+1))
  done
  # a year page exists only when the year has at least one location
  if [ "$year_count" -gt 0 ]; then
    expected+=("_years/${year}.html")
    if [ "$MODE" = write ]; then
      cat > "_years/${year}.html" <<EOF
---
layout: year
title: "${year}"
year: "${year}"
permalink: /${year}/
---
EOF
    fi
    years=$((years+1))
  fi
done

if [ "$MODE" = expected ]; then
  printf '%s\n' "${expected[@]}"
  exit 0
fi

# drift: the expected stub set vs. what is on disk
missing=()
stale=()
for f in "${expected[@]}"; do
  [ -f "$f" ] || missing+=("$f")
done
shopt -s nullglob
for f in _locations/*.html _years/*.html; do
  known=false
  for e in "${expected[@]}"; do [ "$e" = "$f" ] && { known=true; break; }; done
  $known || stale+=("$f")
done
shopt -u nullglob

if [ "$MODE" = check ]; then
  if [ "${#missing[@]}" -eq 0 ] && [ "${#stale[@]}" -eq 0 ]; then
    echo "mklocations.sh: in sync - ${count} location stubs, ${years} year stubs"
    exit 0
  fi
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "mklocations.sh: MISSING stubs (a location directory has no page => 404):"
    printf '  %s\n' "${missing[@]}"
  fi
  if [ "${#stale[@]}" -gt 0 ]; then
    echo "mklocations.sh: STALE stubs (no matching images/<year>/<NN>_<Name>/fulls):"
    printf '  %s\n' "${stale[@]}"
  fi
  echo "mklocations.sh: run ./mklocations.sh to regenerate, then commit the changes"
  exit 1
fi

echo "mklocations.sh: wrote ${count} location stubs to _locations/ and ${years} year stubs to _years/"
if git rev-parse --git-dir >/dev/null 2>&1; then
  uncommitted=()
  for f in "${expected[@]}"; do
    git cat-file -e "HEAD:$f" 2>/dev/null || uncommitted+=("$f")
  done
  if [ "${#uncommitted[@]}" -gt 0 ]; then
    echo "mklocations.sh: NEW stub(s) not yet in git HEAD - commit them or the page stays a 404 after push:"
    printf '  %s\n' "${uncommitted[@]}"
  fi
fi
