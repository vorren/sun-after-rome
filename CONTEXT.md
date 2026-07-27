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
- **26/26 tests passing**
- **`lua-enet` compiled** — `lib/enet.so` built for macOS (LuaJIT ABI)
- **File-based REPL wired** — `lib/stdio.fnl` polls `repl.in`/`repl.out`
- **conf.lua fixed** — rewritten as valid Lua (was Fennel syntax)
- **Git remote present**

### Remaining Work

1. ~~Fix 3 failing integration tests~~ ✓ (wrong entity IDs, missing attack orders, cond→if)
2. ~~Compile/install `lua-enet` C extension~~ ✓ (macOS, see README for Linux/BSD/NixOS)
3. ~~Wire up REPL~~ ✓ (file-based, see lib/stdio.fnl)
4. **TCP REPL** — add luasocket-based TCP server to lib/stdio.fnl. Auto-detect luasocket, fall back to file I/O. Enables `telnet localhost 12345` for live game interaction without file fiddling.
   - **Dependencies:** `luasocket` (compile via `luarocks install luasocket`, or bundle the `.so`)
   - **Implementation:** When `pcall(require, "socket")` succeeds, bind a TCP server on `127.0.0.1:12345`. Accept connections, read lines, evaluate via `fennel.eval`, write results back. Non-blocking via `socket.select` poll in `love.update`.
   - **Fallback:** If luasocket unavailable, current file I/O mode continues unchanged.
   - **Security:** Listen on localhost only. No auth needed for single-player debugging.
   - **Multiplayer note:** TCP REPL is for the host machine only. Remote players can't connect to it (and shouldn't — it's a debug tool, not a game protocol).
5. Create Tiled maps (`.lua` export format)
6. Replace placeholder sprites with real assets
7. Build a lightweight relay server for internet P2P (when not using Tailscale)

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
