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
| Repo | `github.com/a-d/pictrace` (origin). `master` ahead of `origin/master` by local commits (board/docs + PT9 self-hosted assets) — unpushed |
| Branches | `master` (default) · `redesign` · `multi-map` · `namibia` (feature branches, local + origin) |
| Working tree | **Dirty — active WIP** (~190 pending entries): ~170 staged adds of raw photos under `images/_2026-morocco/` + ~27 modified files (templates/JS/CSS/data/scripts) + 2 untracked. Do not bulk-commit, do not discard, do not unstage without the owner's call. |
| Untracked | `.agentbridge/` (local agent state) · `namib1.svg` (working file) — leave as-is |
| Task board | `KANBAN.md` — open: PT15 (lightbox gestures); PT10–PT14 deferred |

## Conventions (must-follow)

- **Prefer CSS over JavaScript — no-JS must always work.** Solve with pure CSS where possible (`:target`, `:has()`, transitions, media queries); use JavaScript only for non-functional visual/UX improvements (e.g. EXIF display, image fade-ins, journey-map fallback). Everything must degrade gracefully — with scripting disabled the gallery, lightbox and navigation stay fully usable. When a JS enhancement gates something visible, ship a CSS fallback via `@media (scripting: none)` (see `.nav-arrow` in `main.css`).
- **JS comments: `/* … */` only — never `//`.** The `compress.html` layout collapses the built HTML to single lines; a `//` comment would comment out the rest of that script. Applies to inline template scripts too.
- **Semantic HTML** — prefer `<article>/<section>/<figure>/<aside>/<nav>` over `<div>/<span>`; vanilla JS; CSS custom properties. More in `.clinerules`.
- **Commits:** Conventional Commits, scope = area — `feat(lightbox): …`, `fix(gallery): …`, `docs: …`. Commit **explicitly named files only** (`git commit --only -- <paths>`); the tree often carries unrelated WIP — never `git add -A`, never a bare `git commit`. End every completed task with a commit and report the message back to the owner.
- **Board:** `KANBAN.md` is the single source of truth for tasks (IDs `PT…`); move lanes only when actually started/finished; log decisions in its Decisions log.
- **Line endings:** most files are CRLF (Windows checkout) — keep them consistent.
- **Gotcha — `assets/` ignores *new* files** (`.gitignore` line `/assets/`): `main.css` / `main.js` are tracked and editable; a *new* file under `assets/` will be silently ignored — `git add -f` it or fix `.gitignore` (tell the owner first).
- **Secrets:** none in the repo. The `contact:` endpoint in `_config.yml` is a public Google Apps Script URL by design; no analytics keys configured. Keep it that way.

## How the site is built (orientation)

- **Config** `_config.yml`: `image_root: images`, `image_fulls_loc: fulls`, `image_thumbs_loc: thumbs`, `preload_count: 12`, `exif:` display list, `baseurl: ""`.
- **Layouts:** `_layouts/default2.html` (page shell — inlines `main.css` into a `<style>` tag, preloads the first N thumbnails, loads vendored exifr (`assets/js/vendor/exifr-7.1.3.lite.umd.js`) + `main.js`, both deferred) wrapped by `_layouts/compress.html` (jekyll-compress-html — the reason for the `//` ban).
- **Image pipeline:** originals → `./resize.sh` (ImageMagick + avifenc + exiftool) → `images/{year}/{NN}_{Location}/fulls` (1024px) + `/thumbs` (512px), JPG + AVIF, EXIF preserved. `rename.sh` stamps EXIF timestamps into filenames (`name~YYYYMMDD_HHMMSS.ext`).
- **Gallery:** `_includes/iterator.html` walks `site.static_files` under `fulls/` (skips `.avif`), groups year → location (newest first), sorts by `~` sort-key then natural name, and renders every image twice: `gallery_item.html` (grid thumbnails 512×384; first `preload_count` eager, rest `loading="lazy"`) and `popup_item.html` (lightbox slides).
- **Lightbox ("popup"):** pure CSS `:target`. `section.lightbox` shows when it contains `:target`; each slide is `figure.lightbox-container#p-{year}-{location}-{filename}`; prev/next are ordinary hash links; `#p` is the empty "closed" state; oversized `::before` hit zones make clicks on the left/right half of the screen navigate. EXIF is fetched on `hashchange` in `main.js` (range request of the first 64 KB of the JPG, parsed by exifr).
- **Journey maps:** `_data/journeys.yml` + `_includes/journeys/{Name}.svg`; travel path animates on scroll via `makeProgressMapper` (CSS scroll-timeline where supported, JS fallback); map tiles hidden ≤899px.
- **Assets:** all site CSS in `assets/css/main.css`, all site JS in `assets/js/main.js` — keep additions there (the only inline script is the journey progress bootstrap, generated from YAML). Third-party vendored files (self-hosted, PT9) live in `assets/js/vendor/` + `assets/fonts/` with their license files.

## Workflow

- **Local dev:** `bundle exec jekyll serve --host 0.0.0.0` (deps/Docker one-liner in README).
- **Deploy:** push to `master` → GitHub Pages rebuilds. No manual deploy.
- **Images:** `./resize.sh` (interactive) or `./resize.sh 2026 "Paris" [-d] [-v]`.
- **Testing:** no test suite — verify visually with `jekyll serve`; check responsive breakpoints (grid 5/4/3/2/1 columns; lightbox mobile rules ≤768px) and cold-cache behavior for image-loading changes.

## Directory map

```
AGENTS.md              This orientation doc
_config.yml            Jekyll config (image paths, preload_count, EXIF list, contact endpoint)
_data/journeys.yml     Journey metadata + animation curves
_includes/             iterator.html · gallery[.html|_item.html] · popup[.html|_item.html] · journeys/*.svg
_layouts/              default2.html (shell) · compress.html (minifier wrapper)
assets/css/main.css    All styles
assets/js/main.js      All JS (journeys, gallery, EXIF, lightbox helpers)
images/                {year}/{NN}_{Location}/{fulls,thumbs} · LICENSE.photos · _2026-morocco/ (WIP raws)
index.html             Page entry: header, gallery, popup, spot/about popovers
0/ · _p1/              Raw-photo staging dirs (mostly gitignored, never deployed)
resize.sh · rename.sh  Image processing / renaming helpers
_site/                 Generated output (gitignored)
.clinerules            Detailed project rulebook — read before editing content/templates
KANBAN.md              Task board
```

## Pitfalls observed

- Any filename containing `~` is treated as a sort-key file by `iterator.html` (key = text after the first `~`; see `rename.sh`).
- Lightbox `<img>`s are `loading="lazy"` inside a `display:none` container — they may not start loading until their slide becomes `:target` (relevant to KANBAN PT2).
- `git status` is noisy right now by design (WIP) — read it carefully before staging anything.
