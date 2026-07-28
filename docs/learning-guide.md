# Learning Guide

A personal learning document for building the Sun After Rome design system. Each section covers a concept, why it matters, and how to learn it by building.

## Lua Fundamentals

### Tables as the universal data structure

Lua has no classes, no arrays, no dictionaries. Everything is a table — a key-value map that can also be used as an array.

```lua
-- Table as object
local unit = { x = 5, y = 3, health = 100, kind = "villager" }

-- Table as array
local units = { unit1, unit2, unit3 }

-- Table as module
local M = {}
function M.greet(name) return "Hello, " .. name end
return M
```

**Why it matters for design systems**: Panels, buttons, bars — all are tables. Understanding tables means understanding everything.

**Learn by doing**: Create a Panel table with fields `:x`, `:y`, `:width`, `:height`, `:color`. Draw it with `love.graphics.rectangle`.

### Metatables (the "magic")

Metatables let you override what happens when you index, call, or operate on a table. This is how LÖVE implements sprites, canvases, fonts, and more.

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

## Lua Patterns

### Table composition

Build complex structures by nesting tables:

```lua
-- Nested table
local panel = {
  x = 10, y = 10,
  children = {
    { type = "label", text = "Hello" },
    { type = "button", text = "Click me" }
  }
}
```

**Why it matters**: ECS is all about composing components into entities. Tables are the universal building block.

### Pattern matching with string.find

Lua uses `string.find` with patterns (similar to regex):

```lua
local name = "villager"
if string.find(name, "vil") then
  print("Found villager!")
end
```

### Function as values

Functions are first-class values — pass them as arguments, return them, store them in tables:

```lua
local commands = {
  move = function(x, y) return {tag = "move", x = x, y = y} end,
  attack = function(target) return {tag = "attack", target = target} end
}
```

## LÖVE Rendering

### The draw stack

LÖVE draws in order: first drawn = behind. No depth buffer. You control z-order by draw order.

```lua
function love.draw()
  love.graphics.setColor(0.3, 0.2, 0.1, 1)  -- background
  love.graphics.rectangle("fill", 0, 0, 800, 600)
  love.graphics.setColor(0.9, 0.8, 0.6, 1)  -- UI on top
  love.graphics.rectangle("fill", 10, 10, 200, 50)
end
```

**Why it matters**: UI must draw on top of the world. Understanding draw order is essential for panels, buttons, floating text.

### love.graphics.push/pop

Save and restore the transform state. Use this for UI positioning without affecting world coordinates.

```lua
love.graphics.push()
love.graphics.translate(100, 100)  -- move origin
love.graphics.rectangle("fill", 0, 0, 50, 50)  -- drawn at 100,100
love.graphics.pop()  -- back to original origin
```

**Why it matters**: UI panels use push/pop to position relative to screen edges, not world coordinates.

### love.graphics.setColor

Sets the color for subsequent draw calls. Takes R, G, B, A (0-1 range).

```lua
-- Parchment: #F5E6C8 = rgb(245, 230, 200)
love.graphics.setColor(245/255, 230/255, 200/255, 1)
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

## Data-Driven UI

The game uses a data-driven UI system. Layouts are defined as tables, not code. This section explains how it works.

### The Node Schema

Every UI element is a table with a `type` field:

```lua
{type = "panel",
 x = 10, y = 10,
 w = 300, h = 50,
 pad = 8,
 dir = "horiz",
 gap = 4,
 children = {...}}
```

**Required field:**
- `type` — `"panel"`, `"label"`, `"icon"`, `"bar"`, or `"button"`

**Positioning (relative):**
- `x = "left"` — left edge
- `x = "right"` — right edge
- `x = "center"` — centered
- `x = "right-120"` — 120px from right edge
- `y = "top"` — top edge
- `y = "bottom"` — bottom edge
- `y = "bottom-40"` — 40px from bottom

**Auto-layout:**
- `dir = "vert"` — stack children top to bottom
- `:dir :horiz` — stack children left to right
- `:gap 4` — space between children
- `:pad 8` — padding inside panel

### Theme System

The golden hour palette is a separate theme table. Easy to swap.

```lua
local ui = require("src.render.ui")

-- Initialize with default theme
ui.init({})

-- Or with overrides
ui.init({parchment = "#FFFFFF"})
```

### Drawing UI

```lua
local ui = require("src.render.ui")

function love.draw()
  ui.draw(
    ui.root({},
      -- Resource bar
      {type = "panel",
       x = "top", y = "left",
       w = 400, h = 50,
       dir = "horiz", gap = 12, pad = 8,
       children = {
         {type = "label",
          x = 0, y = 0,
          text = "Wood: 120",
         :font :md :color :sage}
        {:type :bar
         :x 0 :y 0
         :w 200 :h 12
         :value 0.6 :max 1
         :fill :gold :bg :brown}]}
      ;; Command card
      {:type :panel
       :x :right-170 :y :bottom-110
       :w 160 :h 100
       :dir :horiz :gap 4 :pad 6
       :children
       [{:type :button
         :x 0 :y 0
         :w 44 :h 44
         :text "Move"
         :on-click (fn [] (print "clicked!"))}]})))
```

### Hit Testing

The UI module handles mouse interaction automatically:

```lua
-- In love.update or love.mousepressed
function love.mousemoved(x, y)
  ui.handle_mouse_move(root_node, x, y)
end

function love.mousepressed(x, y, button)
  if button == 1 then
    ui.handle_click(root_node, x, y)
  end
end
```

### Color Resolution

Colors can be:
- HEXSTRING: `"#F5E6C8"` (primary format)
- RGB table: `{0.96, 0.90, 0.78}`
- Theme key: `"parchment"` (resolved from theme)

```lua
ui.resolve("#F5E6C8")  --> {0.96, 0.90, 0.78}
ui.resolve("parchment")   --> {0.96, 0.90, 0.78}
ui.resolve({0.5, 0.5, 0.5})  --> {0.5, 0.5, 0.5}
```

### Exercises

#### Exercise 6: Build a resource bar

Create a horizontal panel with four labels (wood, food, gold, stone) using the UI module.

#### Exercise 7: Add a button

Create a "Train Villager" button that prints to console when clicked.

#### Exercise 8: Build a selection panel

When a unit is selected, show its type, health bar, and current task.

## Questions to ask yourself

When building any UI element:

1. Does this serve the **expansion** feeling?
2. Does the **world** stay primary (80%+ of screen)?
3. Is the feedback **instant** (<50ms)?
4. Is this one of the **five primitives** (Panel, Label, Icon, Button, Bar)?
5. Does this follow the **golden hour** palette?

If the answer to any is "no" — redesign before building.
