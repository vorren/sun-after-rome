# Building and Running

## Prerequisites

### macOS
```bash
brew install love lua luajit
```

### Linux / NixOS
```bash
nix-shell -p love lua
```

## Running the Game

```bash
# Quick run
love .

# Or via Make
make run
```

## Running Tests

```bash
# Run all tests
make test

# Run a single test
lua test/rng_test.lua
```

## Network Multiplayer

### Host a Game
```lua
-- In game console or REPL
src.net.host.init_host(6789)
```

### Join a Game
```lua
-- In game console or REPL
src.net.host.connect("192.168.1.100", 6789)
```

## Troubleshooting

### "module not found" errors
Ensure all `.lua` files are in the correct paths. The game loads modules from `src/` directory.

### LÖVE won't start
Ensure LÖVE 11.4+ is installed: `love --version`

### Tests fail with "attempt to index nil"
Some tests may need LÖVE APIs mocked. Run pure logic tests only.
