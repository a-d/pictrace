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
| PT14 | P4 | Repo history: .git ≈ 5.2 GB — audit + optional filter-repo rewrite (high risk) |

## ✅ Done

| ID | Prio | Task |
|---|---|---|
| PT1 | P2 | Lightbox: navigate with ← / → arrow keys — ✅ done 2026-09-20 (commit `8e6e8706a6cfde36e4710954a5511abb8d7a25df`) |
| PT2 | P2 | Lightbox: arrows revealed only once the slide image is ready — ✅ done 2026-09-20 (commit `f0df932b064c0f7b036e4831aa60c5b762130a9b`) |
| PT5 | P2 | resize.sh: `-d` deletes only originals whose outputs were created — ✅ done 2026-09-20 (commit `e2493c616f32b987200d282dc76854ed4d8d4755`) |
| PT3 | P2 | Build: precomputed AVIF path set replaces per-image scans — ✅ done 2026-09-20 (commit `e20295ed08a93dc8ee6c49583ca5718c002ee15b`) |
| PT4 | P2 | Preload: thumbs preload AVIF when present, else JPG — ✅ done 2026-09-20 (commit `afcea8f43836c9b0737efa2bd28551ea325b7b6c`) |
| PT6 | P2 | Zoom: pinch-zoom in the lightbox only; lightbox controls labeled — ✅ done 2026-09-20 (commit `223a1fcfb4758081b01ed19e77eca247f3511938`) |
| PT7 | P3 | Housekeeping: `_site` junk deleted (−3.7 GB), `.travis.yml` removed, Jekyll excludes added, `/0/` ignores collapsed, `git gc` — ✅ done 2026-09-20 (commit `b3044ab3fb8e7c982c81bf0bc024c1343a3f41e5`) |
| PT8 | P3 | CSS/HTML hygiene: dead `::after` block + unmatched `#gallery-close` rules removed, `24+0`→`24n+0`, dead form attrs — ✅ done 2026-09-20 (commit `46b8d48b1d39d20ef965c9cdc82e876c247cf33a`) |
| PT9 | P3 | Self-host exifr + FontAwesome: exifr 7.1.3 (MIT) + FA 4.7.0 webfont (SIL OFL 1.1) vendored to `assets/js/vendor/` + `assets/fonts/` with license files; CDN refs removed — ✅ done 2026-09-20 (commit `6d0c261be85aee05d12a9a300406a0086aa42315`) |
| PT15 | P2 | Lightbox gestures: horizontal wheel/trackpad + swipe for prev/next (delegates to PT1's `.nav-prev`/`.nav-next`) — ✅ done 2026-09-20 (commit `69ff666514769629f4d90c83216aa3fc360bf68f`) |

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
| PT12 | [`.hermes/plan/PT12-scaling-architecture.md`](.hermes/plan/PT12-scaling-architecture.md) — partially implemented 2026-09-20 (commits `4921d9b`, `df17180`) |
| PT16 | [`.hermes/plan/PT16-per-location-pages.md`](.hermes/plan/PT16-per-location-pages.md) — planned |
| PT13 | [`.hermes/plan/PT13-framework-spike.md`](.hermes/plan/PT13-framework-spike.md) — dormant (gated by PT10, 2026-09-20) |
| PT14 | [`.hermes/plan/PT14-repo-history-size.md`](.hermes/plan/PT14-repo-history-size.md) — deferred |
| PT15 | [`.hermes/plan/PT15-lightbox-gestures.md`](.hermes/plan/PT15-lightbox-gestures.md) — ✅ done 2026-09-20 |

## Decisions log

| Date | Decision |
|---|---|
| 2026-09-20 | PT16 opened — per-location pages + progressive single-page loading (owner-proposed: every location gets a page; the index prerenders N=5; a links block lists all pages in legacy order; JS inserts the next batch before the viewport reaches the end; lazy loading unchanged). Plan confirms the approach with must-solves: deep links into unloaded locations (the links block doubles as the id→page manifest), journey-map re-init for injected content (inline scripts do not run — move the data to `data-*` attributes), prev/next chain rewiring at batch boundaries, page generation via a Jekyll collection + generated stubs (no plugins on the default Pages build). Details: `.hermes/plan/PT16-per-location-pages.md`. |
| 2026-09-20 | PT12 batch 2 done — fragment compaction: slide ids `p-{yy}-{locnum}-{basename}` (mean 32.8 → 21.4 chars), section anchors `p-{yy}` / `p-{yy}-{locnum}`, redundant `nav-arrow` class dropped; `.clinerules` documents the scheme. Verified: prev/next chain self-consistent, tile links match slide order, all in-page links resolve. 1.46 MB → 1.34 MB raw, gzip 72.4 KB; both batches together −20 % raw / −12.6 % gzip. Previously shared `#p-…` links break (fragments cannot redirect). Commit `df17180`. |
| 2026-09-20 | PT12 batch 1 done — merge wrappers (each photo now has one root: the slide `figure` lives inside its gallery `<article>`; the iterator renders once with a precomputed id list, keeping the global prev/next chain identical), micro-trims (`data-name` removed, literal ❮/❯, shorter aria-labels), whitespace collapse in `compress.html` (−164 KB of inter-tag runs), lightbox CSS reworked (targeted figure is the fixed overlay; backdrop via `figure::before`; the shared `.close` link is the click-anywhere catcher; `contain`/`backdrop-filter` are neutralised while open because both re-anchor fixed descendants — verified empirically). Checks: chain byte-identical to the old build, all links resolve, lightbox geometry pixel-identical to the live site (desktop + mobile emulation), no-JS arrows visible, location/year filter unchanged. 1.67 MB → 1.46 MB raw, gzip 82.8 → 74.1 KB. Commit `4921d9b`. |
| 2026-09-20 | PT13 set dormant — gated by the PT10 decision (native build stays): Jekyll-4 can't run on the native builder (env pins Jekyll 3.10.0 / github-pages 232) and Astro/Eleventy can't be built natively at all; any outcome requires reopening the deploy question first (custom build / prebuilt output / other host). If it reopens, decide PT10 + PT13 together. Plan note added: `.hermes/plan/PT13-framework-spike.md`. |
| 2026-09-20 | **PT10 parked — stay on the default Pages build** (owner call: stick with the current solution). Findings: the site is already built by a vendor-owned Actions workflow (`pages-build-deployment`; run #131 success, 2m22s; build job = `ghcr.io/actions/jekyll-build-pages:v1.0.13`; env Jekyll 3.10.0 / github-pages 232 / ruby 3.3.4). Original rationale corrected: SEO plugins already whitelisted (jekyll-seo-tag 2.8.0, jekyll-sitemap 1.4.0); the 10-min limit is a deploy timeout that applies to custom workflows too; the run page already shows jobs + annotations. Revisit triggers: a non-whitelisted plugin or custom build actually wanted · vendor pipeline failing · 10 builds/h soft throttle hit (worst burst so far ≈5/h) · branch-deploy deprecation signals · PT13 keeps Jekyll and adds build needs. Side findings: deploy warns "artifact 1.03 GB exceeds the allowed size of 1 GB — deployment might fail" → weight reduction is the PT11 lever (pipeline-independent); Gemfile pins were behind the live env → aligned (commit `000e300`). Plan: `.hermes/plan/PT10-github-actions-build.md`. |
| 2026-09-20 | PT15 done — lightbox gestures: horizontal trackpad/wheel (≥45 px cumulative, 220 ms quiet-lock absorbs inertia, ctrl/meta+wheel ignored) + one-finger swipe (≥50 px, 1.5× ratio, single-touch only — pinch/pan & touchcancel safe); both delegate to PT1's `.nav-prev`/`.nav-next`. 24/24 stub-DOM harness tests (`.hermes/plan/PT15-tests.js`); owner phone test pending (rides with PT6). Commit `69ff666`. |
| 2026-09-20 | PT9 done — exifr 7.1.3 (MIT) + FontAwesome 4.7.0 woff2 (SIL OFL 1.1) self-hosted (`assets/js/vendor/`, `assets/fonts/`) with license files; both verified byte-identical to upstream (sha256). License check: mirroring allowed (MIT/OFL); the EU GDPR risk (third-party CDN embedding) is removed by this change. Browser check: only first-party requests. Commit `6d0c261`. New `assets/` files committed via `git add -f` (`/assets/` ignore pending owner decision). |
| 2026-09-20 | PT15 opened — lightbox gestures: horizontal wheel (PC) + one-finger swipe (mobile) for prev/next, reusing PT1's delegation to the `.nav-prev`/`.nav-next` links. Details: `.hermes/plan/PT15-lightbox-gestures.md`. |
| 2026-09-20 | PT8 done — dead CSS/HTML stripped (commented ::after block, unmatched #gallery-close rules), 24+0→24n+0 (no visual change), dead form attrs removed. Footer `Design:` credit + `.gitignore /assets/` line flagged for owner decision. Commit `46b8d48`. |
| 2026-09-20 | PT7 done — `_site` junk (root 3.7 GB + nested 33 MB) deleted, dead `.travis.yml` removed, build excludes added, `/0/` ignores collapsed, `git gc` packed 6,913 loose objects (4.78 GiB → consolidated). Commit `b3044ab`. |
| 2026-09-20 | PT6 done — pinch-zoom is lightbox-only (`user-scalable=no` removed; `touch-action: pan-x pan-y` on the gallery; works on modern iOS; desktop/layout unaffected). Aria labels on prev/next/close; owner phone test pending. Commit `223a1fcfb4758081b01ed19e77eca247f3511938`. |
| 2026-09-20 | PT6 scope refined per owner: pinch-zoom is wanted **on the opened photo only** — overview stays fixed, big-screen layout scaling unchanged. Chosen mechanism: drop `user-scalable=no`, apply `touch-action: pan-x pan-y` to the gallery (works on modern iOS too; see .hermes/plan/PT6). |
| 2026-09-20 | PT3 done — precomputed AVIF set replaces O(N·M) per-image scans (3,821-path equivalence test, 0 mismatches). Fix commit `e20295ed08a93dc8ee6c49583ca5718c002ee15b`. |
| 2026-09-20 | PT4 done — thumb preloads guarded (AVIF if present, else JPG; no 404 preloads). Fix commit `afcea8f43836c9b0737efa2bd28551ea325b7b6c`. |
| 2026-09-20 | PT5 done — resize.sh `-d` deletes only successfully processed originals (interrupted runs delete nothing; unknown flags warn). Fix commit `e2493c616f32b987200d282dc76854ed4d8d4755`. |
| 2026-09-20 | Source review completed (templates, JS, CSS, scripts, assets, history). Findings + plans in `.hermes/plan/2026-09-20-source-review.md`; PT3–PT9 opened (quick wins), PT10–PT14 deferred (refactors / higher risk). |
| 2026-09-20 | PT2 done — nav arrows hidden until the slide image is ready (`img-ready` + opacity fade; `@media (scripting: none)` keeps them visible without JS; links stay clickable while hidden). Fix commit `f0df932b064c0f7b036e4831aa60c5b762130a9b`. |
| 2026-09-20 | PT1 done — keyboard navigation via arrow keys (`8e6e8706a6cfde36e4710954a5511abb8d7a25df`). Task details moved to `.hermes/plan/` (one file per task). |
| 2026-09-20 | AGENTS.md + KANBAN.md created; PT1/PT2 opened (P2). Lightbox stays hash/`:target`-based — enhancements go through `main.js` + arrow CSS, no re-architecture. |
| 2026-09-20 | PT2 direction: fade arrows in on image load (opacity, links stay functional) as the primary approach; viewport-anchored arrows kept as fallback if the fade proves insufficient. |

## Working agreement

- Move tasks between lanes only when actually started/finished; log moves in the Decisions log.
- This board is the single source of truth for tasks; per-task details live in `.hermes/plan/` (one file per task, local-only) — keep them in sync when a task moves to Done (note the commit hash).
- Never bulk-commit: the tree carries WIP; commit only explicitly named files (`git commit --only -- <paths>`).
- JS comments `/* … */` only; all CSS/JS goes in `assets/css/main.css` / `assets/js/main.js` (new files under `assets/` are gitignored — see AGENTS.md).
- Verify visually with `jekyll serve`; for loading behavior test cold cache; check mobile breakpoints.
- Never invent facts in docs/boards — mark unknowns as open questions.
