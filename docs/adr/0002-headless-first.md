# ADR-0002: Headless-first core; Chickadee window as a later bolt-on

**Status:** Accepted

## Context
For a process-focused project ([0001](0001-process-over-artifact.md)) the REPL,
not a window, is the primary interface. Graphics-first designs tend to entangle
the game loop with a render/present cycle, which is exactly what makes
live-reload painful.

## Decision
Build the simulation **headless**: the world is a long-lived value, and the only
v1 renderer is a read-only ASCII dump (`render/ascii.scm`). A graphical
frontend (Chickadee — the natural Guile choice) is deferred and will *read*
world state without ever owning it.

## Consequences
- The sim has zero graphics coupling; it can be inspected, snapshotted, diffed,
  and hot-reloaded freely.
- The ASCII map doubles as the best debugging tool for a grid game.
- You will not *see* units move fluidly until the Chickadee layer exists; that
  layer is ~a few hundred lines bolted on the side (it may interpolate between
  tick snapshots for smoothness) and requires no sim changes.
