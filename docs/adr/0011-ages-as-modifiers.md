# ADR-0011: Ages as derived-at-read modifiers

**Status:** Accepted

## Context
Ages were framed as "overall boosts". A boost could be baked in by rewriting
every owned entity's component values on age-up, or derived at read time from a
bonus table.

## Decision
An age is an **integer level per faction** (each player advances independently),
advanced by a command that costs resources and takes ticks. The boost is applied
by **reading effective values through accessors** (`effective-max-hp`,
`effective-gather-rate`, `effective-damage`) that fold in the faction's current
age multipliers from a small table in `content.scm`. Base component values are
never rewritten.

## Consequences
- Matches the "boost = modifier" framing literally; newly trained units benefit
  automatically.
- Supremely inspectable and revertible: change the age integer and everything
  re-derives; the bonus table is one readable data structure.
- Generalizes to per-unit upgrades later via the same read-through mechanism.
- Discipline: systems must read `effective-*` accessors rather than raw fields —
  arguably better design regardless; recompute cost is negligible at this scale.
