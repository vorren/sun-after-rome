# Spec: UI Phase 2 — Interactive Elements

## Problem Statement

The game has a data-driven UI module with panels, labels, bars, and buttons. The HUD shows resource counts and selection info. But the player cannot:
- Click buttons to issue commands (only hotkeys M/G/A work)
- See what buildings are training (production queue is invisible)
- See unit health in the world (only in selection panel)
- Navigate the map without scrolling (no minimap)
- Know unit costs before training

The UI is display-only. It needs to become interactive.

## Solution

Build four interconnected UI features that make the game playable through the interface, not just hotkeys. Each feature uses the existing data-driven UI module (`src/render/ui/`) and follows the Golden Hour design system.

## User Stories

### Command Card
1. As a player, when I select a unit, I want to see available actions as clickable buttons, so I can issue commands without memorizing hotkeys
2. As a player, I want the command card to show Move, Gather, and Attack buttons, so I know what my unit can do
3. As a player, when I click a command button, I want the cursor to change to crosshair, so I know I'm in command mode
4. As a player, when I click a command button and then click the world, I want the command to execute, so I can play without keyboard
5. As a player, when I right-click while in command mode, I want to cancel the command, so I can back out of a decision
6. As a player, I want command buttons to highlight on hover, so I know which one I'm about to click
7. As a player, I want command buttons to depress on click, so I get tactile feedback
8. As a player, I want the command card to appear only when units are selected, so the screen stays clean
9. As a player, I want the command card to disappear when I deselect, so I'm not confused about what's selected
10. As a player, I want the command card to show different buttons for different unit types (villagers show Gather, military shows Attack), so the UI matches the unit's capabilities

### Production Queue
11. As a player, when I select a building, I want to see what units it's training, so I know my production status
12. As a player, I want to see a progress bar for the current training job, so I know when it will finish
13. As a player, I want to see the queue of upcoming units, so I can plan my production
14. As a player, I want to see the resource cost of each unit in the queue, so I know what I'm spending
15. As a player, when I select a barracks, I want to see "Train Villager", "Train Pikeman", "Train Knight" buttons, so I can choose what to produce
16. As a player, when I click a train button, I want the unit added to the queue, so production starts
17. As a player, I want train buttons to be disabled when I can't afford the unit, so I don't waste clicks
18. As a player, I want the production queue to update in real-time, so I see progress as it happens

### Health Bars in World
19. As a player, I want to see health bars above units and buildings, so I can assess combat at a glance
20. As a player, I want health bars to be green when healthy, yellow when damaged, red when critical, so I can read status instantly
21. As a player, I want health bars to appear only when entities are damaged, so the screen stays clean when everything is full health
22. As a player, I want health bars to be small and unobtrusive, so they don't clutter the view
23. As a player, I want health bars to follow entities as they move, so the information stays with the unit
24. As a player, I want health bars to scale with the camera, so they're readable at any zoom level

### Minimap
25. As a player, I want to see a mini map in the corner, so I can navigate without scrolling
26. As a player, I want the minimap to show terrain colors, so I can read the landscape
27. As a player, I want the minimap to show unit dots in faction colors, so I can see where armies are
28. As a player, I want the minimap to show my current viewport, so I know what I'm looking at
29. As a player, I want to click the minimap to scroll the view, so I can jump to distant locations
30. As a player, I want the minimap to update in real-time, so I see changes as they happen
31. As a player, I want the minimap to be toggleable with F2, so I can hide it when I want full screen
32. As a player, I want the minimap to show resource nodes, so I can find wood, gold, and stone

## Implementation Decisions

### Command Card Module
- Create `src/render/ui/command-card.fnl` as a separate module
- Command card reads selected entity's kind and generates appropriate buttons
- Buttons call `hud.set-command-mode` to enter command mode
- Integration point: `hud.fnl` calls `command-card.build` during `draw-hud`
- Command types: `:move`, `:gather`, `:attack` (military units), `:train-villager`, `:train-pikeman`, `:train-knight` (buildings)

### Production Queue Module
- Create `src/render/ui/production-queue.fnl` as a separate module
- Reads `producer` component from selected building
- Displays current training unit, progress bar, and queue
- Train buttons call `orders.train` to add to queue
- Integration point: `hud.fnl` calls `production-queue.build` during `draw-hud`

### Health Bars in World
- Modify `src/render/sprites.fnl` to draw health bars above entities
- Health bar appears only when `hp < max-hp`
- Color interpolation: green (100-60%) → yellow (60-30%) → red (30-0%)
- Bar width scales with entity collision radius
- Bar height is fixed 4px, offset 8px above entity

### Minimap Module
- Create `src/render/ui/minimap.fnl` as a separate module
- Renders to a `love.graphics.newCanvas` (off-screen buffer)
- Updates every N ticks (not every frame) for performance
- Draws terrain as colored pixels, units as dots
- Viewport rectangle shows current camera position
- Click handler scrolls view by mapping click position to world coordinates
- Toggle with F2 key

## Testing Decisions

### What Makes a Good Test
- Test that modules compile and export expected functions
- Test that command card generates correct buttons for different unit types
- Test that production queue reads producer component correctly
- Test that health bar color interpolation works
- Test that minimap canvas is created and rendered
- Do NOT test visual appearance (that's manual QA)
- Do NOT test exact pixel positions (that's brittle)

### Modules to Test
- `src/render/ui/command-card.fnl` — button generation logic
- `src/render/ui/production-queue.fnl` — queue reading logic
- `src/render/sprites.fnl` — health bar drawing (existing test file)
- `src/render/ui/minimap.fnl` — canvas creation and rendering

### Prior Art
- `test/test-ui.fnl` — theme tests (hex-to-rgb, resolve-color)
- `test/hud_test.fnl` — HUD compilation and API tests
- `test/ai_test.fnl` — AI controller tests (similar pattern: test logic, not visuals)

## Out of Scope

- **Fog of war** — deferred per ADR-0008
- **Idle unit notification** — nice to have, not critical for v1
- **Damage numbers** — floating text exists, but combat-specific numbers are v2
- **Tooltips on hover** — would be nice, but adds complexity; v2
- **Keyboard navigation** — RTS uses mouse + hotkeys, not tab navigation
- **Animation of health bars** — static interpolation is enough for v1
- **Minimap signals/pings** — multiplayer feature, v2
- **Production queue reordering** — just append, no drag-reorder

## Further Notes

### Build Order
1. Health bars in world (simplest, immediate visual improvement)
2. Command card (interactive, unlocks mouse-driven gameplay)
3. Production queue (shows building functionality)
4. Minimap (navigation, most complex)

### Design System Alignment
Each feature follows ADR-0017:
- **Expansion feeling** — more UI = more life on screen
- **World is the interface** — health bars are in the world, not in a panel
- **Golden hour palette** — all new UI uses the theme
- **Responsive and snappy** — instant feedback on clicks, no lag
- **Every action gets a reaction** — button hover, click depress, command mode cursor

### Learning Opportunities
- **Health bars**: Love2D draw calls, coordinate transforms, color math
- **Command card**: UI module composition, event handling, state management
- **Production queue**: Reading component data, progress calculation, button states
- **Minimap**: Canvas rendering, pixel manipulation, click-to-scroll mapping
