# ADR-0005: Fixed integer tick timestep

**Status:** Accepted

## Context
Time can advance in discrete fixed steps (AoE2/OpenRA lockstep) or by a variable
real-time `dt`. Determinism and REPL-legibility are core goals.

## Decision
The sim advances in **fixed integer ticks**. All durations (train time, age
time, cooldowns) are integers in ticks. There are no floats in the time
dimension.

## Consequences
- Enables determinism ([0006](0006-seeded-prng.md)): same seed + same commands ⇒
  identical world, and it is the correct foundation for lockstep multiplayer if
  ever pursued.
- Divorces the sim from frame rate; a renderer can interpolate between ticks for
  visual smoothness without touching the sim.
- `(tick! w)` / `(run! w n)` reason about state at exact tick boundaries — far
  more inspectable than "advance 0.3 s".
- Movement looks steppy (tile-to-tile); acceptable headless, smoothable in the
  render layer.
