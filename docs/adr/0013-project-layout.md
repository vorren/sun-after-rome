# ADR-0013: Project layout, Guile-only dependencies, name *Aurelius*

**Status:** Accepted

## Context
The project needs a module layout the user will live in, a clear dependency
story, and a name. (It was initially sketched as "openae"; renamed to
**Aurelius** at the user's request — all module namespaces, directories, and
docs use `aurelius`.)

## Decision
- **Module root** `aurelius/` maps to the `(aurelius …)` namespace: `world`,
  `components`, `content`, `orders`, `rng`, `sim`, `systems/*`, `render/ascii`.
- Entry point `scripts/repl.scm`; ADRs in `docs/adr/`; tests in `tests/`.
- **Core sim depends on Guile only** — no external Scheme libraries — so setup is
  a single package install per platform ([0014](0014-build-and-tests.md)).
- Chickadee is pulled in only by the future render layer and documented then.

## Consequences
- Trivially reproducible; the whole dependency story is "install Guile ≥ 3.0".
- Content and systems are separate files so rebalancing (`content.scm`) never
  touches behaviour.
- Guile targeted at **3.0** (installed: 3.0.7).
