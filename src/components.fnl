;; aurelius.components --- component constructors (plain tables).
;; ADR-0003: entities are bare integer ids; components are plain data.

(fn make-position [x y] {:x x :y y})
(fn make-owner [player] {:player player})
(fn make-kind [tag] {:tag tag})
(fn make-health [hp] {:hp hp})
(fn make-carry [resource amount] {:resource resource :amount amount})
(fn make-node [resource amount] {:resource resource :amount amount})
(fn make-cooldown [ticks] {:ticks ticks})
(fn make-producer [queue progress rally-x rally-y]
  {:queue queue :progress progress :rally-x rally-x :rally-y rally-y})
(fn make-task [kind target tx ty phase]
  {:kind kind :target target :tx tx :ty ty :phase phase})

{: make-position : make-owner : make-kind : make-health
 : make-carry : make-node : make-cooldown : make-producer : make-task}
