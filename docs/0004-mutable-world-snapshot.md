# ADR-0004: Mutable world in place, with explicit snapshot

**Status:** Accepted

## Context
A tick could be `(tick world) -> world'` (immutable) or mutate in place. With
hash-table component stores, true immutability means either copying every tick
or adopting a functional-map library, and it threads the world through every
system. The live-coding win we actually want comes from hot-reloading *system
procedures*, which works regardless of mutability.

## Decision
The world is **mutated in place**; `(tick! world)` bangs on the store.
Time-travel/save/undo is provided **on demand** by `(snapshot world)`, which
walks the store into an independent frozen copy.

## Consequences
- Ticks are O(changed), not O(world); the future Chickadee frame loop stays
  cheap.
- Snapshots cost only when requested; `snapshot` deep-copies components field by
  field so a copy can never be mutated through the live world (verified in
  `tests/determinism.scm`).
- A buggy system can corrupt the world mid-tick with no automatic rollback;
  during development, snapshot at the top of a tick if you need a savepoint.
