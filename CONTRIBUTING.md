# Contributing to Sun After Rome

This is a private project. Contributions are by invitation only.

## Setup

```bash
# Clone the repo
git clone git@github.com:vorren/sun-after-rome.git
cd sun-after-rome

# Option 1: Nix (recommended)
nix develop    # enters dev shell with all deps

# Option 2: Manual install (macOS)
brew install love lua luajit

# Build and test
make test
```

## Development workflow

1. **Pick an issue** — check GitHub Issues for `ready-for-agent` or `ready-for-human` labels.
2. **Create a branch** — `git checkout -b <ticket-slug>`
3. **Make your changes** — see below for conventions.
4. **Run tests** — `make test` (must pass before submitting).
5. **Run smoke test** — `make smoke-test` (catches LÖVE runtime errors).
6. **Submit a PR** — describe what the issue asks for, link the issue.

## Testing

```bash
make test          # Unit tests (69 tests, runs with plain Lua)
make smoke-test    # LÖVE smoke test (catches runtime errors, requires LÖVE)
```

**Smoke test** loads the game and checks for LÖVE API errors at load time. It catches issues like:
- Missing cursor files
- Invalid LÖVE API calls
- Module load failures

The smoke test exits with code 0 (pass) or 1 (fail with traceback).

## Code conventions

### Lua

- **No comments** unless asked.
- **Local functions** — use `local function` for module-private functions.
- **0-based player indices** — game logic uses 0-based factions; Lua tables are 1-indexed (offset by +1).
- **Orders are data** — all simulation input goes through `world.orders`, never direct mutation.
- **Determinism** — same seed + same orders = same world. No randomness outside `rng.lua`.
- **Module exports** — export both underscore and hyphenated names for compatibility.

### File layout

```
src/
├── ai/           # AI controllers (scripted, reactive, etc.)
├── systems/      # Game systems (one per file)
├── render/       # Rendering modules
└── net/          # Networking (lockstep, commands, host)
```

### Tests

- Tests live in `test/` as `*_test.lua`.
- Each test file returns a table of test functions (luaunit style).
- Run with `make test` — all 69 tests must pass.
- Tests run with plain Lua (not LÖVE), so no `love.*` calls in tests.

### Content and stats

Unit/building stats live in `src/content.lua`. When adding new units:
1. Add the kind entry to the `kinds` table
2. Add a test for the new unit's stats
3. Update the README controls section if it's player-controllable

## Architecture decisions

All significant architectural decisions are recorded as ADRs in `docs/adr/`. Read them before changing core systems. The domain glossary is in `CONTEXT.md` — use its vocabulary in code and issues.

## Principles

**KISS** — Keep It Simple, Stupid. Prefer the simplest solution that works. No abstraction until there's a second use case. No framework, no magic, no cleverness. If a 10-line function does the job, don't make it 50.

**Determinism first** — Same seed + same orders = identical world. If you add randomness, it goes through `rng.lua`. This is the hardest constraint — it enables lockstep multiplayer and replay.

**Orders are data** — All simulation input goes through `world.orders`, never direct mutation. Human, AI, and network controllers all use the same path.

## Asking questions

Open a GitHub issue with the `needs-info` label if you're stuck. Describe what you tried and what you expect.

## License

By contributing, you agree your changes are licensed under AGPL v3.0.
