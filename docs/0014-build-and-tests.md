# ADR-0014: Makefile build, multi-OS install, SRFI-64 tests

**Status:** Accepted

## Context
The user asked for a real build step (not bare `guile -L .`) with install
instructions for Linux, FreeBSD, and macOS. The dev machine's Guile was missing
the `guild` compiler front-end (a stripped WSL image), so the build cannot hard-
depend on `guild`.

## Decision
A **`Makefile`** with targets `build` (AOT-compile every module into `ccache/`),
`repl`, `test`, `check`, `clean`, `help`. Compilation uses `guild` when present
and **falls back to Guile's `(system base compile)` module** when it is not.
Tests use **SRFI-64** (ships with Guile). README documents install per platform:

| OS | Command |
|---|---|
| Debian/Ubuntu | `sudo apt-get install guile-3.0` |
| Fedora | `sudo dnf install guile30` |
| Arch | `sudo pacman -S guile` |
| FreeBSD | `pkg install guile3` |
| macOS | `brew install guile` |

## Consequences
- The build works on a Guile install with no `guild` binary — no extra tooling.
- AOT compilation surfaces syntax/unbound errors up front and speeds REPL/test
  startup; it remains an optimization since Guile also auto-compiles on demand.
- `make test` exits non-zero on any failure (custom SRFI-64 runner + fail count),
  so it is CI-usable.
- Makefile gotcha recorded: `#` in a recipe is a comment, so `\#:output-file`
  must be escaped in the fallback compile command.
