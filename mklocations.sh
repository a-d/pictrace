#!/usr/bin/env bash
# mklocations.sh - (re)generate the per-location page stubs in _locations/ (PT16).
#
# Each stub is a tiny front-matter file; the actual page is rendered by
# _layouts/location.html via _includes/iterator.html (single location scope).
# Run this after adding a new location (or any time - it rewrites all stubs).
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p _locations
count=0
for year_dir in images/[0-9][0-9][0-9][0-9]; do
  [ -d "$year_dir" ] || continue
  year=$(basename "$year_dir")
  for loc_dir in "$year_dir"/*/; do
    dir=$(basename "$loc_dir")
    [ -d "${loc_dir}fulls" ] || continue
    locnum=${dir%%_*}
    name=${dir#*_}
    stub="_locations/${year}-${dir}.html"
    cat > "$stub" <<EOF
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
    count=$((count+1))
  done
done
echo "mklocations.sh: wrote ${count} stubs to _locations/"
