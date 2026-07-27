# Faction + Controller split

We split "player" into two concepts: **Faction** (a side in the game — owns entities, resources, age) and **Controller** (the thing issuing orders for a faction — human, AI, remote, or spectator).

Previously, "player" conflated both: a human playing a side. This broke down when we needed AI opponents and spectators. A faction is game state; a controller is decision-making. They're bound at game start but can be swapped at runtime (e.g., AI takeover on disconnect).

The simulation doesn't care who issues orders — it only sees `world.orders`. The controller is the source of those orders, not part of the simulation itself.
