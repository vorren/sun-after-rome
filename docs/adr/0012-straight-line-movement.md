# ADR-0012: Straight-line movement; A\* deferred

**Status:** Accepted

## Context
On a tile grid, movement can be straight-line stepping with no obstacle
avoidance, grid A\*/BFS around blockers, or flow fields. Pathfinding is the most
over-engineered subsystem in hobby RTS projects.

## Decision
v1 uses **straight-line stepping**: each move advances one tile per unit of
speed toward the destination, ignoring obstacles (units may overlap or pass
through trees). All movement routes through a single `step-toward!` procedure in
`systems/movement.scm`.

## Consequences
- Keeps v1 genuinely small; reaching a target in a straight line is fully legible
  on the ASCII map, and obstacle avoidance is not part of what the demo proves.
- Swapping in real A\* is a localized change to `step-toward!` with no ripple into
  gather/combat — a natural, self-contained extension.
- Trade-off: no collision; units can stack. Acceptable headless.
