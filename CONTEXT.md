# Sun After Rome — Domain Context

An Age of Empires II-style deterministic RTS. Two factions compete by gathering resources, training units, advancing through ages, and fighting.

## Language

**Faction**:
A side in the game. Owns entities, resources, and an age level. Identified by player index (0 or 1).
_Avoid_: player, side, team

**Controller**:
The thing deciding what orders to issue for a faction. Can be `:human` (keyboard/mouse), `:ai` (decision function), `:remote` (network peer), or `:spectator` (observes, issues no orders). Bound to exactly one faction at game start. All controllers issue orders through the same path — no direct world mutation. When a controller disconnects, the faction goes idle (no orders issued). A new controller can be bound at runtime. AI controllers run as a system in the tick pipeline — they read live state and issue orders that apply next tick. AI intelligence for v1 is scripted (fixed build order with guards — checks world state before issuing orders). AI personality is data-driven (config table controls aggression, defense radius, resource ratios). In multiplayer, disconnected players get AI takeover (deterministic AI preserves lockstep).
_Avoid_: player, input source

**Entity**:
A game object identified by a unique integer ID. Has components attached (position, health, kind, etc.).
_Avoid_: unit, object, thing

**Component**:
Plain data attached to an entity. Types: position, owner, kind, health, carry, node, cooldown, producer, task. Stored in the world's component store, keyed by entity ID.
_Avoid_: attribute, property, field

**World**:
The entire mutable game state. Contains the component store, per-faction resources, ages, RNG, order queue, and event log. Two factions compete; the win condition is destroying all enemy Town Centres or attaining a special victory (e.g., building a wonder). A faction can concede at any time.
_Avoid_: state, game state, environment

**Order** (also: Command):
A player/decision input to the simulation. Orders-as-data: plain tables with a `:tag` field. Types: move, gather, attack, train, advance-age. The ONLY way to change the simulation. Both human and AI controllers can issue multiple orders per tick — fairness comes from decision quality, not order count.
_Avoid_: command, instruction, input

**Tick**:
One discrete time step of the simulation. Fixed-timestep, integer-counted. Systems run in fixed order each tick. The AI runs as a system within the tick pipeline, reading live state and issuing orders for the next tick.
_Avoid_: frame, step, update

**Age**:
A technology level (1, 2, or 3) that modifies unit stats via multipliers. Advancing costs resources and time.
_Aavoid_: era, epoch, level

**Resource**:
Materials gathered and spent. Types: wood, stone, gold. Stored per-faction.
_Avoid_: material, currency

**Task**:
What an entity is currently doing. Types: idle, move, gather (with phases: to-node, gathering, to-drop), attack.
_Avoid_: action, behaviour, state

**Producer**:
A building that trains units. Has a queue of unit types and a progress counter.
_Avoid_: building, factory, spawner

**Node**:
A resource deposit on the map (tree, gold mine, stone mine). Has a resource type and depleting amount. Sits ON a terrain tile but IS NOT the tile. When depleted, the entity is removed — the underlying terrain remains.
_Avoid_: resource node, deposit, mine

**Terrain**:
The static tile grid of the map. Determines walkability and visual background. Set at game start, never changes during gameplay. Entities (units, buildings, nodes) sit on top of terrain tiles.
_Avoid_: map, ground, tile (use "tile" only when referring to a specific grid cell)

## Design System

**Design System**:
The complete set of principles, primitives, and rules that govern how Sun After Rome looks, feels, and communicates. Covers visual identity, interaction patterns, information hierarchy, animation, and feedback. The design system answers "how does the player *feel* and *understand* the game."
_Avoid_: style guide, theme, visual design

**Expansion** (core feeling):
The primary player feeling: "I'm building something growing and powerful." Every design decision serves this. The world should fill with life as the player grows. More units, more movement, more buildings, more animation. The UI stays clean and lets the world speak.
_Avoid_: power, progression, growth (use "expansion" for the feeling specifically)

**Panel**:
A bounded UI region with background, border, padding. The fundamental container. Hand-drawn style: visible borders, warm fills, parchment texture. Everything lives inside panels.
_Avoid_: window, frame, container

**Label**:
UI text with a font, color, alignment. The font module provides small/medium/large sizes. Functional, not decorative.
_Avoid_: text, heading, caption

**Icon**:
A sprite or drawn symbol representing a resource, unit type, or age. Small, clear, scannable. Used in command cards, resource displays, and production queues.
_Avoid_: symbol, glyph, image

**Button**:
A panel + label + click handler. Responsive and snappy: instant visual feedback (depress, highlight, glow). The interactive primitive.
_Avoid_: control, widget, control

**Bar**:
A horizontal fill indicator. Health bars, resource counters, progress meters. The "expansion" visual — bars fill as you grow.
_Avoid_: meter, gauge, progress bar (use "bar" for brevity)

**Empire Status**:
The thin strip of resource bars and age indicator, always visible but never competing with the world. Shows wood, food, gold, stone, and current age. Minimal, scannable, always present.
_Avoid_: resource panel, top bar, status bar

**Selection Context**:
The panel that appears when a unit or building is selected. Shows what it can do — command card, health, production queue. Appears on demand, disappears when not needed.
_Avoid_: selection panel, unit info, details

**Command Card**:
A grid of buttons showing available actions for the selected entity. Right-click to issue. Appears in selection context.
_Avoid_: action bar, ability bar, hotbar

**Information Hierarchy**:
The priority order for what the player sees: (1) The world — always primary, fills 80%+ of screen. (2) Selection context — on demand. (3) Empire status — thin strip, always visible. The world is the interface.
_Avoid_: UI hierarchy, visual priority

**Feedback**:
Every action gets a reaction. Visual (glow, particles, floating text), auditory (clicks, acknowledgments, ambient). No silent failures. The player should never wonder "did the game hear me?"
_Avoid_: response, reaction, confirmation (use "feedback" for the complete system)

**Golden Hour**:
The color temperature of the entire UI. Warm by default, cool only for exception. Parchment backgrounds, terracotta borders, gold accents. The visual signature of Sun After Rome.
_Avoid_: warm palette, brown theme (use "golden hour" for the feeling)
