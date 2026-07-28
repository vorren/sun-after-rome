;; aurelius.render.ui.production-queue --- shows what buildings are training.
;; Displays current unit, progress bar, queue, and resource costs.

(local world (require :src.world))
(local content (require :src.content))
(local log (require :src.log))

(fn resource-cost-text [cost]
  "Format resource cost as a string."
  (let [parts []]
    (each [res amt (pairs cost)]
      (table.insert parts (.. (tostring amt) " " (tostring res))))
    (table.concat parts ", ")))

(fn build [w selected-eids]
  "Build production queue UI tree for selected building."
  (when (> (# selected-eids) 0)
    (let [eid (. selected-eids 1)
          kind (world.world-get w eid :kind)
          producer (world.world-get w eid :producer)]
      (when (and kind producer)
        (let [tag kind.tag
              trains (content.producer-trains tag)]
          (when (> (# trains) 0)
            ;; build queue display
            (let [children []
                  queue-len (or (and producer.queue (# producer.queue)) 0)]
              ;; current training progress
              (when (> queue-len 0)
                (let [current (. producer.queue 1)
                      progress (or producer.progress 0)
                      train-time (content.train-time current)
                      ratio (if (> train-time 0) (/ progress train-time) 0)]
                  (table.insert children
                    {:type :panel
                     :x 0 :y 0
                     :w 280 :h 60
                     :pad 6
                     :children
                     [{:type :label
                       :x 0 :y 0
                       :text (.. "Training: " (string.upper current))
                       :font :md :color :gold}
                      {:type :bar
                       :x 0 :y 22
                       :w 260 :h 10
                       :value ratio :max 1
                       :fill :gold :bg :brown}
                      (let [cost (content.unit-cost current)]
                        (when cost
                          {:type :label
                           :x 0 :y 38
                           :text (.. "Cost: " (resource-cost-text cost))
                           :font :sm :color :brown-light}))]}))

              ;; queue items (after current)
              (when (> queue-len 1)
                (let [queue-items []]
                  (for [i 2 queue-len]
                    (let [unit (. producer.queue i)]
                      (table.insert queue-items
                        {:type :label
                         :x 0 :y 0
                         :text (.. "Queued: " (string.upper unit))
                         :font :sm :color :brown-light})))
                  (table.insert children
                    {:type :panel
                     :x 0 :y 0
                     :w 280 :h (* 18 (+ 1 (- queue-len 1)))
                     :pad 4
                     :children queue-items})))

              ;; train buttons
              (let [train-btns []]
                (each [_ unit-tag (ipairs trains)]
                  (let [cost (content.unit-cost unit-tag)
                        can-afford (or (not cost)
                                       (and
                                         (or (not cost.wood) (>= (world.resource-amount w 0 :wood) cost.wood))
                                         (or (not cost.gold) (>= (world.resource-amount w 0 :gold) cost.gold))
                                         (or (not cost.stone) (>= (world.resource-amount w 0 :stone) cost.stone))))]
                    (table.insert train-btns
                      {:type :button
                       :x 0 :y 0
                       :w 80 :h 24
                       :text (string.upper unit-tag)
                       :font :sm
                       :disabled (not can-afford)
                       :on-click (fn [_]
                                   (log.info :production-queue (.. "Training " unit-tag))
                                   ;; TODO: issue train order
                                   )})))
                (when (> (# train-btns) 0)
                  (table.insert children
                    {:type :panel
                     :x 0 :y 0
                     :w (+ (* (# train-btns) 84) 8) :h 30
                     :dir :horiz :gap 4 :pad 4
                     :children train-btns})))

              (when (> (# children) 0)
                {:type :panel
                 :x :right-300 :y :bottom-180
                 :w 300 :h (+ 70 (* 20 queue-len))
                 :pad 8
                 :children children})))))))))

{: build : resource-cost-text}
