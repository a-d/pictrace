# Pictrace — Kanban

> Board seeded 2026-09-20. Priorities: **P1** core · **P2** important · **P3** nice-to-have · **P4** later.
> Site: https://pictrace.de (GitHub Pages, deploys from `master`). Conventions & current state: [AGENTS.md](AGENTS.md).
> ⚠️ The working tree currently carries unrelated WIP (see AGENTS.md) — commit only explicitly named files.

## 📋 Open

| ID | Prio | Task |
|---|---|---|
| PT7 | P3 | Housekeeping: nested thumbs/_site junk (33 MB), stale _site (3.7 GB), .travis.yml, Jekyll excludes, gitignore, git gc |
| PT8 | P3 | CSS/HTML hygiene: dead CSS block, `:nth-child(24+0)` typo, dead form attributes |
| PT9 | P3 | Self-host exifr + FontAwesome (currently CDN; no SRI) |

## 🔵 In progress

_(empty)_

## ⛔ Blocked

_(empty)_

## ⏸️ Deferred

| ID | Prio | Task |
|---|---|---|
| PT10 | P3 | Build via GitHub Actions (Jekyll 4 + plugins: responsive images, SEO) — deploy pipeline change |
| PT11 | P3 | Image pipeline: AVIF for 2024–25 (1468 photos), parallelize resize.sh, quality re-tune, optional srcset |
| PT12 | P4 | Scaling: single-page payload (≈1.5 MB HTML, ~3.8k blocks at 1.9k photos) — split/paginate strategy |
| PT13 | P4 | Framework evaluation spike: Astro vs Eleventy vs Jekyll-4 (prototype first) |
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
| PT7 | [`.hermes/plan/PT7-housekeeping.md`](.hermes/plan/PT7-housekeeping.md) — open |
| PT8 | [`.hermes/plan/PT8-css-html-hygiene.md`](.hermes/plan/PT8-css-html-hygiene.md) — open |
| PT9 | [`.hermes/plan/PT9-self-host-external-assets.md`](.hermes/plan/PT9-self-host-external-assets.md) — open |
| PT10 | [`.hermes/plan/PT10-github-actions-build.md`](.hermes/plan/PT10-github-actions-build.md) — deferred |
| PT11 | [`.hermes/plan/PT11-image-pipeline-modernization.md`](.hermes/plan/PT11-image-pipeline-modernization.md) — deferred |
| PT12 | [`.hermes/plan/PT12-scaling-architecture.md`](.hermes/plan/PT12-scaling-architecture.md) — deferred |
| PT13 | [`.hermes/plan/PT13-framework-spike.md`](.hermes/plan/PT13-framework-spike.md) — deferred |
| PT14 | [`.hermes/plan/PT14-repo-history-size.md`](.hermes/plan/PT14-repo-history-size.md) — deferred |

## Decisions log

| Date | Decision |
|---|---|
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
