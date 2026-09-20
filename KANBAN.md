# Pictrace — Kanban

> Board seeded 2026-09-20. Priorities: **P1** core · **P2** important · **P3** nice-to-have · **P4** later.
> Site: https://pictrace.de (GitHub Pages, deploys from `master`). Conventions & current state: [AGENTS.md](AGENTS.md).
> ⚠️ The working tree currently carries unrelated WIP (see AGENTS.md) — commit only explicitly named files.

## 📋 Open

| ID | Prio | Task |
|---|---|---|
| PT1 | P2 | Lightbox: navigate with ← / → arrow keys (parity with the on-screen prev/next buttons) |
| PT2 | P2 | Lightbox: prev/next buttons visibly jump while an uncached image loads — show them only once the image is ready, keep the links functional |

## 🔵 In progress

_(empty)_

## ⛔ Blocked

_(empty)_

## ⏸️ Deferred

_(empty)_

## ✅ Done

_(empty)_

## Task details

### PT1 — Keyboard navigation (← / →) in the lightbox

**Wanted:** with a photo open in the lightbox, pressing ←/→ moves to the previous/next image — identical behavior to the on-screen `.nav-prev` / `.nav-next` buttons.

**Current behavior:** the buttons are plain hash links (`<a href="#…">`, `_includes/popup_item.html`); navigation happens purely through the URL hash + CSS `:target`. Only mouse/touch works today; there is no keyboard handling anywhere.

**Where to change:** `assets/js/main.js` (lightbox logic lives there — `handleHashChange()` already tracks the open slide). A small document-level `keydown` listener; likely no markup/CSS changes.

**Suggested approach:** on `keydown`, if a slide is open (`document.querySelector('.lightbox-container:target')` matches), map ArrowLeft/ArrowRight to a click on that slide's `.nav-prev` / `.nav-next` anchor — delegate to the existing links so EXIF loading, close-link logic and the empty `#p` state all keep working. `preventDefault()` on handled keys; no-op when no slide is open. Edge semantics match the buttons exactly: the first slide's prev link closes the lightbox (`href="#"`), the last slide has no next arrow.

**Acceptance criteria:**
- Lightbox open: ←/→ navigate exactly like the on-screen buttons (incl. across location/year boundaries).
- Lightbox closed: arrow keys do nothing new (page behavior unchanged).
- Follows `.clinerules` style: `/* … */` comments only, vanilla JS, no new globals beyond a scoped IIFE.
- Verified in `jekyll serve` on desktop.

### PT2 — Buttons jump while an uncached image loads

**Reported:** with the lightbox open, navigating (e.g. next) toward an image that is not cached: the nav buttons appear for a split second in the middle of the screen, then jump to their correct position once the image finishes loading and its dimensions are known.

**Root cause (verified in code):** each slide is `figure.lightbox-container`, sized by its content; the popup `<img>` (`_includes/popup_item.html`) has **no `width`/`height` attributes** and `loading="lazy"`, so until it loads the figure is ~0×0. The arrows are `position: absolute; top: 50%; left/right: -1.7em` **relative to the figure** — while the figure is empty they sit at its center (≈ screen center); when the image loads the figure grows and the arrows jump to the image edges. Cached images load instantly, so the jump is only visible for uncached ones.

**Owner's suggested fix (workable — recommended):** show the arrows only once the image is loaded, via `opacity` (not `display`/`visibility`), driven by a `load` listener + a class toggle on the slide. Keep the links functional while invisible — `opacity: 0` leaves the anchors clickable, and the big half-screen `::before` hit zones keep working regardless. Watch out for:
- images already cached: `load` never fires for them after the listener attaches → check `img.complete && img.naturalWidth > 0` first;
- re-arm on every `hashchange` (each slide is a separate `<figure>`);
- add a CSS `transition` so the arrows fade in instead of popping.

**Alternative / better?** Decouple arrow position from image size: anchor them to the overlay viewport (e.g. `position: fixed` left/right of the screen, vertically centered) so they can never jump, regardless of cache state. Trade-off: arrows no longer hug the image edge (small visual change). Can be combined with the fade for polish. Decide at implementation time; if the fade alone reads well, keep the current look.

**Acceptance criteria:**
- Cold cache (DevTools "Disable cache" / hard reload): navigating to an uncached image — no visible jump; arrows fade in at their final position.
- Cached images: arrows visible immediately (no waiting on an event that already fired).
- While hidden, prev/next still function (screen-half clicks; keyboard once PT1 lands).
- No regression: close behavior, `::before` hit zones, ≤768px mobile rules (prev hidden, right-half tap = next).

**Note:** PT1 and PT2 touch the same areas (`main.js` lightbox/hash logic, arrow CSS). Implement together or PT2 first, PT1 second — keep both in one review if convenient.

## Decisions log

| Date | Decision |
|---|---|
| 2026-09-20 | AGENTS.md + KANBAN.md created; PT1/PT2 opened (P2). Lightbox stays hash/`:target`-based — enhancements go through `main.js` + arrow CSS, no re-architecture. |
| 2026-09-20 | PT2 direction: fade arrows in on image load (opacity, links stay functional) as the primary approach; viewport-anchored arrows kept as fallback if the fade proves insufficient. |

## Working agreement

- Move tasks between lanes only when actually started/finished; log moves in the Decisions log.
- This board is the single source of truth for tasks; task details live under "Task details" — keep them in sync when a task moves to Done (note the commit hash).
- Never bulk-commit: the tree carries WIP; commit only explicitly named files (`git commit --only -- <paths>`).
- JS comments `/* … */` only; all CSS/JS goes in `assets/css/main.css` / `assets/js/main.js` (new files under `assets/` are gitignored — see AGENTS.md).
- Verify visually with `jekyll serve`; for loading behavior test cold cache; check mobile breakpoints.
- Never invent facts in docs/boards — mark unknowns as open questions.
