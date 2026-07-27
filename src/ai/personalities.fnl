;; src.ai.personalities --- data-driven AI personality configs.
;; Controls aggression, resource ratios, and military thresholds.
;; ADR-0016: personality is a data table, not logic.

(local personalities
  {:aggressive {:name :aggressive
                :villager-target 6
                :wood-ratio 0.4
                :food-ratio 0.4
                :gold-ratio 0.2
                :stone-ratio 0.0
                :military-threshold 3
                :attack-when-idle true}
   :defensive  {:name :defensive
                :villager-target 8
                :wood-ratio 0.3
                :food-ratio 0.3
                :gold-ratio 0.2
                :stone-ratio 0.2
                :military-threshold 5
                :attack-when-idle false}
   :balanced   {:name :balanced
                :villager-target 7
                :wood-ratio 0.35
                :food-ratio 0.35
                :gold-ratio 0.2
                :stone-ratio 0.1
                :military-threshold 4
                :attack-when-idle true}})

(fn get-personality [name]
  "Get personality config by NAME, or error if not found."
  (or (. personalities name)
      (error (.. "unknown personality: " (tostring name)))))

(fn default-personality []
  "The v1 default: aggressive."
  (. personalities :aggressive))

{: personalities : get-personality : default-personality}
