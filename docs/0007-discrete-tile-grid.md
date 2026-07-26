# ADR-0007: Discrete tile grid

**Status:** Accepted

## Context
Positions and movement can use a discrete tile grid (AoE2's underlying model) or
continuous 2D coordinates (OpenRA's finer feel, needing floats, collision, and
steering).

## Decision
Use a **discrete tile grid**. Entities occupy integer tile coordinates; distance
is Chebyshev (king-move); movement is tile-to-tile.

## Consequences
- Keeps the sim fully integer and deterministic, pairing cleanly with fixed
  ticks ([0005](0005-fixed-integer-ticks.md)).
- Makes the world legible: `print-map` dumps an ASCII picture that is the v1
  renderer and the primary debugger.
- Pathfinding reduces to grid algorithms ([0012](0012-straight-line-movement.md));
  adjacency checks (villager next to a tree, unit in weapon range) are integer
  neighbour tests.
- Movement is visually steppy; the render layer can interpolate between tile
  centres later.
