;; aurelius.render.ui.command-card --- clickable action buttons for selected units.
;; Shows Move, Gather, Attack for villagers; Move, Attack for military; Train for buildings.

(local world (require :src.world))
(local content (require :src.content))
(local log (require :src.log))

(fn unit-commands [kind-tag]
  "Return available commands for a unit type."
  (if (= kind-tag :villager)
      [{:id :move    :label "Move"    :mode :move}
       {:id :gather  :label "Gather"  :mode :gather}
       {:id :attack  :label "Attack"  :mode :attack}]
      ;; military units
      [{:id :move    :label "Move"    :mode :move}
       {:id :attack  :label "Attack"  :mode :attack}]))

(fn building-commands [kind-tag]
  "Return available commands for a building type."
  (let [trains (content.producer-trains kind-tag)]
    (when (> (# trains) 0)
      (let [cmds []]
        (each [_ unit-tag (ipairs trains)]
          (table.insert cmds {:id (.. :train- unit-tag)
                              :label (.. "Train " (string.upper unit-tag))
                              :train unit-tag}))
        cmds))))

(fn build [w selected-eids on-command]
  "Build command card UI tree for selected entities.
   on-command: (fn [cmd]) called when a command is clicked."
  (when (> (# selected-eids) 0)
    (let [eid (. selected-eids 1)
          kind (world.world-get w eid :kind)]
      (when kind
        (let [commands (if (. content.kinds kind.tag)
                          (if (. content.kinds kind.tag :trains)
                              (building-commands kind.tag)
                              (unit-commands kind.tag))
                          [])
              buttons []]
          (each [_ cmd (ipairs commands)]
            (table.insert buttons
              {:type :button
               :x 0 :y 0
               :w 80 :h 30
               :text cmd.label
               :font :sm
               :on-click (fn [_]
                           (log.debug :command-card (.. "Clicked: " cmd.label))
                           (on-command cmd))}))
          (when (> (# buttons) 0)
            {:type :panel
             :x :right-170 :y :bottom-110
             :w (+ (* (# buttons) 84) 8) :h 40
             :dir :horiz :gap 4 :pad 4
             :children buttons}))))))

{: build : unit-commands : building-commands}
