# ADR-0010: Armour-class/bonus/range combat; two REPL factions, no AI

**Status:** Accepted

## Context
Three combatants force two coupled decisions: how combat resolves, and what the
units fight.

## Decision
**Combat** models AoE2's identity with two data fields on each unit's content:
an `armour` class (`cavalry` / `infantry` / `archer`) and a `bonus-vs` alist of
extra damage per target class, plus an integer `range` (melee 1, archer 4).
Damage = `(base + bonus-vs target's class)` × age-damage-multiplier, then a small
±5% RNG wobble, minimum 1. The counters:
- pikeman → bonus vs cavalry (counters knight),
- archer → bonus vs infantry (counters pikeman) and strikes at range,
- knight → high HP/damage, strong against the squishy archer.

**Opponent:** **two factions, both REPL-controlled, no AI.** Ownership is an
`owner` component (player 0 / 1).

## Consequences
- Ownership is in the model anyway and lets you actually test the counter
  triangle by ordering both sides.
- The counter is about **cost-efficiency**, not guaranteed 1v1 wins: a lone
  pikeman can lose to a knight (as in AoE2), but it is far cheaper. Tests assert
  the *bonus damage* is real, not that the cheaper unit wins duels.
- AI is deferred cleanly to "a system that issues player-1 orders".
