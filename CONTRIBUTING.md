# Contributing to Sun After Rome

Thanks for interest in contributing. This guide covers what you need to get started.

## Setup

```bash
# Clone the repo
git clone git@github.com:vorren/sun-after-rome.git
cd sun-after-rome

# Install dependencies (macOS)
brew install love fennel lua luajit

# Build and test
make build
make test
```

See README.md for Linux/BSD/NixOS setup instructions.

## Development workflow

1. **Pick an issue** — check [GitHub Issues](https://github.com/vorren/sun-after-rome/issues) for `ready-for-agent` or `ready-for-human` labels.
2. **Create a branch** — `git checkout -b <ticket-slug>`
3. **Make your changes** — see below for conventions.
4. **Run tests** — `make test` (must pass before submitting).
5. **Submit a PR** — describe what the issue asks for, link the issue.

## Code conventions

### Fennel

- **No comments** unless asked.
- **No method-call syntax** — use `(obj.method obj args)` instead of `(obj:method args)`.
- **`var` for mutable locals** — `let` bindings are immutable.
- **0-based player indices** — game logic uses 0-based factions; Lua tables are 1-indexed (offset by +1).
- **Orders are data** — all simulation input goes through `world.orders`, never direct mutation.
- **Determinism** — same seed + same orders = same world. No randomness outside `rng.fnl`.

### File layout

```
src/
├── ai/           # AI controllers (scripted, reactive, etc.)
├── systems/      # Game systems (one per file)
├── render/       # Rendering modules
└── net/          # Networking (lockstep, commands, host)
```

### Tests

- Tests live in `test/` as `*_test.fnl`.
- Each test file returns a table of test functions (luaunit style).
- Run with `make test` — all 26 tests must pass.
- Tests run with plain Lua (not LÖVE), so no `love.*` calls in tests.

### Content and stats

Unit/building stats live in `src/content.fnl`. When adding new units:
1. Add the kind entry to the `kinds` table
2. Add a test for the new unit's stats
3. Update the README controls section if it's player-controllable

## Architecture decisions

All significant architectural decisions are recorded as ADRs in `docs/adr/`. Read them before changing core systems. The domain glossary is in `CONTEXT.md` — use its vocabulary in code and issues.

## Asking questions

Open a GitHub issue with the `needs-info` label if you're stuck. Describe what you tried and what you expect.

## License

By contributing, you agree your changes are licensed under AGPL v3.0.
