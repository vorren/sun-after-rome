;; aurelius.render.ui --- Data-driven UI for Sun After Rome.
;; Layouts are tables, not code. Single draw-ui function renders everything.

(local log (require :src.log))
(local theme (require :src.render.ui.theme))

;; ---------------------------------------------------------------------------
;; State
;; ---------------------------------------------------------------------------

(var current-theme nil)
(var hover-id nil)
(var click-id nil)
(var widget-bounds {})
(var font-cache {})

;; ---------------------------------------------------------------------------
;; Font
;; ---------------------------------------------------------------------------

(fn get-font [size]
  "Get or create a font at SIZE px. Cached."
  (or (. font-cache size)
      (let [f (love.graphics.newFont size)]
        (tset font-cache size f)
        f)))

(fn resolve-font [font-key]
  "Resolve :sm/:md/:lg/:xl to a LÖVE Font object."
  (let [size (or (and current-theme
                      (. current-theme.fonts font-key))
                 (and font-key (= (type font-key) :number) font-key)
                 14)]
    (get-font size)))

;; ---------------------------------------------------------------------------
;; Color
;; ---------------------------------------------------------------------------

(fn resolve [color]
  "Resolve a color: HEXSTRING, RGB table, or theme key."
  (if (= (type color) :string)
      (if (. current-theme color)
          (. current-theme color)
          (theme.hex-to-rgb color))
      (= (type color) :table)
      color
      [1 1 1]))

(fn set-color [color alpha]
  "Set love.graphics.setColor from resolved color + optional alpha."
  (let [(r g b) (values (. color 1) (. color 2) (. color 3))
        a (or alpha (. color 4) 1)]
    (love.graphics.setColor r g b a)))

;; ---------------------------------------------------------------------------
;; Position: relative resolution
;; ---------------------------------------------------------------------------

(fn resolve-x [x w screen-w]
  "Resolve :right-N, :center-N, or absolute x."
  (if (= x :left) 0
      (= x :right) (- screen-w w)
      (= x :center) (/ (- screen-w w) 2)
      (= (type x) :string)
      (let [(rel offset) (x:match "^:(%w+)[%-+](%d+)$")]
        (if (= rel :right) (- screen-w w (tonumber offset))
            (= rel :center) (/ (- screen-w w) 2)
            (= rel :bottom) 0
            (= rel :top) 0
            (or (tonumber offset) 0)))
      (or x 0)))

(fn resolve-y [y h screen-h]
  "Resolve :bottom-N, :center-N, or absolute y."
  (if (= y :top) 0
      (= y :bottom) (- screen-h h)
      (= y :center) (/ (- screen-h h) 2)
      (= (type y) :string)
      (let [(rel offset) (y:match "^:(%w+)[%-+](%d+)$")]
        (if (= rel :bottom) (- screen-h h (tonumber offset))
            (= rel :center) (/ (- screen-h h) 2)
            (= rel :right) 0
            (= rel :left) 0
            (or (tonumber offset) 0)))
      (or y 0)))

;; ---------------------------------------------------------------------------
;; Layout engine
;; ---------------------------------------------------------------------------

(fn measure-text [text font]
  "Get width and height of text."
  (let [f (resolve-font font)
        (w h) (f:getWidth text)]
    [w h]))

(fn auto-size-children [node]
  "Compute size of panel from children."
  (var max-w 0)
  (var total-h 0)
  (let [dir (or node.dir :vert)
        gap (or node.gap current-theme.gap)]
    (each [_ child (ipairs (or node.children []))]
      (auto-size-children child)
      (if (= dir :vert)
          (do
            (set max-w (math.max max-w (or child.w 0)))
            (set total-h (+ total-h (or child.h 0) gap)))
          (do
            (set max-w (+ max-w (or child.w 0) gap))
            (set total-h (math.max total-h (or child.h 0))))))
    (when (= dir :vert)
      (set total-h (- total-h gap)))
    (when (= dir :horiz)
      (set max-w (- max-w gap)))
    (values max-w total-h)))

(fn layout-children [node]
  "Position children in panel based on :dir and :gap."
  (let [dir (or node.dir :vert)
        gap (or node.gap current-theme.gap)
        pad (or node.pad current-theme.pad)
        pad-top (or node.pad-top pad)
        pad-left (or node.pad-left pad)
        x0 (+ node.x pad-left)
        y0 (+ node.y pad-top)]
    (var cx x0)
    (var cy y0)
    (each [_ child (ipairs (or node.children []))]
      (set child.x cx)
      (set child.y cy)
      (if (= dir :vert)
          (set cy (+ cy (or child.h 0) gap))
          (set cx (+ cx (or child.w 0) gap)))
      (layout-children child))))

(fn resolve-position [node screen-w screen-h]
  "Resolve relative positions to absolute."
  (set node.x (resolve-x node.x (or node.w 0) screen-w))
  (set node.y (resolve-y node.y (or node.h 0) screen-h))
  (each [_ child (ipairs (or node.children []))]
    (resolve-position child screen-w screen-h)))

(fn compute-bounds [node]
  "Store bounds for hit-testing."
  (when node.id
    (tset widget-bounds node.id
          {:x node.x :y node.y :w (or node.w 0) :h (or node.h 0)}))
  (each [_ child (ipairs (or node.children []))]
    (compute-bounds child)))

(fn layout [node screen-w screen-h]
  "One-pass layout: auto-size, position, compute bounds."
  (set widget-bounds {})
  (auto-size-children node)
  (resolve-position node screen-w screen-h)
  (layout-children node)
  (compute-bounds node))

;; ---------------------------------------------------------------------------
;; Drawing primitives
;; ---------------------------------------------------------------------------

(fn draw-panel [node]
  "Draw panel: filled rectangle + border."
  (let [bg (resolve (or node.color current-theme.panel-bg))
        border (resolve (or node.border current-theme.panel-border))
        border-w (or node.border-w current-theme.panel-border-w)]
    (when bg
      (set-color bg (or node.alpha 1))
      (love.graphics.rectangle :fill node.x node.y (or node.w 0) (or node.h 0)))
    (when border
      (set-color border (or node.alpha 1))
      (love.graphics.setLineWidth border-w)
      (love.graphics.rectangle :line node.x node.y (or node.w 0) (or node.h 0)))))

(fn draw-label [node]
  "Draw label: text at position."
  (let [color (resolve (or node.color current-theme.label-color))
        font (resolve-font (or node.font current-theme.label-font))
        text (or node.text "")
        align (or node.align :left)]
    (love.graphics.setFont font)
    (set-color color (or node.alpha 1))
    (love.graphics.printf text node.x node.y (or node.w 9999) align)))

(fn draw-icon [node]
  "Draw icon: colored circle with initial letter (placeholder)."
  (let [color (resolve (or node.color current-theme.icon-color))
        size (or node.scale current-theme.icon-scale)
        r (* 8 size)
        text (string.sub (or node.text "?") 1 1)]
    (set-color color (or node.alpha 1))
    (love.graphics.circle :fill (+ node.x r) (+ node.y r) r)
    (love.graphics.setColor 1 1 1 (or node.alpha 1))
    (let [font (resolve-font (* 8 size))]
      (love.graphics.setFont font)
      (love.graphics.printf text (+ node.x (- r 4)) (+ node.y (- r 6)) (* r 2) :center))))

(fn draw-bar [node]
  "Draw bar: background + fill + border."
  (let [fill (resolve (or node.fill current-theme.bar-fill))
        bg (resolve (or node.bg current-theme.bar-bg))
        border (resolve (or node.border current-theme.bar-border))
        w (or node.w 100)
        h (or node.h current-theme.bar-h)
        value (or node.value 0)
        ratio (math.min 1 (math.max 0 (if node.max
                                         (/ value node.max)
                                         value)))
        fill-w (* w ratio)]
    (when bg
      (set-color bg (or node.alpha 1))
      (love.graphics.rectangle :fill node.x node.y w h))
    (when fill
      (set-color fill (or node.alpha 1))
      (love.graphics.rectangle :fill node.x node.y fill-w h))
    (when border
      (set-color border (or node.alpha 1))
      (love.graphics.setLineWidth 1)
      (love.graphics.rectangle :line node.x node.y w h))))

(fn draw-button [node]
  "Draw button: background + label + hover/active state."
  (let [is-hover (= hover-id node.id)
        is-click (= click-id node.id)
        bg (if is-click
               (resolve (or node.active-color current-theme.btn-active))
               is-hover
               (resolve (or node.hover-color current-theme.btn-hover))
               (resolve (or node.color current-theme.btn-bg)))
        text-color (resolve (or node.text-color current-theme.btn-color))
        w (or node.w 80)
        h (or node.h 30)]
    (when bg
      (set-color bg (or node.alpha 1))
      (love.graphics.rectangle :fill node.x node.y w h
                               (or node.radius current-theme.btn-radius)))
    (when text-color
      (let [font (resolve-font (or node.font :md))
            text (or node.text "")]
        (love.graphics.setFont font)
        (set-color text-color (or node.alpha 1))
        (love.graphics.printf text node.x node.y w :center)))))

;; ---------------------------------------------------------------------------
;; Draw dispatch
;; ---------------------------------------------------------------------------

(fn draw-node [node]
  "Draw a node and its children."
  (match node.type
    :panel  (do (draw-panel node)
                (each [_ child (ipairs (or node.children []))]
                  (draw-node child)))
    :label  (draw-label node)
    :icon   (draw-icon node)
    :bar    (draw-bar node)
    :button (draw-button node)
    _       (log.warn :ui (.. "Unknown node type: " (tostring node.type)))))

;; ---------------------------------------------------------------------------
;; Hit-testing
;; ---------------------------------------------------------------------------

(fn point-in-rect [px py rx ry rw rh]
  "Check if point is inside rectangle."
  (and (>= px rx) (<= px (+ rx rw))
       (>= py ry) (<= py (+ ry rh))))

(fn hit-test [node px py]
  "Find deepest node at (px, py). Buttons win over panels."
  (var result nil)
  (when node
    (when (and node.id
               (point-in-rect px py node.x node.y (or node.w 0) (or node.h 0)))
      (set result node))
    (each [_ child (ipairs (or node.children []))]
      (let [child-hit (hit-test child px py)]
        (when child-hit
          (set result child-hit)))))
  result)

;; ---------------------------------------------------------------------------
;; Mouse handling
;; ---------------------------------------------------------------------------

(fn handle-mouse-move [node mx my]
  "Update hover state."
  (let [hit (hit-test node mx my)]
    (set hover-id (if hit hit.id nil))))

(fn handle-click [node mx my]
  "Fire on-click if a button was clicked."
  (let [hit (hit-test node mx my)]
    (when (and hit hit.on-click)
      (set click-id hit.id)
      (hit.on-click hit))
    hit))

(fn clear-click []
  "Clear click state (call after frame)."
  (set click-id nil))

;; ---------------------------------------------------------------------------
;; Public API
;; ---------------------------------------------------------------------------

(fn init [theme-overrides]
  "Initialize UI with a theme."
  (set current-theme (theme.make-theme theme-overrides))
  (set hover-id nil)
  (set click-id nil)
  (set widget-bounds {})
  (set font-cache {})
  (log.info :ui "UI initialized"))

(fn draw [node]
  "Draw a UI tree."
  (let [(sw sh) (love.graphics.getDimensions)]
    (layout node sw sh)
    (draw-node node)))

(fn root [props & children]
  "Create a root node."
  (let [flat-children []]
    (fn flatten [node]
      (if (= (type node) :table)
          (if node.type
              (table.insert flat-children node)
              (each [_ v (ipairs node)]
                (flatten v)))
          (when node
            (table.insert flat-children node))))
    (flatten children)
    {:type :panel
     :x (or props.x 0)
     :y (or props.y 0)
     :w props.w
     :h props.h
     :alpha props.alpha
     :children flat-children}))

{: init : draw : root
 : handle-mouse-move : handle-click : clear-click
 : resolve : set-color : get-font : resolve-font
 : hit-test : layout}
