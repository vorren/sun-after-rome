# Sun After Rome

[![Tests](https://github.com/vorren/sun-after-rome/actions/workflows/test.yml/badge.svg)](https://github.com/vorren/sun-after-rome/actions/workflows/test.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

An Age of Empires II-style deterministic RTS built with **Lua** and **LÖVE**.

> **Private repository.** This project is not publicly available. For access, contact the maintainer.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Building](#building)
- [Controls](#controls)
- [Architecture](#architecture)
- [Multiplayer](#multiplayer)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [Reading List](#reading-list)
- [License](#license)

## Overview

Sun After Rome implements the core AoE2 gameplay loop: **gather resources, train units, advance through ages, and fight**. Two factions compete on a procedurally generated isometric map.

- **Deterministic simulation** — same seed + same commands = identical world
- **Two-player LAN multiplayer** — lockstep simulation via ENet
- **Isometric 2D rendering** — placeholder graphics with Tiled map support
- **Procedural map generation** — Perlin noise terrain, or design maps in Tiled
- **Scripted AI** — deterministic build-order AI with configurable personality

## Quick Start

```bash
# Clone (requires access)
git clone git@github.com:vorren/sun-after-rome.git
cd sun-after-rome

# Option 1: Nix (recommended)
nix develop    # enters dev shell with all deps
love .         # run game

# Option 2: Manual
make run
```

## Requirements

- [LÖVE](https://love2d.org/) 11.4+ (installed externally)
- [Nix](https://nixos.org/) (recommended) or manual install of Lua, ENet

### Nix (recommended)

```bash
nix develop    # provides: luajit, enet, gcc, pkg-config
love .         # run game (love must be installed externally)
```

### macOS (manual)

```bash
brew install love lua luajit
make run
```

### Building the ENet Binding (optional, for multiplayer)

In the Nix dev shell, `make enet` works automatically — paths are set by `shellHook`.

For manual installs, see the Makefile for required flags.

If the ENet binding cannot be found at runtime, networking is disabled — the game still works in single-player.

## Building

```bash
make test     # Run the test suite (69 tests)
make enet     # Compile the ENet binding (requires headers)
```

## Controls

| Key | Action |
|-----|--------|
| `1` | Train Villager (Town Centre) |
| `2` | Train Knight (Barracks) |
| `3` | Train Pikeman (Barracks) |
| `4` | Train Archer (Barracks) |
| `A` | Advance Age (Player 0) |
| `B` | Advance Age (Player 1) |
| `Left Click` | Select entity |
| `Right Click` | Issue command (Move/Gather/Attack) |
| `Shift+Right Click` | Queue order |
| `F2` | Toggle minimap |
| `F3` | Toggle grid |
| `F5` | Reset world |
| `Escape` | Quit |

## Architecture

The game uses an **Entity-Component-System (ECS)** architecture:

- **Entities** are integer IDs
- **Components** are plain tables (position, health, kind, etc.)
- **Systems** are functions that process entities each tick
- **World** is the single mutable state container

### System Pipeline (each tick)

1. `apply_orders` — drain command queue, translate to entity tasks
2. `controller_dispatch` — AI controllers issue orders
3. `production` — buildings advance training queues, spawn units
4. `age` — faction age countdowns tick down
5. `movement` — units step toward destinations
6. `gather` — villagers harvest, carry, deposit
7. `combat` — cooldowns tick, attacks resolve, deaths handled

### Network Model

Peer-to-peer **deterministic lockstep** via [lua-enet](https://github.com/leafo/lua-enet):

- Both players run the full simulation
- Each tick, commands are exchanged via reliable UDP
- Same seed + same commands = identical worlds
- No game state is sent over the network — only commands

## Multiplayer

### LAN

Both players connect to the same local network. Host runs `love .`, client connects via the in-game menu.

### Internet (via Tailscale)

Use [Tailscale](https://tailscale.com/) to create a virtual LAN — no port forwarding required:

```bash
# Install Tailscale
brew install --cask tailscale   # macOS
curl -fsSL https://tailscale.com/install.sh | sh  # Linux

# Start and check IP
tailscale up
tailscale ip -4
```

1. Both players install Tailscale and sign in
2. Host runs `love .` — note the Tailscale IP
3. Client connects to the host's Tailscale IP

## Project Structure

```
sun-after-rome/
├── lib/                    # Third-party libraries
│   ├── luaunit.lua         # Test framework
│   └── enet.so             # ENet binding (compiled, not in repo)
├── src/
│   ├── init.lua            # LÖVE callbacks
│   ├── world.lua           # Entity/component store
│   ├── components.lua      # Component constructors
│   ├── content.lua         # Unit/building stats
│   ├── orders.lua          # Commands-as-data
│   ├── rng.lua             # Deterministic PRNG
│   ├── log.lua             # Logging system
│   ├── sim.lua             # Fixed-timestep tick loop
│   ├── ai/                 # AI controllers
│   │   ├── scripted.lua    # Scripted build-order AI
│   │   └── personalities.lua # Data-driven personality configs
│   ├── systems/            # Game systems
│   │   ├── age.lua
│   │   ├── combat.lua
│   │   ├── gather.lua
│   │   ├── movement.lua
│   │   ├── production.lua
│   │   └── win-condition.lua
│   ├── net/                # Networking
│   │   ├── lockstep.lua    # Lockstep coordinator
│   │   ├── commands.lua    # Command serialization
│   │   └── host.lua        # ENet connection management
│   └── render/             # Rendering
│       ├── iso.lua         # Isometric transforms
│       ├── sprites.lua     # Placeholder sprite rendering
│       ├── map.lua         # Terrain + Tiled integration
│       ├── hud.lua         # HUD overlay
│       ├── camera.lua      # Viewport management
│       ├── animation.lua   # Sprite animation
│       ├── interpolation.lua # Frame interpolation
│       └── ui/             # UI system
│           ├── init.lua    # UI engine
│           ├── theme.lua   # Golden hour color palette
│           ├── command-card.lua # Action buttons
│           ├── minimap.lua # Minimap
│           └── production-queue.lua # Production display
├── test/                   # Test suite (69 tests)
├── docs/
│   ├── adr/                # Architecture Decision Records
│   └── agents/             # Agent configuration
├── conf.lua                # LÖVE configuration
├── main.lua                # Bootstrap
└── Makefile                # Build system
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, workflow, and code conventions.

## Reading List

### RTS Game Design

- [Age of Empires II: Design Notes](https://www.wildfiregames.com/blog/2023/01/03/age-of-empires-ii-design-notes/)
- [Game Programming Patterns (Nystrom)](https://gameprogrammingpatterns.com/) — free online book, ECS and game loops chapters
- [Rules of Play (Salen & Zimmerman)](https://mitpress.mit.edu/9780262240453/rules-of-play/) — game design theory

### Lua

- [Programming in Lua (4th ed.)](https://www.lua.org/pil/) — definitive Lua reference
- [Lua Reference Manual](https://www.lua.org/manual/5.4/) — official Lua docs
- [Lua Users Wiki](https://lua-users.org/wiki/) — community tutorials

### LÖVE Framework

- [LÖVE Wiki](https://love2d.org/wiki/Main_Page) — official API docs
- [How to Make LÖVE](https://0x72.itch.io/lovetutorial) — free e-book

### ECS Architecture

- [Entity Component System (Evolve)](https://evolvegame.com/developer-blog/entity-component-system/)
- [ECS on Wikipedia](https://en.wikipedia.org/wiki/Entity_component_system)

### Deterministic Lockstep Networking

- [Lockstep Networking (Glenn Fiedler)](https://gafferongames.com/)
- [Deterministic Lockstep (Gabriel Gambetta)](https://www.gabrielgambetta.com/client-server-game-architecture.html)
- [ENet Documentation](http://enet.bespin.org/)

### AI for Games

- [AI for Games (Millington)](https://www.amazon.com/AI-Games-Ian-Millington/dp/0123944430)
- [Game AI Pro (Series)](https://www.gameaipro.com/) — free online collection

## License

[AGPL v3.0](LICENSE.md) — Copyright (c) 2026 Jordan Firth
