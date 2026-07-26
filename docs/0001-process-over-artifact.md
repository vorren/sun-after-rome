# ADR-0001: Optimize for the live-programming process, artifact secondary

**Status:** Accepted

## Context
The project can be pulled toward two goals: demonstrating live, REPL-driven
development in Guile (the *process*), or producing a polished small game (the
*artifact*). Guile was chosen partly to experience its live workflow.

## Decision
Treat the **live-programming process as the primary success criterion**, with a
playable foundation the user extends themselves as the secondary outcome.

## Consequences
- Architecture is judged first on inspectability, clean state/system/render
  separation, and hot-reloadability — qualities that also happen to make a good
  game codebase.
- We keep the presentation layer thin and swappable so it never blocks REPL
  iteration (see [0002](0002-headless-first.md)).
- We accept less game-feel polish in v1 in exchange for a codebase that is a
  pleasure to grow.
