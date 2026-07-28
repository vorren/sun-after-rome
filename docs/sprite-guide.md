# Sprite Guide

How to create, animate, and integrate sprites for Sun After Rome.

## Art Style

**Hand-drawn low poly** — warm, rustic, imperfect. Think watercolor sketches with clean silhouettes. Not pixel art, not vector. The imperfection is the style.

### Principles

- **Warm palette**: browns, golds, terracotta, sage green
- **Visible brushstrokes**: not perfectly smooth edges
- **Strong silhouette**: readable at 64×64 or smaller
- **Limited colors**: 4-6 per unit, maximum contrast
- **No outlines**: shape defines form, not borders

## Recommended Tools

### Aseprite (Paid, $19.99)
- **Best for**: Pixel art, sprite sheets, animation
- **Why**: Built-in sprite sheet export, animation timeline, onion skinning
- **Platform**: Windows, macOS, Linux
- **Website**: https://www.aseprite.org/

### GraphicsGale (Free, Windows only)
- **Best for**: Sprite animation, GIF creation
- **Why**: Free, lightweight, good animation tools
- **Platform**: Windows
- **Website**: https://graphicsgale.en.softonic.com/

### LibreSprite (Free, Open Source)
- **Best for**: Aseprite alternative, pixel art
- **Why**: Free, open source, fork of old Aseprite
- **Platform**: Windows, macOS, Linux
- **Website**: https://libresprite.github.io/

### Piskel (Free, Browser-based)
- **Best for**: Quick prototyping, learning
- **Why**: No install, instant preview, export to sprite sheets
- **Platform**: Any browser
- **Website**: https://www.piskelapp.com/

### GIMP (Free, Open Source)
- **Best for**: General image editing, touch-ups
- **Why**: Free, powerful, plugin support
- **Platform**: Windows, macOS, Linux
- **Website**: https://www.gimp.org/

## Sprite Sheet Structure

### Directory Layout

```
assets/units/
└── Villager/
    └── Male/
        └── Woodcutter/
            └── Walk/
                ├── Carrying no Wood/
                │   ├── Villagerwalk001.png
                │   ├── Villagerwalk002.png
                │   └── ... (75 frames)
                └── Carrying Wood/
                    ├── Villagerwalk001.png
                    ├── Villagerwalk002.png
                    └── ... (75 frames)
```

### Frame Numbering

Every **15 frames** represents a direction. The game uses 5 directions (South, South West, West, North West, North). East, North East, and South East are created by mirroring.

| Frames | Direction | Mirror? |
|--------|-----------|---------|
| 1-15 | South (facing down) | No |
| 16-30 | South West | No |
| 31-45 | West | No |
| 46-60 | North West | No |
| 61-75 | North (facing up) | No |
| 76-90 | North East | Mirror NW |
| 91-105 | East | Mirror W |
| 106-120 | South East | Mirror SW |

### File Naming

```
{Unit}{Action}{Number}.png
```

Examples:
- `Villagerwalk001.png` — Villager walk frame 1
- `Villageract015.png` — Villager act frame 15
- `Villagerrot025.png` — Villager rotate frame 25

## Creating a New Animation

### Step 1: Set Up Canvas

For a villager walk cycle:
- **Size**: 64×64 pixels per frame (or match existing sprites)
- **Frames**: 75 minimum (5 directions × 15 frames)
- **Background**: Transparent

### Step 2: Draw Key Frames

Start with the 4 key poses:
1. **Contact** — foot touches ground
2. **Down** — weight on front foot
3. **Passing** — legs crossed, highest point
4. **Up** — weight on back foot

### Step 3: In-Between

Add frames between key poses:
- 15 frames per direction = 3-4 frames between each key pose
- Smooth transitions, no jumping

### Step 4: Copy and Flip

For missing directions:
1. Draw South, South West, West, North West, North
2. Copy North West → flip horizontal → North East
3. Copy West → flip horizontal → East
4. Copy South West → flip horizontal → South East

### Step 5: Export

Export as individual PNGs:
- Name: `{prefix}{001-075}.png`
- Background: Transparent
- Color depth: 32-bit (RGBA)

## Animation Speed

| Animation | Speed | Notes |
|-----------|-------|-------|
| Walk | 15 fps | Standard AoE2 speed |
| Attack | 12-15 fps | Slightly slower for weight |
| Gather | 10-12 fps | Rhythmic, repetitive |
| Death | 8-10 fps | Slow, dramatic |
| Idle | 4-6 fps | Subtle breathing |

## Integration

### Loading Sprites

```fennel
(local sprite-sheet (require :src.render.sprite-sheet))

;; Load a sprite sequence
(let [sprites (sprite-sheet.load-animation
                "assets/units/Villager/Male/Woodcutter/Walk/Carrying no Wood"
                "Villagerwalk"
                75)]
  ;; sprites is a table of 75 images
  )
```

### Creating Animation

```fennel
(local animation (require :src.render.animation))

;; Create animation from sprites
(let [anim (animation.make-animation sprites 15 true)]
  ;; 15 fps, looping
  (animation.update anim dt)  ;; advance frame
  (let [sprite (animation.get-sprite anim direction)]
    ;; sprite.image — the Love2D image
    ;; sprite.mirror — whether to flip horizontally
    ))
```

### Drawing

```fennel
(when sprite.image
  (love.graphics.setColor 1 1 1)
  (if sprite.mirror
      (love.graphics.draw sprite.image
                         (+ sx 32) sy
                         0 -1 1 32 0)
      (love.graphics.draw sprite.image
                         (- sx 32) sy
                         0 1 1 0 0)))
```

## Adding New Units

1. Create directory: `assets/units/{UnitName}/Male/`
2. Add action folders: `Walk/`, `Attack/`, `Die/`, etc.
3. Export sprites with correct naming
4. Add loading code in `sprites.fnl`
5. Add fallback color in `unit-colors`

## Troubleshooting

### Sprites not loading
- Check file path is correct
- Ensure PNG has transparent background
- Check console for error messages

### Wrong direction
- Verify frame numbering (1-based, not 0-based)
- Check `frames-per-direction` constant (should be 15)

### Mirroring looks wrong
- Ensure source direction is correct (NW, W, SW)
- Check that mirror flag is being used in draw call
