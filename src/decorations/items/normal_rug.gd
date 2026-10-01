extends DecoItem
## Welcome Mat (Norm's Totally Normal Collection, docs/DAILY_STAMPS_SPEC.md 3) — a doormat with a
## fringe at both ends. Where a human mat says WELCOME, Norm's says NORMAL, so visitors know.
## Non-blocking: you walk right over it.

const Letters := preload("res://src/decorations/items/normal_letters.gd")

const RUG := Color("#74839e")
const RUG_DARK := Color("#63718a")
const CREAM := Color("#e0d4b4")
const W := 1.72
const D := 1.04
const THICK := 0.05
## Each printed layer sits this far above the one below it (far enough not to shimmer at 8.6 m).
const LAYER := 0.007


func _init() -> void:
	footprint = 1.0
	blocking = false
	collide_radius = 1.0
	collide_height = 0.06


func _build() -> void:
	var kit := DecoKit.new()
	var flat := Basis(Vector3.RIGHT, deg_to_rad(-90.0))
	kit.extrude(DecoKit.round_rect_poly(W, D, 0.08, 3), THICK, RUG_DARK, Transform3D(flat, Vector3(0.0, THICK * 0.5 + 0.004, 0.0)))
	# printed border: a cream band with the blue field inside it
	var top := THICK + 0.004
	_layer(kit, W - 0.14, D - 0.14, 0.05, CREAM, top + LAYER)
	_layer(kit, W - 0.26, D - 0.26, 0.03, RUG, top + LAYER * 2.0)
	Letters.draw(kit, "NORMAL", Transform3D(Letters.FLOOR, Vector3(0.0, top + LAYER * 3.0, 0.0)), 0.05, CREAM)
	# fringe on the two short ends
	for s in [-1.0, 1.0]:
		for i in 8:
			var z := lerpf(-D * 0.5 + 0.09, D * 0.5 - 0.09, float(i) / 7.0)
			kit.rbox(Vector3((W * 0.5 + 0.045) * s, 0.02, z), Vector3(0.13, 0.026, 0.06), 0.012, CREAM, Basis.IDENTITY, 0)
	add_body(kit.commit())


## One flat printed layer: a rounded rectangle facing up at height `y`.
func _layer(kit: DecoKit, w: float, d: float, r: float, color: Color, y: float) -> void:
	var p := DecoKit.round_rect_poly(w, d, r, 3)
	var n := p.size()
	var c := Vector3(0.0, y, 0.0)
	for i in n:
		var a := p[i]
		var b := p[(i + 1) % n]
		kit.triangle(c, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), color, false)
