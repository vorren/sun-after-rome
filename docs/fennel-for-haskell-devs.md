# Fennel for Haskell Developers

A quick guide for Haskell programmers picking up Fennel for Aurelius.

## Key Differences

### No Type System
Fennel is dynamically typed. There are no type classes, no GADTs, no compile-time guarantees. You rely on the REPL and tests for correctness.

### Tables Instead of ADTs
```haskell
-- Haskell
data Command = Move Int Int Int | Gather Int Int | Attack Int Int
```
```fennel
;; Fennel - tagged tables
{:tag :move :eid 5 :tx 10 :ty 8}
{:tag :gather :eid 3 :node 7}
```

### Mutation is Default
```haskell
-- Haskell - IORef, STRef, etc.
modifyIORef ref (+1)
```
```fennel
;; Fennel - direct mutation
(set x (+ x 1))
```

### Function Calls Require Parens
```haskell
-- Haskell
f x y
```
```fennel
;; Fennel - parens required
(f x y)
```

### Let Bindings
```haskell
-- Haskell
let x = 1
    y = 2
in x + y
```
```fennel
;; Fennel
(let [x 1 y 2]
  (+ x y))
```

### Pattern Matching
```haskell
-- Haskell
case cmd of
  Move eid tx ty -> ...
  Gather eid node -> ...
```
```fennel
;; Fennel
(match cmd.tag
  :move (...)
  :gather (...)
  _ (default))
```

### List Comprehensions
```haskell
-- Haskell
[x * 2 | x <- [1..10], x > 3]
```
```fennel
;; Fennel - icollect
(icollect [x (ipairs (range 1 10))]
  (when (> x 3) (* x 2)))
```

### Iteration
```haskell
-- Haskell
mapM_ print [1..10]
```
```fennel
;; Fennel
(each [i (ipairs (range 1 10))]
  (print i))
```

## ECS Concepts

The ECS maps cleanly:
- **Entity** = integer ID (like a record index)
- **Component** = table with specific shape (like a record value)
- **System** = function `(fn [world] ...)` (like a fold over entities)
- **World** = single mutable table containing all state

## REPL Workflow

Start the game and interact from the terminal:
```fennel
>> (pp (. game-world :tick))
>> (set (. game-world.resources 1 :wood) 999)
```

## Key Resources

- [Fennel Reference](https://fennel-lang.org/reference)
- [Fennel Tutorial](https://fennel-lang.org/tutorial)
- [Programming in Lua](https://www.lua.org/pil/) (applies to Fennel)
