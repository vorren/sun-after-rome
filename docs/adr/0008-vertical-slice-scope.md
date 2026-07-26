# ADR-0008: Vertical-slice scope

**Status:** Accepted

## Context
"Small and formal" needs a hard boundary. The smallest thing that exercises the
whole AoE2 loop — gather → train → advance age → fight — defines v1.

## Decision
**In scope (v1):**
- Town Centre (trains villagers) and Barracks (trains military).
- Villagers that gather and deposit.
- Three resources: **wood, stone, gold** — **no Food** (its farm/forage mechanic
  is the fiddliest and adds no new lesson here).
- All three combatants: **knight, pikeman, archer** (the user chose the full
  roster over a single starter unit; it adds the counter triangle, which is
  meaningful content rather than sprawl).
- Age advancement with global boosts.
- Two factions.

**Deferred (extend yourself):** enemy AI, fog of war, farms/Food, population
cap, multiple building types, upgrades beyond ages, real pathfinding.

## Consequences
- The counter triangle requires ranged-vs-melee and bonus damage — folded into
  combat ([0010](0010-combat-and-factions.md)).
- New units / a fourth age are pure edits to `content.scm`.
