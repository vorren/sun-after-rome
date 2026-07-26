# Sun After Rome

[![Tests](https://github.com/vorren/sun-after-rome/actions/workflows/test.yml/badge.svg)](https://github.com/vorren/sun-after-rome/actions/workflows/test.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

An Age of Empires II-style real-time strategy game built with **Fennel** and **LÖVE**.

## What is this?

Sun After Rome is a small, deterministic RTS game implementing the core AoE2 gameplay loop: **gather resources, train units, advance through ages, and fight**. It features:

- **Deterministic simulation** — same seed + same commands = identical world
- **Two-player LAN multiplayer** — lockstep simulation via ENet
- **Isometric 2D rendering** — placeholder graphics with Tiled map support
- **Live REPL** — modify game state at runtime via a Fennel REPL
- **Procedural map generation** — Perlin noise terrain, or design maps in Tiled

## Requirements

- [LÖVE](https://love2d.org/) 11.4+
- [Fennel](https://fennel-lang.org/) (for building from source)
- [Lua](https://www.lua.org/) (for running tests)

### macOS

```bash
brew install love fennel lua
```

### Linux (NixOS)

```bash
nix-shell -p love fennel lua
```

## Quick Start

```bash
# Run the game
make run

# Or directly
love .
```

### Controls

| Key | Action |
|-----|--------|
| `1` | Train Villager (Town Centre) |
| `2` | Train Knight (Barracks) |
| `3` | Train Pikeman (Barracks) |
| `4` | Train Archer (Barracks) |
| `A` | Advance Age (Player 0) |
| `B` | Advance Age (Player 1) |
| `F5` | Reset world |
| `Click` | Select entity |
| `Escape` | Quit |

## Building

```bash
# AOT compile Fennel to Lua (faster startup)
make build

# Run tests
make test

# Clean compiled files
make clean
```

## Architecture

The game uses an **Entity-Component-System (ECS)** architecture:

- **Entities** are integer IDs
- **Components** are plain tables (position, health, kind, etc.)
- **Systems** are functions that process entities each tick
- **World** is the single mutable state container

### System Pipeline (each tick)

1. `apply-orders!` — drain command queue, translate to entity tasks
2. `production` — buildings advance training queues, spawn units
3. `age` — faction age countdowns tick down
4. `movement` — units step toward destinations
5. `gather` — villagers harvest, carry, deposit
6. `combat` — cooldowns tick, attacks resolve, deaths handled

### Network Model

Peer-to-peer **deterministic lockstep** via [lua-enet](https://github.com/leafo/lua-enet):

- Both players run the full simulation
- Each tick, commands are exchanged via reliable UDP
- Same seed + same commands = identical worlds
- No game state is sent over the network — only commands

## Project Structure

```
aurelius-fennel/
├── lib/                    # Third-party libraries
│   ├── fennel.lua          # Embedded Fennel compiler
│   ├── fennelview.lua      # Pretty-printer
│   └── luaunit.lua         # Test framework
├── src/
│   ├── init.fnl            # LÖVE callbacks
│   ├── world.fnl           # Entity/component store
│   ├── components.fnl      # Component constructors
│   ├── content.fnl         # Unit/building stats
│   ├── orders.fnl          # Commands-as-data
│   ├── rng.fnl             # Deterministic PRNG
│   ├── sim.fnl             # Fixed-timestep tick loop
│   ├── systems/            # Game systems
│   │   ├── age.fnl
│   │   ├── combat.fnl
│   │   ├── gather.fnl
│   │   ├── movement.fnl
│   │   └── production.fnl
│   ├── net/                # Networking
│   │   ├── lockstep.fnl    # Lockstep coordinator
│   │   ├── commands.fnl    # Command serialization
│   │   └── host.fnl        # ENet connection management
│   └── render/             # Rendering
│       ├── iso.fnl         # Isometric transforms
│       ├── sprites.fnl     # Placeholder sprite rendering
│       ├── map.fnl         # Terrain + Tiled integration
│       └── hud.fnl         # HUD overlay
├── test/                   # Test suite
├── assets/                 # Maps, fonts, sprites
├── conf.lua                # LÖVE configuration
├── main.lua                # Fennel bootstrap
└── Makefile                # Build system
```

## License

AGPL v3.0
