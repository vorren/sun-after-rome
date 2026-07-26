# ADR-0009: Commands as data with a serializable order log

**Status:** Accepted

## Context
In a deterministic sim, commands are the only input to the world, and they are
the API surface the user extends most. Options ranged from direct mutating calls
to queued command objects to a fully logged command stream.

## Decision
Intents are **immutable tagged-list commands** (e.g. `(gather 7 12)`). `issue!`
enqueues; at the top of each tick `apply-orders!` drains the queue in submission
order, translating each command into entity state (usually a task component) and
appending it to a **serializable order log**.

## Consequences
- The entire game is `(seed + ordered command log)`, giving exact tests and full
  replay (`orders->sexp` / `sexp->orders`).
- Clean separation of *intent* (order) from *behaviour* (the system that fulfils
  it over many ticks): e.g. a `gather` order sets a task; the gather system works
  it tick by tick.
- Rejected commands (unaffordable train, illegal age-up) are still logged so a
  replay reproduces the same failed attempt.
- One layer of indirection (order → task → system) instead of calling behaviour
  directly — this indirection *is* the design.
