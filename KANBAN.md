# Pictrace — Kanban

> Board seeded 2026-09-20. Priorities: **P1** core · **P2** important · **P3** nice-to-have · **P4** later.
> Site: https://pictrace.de (GitHub Pages, deploys from `master`). Conventions & current state: [AGENTS.md](AGENTS.md).
> ⚠️ The working tree currently carries unrelated WIP (see AGENTS.md) — commit only explicitly named files.

## 📋 Open

| ID | Prio | Task |
|---|---|---|
| PT16 | P3 | Per-location pages + progressive single-page loading (N=5 prerendered, all-location link list, JS batch insert on scroll) — plan + issue list in `.hermes/plan/PT16-per-location-pages.md`; awaiting owner confirm on the open questions |

## 🔵 In progress

_(empty)_

## ⛔ Blocked

_(empty)_

## ⏸️ Deferred

| ID | Prio | Task |
|---|---|---|
| PT10 | P3 | Build via GitHub Actions (Jekyll 4 + plugins) — parked 2026-09-20: keep the default Pages build (trigger-based escape hatch, see plan) |
| PT11 | P3 | Image pipeline: AVIF for 2024–25 (1468 photos), parallelize resize.sh, quality re-tune, optional srcset |
| PT12 | P4 | Scaling: single-page payload — **partially landed 2026-09-20** (batches 1+2: merge wrappers, trims, whitespace collapse, fragment compaction; −20 % raw / −12.6 % gzip); remaining: split strategy → PT16 |
| PT13 | P4 | Framework evaluation spike: Astro vs Eleventy vs Jekyll-4 (prototype first) — dormant 2026-09-20: gated by the PT10 decision — every outcome except staying on Jekyll requires reopening the deploy question (see plan) |

## ✅ Done

| ID | Prio | Task |
|---|---|---|
| PT1 | P2 | Lightbox: navigate with ← / → arrow keys — ✅ done 2026-09-20 (commit `1f7d83e7b1a834a36e867cae6107ef47e3895f6f`) |
| PT2 | P2 | Lightbox: arrows revealed only once the slide image is ready — ✅ done 2026-09-20 (commit `822ad561eeae1903566feb253587900e5e98ab98`) |
| PT5 | P2 | resize.sh: `-d` deletes only originals whose outputs were created — ✅ done 2026-09-20 (commit `03a2c446377a9c0b9cf40745c4442c80b2ac7c4b`) |
| PT3 | P2 | Build: precomputed AVIF path set replaces per-image scans — ✅ done 2026-09-20 (commit `5af1685c02ed16f54ae63c6eedcc4f71099b4063`) |
| PT4 | P2 | Preload: thumbs preload AVIF when present, else JPG — ✅ done 2026-09-20 (commit `aebc45b6327391fb85668502ed68ee2a63b0dc61`) |
| PT6 | P2 | Zoom: pinch-zoom in the lightbox only; lightbox controls labeled — ✅ done 2026-09-20 (commit `fd5a57486ec1f1c7d1cd6022e0fc2de9b11dba96`) |
| PT7 | P3 | Housekeeping: `_site` junk deleted (−3.7 GB), `.travis.yml` removed, Jekyll excludes added, `/0/` ignores collapsed, `git gc` — ✅ done 2026-09-20 (commit `09443960cbdec69e0c1efc8e9f8dd506a9895465`) |
| PT8 | P3 | CSS/HTML hygiene: dead `::after` block + unmatched `#gallery-close` rules removed, `24+0`→`24n+0`, dead form attrs — ✅ done 2026-09-20 (commit `5a0e06b5878c1334a075c74bf946d339df19fba7`) |
| PT9 | P3 | Self-host exifr + FontAwesome: exifr 7.1.3 (MIT) + FA 4.7.0 webfont (SIL OFL 1.1) vendored to `assets/js/vendor/` + `assets/fonts/` with license files; CDN refs removed — ✅ done 2026-09-20 (commit `81e7fc63c38804e73c2fab99c4b38bec1215ac37`) |
| PT15 | P2 | Lightbox gestures: horizontal wheel/trackpad + swipe for prev/next (delegates to PT1's `.nav-prev`/`.nav-next`) — ✅ done 2026-09-20 (commit `4d2e37692e7df2037b95d22aed8e2f7cfae5a750`) |
| PT14 | P4 | Repo history: rescue + prune + rewrite executed and **pushed 2026-09-20** — `.git` 3.6 → **1.2 GB**; 170 source files rescued to `pictrace-morocco-sources/`; old `images/fulls/` stripped from history; origin branches deleted; Pages rebuilt — ✅ done 2026-09-20 (commit `c0a35d6`) |

## Task details

Per-task details live in `.hermes/plan/` — one file per task (local-only, not committed):

| Task | Details |
|---|---|
| PT1 | [`.hermes/plan/PT1.md`](.hermes/plan/PT1.md) — ✅ done 2026-09-20 |
| PT2 | [`.hermes/plan/PT2.md`](.hermes/plan/PT2.md) — ✅ done 2026-09-20 |
| PT3 | [`.hermes/plan/PT3-build-time-liquid-avif-lookup.md`](.hermes/plan/PT3-build-time-liquid-avif-lookup.md) — ✅ done 2026-09-20 |
| PT4 | [`.hermes/plan/PT4-preload-avif-guard.md`](.hermes/plan/PT4-preload-avif-guard.md) — ✅ done 2026-09-20 |
| PT5 | [`.hermes/plan/PT5-resize-sh-delete-safety.md`](.hermes/plan/PT5-resize-sh-delete-safety.md) — ✅ done 2026-09-20 |
| PT6 | [`.hermes/plan/PT6-a11y-quick-wins.md`](.hermes/plan/PT6-a11y-quick-wins.md) — ✅ done 2026-09-20 |
| PT7 | [`.hermes/plan/PT7-housekeeping.md`](.hermes/plan/PT7-housekeeping.md) — ✅ done 2026-09-20 |
| PT8 | [`.hermes/plan/PT8-css-html-hygiene.md`](.hermes/plan/PT8-css-html-hygiene.md) — ✅ done 2026-09-20 |
| PT9 | [`.hermes/plan/PT9-self-host-external-assets.md`](.hermes/plan/PT9-self-host-external-assets.md) — ✅ done 2026-09-20 |
| PT10 | [`.hermes/plan/PT10-github-actions-build.md`](.hermes/plan/PT10-github-actions-build.md) — parked (decision 2026-09-20) |
| PT11 | [`.hermes/plan/PT11-image-pipeline-modernization.md`](.hermes/plan/PT11-image-pipeline-modernization.md) — deferred |
| PT12 | [`.hermes/plan/PT12-scaling-architecture.md`](.hermes/plan/PT12-scaling-architecture.md) — partially implemented 2026-09-20 (commits `1f1b98c`, `69ad0b1`) |
| PT16 | [`.hermes/plan/PT16-per-location-pages.md`](.hermes/plan/PT16-per-location-pages.md) — planned |
| PT13 | [`.hermes/plan/PT13-framework-spike.md`](.hermes/plan/PT13-framework-spike.md) — dormant (gated by PT10, 2026-09-20) |
| PT14 | [`.hermes/plan/PT14-repo-history-size.md`](.hermes/plan/PT14-repo-history-size.md) — ✅ done 2026-09-20 (push verified) |
| PT15 | [`.hermes/plan/PT15-lightbox-gestures.md`](.hermes/plan/PT15-lightbox-gestures.md) — ✅ done 2026-09-20 |

## Decisions log

| Date | Decision |
|---|---|
| 2026-09-20 | PT14 push verified — owner force-pushed `master` (`c0a35d6`); origin branches `redesign`/`namibia`/`multi-map` deleted; remote tree matches local (`2da1d517…`); Pages rebuild for `c0a35d6` succeeded; `master` in sync with `origin/master`; fresh clone check passed. Local `.git` 1.2 GB. GitHub repo-size figure shrinks over time (server gc is eventual — was ~1.5 GB at push time). |
| 2026-09-20 | PT14 executed (local) — (1) **Rescue first:** 170 files (163 full-size Morocco sources + 7 staged `P8010*`) → `IdeaProjects/pictrace-morocco-sources/`, md5-verified (2,319.6 MB), then the 7 staged phantoms unstaged. (2) **Prune:** `reflog expire` + `gc --prune=now` removed the 2.22 GB cruft pack (+63 MB phantoms) → `.git` 3.6 → 1.5 GB. (3) **Rewrite:** git-filter-repo `--path images/fulls/ --invert-paths --strip-blobs-bigger-than 2M` — the pre-restructure originals (~347 MB, 240 versions) removed from all history; content trees preserved (state commit tree byte-identical, `a157377a…`; `fsck` clean); `.git` now **1.2 GB** (single pack). Old→new commit hashes: `.hermes/plan/PT14-audit/filter-repo/commit-map` — the hashes previously listed on this board were remapped through it. (4) Local branches `redesign`/`namibia`/`multi-map` deleted (all merged; multi-map wip archived as `PT14-audit/multi-map-wip.patch`). (5) `origin` remote re-added (filter-repo removes it by design). Safety net: pre-rewrite bundle (1.57 GB, all refs) + WIP patches + untracked copies in `IdeaProjects/pictrace-backups/`. Notes: executed in place; a parallel session was committing during the operation (its PT12 blur-backdrop work is preserved — re-verified). **Remaining (owner):** `git push --force-with-lease=refs/heads/master:d809adac857028b69d10316617ec98ba36e3ffef origin master` + `git push origin --delete redesign namibia multi-map` (server-side gc afterwards is eventual). |
| 2026-09-20 | PT16 opened — per-location pages + progressive single-page loading (owner-proposed: every location gets a page; the index prerenders N=5; a links block lists all pages in legacy order; JS inserts the next batch before the viewport reaches the end; lazy loading unchanged). Plan confirms the approach with must-solves: deep links into unloaded locations (the links block doubles as the id→page manifest), journey-map re-init for injected content (inline scripts do not run — move the data to `data-*` attributes), prev/next chain rewiring at batch boundaries, page generation via a Jekyll collection + generated stubs (no plugins on the default Pages build). Details: `.hermes/plan/PT16-per-location-pages.md`. |
| 2026-09-20 | PT12 batch 2 done — fragment compaction: slide ids `p-{yy}-{locnum}-{basename}` (mean 32.8 → 21.4 chars), section anchors `p-{yy}` / `p-{yy}-{locnum}`, redundant `nav-arrow` class dropped; `.clinerules` documents the scheme. Verified: prev/next chain self-consistent, tile links match slide order, all in-page links resolve. 1.46 MB → 1.34 MB raw, gzip 72.4 KB; both batches together −20 % raw / −12.6 % gzip. Previously shared `#p-…` links break (fragments cannot redirect). Commit `69ad0b1`. |
| 2026-09-20 | PT12 batch 1 done — merge wrappers (each photo now has one root: the slide `figure` lives inside its gallery `<article>`; the iterator renders once with a precomputed id list, keeping the global prev/next chain identical), micro-trims (`data-name` removed, literal ❮/❯, shorter aria-labels), whitespace collapse in `compress.html` (−164 KB of inter-tag runs), lightbox CSS reworked (targeted figure is the fixed overlay; backdrop via `figure::before`; the shared `.close` link is the click-anywhere catcher; `contain`/`backdrop-filter` are neutralised while open because both re-anchor fixed descendants — verified empirically). Checks: chain byte-identical to the old build, all links resolve, lightbox geometry pixel-identical to the live site (desktop + mobile emulation), no-JS arrows visible, location/year filter unchanged. 1.67 MB → 1.46 MB raw, gzip 82.8 → 74.1 KB. Commit `1f1b98c`. |
| 2026-09-20 | PT13 set dormant — gated by the PT10 decision (native build stays): Jekyll-4 can't run on the native builder (env pins Jekyll 3.10.0 / github-pages 232) and Astro/Eleventy can't be built natively at all; any outcome requires reopening the deploy question first (custom build / prebuilt output / other host). If it reopens, decide PT10 + PT13 together. Plan note added: `.hermes/plan/PT13-framework-spike.md`. |
| 2026-09-20 | **PT10 parked — stay on the default Pages build** (owner call: stick with the current solution). Findings: the site is already built by a vendor-owned Actions workflow (`pages-build-deployment`; run #131 success, 2m22s; build job = `ghcr.io/actions/jekyll-build-pages:v1.0.13`; env Jekyll 3.10.0 / github-pages 232 / ruby 3.3.4). Original rationale corrected: SEO plugins already whitelisted (jekyll-seo-tag 2.8.0, jekyll-sitemap 1.4.0); the 10-min limit is a deploy timeout that applies to custom workflows too; the run page already shows jobs + annotations. Revisit triggers: a non-whitelisted plugin or custom build actually wanted · vendor pipeline failing · 10 builds/h soft throttle hit (worst burst so far ≈5/h) · branch-deploy deprecation signals · PT13 keeps Jekyll and adds build needs. Side findings: deploy warns "artifact 1.03 GB exceeds the allowed size of 1 GB — deployment might fail" → weight reduction is the PT11 lever (pipeline-independent); Gemfile pins were behind the live env → aligned (commit `3e8ec49`). Plan: `.hermes/plan/PT10-github-actions-build.md`. |
| 2026-09-20 | PT15 done — lightbox gestures: horizontal trackpad/wheel (≥45 px cumulative, 220 ms quiet-lock absorbs inertia, ctrl/meta+wheel ignored) + one-finger swipe (≥50 px, 1.5× ratio, single-touch only — pinch/pan & touchcancel safe); both delegate to PT1's `.nav-prev`/`.nav-next`. 24/24 stub-DOM harness tests (`.hermes/plan/PT15-tests.js`); owner phone test pending (rides with PT6). Commit `4d2e376`. |
| 2026-09-20 | PT9 done — exifr 7.1.3 (MIT) + FontAwesome 4.7.0 woff2 (SIL OFL 1.1) self-hosted (`assets/js/vendor/`, `assets/fonts/`) with license files; both verified byte-identical to upstream (sha256). License check: mirroring allowed (MIT/OFL); the EU GDPR risk (third-party CDN embedding) is removed by this change. Browser check: only first-party requests. Commit `81e7fc6`. New `assets/` files committed via `git add -f` (`/assets/` ignore pending owner decision). |
| 2026-09-20 | PT15 opened — lightbox gestures: horizontal wheel (PC) + one-finger swipe (mobile) for prev/next, reusing PT1's delegation to the `.nav-prev`/`.nav-next` links. Details: `.hermes/plan/PT15-lightbox-gestures.md`. |
| 2026-09-20 | PT8 done — dead CSS/HTML stripped (commented ::after block, unmatched #gallery-close rules), 24+0→24n+0 (no visual change), dead form attrs removed. Footer `Design:` credit + `.gitignore /assets/` line flagged for owner decision. Commit `5a0e06b`. |
| 2026-09-20 | PT7 done — `_site` junk (root 3.7 GB + nested 33 MB) deleted, dead `.travis.yml` removed, build excludes added, `/0/` ignores collapsed, `git gc` packed 6,913 loose objects (4.78 GiB → consolidated). Commit `0944396`. |
| 2026-09-20 | PT6 done — pinch-zoom is lightbox-only (`user-scalable=no` removed; `touch-action: pan-x pan-y` on the gallery; works on modern iOS; desktop/layout unaffected). Aria labels on prev/next/close; owner phone test pending. Commit `fd5a57486ec1f1c7d1cd6022e0fc2de9b11dba96`. |
| 2026-09-20 | PT6 scope refined per owner: pinch-zoom is wanted **on the opened photo only** — overview stays fixed, big-screen layout scaling unchanged. Chosen mechanism: drop `user-scalable=no`, apply `touch-action: pan-x pan-y` to the gallery (works on modern iOS too; see .hermes/plan/PT6). |
| 2026-09-20 | PT3 done — precomputed AVIF set replaces O(N·M) per-image scans (3,821-path equivalence test, 0 mismatches). Fix commit `5af1685c02ed16f54ae63c6eedcc4f71099b4063`. |
| 2026-09-20 | PT4 done — thumb preloads guarded (AVIF if present, else JPG; no 404 preloads). Fix commit `aebc45b6327391fb85668502ed68ee2a63b0dc61`. |
| 2026-09-20 | PT5 done — resize.sh `-d` deletes only successfully processed originals (interrupted runs delete nothing; unknown flags warn). Fix commit `03a2c446377a9c0b9cf40745c4442c80b2ac7c4b`. |
| 2026-09-20 | Source review completed (templates, JS, CSS, scripts, assets, history). Findings + plans in `.hermes/plan/2026-09-20-source-review.md`; PT3–PT9 opened (quick wins), PT10–PT14 deferred (refactors / higher risk). |
| 2026-09-20 | PT2 done — nav arrows hidden until the slide image is ready (`img-ready` + opacity fade; `@media (scripting: none)` keeps them visible without JS; links stay clickable while hidden). Fix commit `822ad561eeae1903566feb253587900e5e98ab98`. |
| 2026-09-20 | PT1 done — keyboard navigation via arrow keys (`1f7d83e7b1a834a36e867cae6107ef47e3895f6f`). Task details moved to `.hermes/plan/` (one file per task). |
| 2026-09-20 | AGENTS.md + KANBAN.md created; PT1/PT2 opened (P2). Lightbox stays hash/`:target`-based — enhancements go through `main.js` + arrow CSS, no re-architecture. |
| 2026-09-20 | PT2 direction: fade arrows in on image load (opacity, links stay functional) as the primary approach; viewport-anchored arrows kept as fallback if the fade proves insufficient. |

## Working agreement

- Move tasks between lanes only when actually started/finished; log moves in the Decisions log.
- This board is the single source of truth for tasks; per-task details live in `.hermes/plan/` (one file per task, local-only) — keep them in sync when a task moves to Done (note the commit hash).
- Never bulk-commit: the tree carries WIP; commit only explicitly named files (`git commit --only -- <paths>`).
- JS comments `/* … */` only; all CSS/JS goes in `assets/css/main.css` / `assets/js/main.js` (new files under `assets/` are gitignored — see AGENTS.md).
- Verify visually with `jekyll serve`; for loading behavior test cold cache; check mobile breakpoints.
- Never invent facts in docs/boards — mark unknowns as open questions.
