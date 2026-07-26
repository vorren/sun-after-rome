# Architecture Decision Records

Each ADR captures one decision made while designing Aurelius, with the context
and trade-offs behind it. They were produced during the initial design
interview and reflect what was true at v1; supersede rather than edit when a
decision changes.

| # | Decision | Status |
|---|---|---|
| [0001](0001-process-over-artifact.md) | Optimize for the live-programming *process*, artifact secondary | Accepted |
| [0002](0002-headless-first.md) | Headless-first core; Chickadee window as a later bolt-on | Accepted |
| [0003](0003-lightweight-ecs.md) | Lightweight ECS with plain records, no GOOPS | Accepted |
| [0004](0004-mutable-world-snapshot.md) | Mutable world in place, with explicit snapshot | Accepted |
| [0005](0005-fixed-integer-ticks.md) | Fixed integer tick timestep | Accepted |
| [0006](0006-seeded-prng.md) | Seeded PRNG inside the world; small combat variance | Accepted |
| [0007](0007-discrete-tile-grid.md) | Discrete tile grid | Accepted |
| [0008](0008-vertical-slice-scope.md) | Vertical-slice scope | Accepted |
| [0009](0009-commands-as-data.md) | Commands as data with a serializable order log | Accepted |
| [0010](0010-combat-and-factions.md) | Armour-class/bonus/range combat; two REPL factions, no AI | Accepted |
| [0011](0011-ages-as-modifiers.md) | Ages as derived-at-read modifiers | Accepted |
| [0012](0012-straight-line-movement.md) | Straight-line movement; A\* deferred | Accepted |
| [0013](0013-project-layout.md) | Project layout, Guile-only deps, name *Aurelius* | Accepted |
| [0014](0014-build-and-tests.md) | Makefile build, multi-OS install, SRFI-64 tests | Accepted |
