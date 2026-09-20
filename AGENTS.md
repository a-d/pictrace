# AGENTS.md — Pictrace

Operating notes for AI agents (Cline, Hermes, others) working in this repository.
Read this first, then [.clinerules](.clinerules) — the authoritative rulebook for content/template/code conventions.

## What this is

Pictrace is a Jekyll photo blog — Alexander Dümont's photography grouped by year and location, with a hash-based lightbox ("popup") showing EXIF data, and scroll-animated SVG "journey" maps for select trips. Published on GitHub Pages at **https://pictrace.de**.

- Upstream template: fork of [rampatra/photography](https://github.com/rampatra/photography). Code: GPL-3.0 (`LICENSE`). **Photographs: © Alexander Dümont, all rights reserved** (`images/LICENSE.photos`) — never reuse or re-publish them.
- Stack: Jekyll + Liquid, vanilla JS, plain CSS. No npm, no frameworks, no build step beyond Jekyll.
- Local paths: Windows `C:\Users\James\IdeaProjects\pictrace` · WSL `/mnt/c/Users/James/IdeaProjects/pictrace`.

## Current state (2026-09-20)

| Area | State |
|---|---|
| Live site | https://pictrace.de — GitHub Pages, publishes from default branch `master` |
| Repo | `github.com/a-d/pictrace` (origin). PT14 (history rewrite) is pushed. PT12 + PT16 are local commits ahead of `origin/master` — **unpushed** |
| Branches | `master` only — `redesign` / `multi-map` / `namibia` were deleted in PT14 (the `multi-map` WIP is kept as `.hermes/plan/PT14-audit/multi-map-wip.patch`) |
| Working tree | Clean apart from two untracked entries (below). The ~170 staged Morocco raw photos are gone from the index — PT14 rescued the sources to `IdeaProjects/pictrace-morocco-sources/` (md5-verified) and `images/_2026-morocco/` no longer exists |
| Untracked | `.agentbridge/` (local agent state) · `namib1.svg` (working file) — leave as-is |
| Task board | `KANBAN.md` — PT16 implemented (unpushed); PT10 parked; PT11–PT13 deferred/dormant |

## Conventions (must-follow)

- **Prefer CSS over JavaScript — no-JS must always work.** Solve with pure CSS where possible (`:target`, `:has()`, transitions, media queries); use JavaScript only for non-functional visual/UX improvements (e.g. EXIF display, image fade-ins, progressive batch loading). Everything must degrade gracefully — with scripting disabled the gallery, lightbox and navigation stay fully usable. When a JS enhancement gates something visible, ship a CSS fallback via `@media (scripting: none)` (see `.nav-prev` / `.nav-next` in `main.css`).
- **JS comments: `/* … */` only — never `//`.** The `compress.html` layout collapses the built HTML to single lines; a `//` comment would comment out the rest of that script. Applies to inline template scripts too.
- **Semantic HTML** — prefer `<article>/<section>/<figure>/<aside>/<nav>` over `<div>/<span>`; vanilla JS; CSS custom properties. More in `.clinerules`.
- **Commits:** Conventional Commits, scope = area — `feat(lightbox): …`, `fix(gallery): …`, `docs: …`. Commit **explicitly named files only** (`git commit --only -- <paths>`); the tree often carries unrelated WIP — never `git add -A`, never a bare `git commit`. End every completed task with a commit and report the message back to the owner.
- **Line endings — per file, and binaries are never normalised.** `_config.yml`, templates, CSS and JS are **LF** in git; `KANBAN.md` and `AGENTS.md` are **CRLF**. The drvfs worktree may report either, so commit through a temp index (`GIT_INDEX_FILE=… git read-tree HEAD`, `git hash-object -w`, `git update-index --cacheinfo`) that stores each file with its existing convention — and **never** run LF normalisation over JPEG/AVIF binaries (it corrupts them). Finish with `git reset -q` so the real index is refreshed to the new HEAD.
- **Board:** `KANBAN.md` is the single source of truth for tasks (IDs `PT…`); move lanes only when actually started/finished; log decisions in its Decisions log.
- **Gotcha — `assets/` ignores *new* files** (`.gitignore` line `/assets/`): `main.css` / `main.js` are tracked and editable; a *new* file under `assets/` will be silently ignored — `git add -f` it or fix `.gitignore` (tell the owner first).
- **Secrets:** none in the repo. The `contact:` endpoint in `_config.yml` is a public Google Apps Script URL by design; no analytics keys configured. Keep it that way.

## How the site is built (orientation)

- **Config** `_config.yml`: `image_root: images`, `image_fulls_loc: fulls`, `image_thumbs_loc: thumbs`, `preload_count: 12`, `exif:` display list, `baseurl: ""`, `url: "https://pictrace.de"` (used by jekyll-sitemap), **`prerender_locations: 5`** (PT16 — how many locations the index renders inline), a `locations` collection (`output: true`) and an `exclude:` list for local tooling.
- **Layouts:** `_layouts/default2.html` (page shell — inlines `main.css` **through `site.pages`**, preloads the page's first thumbnails, loads vendored exifr (`assets/js/vendor/exifr-7.1.3.lite.umd.js`) + `main.js`, both deferred) wrapped by `_layouts/compress.html` (jekyll-compress-html — the reason for the `//` ban). `_layouts/location.html` (PT16) renders a single location page: title, scoped gallery, links block.
- **Image pipeline:** originals → `./resize.sh` (ImageMagick + avifenc + exiftool) → `images/{year}/{NN}_{Location}/fulls` (1024px) + `/thumbs` (512px), JPG + AVIF, EXIF preserved. `rename.sh` stamps EXIF timestamps into filenames (`name~YYYYMMDD_HHMMSS.ext`).
- **Gallery:** `_includes/iterator.html` walks `site.static_files` under `fulls/` (skips `.avif`), groups year → location (newest first), sorts by `~` sort-key then natural name, and renders **one `<article>` per photo** — the lightbox `figure` lives inside its grid article (PT12 merged the two renders). Scope parameters: `only_year`, `only_location`, `limit_locations` (the index prerender) and `with_ids` (a first pass that collects every slide id so the prev/next chain is precomputed). Slide ids are `p-{yy}-{locnum}-{basename}`; section anchors are `p-{yy}` (year) and `p-{yy}-{locnum}` (location) — scheme documented in `.clinerules`.
- **Per-location pages (PT16):** every location has a static page at `/{year}/{NN}_{Location}/`, generated from front-matter-only stubs in `_locations/*.html` — **regenerate them with `./mklocations.sh`** after adding or renaming a location (a missing stub = a missing page = a 404 from the links block). The index prerenders the newest `prerender_locations` (5) locations and lists every location in `<nav class="location-links">` (legacy order), which doubles as the id → page manifest for the JS.
- **Progressive loading (PT16):** with JS, `main.js` fetches the next batch of 5 location pages as the visitor approaches the end (IntersectionObserver on the links nav), injects their galleries, rewires the prev/next chain at both batch boundaries, re-registers injected journey maps from their `data-progress` attributes and rewires popover links to the now-in-page anchors. A deep link (`#p-…`) to a non-prerendered photo hops to that photo's location page. Without JS: the prerendered 5 locations plus the links block.
- **Lightbox ("popup"):** pure CSS `:target`. The targeted `figure.lightbox-container` is the fixed overlay (inside its article); prev/next are ordinary hash links; `#p` is the empty "closed" state; oversized `::before` hit zones make clicks on the left/right half of the screen navigate. EXIF is fetched on `hashchange` in `main.js` (range request of the first 64 KB of the JPG, parsed by exifr).
- **Journey maps:** `_data/journeys.yml` + `_includes/journeys/{Name}.svg`; travel path animates on scroll via `makeProgressMapper` (CSS scroll-timeline where supported, JS fallback); map tiles hidden ≤899px. The journey data reaches the page as `data-progress` attributes on the map `<aside>` — inline scripts do not run for injected HTML, so `main.js` initialises injected maps itself.
- **Assets:** all site CSS in `assets/css/main.css`, all site JS in `assets/js/main.js` — keep additions there. The only inline script is the contact-form `handleSubmit` in `_includes/site-popovers.html`. Third-party vendored files (self-hosted, PT9) live in `assets/js/vendor/` + `assets/fonts/` with their license files.

## Workflow

- **Local dev:** `bundle exec jekyll serve --host 0.0.0.0` (deps/Docker one-liner in README).
- **Local build:** `jekyll build -s . -d /tmp/site` (Jekyll 3.10 + jekyll-sitemap; ~80 s for ~1 900 photos + 56 location pages).
- **Deploy:** push to `master` → GitHub Pages rebuilds. No manual deploy.
- **Images:** `./resize.sh` (interactive) or `./resize.sh 2026 "Paris" [-d] [-v]`; `./mklocations.sh` after adding locations.
- **Testing:** no test suite — verify visually with `jekyll serve`; check responsive breakpoints (grid 5/4/3/2/1 columns; lightbox mobile rules ≤768px) and cold-cache behavior for image-loading changes. For the PT16 loader, a `file://` fixture (index + a few location pages) works: fetch the pages over `file://` and stub `window.fetch` if the browser blocks it.

## Directory map

```
AGENTS.md              This orientation doc
_config.yml            Jekyll config (image paths, preload_count, EXIF list, contact endpoint, prerender_locations)
_data/journeys.yml     Journey metadata + animation curves
_includes/             iterator.html · gallery[.html|_item.html] · popup[.html|_item.html] · site-header.html · site-popovers.html · location-links.html · journeys/*.svg
_layouts/              default2.html (shell) · location.html (PT16 location page) · compress.html (minifier wrapper)
_locations/            Per-location page stubs (front matter only) — generated by mklocations.sh
assets/css/main.css    All styles (a Jekyll page: front matter, inlined via site.pages)
assets/js/main.js      All JS (journeys, gallery, EXIF, lightbox helpers, PT16 batch loader)
images/                {year}/{NN}_{Location}/{fulls,thumbs} · LICENSE.photos · bg-blurred.jpg (baked backdrop)
index.html             Page entry: header, prerendered gallery, popovers, all-locations links
mklocations.sh         Regenerates the _locations/ stubs from images/{year}/{NN}_{Location}/
0/ · _p1/              Raw-photo staging dirs (mostly gitignored, never deployed)
resize.sh · rename.sh  Image processing / renaming helpers
_site/                 Generated output (gitignored)
.clinerules            Detailed project rulebook — read before editing content/templates
KANBAN.md              Task board
```

## Pitfalls observed

- **Re-run `./mklocations.sh` whenever locations change** — a missing stub means a missing page; the links block (and the sitemap) would point at a 404.
- **`content-visibility: auto` implies containment** — it re-anchors `position: fixed` descendants (the lightbox overlay) to their article, shrinking it to the grid cell. The `body:has(.lightbox-container:target)` guard must reset **both** `contain: none` **and** `content-visibility: visible`; `contain: none` alone does not undo it.
- **`contain-intrinsic-size` must be `auto calc(100vw/N)`** (N = the column count at that breakpoint) — a fixed placeholder (e.g. `auto 512px 384px`) inflates the page height by more than 60 %.
- The lightbox backdrop is a **baked** 96 px blur (`images/bg-blurred.jpg`, ~1.7 KB, regenerated by `./blur-bg.sh`) — the runtime `backdrop-filter` was removed because it re-anchored fixed descendants (same class of bug as `content-visibility`).
- Any filename containing `~` is treated as a sort-key file by `iterator.html` (key = text after the first `~`; see `rename.sh`).
- Lightbox `<img>`s are `loading="lazy"` inside a `display:none` container — they may not start loading until their slide becomes `:target` (relevant to KANBAN PT2).
- `git status` is noisy whenever WIP is present — read it carefully before staging anything.
