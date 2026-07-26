# Project Architecture

## ECS Data Flow

```
Commands (input)
    ↓
apply-orders! → translates commands to entity tasks
    ↓
production → buildings train units
    ↓
age → faction age countdowns tick
    ↓
movement → units step toward destinations
    ↓
gather → villagers harvest/carry/deposit
    ↓
combat → cooldowns + attacks + deaths
    ↓
World State (output)
    ↓
Rendering (read-only)
```

## Component Types

| Component | Fields | Purpose |
|-----------|--------|---------|
| `position` | `x, y` | Grid coordinates |
| `owner` | `player` | Faction membership |
| `kind` | `tag` | Content-table key |
| `health` | `hp` | Current hit points |
| `carry` | `resource, amount` | Villager cargo |
| `node` | `resource, amount` | Resource node stock |
| `cooldown` | `ticks` | Attack cooldown |
| `producer` | `queue, progress` | Training queue |
| `task` | `kind, target, tx, ty, phase` | Current order |

## Network Architecture

```
Player A                          Player B
  │                                 │
  │◄──── ENet (UDP reliable) ────►│
  │  Commands: [move 5 10 8,       │
  │             gather 3 7]        │
  │                                 │
  │  Both run same simulation       │
  │  Both get same result           │
```

Commands are serialized as strings: `"m:5:10:8|g:3:7"`

## Determinism Guarantees

1. Seeded PRNG (LCG with fixed constants)
2. Sorted entity iteration (by entity ID)
3. Fixed integer timestep (no floats in game logic)
4. No `math.random()` — only through `(world-rng w)`
