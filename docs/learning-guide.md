# Learning Guide

A personal learning document for building the Sun After Rome design system. Each section covers a concept, why it matters, and how to learn it by building.

## Lua Fundamentals

### Tables as the universal data structure

Lua has no classes, no arrays, no dictionaries. Everything is a table — a key-value map that can also be used as an array.

```lua
-- Table as object
local unit = { x = 5, y = 3, health = 100, kind = :villager }

-- Table as array
local units = { unit1, unit2, unit3 }

-- Table as module (what Fennel compiles to)
local M = {}
function M.greet(name) return "Hello, " .. name end
return M
```

**Why it matters for design systems**: Panels, buttons, bars — all are tables. Understanding tables means understanding everything.

**Learn by doing**: Create a Panel table with fields `:x`, `:y`, `:width`, `:height`, `:color`. Draw it with `love.graphics.rectangle`.

### Metatables (the "magic")

Metatables let you override what happens when you index, call, or operate on a table. This is how Fennel implements modules, destructuring, and more.

```lua
-- __index: what happens when you access a missing key
local mt = { __index = function(t, k) return "missing: " .. k end }
setmetatable(unit, mt)
print(unit.missing_field) --> "missing: missing_field"
```

**Why it matters**: LÖVE uses metatables for sprites, canvases, fonts. Understanding them demystifies the engine.

### Closures (functions that remember)

A function in Lua can read variables from its enclosing scope, even after that scope has exited. This is how callbacks, event handlers, and stateful UI work.

```lua
local function make_counter(start)
  local count = start
  return function()
    count = count + 1
    return count
  end
end

local counter = make_counter(0)
counter() --> 1
counter() --> 2
```

**Why it matters**: Button click handlers, animation tweens, coroutine bodies — all use closures.

## Fennel Essentials

### Everything is an expression

Fennel has no statements — everything returns a value. This makes code composable and reduces bugs.

```fennel
;; Lua: if x then y end (statement)
;; Fennel: (when x y) (expression)
(var result (when (> x 0) x))
```

### Immutable by default

Fennel encourages immutable data. Use `let` for bindings, `set` only when mutation is needed. This reduces side effects.

```fennel
(let [x 5
      y (+ x 1)]  ;; y is 6, x is still 5
  y)
```

### Destructuring (pattern matching on data)

Pull apart tables with let bindings:

```fennel
(let [{: x : y} position
      {: health : max-hp} entity]
  (print x y health))
```

**Why it matters**: ECS is all about destructuring entities into their components.

### Threading macros (-> and ->>)

Pipe data through transformations. Readable, composable.

```fennel
(->> (world.world-query game-world :health)
     (filter (fn [e] (= e.owner 0)))
     (map (fn [e] e.eid)))
```

## LÖVE Rendering

### The draw stack

LÖVE draws in order: first drawn = behind. No depth buffer. You control z-order by draw order.

```fennel
(fn love.draw []
  (love.graphics.setColor 0.3 0.2 0.1 1)  ;; background
  (love.graphics.rectangle :fill 0 0 800 600)
  (love.graphics.setColor 0.9 0.8 0.6 1)  ;; UI on top
  (love.graphics.rectangle :fill 10 10 200 50))
```

**Why it matters**: UI must draw on top of the world. Understanding draw order is essential for panels, buttons, floating text.

### love.graphics.push/pop

Save and restore the transform state. Use this for UI positioning without affecting world coordinates.

```fennel
(love.graphics.push)
(love.graphics.translate 100 100)  ;; move origin
(love.graphics.rectangle :fill 0 0 50 50)  ;; drawn at 100,100
(love.graphics.pop)  ;; back to original origin
```

**Why it matters**: UI panels use push/pop to position relative to screen edges, not world coordinates.

### love.graphics.setColor

Sets the color for subsequent draw calls. Takes R, G, B, A (0-1 range).

```fennel
;; Parchment: #F5E6C8 = rgb(245, 230, 200)
(love.graphics.setColor (/ 245 255) (/ 230 255) (/ 200 255) 1)
```

**Why it matters**: The color palette must be converted to 0-1 range. Create helper functions for each palette color.

## Game Design Concepts

### Feedback loops

Positive feedback: success → more success (expansion feels good → you expand more). Negative feedback: success → resistance (you're winning → enemy gets stronger).

**Sun After Rome uses positive feedback for expansion.** Growing your empire feels good, so you want to grow more. Combat is the climax, not the undoing.

### Information hierarchy

What the player sees first, second, third. In Sun After Rome:
1. The world (always primary)
2. Selection context (on demand)
3. Empire status (thin strip, always visible)

**Learn by doing**: Take a screenshot of AoE2. Cover the UI. What can you still tell? Cover the world. What's left? The ratio is the hierarchy.

### The MDA framework

- **Mechanics**: rules and systems (gathering, training, combat)
- **Dynamics**: player behavior that emerges (rushing, booming, turtling)
- **Aesthetics**: emotional response (expansion, mastery, tension)

The design system lives at the Aesthetics level. The mechanics produce dynamics, which produce aesthetics. Design from aesthetics backward.

## Design Principles

### Consistency beats cleverness

A consistent system (same colors, same spacing, same animation timing) is more usable than a clever one with exceptions. The player builds mental models. Consistency reinforces them.

### Progressive disclosure

Don't show everything at once. Show what's needed now, reveal more as the player needs it. The command card appears on selection. Advanced options appear at higher ages. The minimap can be toggled.

### Affordance

Things should look like what they do. Buttons look clickable (border, hover state). Bars look fillable (empty space invites filling). Panels look containable (border defines space).

### Constraint

Limit choices to make decisions meaningful. Three resource types, not ten. Three ages, not five. Five UI primitives, not fifty. Constraint breeds creativity.

## Exercises

### Exercise 1: Draw a panel

Create a function `draw-panel` that draws a rectangle with border, padding, and background color using the warm palette. Test it with different sizes.

### Exercise 2: Create a bar primitive

Build a `draw-bar` function that shows a fill amount (0-1) with a label. Use it to display a resource count.

### Exercise 3: Build a resource strip

Combine five bars (wood, food, gold, stone, age) into a horizontal strip at the top of the screen. This is the empire status.

### Exercise 4: Add click handling

Make a button that responds to mouse hover and click. Use `love.mouse.getPosition` and bounds checking.

### Exercise 5: Animate a bar

Make a bar that fills smoothly when the value changes, using linear interpolation over 200ms.

## Questions to ask yourself

When building any UI element:

1. Does this serve the **expansion** feeling?
2. Does the **world** stay primary (80%+ of screen)?
3. Is the feedback **instant** (<50ms)?
4. Is this one of the **five primitives** (Panel, Label, Icon, Button, Bar)?
5. Does this follow the **golden hour** palette?

If the answer to any is "no" — redesign before building.
