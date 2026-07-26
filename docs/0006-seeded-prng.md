# ADR-0006: Seeded PRNG inside the world; small combat variance

**Status:** Accepted

## Context
Some mechanics want randomness (combat damage variance). Guile's global
`random` state is mutable process-wide, can't be snapshotted cleanly, and breaks
determinism.

## Decision
A **seeded PRNG lives inside the world record** (`rng.scm`, a small LCG whose
entire state is one integer). Every random draw routes through it and advances
it. Seed is a `make-world` argument. Combat applies a small ±5% damage wobble
through this PRNG.

## Consequences
- The RNG is captured by `snapshot`, so replays and tests are exact; different
  seeds visibly diverge (both verified in `tests/determinism.scm`).
- Discipline: systems must draw randomness via the world's rng, never a global —
  easy since systems already receive the world.
- Combat feels game-like without being unpredictable across runs.
