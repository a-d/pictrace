# Pictrace — Kanban

> Board seeded 2026-09-20. Priorities: **P1** core · **P2** important · **P3** nice-to-have · **P4** later.
> Site: https://pictrace.de (GitHub Pages, deploys from `master`). Conventions & current state: [AGENTS.md](AGENTS.md).
> ⚠️ The working tree currently carries unrelated WIP (see AGENTS.md) — commit only explicitly named files.

## 📋 Open

_(empty)_

## 🔵 In progress

_(empty)_

## ⛔ Blocked

_(empty)_

## ⏸️ Deferred

_(empty)_

## ✅ Done

| ID | Prio | Task |
|---|---|---|
| PT1 | P2 | Lightbox: navigate with ← / → arrow keys — ✅ done 2026-09-20 (commit `8e6e8706a6cfde36e4710954a5511abb8d7a25df`) |
| PT2 | P2 | Lightbox: arrows revealed only once the slide image is ready — ✅ done 2026-09-20 (commit `f0df932b064c0f7b036e4831aa60c5b762130a9b`) |

## Task details

Per-task details live in `.hermes/plan/` — one file per task (local-only, not committed):

| Task | Details |
|---|---|
| PT1 | [`.hermes/plan/PT1.md`](.hermes/plan/PT1.md) — ✅ done 2026-09-20 |
| PT2 | [`.hermes/plan/PT2.md`](.hermes/plan/PT2.md) — ✅ done 2026-09-20 |

## Decisions log

| Date | Decision |
|---|---|
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
