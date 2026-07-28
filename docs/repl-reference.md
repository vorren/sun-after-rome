# REPL Reference Guide

The game includes a live Fennel REPL for inspecting and modifying game state at runtime. This guide covers available commands, data structures, and examples.

## Quick Start

```bash
# Start the game
love .

# In another terminal, use the helper script
./repl.sh

# Or manually
echo '(world.resource-amount game-world 0 :wood)' > repl.in
cat repl.out
```

## Available Variables

| Variable | Type | Description |
|----------|------|-------------|
| `game-world` | table | The current game world state |
| `world` | module | World manipulation functions |
| `sim` | module | Simulation tick functions |
| `orders` | module | Order creation and application |
| `content` | module | Game data (unit stats, costs) |
| `combat` | module | Combat system |
| `movement` | module | Movement system |
| `gather` | module | Gathering system |
| `production` | module | Production system |

## World State Queries

### Inspect Entities

```fennel
;; List all entities with their kind
(pp (world.world-query game-world :kind))

;; List all entities with position
(pp (world.world-query game-world :position))

;; List all entities with health
(pp (world.world-query game-world :health))

;; Get a specific entity's component
(world.world-get game-world 1 :position)
(world.world-get game-world 1 :kind)
(world.world-get game-world 1 :owner)
(world.world-get game-world 1 :task)

;; Check if entity has a component
(world.world-has? game-world 1 :position)
```

### Inspect Resources

```fennel
;; Player 0's resources
(world.resource-amount game-world 0 :wood)
(world.resource-amount game-world 0 :gold)
(world.resource-amount game-world 0 :stone)

;; Player 1's resources
(world.resource-amount game-world 1 :wood)
```

### Inspect Ages

```fennel
;; Current age for each player
(world.player-age game-world 0)
(world.player-age game-world 1)

;; Age progress (nil if not advancing)
(world.age-progress game-world 0)
```

## World Manipulation

### Give Resources

```fennel
;; Give player 0 infinite resources
(world.add-resource! game-world 0 :wood 9999)
(world.add-resource! game-world 0 :gold 9999)
(world.add-resource! game-world 0 :stone 9999)

;; Give player 1 some wood
(world.add-resource! game-world 1 :wood 500)
```

### Spawn Entities

```fennel
;; Spawn a villager for player 0 at (10, 10)
(world.spawn! game-world :villager {:owner 0 :x 10 :y 10})

;; Spawn a knight for player 0
(world.spawn! game-world :knight {:owner 0 :x 5 :y 5})

;; Spawn a resource node
(world.spawn! game-world :tree {:x 8 :y 6})
(world.spawn! game-world :gold-mine {:x 12 :y 8})
```

### Remove Entities

```fennel
;; Remove entity by ID
(world.world-remove-entity! game-world 5)

;; Remove all enemy units
(each [_ pair (ipairs (world.world-query game-world :health))]
  (let [owner (world.world-get game-world pair.eid :owner)]
    (when (and owner (= owner.player 1))
      (world.world-remove-entity! game-world pair.eid))))
```

### Modify Entity Components

```fennel
;; Change entity position
(let [pos (world.world-get game-world 1 :position)]
  (set pos.x 10)
  (set pos.y 10))

;; Change entity health
(let [hp (world.world-get game-world 1 :health)]
  (set hp.hp 100))

;; Set entity task
(let [task (world.world-get game-world 1 :task)]
  (set task.kind :idle))
```

## Issue Orders

```fennel
;; Move entity 1 to (10, 10)
(orders.issue! game-world (orders.move 1 10 10))

;; Gather from node 3
(orders.issue! game-world (orders.gather 2 3))

;; Attack entity 5
(orders.issue! game-world (orders.attack 2 5))

;; Train a villager from building 1
(orders.issue! game-world (orders.train 1 :villager))

;; Advance to age 2
(orders.issue! game-world (orders.advance-age 0))
```

## AI Controller

```fennel
;; Check current controller
(world.get-controller game-world 0)
(world.get-controller game-world 1)

;; Set AI controller for player 1
(local ai (require :src.ai.scripted))
(world.set-controller! game-world 1 (ai.make-ai-controller 1))

;; Take over a player with AI
(sim.take-player! game-world 1)
```

## Simulation Control

```fennel
;; Run one tick
(sim.tick! game-world)

;; Run multiple ticks
(sim.run! game-world 10)

;; Check current tick
game-world.tick
```

## Data Structures

### World

```fennel
{:tick 0                    ;; current tick number
 :width 24                  ;; map width in tiles
 :height 16                 ;; map height in tiles
 :num-players 2             ;; number of factions
 :store {                   ;; ECS component store
   :position {eid {:x N :y N} ...}
   :owner {eid {:player N} ...}
   :kind {eid {:tag :keyword} ...}
   :health {eid {:hp N} ...}
   :task {eid {:kind :idle :target nil :tx N :ty N} ...}
   :producer {eid {:queue [:villager] :progress N} ...}
   :carry {eid {:resource :wood :amount N} ...}
   :node {eid {:resource :wood :amount N} ...}
   :cooldown {eid {:ticks N} ...}}
 :resources {p {:wood N :gold N :stone N} ...}
 :ages {p 1 ...}
 :age-progress {p nil ...}
 :orders []
 :log []
 :controllers {p {:type :idle} ...}}
```

### Entity Components

```fennel
;; Position
{:x N :y N}

;; Owner
{:player N}

;; Kind
{:tag :keyword}

;; Health
{:hp N}

;; Task
{:kind :idle :target nil :tx N :ty N :phase nil}
{:kind :move :target nil :tx N :ty N :phase nil}
{:kind :gather :target eid :tx N :ty N :phase :to-node}
{:kind :attack :target eid :tx N :ty N :phase nil}

;; Producer
{:queue [:villager :knight] :progress N}

;; Carry
{:resource :wood :amount N}

;; Node
{:resource :wood :amount N}

;; Cooldown
{:ticks N}
```

### Orders

```fennel
{:tag :move :eid eid :tx N :ty N}
{:tag :gather :eid eid :node node-eid}
{:tag :attack :eid eid :target target-eid}
{:tag :train :prod building-eid :unit :villager}
{:tag :advance-age :player N}
```

## Debugging Tips

### Find Entities by Type

```fennel
;; Find all villagers
(each [_ pair (ipairs (world.world-query game-world :kind))]
  (when (= pair.val.tag :villager)
    (print (.. "Villager " pair.eid " at "
               (world.world-get game-world pair.eid :position).x ","
               (world.world-get game-world pair.eid :position).y))))
```

### Check Why Unit Isn't Moving

```fennel
;; Check unit's task
(let [task (world.world-get game-world 1 :task)]
  (print (.. "Task: " task.kind))
  (print (.. "Target: " (tostring task.target)))
  (print (.. "Position: " (world.world-get game-world 1 :position).x ","
             (world.world-get game-world 1 :position).y)))
```

### Check Why Unit Isn't Attacking

```fennel
;; Check unit's health and cooldown
(let [hp (world.world-get game-world 1 :health)
      cd (world.world-get game-world 1 :cooldown)]
  (print (.. "HP: " hp.hp))
  (print (.. "Cooldown: " cd.ticks)))
```

### Monitor AI Behavior

```fennel
;; Check AI controller
(let [ctrl (world.get-controller game-world 1)]
  (print (.. "Controller type: " ctrl.type)))

;; Check what orders are pending
(pp game-world.orders)
```

## Common Patterns

### Reset a Unit to Idle

```fennel
(let [task (world.world-get game-world 1 :task)]
  (set task.kind :idle)
  (set task.target nil)
  (set task.phase nil))
```

### Heal a Unit

```fennel
(let [hp (world.world-get game-world 1 :health)]
  (set hp.hp 100))
```

### Teleport a Unit

```fennel
(let [pos (world.world-get game-world 1 :position)]
  (set pos.x 10)
  (set pos.y 10))
```

### Give All Players Resources

```fennel
(for [p 0 1]
  (world.add-resource! game-world p :wood 9999)
  (world.add-resource! game-world p :gold 9999)
  (world.add-resource! game-world p :stone 9999))
```

### Kill All Enemy Units

```fennel
(each [_ pair (ipairs (world.world-query game-world :health))]
  (let [owner (world.world-get game-world pair.eid :owner)]
    (when (and owner (= owner.player 1))
      (world.world-remove-entity! game-world pair.eid))))
```
