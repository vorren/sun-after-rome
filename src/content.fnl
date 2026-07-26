;; aurelius.content --- static game data: unit/building stats, costs, age bonuses.
;; Pure data + lookup helpers. ADR-0003/0008/0011.

(local resource-types [:wood :stone :gold])

;; Kind table: each entry maps tag -> stat plist
(local kinds
  {:town-centre  {:max-hp 600 :trains [:villager] :blocks true}
   :barracks     {:max-hp 350 :trains [:knight :pikeman :archer] :blocks true}
   :villager     {:max-hp 40 :cost {:wood 25} :train-time 25 :speed 1
                  :gather-rate 1 :gather-capacity 10}
   :knight       {:max-hp 100 :cost {:wood 20 :gold 75} :train-time 30 :speed 2
                  :damage 10 :range 1 :armour :cavalry :bonus-vs {} :cooldown 10}
   :pikeman      {:max-hp 55 :cost {:wood 25 :stone 10} :train-time 22 :speed 1
                  :damage 4 :range 1 :armour :infantry :bonus-vs {:cavalry 15} :cooldown 10}
   :archer       {:max-hp 30 :cost {:wood 25 :gold 45} :train-time 27 :speed 1
                  :damage 4 :range 4 :armour :archer :bonus-vs {:infantry 3} :cooldown 14}
   :tree         {:node :wood :amount 100}
   :gold-mine    {:node :gold :amount 80}
   :stone-mine   {:node :stone :amount 80}})

(fn kind-stats [tag]
  (or (. kinds tag) (error (.. "unknown kind: " (tostring tag)))))

(fn kind-stat [tag key default]
  (let [stats (kind-stats tag)]
    (or (. stats key) default)))

(fn base-max-hp [tag] (kind-stat tag :max-hp 1))
(fn unit-cost [tag] (kind-stat tag :cost {}))
(fn train-time [tag] (kind-stat tag :train-time 1))
(fn gather-capacity [tag] (kind-stat tag :gather-capacity 0))
(fn gather-resource [tag] (kind-stat tag :node nil))
(fn producer-trains [tag] (kind-stat tag :trains []))

(fn attack-of [tag]
  {:damage (kind-stat tag :damage 0)
   :range (kind-stat tag :range 0)
   :armour (kind-stat tag :armour :none)
   :bonus-vs (kind-stat tag :bonus-vs {})
   :cooldown (kind-stat tag :cooldown 1)})

;; Age table (ADR-0011). Bonuses are multipliers applied at read time.
;; Using exact ratios: 23/20, 13/10 etc stored as {numerator, denominator}.
(local ages
  {1 {:hp 1 :gather 1 :damage 1 :cost {} :time 0}
   2 {:hp (/ 23 20) :gather 2 :damage (/ 23 20) :cost {:wood 100 :stone 50} :time 100}
   3 {:hp (/ 13 10) :gather 3 :damage (/ 13 10) :cost {:wood 200 :gold 100 :stone 100} :time 150}})

(fn max-age [] (var m 0) (each [k _ (pairs ages)] (when (> k m) (set m k))) m)

(fn age-bonus [level key]
  (let [row (. ages level)]
    (if row (. row key) (error (.. "no such age: " (tostring level))))))

(fn age-cost [level] (. (. ages level) :cost))
(fn age-time [level] (. (. ages level) :time))

{: resource-types : kind-stat : kind-stats : unit-cost : train-time
 : gather-capacity : gather-resource : attack-of : producer-trains
 : base-max-hp : age-bonus : max-age : age-cost : age-time : kinds}
