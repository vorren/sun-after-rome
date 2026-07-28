# Design system and visual identity

The game's design system is anchored on a single feeling: **expansion** — "I'm building something growing and powerful." Every visual, interaction, and feedback decision serves this.

## Core decisions

**Visual identity**: warmth after collapse, rustic browns, rebirth, hand drawn. Golden light through ruins. Growth from decay. The hand-drawn style adds warmth and imperfection — this isn't a sterile empire, it's a *living* one.

**Information hierarchy**: the world is the interface. The map fills 80%+ of the screen. Selection context appears on demand. Empire status is a thin strip that never competes. Numbers confirm what the eye already sees.

**Interaction feel**: responsive and snappy with organic touches. The core loop (select → command → see result) is instant — expansion requires momentum, and lag kills momentum. Transitions between ages, menu opens, and major moments breathe with warmth.

**Component philosophy**: five primitives — Panel, Label, Icon, Button, Bar. Everything composed from them. No special-case UI code. A resource display is five bars. A command card is a grid of buttons.

**Color system**: warm browns (#F5E6C8 parchment, #3D2B1F deep brown), terracotta (#C1694F), gold (#D4A017), sage green (#7D8A5A), sky blue (#6B9AC4). Warmth is default, cool is exception. The entire UI feels like golden hour.

**Typography**: serif headers (character, warmth), sans-serif body (functional, readable), monospace numbers (alignment). Fonts are functional, not decorative — the hand-drawn style comes from sprites and borders.

**Animation**: instant feedback (<50ms), smooth interpolation (linear/ease-out), organic breathing (idle sway, ambient life), escalation (more complex animations at higher ages). Motion communicates state — if it's moving, it's alive.

**Feedback**: every action gets a reaction. Visual (glow, particles, floating text), auditory (clicks, acknowledgments, ambient). No silent failures. The player should never wonder "did the game hear me?"

## Constraints

- LÖVE 2D has no built-in UI framework — everything drawn with `love.graphics`
- Hand-drawn art assets (placeholder for v1, refined later)
- Must layer on top of existing render system without rewrite
- Small team (one human, one AI) — system must be simple to maintain

## Build order

1. Color palette into existing HUD
2. Panel primitive (hand-drawn container)
3. Resource bar (empire status)
4. Selection context panel (command card)
5. Floating text polish

Each step builds on the last, teaches something new, and makes the game feel more alive.
