;; src.ai.scripted --- scripted AI controller for v1.
;; Deterministic build order with guards. Runs as a system in the tick pipeline.
;; ADR-0016: AI as deterministic tick system.

(local world (require :src.world))
(local content (require :src.content))
(local orders (require :src.orders))
(local personalities (require :src.ai.personalities))

;; ---- Query helpers ----

(fn faction-entities [w faction]
  "All entities owned by FACTION, sorted by eid."
  (let [result []]
    (each [_ pair (ipairs (world.world-query w :owner))]
      (when (= pair.val.player faction)
        (table.insert result pair.eid)))
    (table.sort result (fn [a b] (< a b)))
    result))

(fn has-building? [w faction tag]
  "Does FACTION own a building of TAG?"
  (var found false)
  (each [_ eid (ipairs (faction-entities w faction))]
    (let [kind (world.world-get w eid :kind)]
      (when (and kind (= kind.tag tag))
        (let [owner (world.world-get w eid :owner)]
          (when (and owner (= owner.player faction))
            (set found true))))))
  found)

(fn get-building [w faction tag]
  "Get the first building eid of TAG owned by FACTION, or nil."
  (var result nil)
  (each [_ eid (ipairs (faction-entities w faction))]
    (when (not result)
      (let [kind (world.world-get w eid :kind)]
        (when (and kind (= kind.tag tag))
          (let [owner (world.world-get w eid :owner)]
            (when (and owner (= owner.player faction))
              (set result eid)))))))
  result)

(fn count-units [w faction tag]
  "Count units of TAG owned by FACTION."
  (var n 0)
  (each [_ eid (ipairs (faction-entities w faction))]
    (let [kind (world.world-get w eid :kind)]
      (when (and kind (= kind.tag tag))
        (let [owner (world.world-get w eid :owner)]
          (when (and owner (= owner.player faction))
            (set n (+ n 1)))))))
  n)

(fn idle-villagers [w faction]
  "Villagers owned by FACTION with idle task."
  (let [result []]
    (each [_ eid (ipairs (faction-entities w faction))]
      (let [kind (world.world-get w eid :kind)
            task (world.world-get w eid :task)]
        (when (and kind (= kind.tag :villager) task (= task.kind :idle))
          (table.insert result eid))))
    (table.sort result (fn [a b] (< a b)))
    result))

(fn nearest-node [w eid resource-type]
  "Nearest node of RESOURCE-TYPE to entity EID, or nil."
  (let [pos (world.world-get w eid :position)]
    (when pos
      (var best nil)
      (var best-dist nil)
      (each [_ pair (ipairs (world.world-query w :node))]
        (let [node pair.val
              node-pos (world.world-get w pair.eid :position)]
          (when (and node-pos (= node.resource resource-type))
            (let [d (+ (math.abs (- pos.x node-pos.x))
                       (math.abs (- pos.y node-pos.y)))]
              (when (or (= best-dist nil) (< d best-dist))
                (set best pair.eid)
                (set best-dist d))))))
      best)))

(fn nearest-enemy [w faction]
  "Nearest entity with health owned by an enemy of FACTION."
  (var best nil)
  (var best-dist nil)
  (each [_ pair (ipairs (world.world-query w :owner))]
    (when (not= pair.val.player faction)
      (let [eid pair.eid
            epos (world.world-get w eid :position)
            h (world.world-get w eid :health)]
        (when (and epos h)
          (let [my-eid (. (faction-entities w faction) 1)]
            (when my-eid
              (let [mpos (world.world-get w my-eid :position)]
                (when mpos
                  (let [dx (- mpos.x epos.x)
                        dy (- mpos.y epos.y)
                        d (+ (math.abs dx) (math.abs dy))]
                    (when (or (= best-dist nil) (< d best-dist))
                      (set best eid)
                      (set best-dist d)))))))))))
  best)

;; ---- Resource gathering helpers ----

(fn count-gatherers [w faction resource-type]
  "Count villagers gathering RESOURCE-TYPE."
  (var n 0)
  (each [_ eid (ipairs (faction-entities w faction))]
    (let [kind (world.world-get w eid :kind)
          task (world.world-get w eid :task)]
      (when (and kind (= kind.tag :villager) task (= task.kind :gather))
        (let [node (world.world-get w task.target :node)]
          (when (and node (= node.resource resource-type))
            (set n (+ n 1)))))))
  n)

(fn pick-resource-for-villager [w faction personality]
  "Pick which resource type an idle villager should gather based on personality ratios."
  (let [villager-count (count-units w faction :villager)
        wood-gatherers (count-gatherers w faction :wood)
        gold-gatherers (count-gatherers w faction :gold)
        stone-gatherers (count-gatherers w faction :stone)
        wood-target (if personality.wood-ratio (math.floor (* villager-count personality.wood-ratio)) 0)
        gold-target (if personality.gold-ratio (math.floor (* villager-count personality.gold-ratio)) 0)
        stone-target (if personality.stone-ratio (math.floor (* villager-count personality.stone-ratio)) 0)]
    (if (< wood-gatherers wood-target)
        :wood
        (< gold-gatherers gold-target)
        :gold
        (< stone-gatherers stone-target)
        :stone
        true :wood)))

;; ---- Build order phases ----

(fn train-villagers! [w faction personality]
  "Train villagers from TC until we reach personality's villager-target."
  (let [count (count-units w faction :villager)
        tc (get-building w faction :town-centre)
        target (or personality.villager-target 6)]
    (when (and tc (< count target))
      (let [cost (content.unit-cost :villager)]
        (when (world.can-afford? w faction cost)
          (orders.issue! w (orders.train tc :villager))
          true)))))

(fn gather-resources! [w faction personality]
  "Send idle villagers to gather resources based on personality ratios."
  (let [vills (idle-villagers w faction)]
    (each [_ eid (ipairs vills)]
      (let [resource-type (pick-resource-for-villager w faction personality)
            node (nearest-node w eid resource-type)]
        (when node
          (orders.issue! w (orders.gather eid node)))))))

(fn advance-age-if-ready! [w faction]
  "Advance to age 2 if we can afford it."
  (let [age (world.player-age w faction)]
    (when (= age 1)
      (let [cost (content.age-cost 2)]
        (when (world.can-afford? w faction cost)
          (orders.issue! w (orders.advance-age faction))
          true)))))

(fn train-knights! [w faction personality]
  "Train knights from barracks if military threshold not met."
  (let [barracks (get-building w faction :barracks)
        military-count (count-units w faction :knight)
        threshold (or personality.military-threshold 3)]
    (when (and barracks (< military-count threshold))
      (let [cost (content.unit-cost :knight)]
        (when (world.can-afford? w faction cost)
          (orders.issue! w (orders.train barracks :knight))
          true)))))

(fn attack-with-military! [w faction personality]
  "Send idle military units to attack the nearest enemy if attack-when-idle enabled."
  (when personality.attack-when-idle
    (let [target (nearest-enemy w faction)]
      (when target
        (each [_ eid (ipairs (faction-entities w faction))]
          (let [kind (world.world-get w eid :kind)
                task (world.world-get w eid :task)]
            (when (and kind task (= task.kind :idle)
                       (> (content.kind-stat kind.tag :damage 0) 0))
              (orders.issue! w (orders.attack eid target)))))))))

;; ---- Main AI system ----

(fn ai-system [w faction personality]
  "Run one tick of the scripted AI for FACTION with PERSONALITY."
  (let [personality (or personality (personalities.default-personality))]
    ;; Phase 1: Economy — train villagers
    (train-villagers! w faction personality)
    ;; Phase 2: Resource gathering
    (gather-resources! w faction personality)
    ;; Phase 3: Age advancement (when affordable)
    (advance-age-if-ready! w faction)
    ;; Phase 4: Military production
    (train-knights! w faction personality)
    ;; Phase 5: Attack
    (attack-with-military! w faction personality)))

(fn make-ai-controller [faction personality]
  "Create an AI controller bound to FACTION with PERSONALITY."
  (let [personality (or personality (personalities.default-personality))]
    {:type :ai
     :faction faction
     :personality personality
     :tick (fn [w] (ai-system w faction personality))}))

(fn make-ai-takeover [faction]
  "Create an AI takeover controller for a disconnected player."
  (make-ai-controller faction (personalities.default-personality)))

{: ai-system : make-ai-controller : make-ai-takeover
 : faction-entities : has-building? : get-building : count-units
 : idle-villagers : nearest-node : nearest-enemy}