# Domain Docs

Single-context repo. One `CONTEXT.md` at the root + `docs/adr/` for architectural decisions.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root — domain glossary (Faction, Controller, Entity, World, Order, etc.)
- **`docs/adr/`** — 16 ADRs covering ECS, determinism, movement, combat, ages, AI architecture

## Use the glossary's vocabulary

When naming a domain concept, use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

## Key terms

- **Faction** — a side in the game (not "player")
- **Controller** — the thing issuing orders (human, AI, remote, spectator)
- **Entity** — a game object (integer ID with components)
- **Order** — input to the simulation (the ONLY way to change state)
- **Tick** — one discrete time step
