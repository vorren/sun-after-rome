# Sun After Rome

[![Tests](https://github.com/vorren/sun-after-rome/actions/workflows/test.yml/badge.svg)](https://github.com/vorren/sun-after-rome/actions/workflows/test.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

An Age of Empires II-style deterministic RTS built with **Fennel** and **LÖVE**.

> **Private repository.** This project is not publicly available. For access, contact the maintainer.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Building](#building)
- [Controls](#controls)
- [REPL](#repl)
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
- **Live REPL** — modify game state at runtime via a Fennel REPL
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
make build
make run
```

## Requirements

- [LÖVE](https://love2d.org/) 11.4+ (installed externally)
- [Nix](https://nixos.org/) (recommended) or manual install of Fennel, Lua, ENet

### Nix (recommended)

```bash
nix develop    # provides: fennel, luajit, enet, gcc, pkg-config, lua5_4
love .         # run game (love must be installed externally)
```

### macOS (manual)

```bash
brew install love fennel lua luajit
make run
```

### Building the ENet Binding (optional, for multiplayer)

In the Nix dev shell, `make enet` works automatically — paths are set by `shellHook`.

For manual installs, see the Makefile for required flags.

If the ENet binding cannot be found at runtime, networking is disabled — the game still works in single-player.

## Building

```bash
make build    # AOT compile Fennel to Lua
make test     # Run the test suite (60 tests)
make clean    # Remove compiled output
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
| `F5` | Reset world |
| `Escape` | Quit |

## REPL

The game includes a file-based Fennel REPL for inspecting and modifying game state at runtime.

**Full reference guide:** [docs/repl-reference.md](docs/repl-reference.md)

### Terminal

```bash
# Start the game
love .

# In another terminal
./repl.sh

# Or manually
echo '(world.resource-amount game-world 0 :wood)' > repl.in
cat repl.out
```

### Emacs

```elisp
;; M-x shell — run repl.sh in a shell buffer
(defun sar-repl ()
  "Open a Sun After Rome REPL buffer."
  (interactive)
  (let ((buf (make-comint "sar-repl" "./repl.sh")))
    (pop-to-buffer buf)))

;; Send a region to the REPL
(defun sar-send-region (start end)
  "Send the active region to the SAR REPL."
  (interactive "r")
  (let ((code (buffer-substring-no-properties start end)))
    (with-current-buffer "*sar-repl*"
      (comint-send-string (get-buffer-process (current-buffer))
                          (concat code "\n")))))

(global-set-key (kbd "C-c C-r") 'sar-send-region)
```

### Vim / Neovim

```vim
" Terminal mode — run repl.sh in a terminal split
command! SARRepl terminal ./repl.sh

" Send current line to the REPL
function! SARSendLine()
  let l:line = getline('.')
  call chansend(b:terminal_job_id, l:line . "\n")
endfunction

" Send visual selection to the REPL
function! SARSendSelection() range
  let l:lines = getline(a:firstline, a:lastline)
  call chansend(b:terminal_job_id, l:lines)
endfunction

nnoremap <leader>r :call SARSendLine()<CR>
vnoremap <leader>r :call SARSendSelection()<CR>
```

### Example REPL Sessions

```fennel
;; Inspect all entities
(pp (world.world-query game-world :kind))

;; Check player 0's wood
(world.resource-amount game-world 0 :wood)

;; Give player 0 infinite gold
(world.add-resource! game-world 0 :gold 9999)

;; Spawn a knight for player 0 at (10, 10)
(world.spawn! game-world :knight {:owner 0 :x 10 :y 10})

;; Kill all enemies
(each [_ pair (ipairs (world.world-query game-world :health))]
  (let [owner (world.world-get game-world pair.eid :owner)]
    (when (and owner (= owner.player 1))
      (world.world-remove-entity! game-world pair.eid))))

;; Force-advance player 0 to age 3
(world.set-player-age! game-world 0 3)
```

## Architecture

The game uses an **Entity-Component-System (ECS)** architecture:

- **Entities** are integer IDs
- **Components** are plain tables (position, health, kind, etc.)
- **Systems** are functions that process entities each tick
- **World** is the single mutable state container

### System Pipeline (each tick)

1. `apply-orders!` — drain command queue, translate to entity tasks
2. `controller-dispatch!` — AI controllers issue orders
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
aurelius-fennel/
├── lib/                    # Third-party libraries
│   ├── fennel.lua          # Embedded Fennel compiler
│   ├── fennelview.lua      # Pretty-printer
│   ├── luaunit.lua         # Test framework
│   └── enet.so             # ENet binding (compiled, not in repo)
├── src/
│   ├── init.fnl            # LÖVE callbacks
│   ├── world.fnl           # Entity/component store
│   ├── components.fnl      # Component constructors
│   ├── content.fnl         # Unit/building stats
│   ├── orders.fnl          # Commands-as-data
│   ├── rng.fnl             # Deterministic PRNG
│   ├── sim.fnl             # Fixed-timestep tick loop
│   ├── ai/                 # AI controllers
│   │   ├── scripted.fnl    # Scripted build-order AI
│   │   └── personalities.fnl # Data-driven personality configs
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
├── test/                   # Test suite (60 tests)
├── docs/
│   ├── adr/                # Architecture Decision Records
│   └── agents/             # Agent configuration
├── conf.lua                # LÖVE configuration
├── main.lua                # Fennel bootstrap
└── Makefile                # Build system
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, workflow, and code conventions.

## Reading List

### RTS Game Design

- [Age of Empires II: Design Notes](https://www.wildfiregames.com/blog/2023/01/03/age-of-empires-ii-design-notes/)
- [Game Programming Patterns (Nystrom)](https://gameprogrammingpatterns.com/) — free online book, ECS and game loops chapters
- [Rules of Play (Salen & Zimmerman)](https://mitpress.mit.edu/9780262240453/rules-of-play/) — game design theory

### Fennel and Lua

- [Fennel Programming Language](https://fennel-lang.org/) — official docs and tutorial
- [Programming in Lua (4th ed.)](https://www.lua.org/pil/) — definitive Lua reference
- [Lua Reference Manual](https://www.lua.org/manual/5.4/) — official Lua docs

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
