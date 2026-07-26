# ADR-0003: Lightweight ECS with plain records, no GOOPS

**Status:** Accepted

## Context
The entity zoo (villager, TC, knight, pikeman, archer, resource nodes) shares
orthogonal concerns — position, health, ownership, gathering, attacking. Three
idioms were considered: ECS (OpenAge's lineage), GOOPS trait objects (closest to
OpenRA's `Actor`/`Trait`), and a pure functional core.

## Decision
A **lightweight entity-component-system implemented as plain data**:
- entities are integer ids;
- components are `define-record-type` records held in hash tables keyed by id;
- systems are ordinary procedures `(system world)`.

No GOOPS.

## Consequences
- Components compose without a type explosion; "ages as boosts"
  ([0011](0011-ages-as-modifiers.md)) become modifiers read off components.
- Plain records print readably at the REPL and serialize/snapshot trivially —
  GOOPS' generic dispatch and opaque objects would fight the "world is just data"
  goal.
- Mild upfront machinery (id allocation, a component store, system ordering)
  before anything "happens"; it pays for itself immediately when extending.
- Adding a component means adding its record and registering its symbol in
  `*component-types*` so snapshot/removal handle it automatically.
