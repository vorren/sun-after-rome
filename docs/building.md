# Building and Running

## Prerequisites

### macOS
```bash
brew install love fennel lua
```

### Linux / NixOS
```bash
nix-shell -p love fennel lua
```

## Running the Game

```bash
# Quick run
love .

# Or via Make
make run
```

## Building (AOT Compilation)

```bash
make build
```

This compiles all `.fnl` files to `.lua` for faster startup.

## Running Tests

```bash
# Run all tests
make test

# Run a single test
lua test/rng_test.lua
```

## REPL Workflow

The game starts a REPL thread automatically. Connect from your terminal:

```bash
# The game prints "REPL started" when ready
# Then you can type Fennel expressions:

>> (. game-world :tick)        # Read tick count
>> (set (. game-world.resources 1 :wood) 999)  # Cheat resources
>> (pp (src.world.world-entities game-world))   # List entities
```

### Useful REPL Commands

```fennel
;; Inspect world state
(. game-world :tick)
(. game-world :next-id)

;; Resources
(. game-world.resources 1 :wood)

;; Entity components
(. (. game-world.store :kind) 1)
(. (. game-world.store :position) 1)

;; Spawn entities
(src.world.spawn! game-world :knight {:owner 0 :x 10 :y 10})

;; Issue commands
(src.orders.issue! game-world (src.orders.move 5 15 8))
```

## Network Multiplayer

### Host a Game
```fennel
>> (src.net.host.init-host! 6789)
```

### Join a Game
```fennel
>> (src.net.host.connect! "192.168.1.100" 6789)
```

## Troubleshooting

### "module not found" errors
Run `make build` to AOT-compile all modules.

### LÖVE won't start
Ensure LÖVE 11.4+ is installed: `love --version`

### Tests fail with "attempt to index nil"
Some tests may need LÖVE APIs mocked. Run pure logic tests only.
