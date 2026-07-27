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
- [Lua](https://www.lua.org/) or [LuaJIT](https://luajit.org/) (for running tests)
- [LuaRocks](https://luarocks.org/) (for compiling the ENet binding)

### macOS

```bash
brew install love fennel lua luajit
```

### Debian/Ubuntu Linux

```bash
sudo apt install love fennel lua5.4 liblua5.4-dev luajit libluajit-5.1-dev
# Build libenet from source (not in most distro repos):
sudo apt install cmake build-essential
git clone https://github.com/lsalzman/enet.git /tmp/enet
cd /tmp/enet && mkdir build && cd build
cmake .. && make && sudo make install
sudo ldconfig
```

### Arch Linux

```bash
sudo pacman -S love fennel lua luajit enet cmake
```

### NixOS

```bash
nix-shell -p love fennel lua luajit enet cmake gcc
```

### FreeBSD

```bash
pkg install love2d fennel lua54 luajit enet cmake
```

### Building the ENet Binding

The ENet C library must be installed before compiling the Lua binding.

```bash
# Clone and build lua-enet
git clone https://github.com/leafo/lua-enet.git /tmp/lua-enet
cd /tmp/lua-enet

# Compile for LÖVE's LuaJIT ABI (Linux/macOS/FreeBSD):
gcc -O2 -fPIC -shared -o enet.so enet.c \
  -I/path/to/luajit/include \
  -I/path/to/enet/include \
  -L/path/to/lib \
  -lenet -lluajit-5.1 -lm

# Copy to project
cp enet.so /path/to/aurelius-fennel/lib/

# On Linux, LÖVE also searches for .so in lib/ via LUA_CPATH
```

**Platform-specific notes:**

| Platform | LUAJIT include path | ENet library |
|---|---|---|
| macOS (Homebrew) | `/opt/homebrew/include/luajit-2.1` | `/opt/homebrew/lib/libenet.a` |
| Linux (Debian) | `/usr/include/luajit-2.1` | `/usr/local/lib/libenet.so` |
| Linux (Arch) | `/usr/include/luajit-2.1` | `/usr/lib/libenet.so` |
| NixOS | Check `nix-build` output for `luajit` | Check `nix-build` output for `enet` |
| FreeBSD | `/usr/local/include/luajit-2.1` | `/usr/local/lib/libenet.so` |

If the ENet binding cannot be found at runtime, networking is disabled — the game still works in single-player.

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

## Live REPL

The game includes a file-based Fennel REPL for inspecting and modifying game state at runtime. Start the game, then send expressions from another terminal.

### Terminal usage

```bash
# Start the game
love .

# In another terminal, use the helper script
./repl.sh

# Or manually:
echo '(pp (world.world-query game-world :kind))' > repl.in
cat repl.out
```

### Emacs usage

**Option 1: Shell buffer with repl.sh (no extra packages)**

```elisp
;; M-x shell — run repl.sh in a shell buffer
;; Or create a dedicated REPL buffer:
(defun sar-repl ()
  "Open a Sun After Rome REPL buffer."
  (interactive)
  (let ((buf (make-comint "sar-repl" "./repl.sh")))
    (pop-to-buffer buf)))

;; Send a region to the REPL:
(defun sar-send-region (start end)
  "Send the active region to the SAR REPL."
  (interactive "r")
  (let ((code (buffer-substring-no-properties start end)))
    (with-current-buffer "*sar-repl*"
      (comint-send-string (get-buffer-process (current-buffer))
                          (concat code "\n")))))

;; Bind it:
(global-set-key (kbd "C-c C-r") 'sar-send-region)
```

**Option 2: Fennel mode + comint (if using fennel-mode)**

```elisp
;; In your init.el, fennel-mode can send code to a comint buffer:
(require 'fennel-mode)

;; Bind fennel-send-last-sexp to send the expression before point:
(define-key fennel-mode-map (kbd "C-c C-e") 'fennel-send-last-sexp)
```

### Example REPL sessions

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

;; Check current tick
game-world.tick

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

### Multiplayer Setup

**LAN:** Both players connect to the same local network. Host runs `love .`, client connects via the in-game menu.

**Internet (via Tailscale):** Since neither player can port-forward, use [Tailscale](https://tailscale.com/) to create a virtual LAN:

1. Both players install Tailscale (free) and sign in
2. Host runs `love .` — note the Tailscale IP shown in the Tailscale app
3. Client connects to the host's Tailscale IP
4. No port forwarding required — Tailscale handles NAT traversal

```bash
# Install Tailscale
# macOS:
brew install --cask tailscale
# Linux:
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
tailscale up
# Check your Tailscale IP
tailscale ip -4
```

Tailscale is free for up to 3 users and 100 devices. It creates a wireguard tunnel so both peers see each other as if on the same LAN.

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
