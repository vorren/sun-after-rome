# Sun After Rome — Session Context

## What We Built

Ported Sun After Rome (AOE2-style RTS, formerly "Aurelius") from Guile Scheme to Fennel + LÖVE.

### Decision Log

- **Guile → Fennel + LÖVE** — decided after grilling session. Guile's live REPL was the best for inspection, but Fennel + LÖVE won on: isometric rendering (LÖVE proven), LAN multiplayer (lua-enet), cross-platform (macOS + Linux), easier onboarding for Haskell co-dev.
- **Common Lisp ruled out** — too steep a learning curve.
- **Haskell ruled out** — weakest live inspection (GHCi requires pausing game loop), no LÖVE-equivalent game framework.
- **Placeholder sprites** — colored shapes until real art assets exist.
- **Tiled + procedural** — both map design approaches supported.
- **LAN lockstep** — AoE2-style deterministic lockstep via lua-enet. Both players run full simulation, exchange commands only.
- **Test suite** — luaunit, test pure logic outside LÖVE.

### Project State

- **Location:** `/Users/jordan/Projects/Programming/aurelius-fennel/`
- **Original Guile project:** `/Users/jordan/Projects/Programming/aurelius/`
- **19 Fennel modules** compiled successfully
- **23/26 tests passing** (3 integration tests need task setup fixes)
- **No git remote** — needs one before push
- **No `lua-enet`** — networking module exists but C extension not compiled

### Remaining Work

1. Fix 3 failing integration tests (knight-beats-archer, gather-deposits, training-produces-unit)
2. Compile/install `lua-enet` C extension for LAN multiplayer
3. Wire up `lib/stdio.fnl` REPL thread (LÖVE threading API)
4. Create Tiled maps (`.lua` export format)
5. Replace placeholder sprites with real assets
6. Add remote git repo and push

### Key Files

| File | Purpose |
|---|---|
| `src/init.fnl` | LÖVE callbacks, game setup, keyboard shortcuts |
| `src/world.fnl` | ECS store, spawn, snapshot, effective stats |
| `src/orders.fnl` | Commands-as-data, issue/apply |
| `src/sim.fnl` | Fixed-timestep tick loop |
| `src/systems/*.fnl` | 5 game systems |
| `src/render/*.fnl` | Isometric transforms, sprites, HUD, map |
| `src/net/*.fnl` | Lockstep, command serialization, ENet host |
| `test/*.fnl` | 11 test files |
| `docs/` | ADRs, architecture, Fennel guide for Haskell devs |

### Gotchas / Notes

- Lua tables are 1-indexed; game logic uses 0-indexed players. Player data tables are offset by +1.
- Fennel `match` needs a `_` catch-all pattern or "even number of pattern/body pairs" error.
- Fennel `let` bindings are immutable; use `var` for mutable locals.
- Fennel doesn't support method-call syntax `obj:method()` — use `(obj.method obj args)`.
- `each [k v (ipairs t)]` gives index first, value second (swapped from直觉).
- Forward references don't work in Fennel — define functions before use.
