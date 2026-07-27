;; aurelius.audio.sounds --- sound effects for commands and events.

(var sounds {})

(fn load-sounds []
  (let [(ok move) (pcall love.audio.newSource "assets/sounds/move.ogg" "static")]
    (when ok (set sounds.move move)))
  (let [(ok gather) (pcall love.audio.newSource "assets/sounds/gather.ogg" "static")]
    (when ok (set sounds.gather gather)))
  (let [(ok attack) (pcall love.audio.newSource "assets/sounds/attack.ogg" "static")]
    (when ok (set sounds.attack attack))))

(fn play [name]
  (let [s (. sounds name)]
    (when s
      (s:stop)
      (s:play))))

{: load-sounds : play}
