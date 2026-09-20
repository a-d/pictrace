#!/usr/bin/env bash
# mklocations.sh - (re)generate the per-location and per-year page stubs in
# _locations/ and _years/ (PT16/PT20).
#
# Each stub is a tiny front-matter file; the actual page is rendered by
# _layouts/location.html resp. _layouts/year.html via _includes/iterator.html
# (a single-location / single-year scope).
# Run this after adding a new location (or any time - it rewrites all stubs).
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p _locations _years
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
    year_count=$((year_count+1))
  done
  # a year page exists only when the year has at least one location
  if [ "$year_count" -gt 0 ]; then
    cat > "_years/${year}.html" <<EOF
---
layout: year
title: "${year}"
year: "${year}"
permalink: /${year}/
---
EOF
    years=$((years+1))
  fi
done
echo "mklocations.sh: wrote ${count} location stubs to _locations/ and ${years} year stubs to _years/"
