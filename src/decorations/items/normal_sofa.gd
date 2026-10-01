extends DecoItem
## Very Normal Sofa (Norm's Totally Normal Collection, docs/DAILY_STAMPS_SPEC.md 3) — a comfy
## two-seater that Norm built from memory. He was sure about the cushions and less sure about the
## legs, so it has sixteen.
##
## COLOURS (the whole normal_* set): the hexes are paler and greyer than what you see, on purpose.
## The toon ramp renders a mid-value albedo much punchier than its swatch: the first pass used
## #5f9a98 here (S 0.38) and measured S 0.70 on a 2556x1179 Compatibility frame, the rug's #56698f
## (S 0.40) measured S 0.81. Each colour was picked as a display target and walked back until the
## frame measured it; over the eight items' own pixels the set now reads saturation p90 0.62,
## value mean 0.69, blown 0% (docs/STYLE_GUIDE.md R2.6: p90 <= 0.68).

const SOFA := Color("#83a8a5")
const SOFA_DARK := Color("#709290")
const CUSHION := Color("#9dbab4")
const PILLOW := Color("#d9c590")
const LEG := Color("#e0cfa8")
const LEG_FOOT := Color("#aa8e76")
const LEG_H := 0.27
const LEGS_PER_ROW := 7


func _init() -> void:
	footprint = 1.0
	collide_radius = 0.75
	collide_height = 0.9


func _build() -> void:
	var kit := DecoKit.new()
	# --- the legs: far too many, evenly spaced, each with a little wooden shoe -------------------
	for row in [-0.3, 0.3]:
		for i in LEGS_PER_ROW:
			_leg(kit, Vector3(lerpf(-0.78, 0.78, float(i) / float(LEGS_PER_ROW - 1)), 0.0, row))
	for s in [-1.0, 1.0]:
		_leg(kit, Vector3(0.84 * s, 0.0, 0.0))
	# --- frame, arms and back ---------------------------------------------------------------
	kit.rbox(Vector3(0.0, LEG_H + 0.13, 0.0), Vector3(1.84, 0.3, 0.84), 0.09, SOFA_DARK)
	var lean := Basis(Vector3.RIGHT, deg_to_rad(8.0))
	kit.rbox(Vector3(0.0, 0.9, 0.33), Vector3(1.6, 0.7, 0.24), 0.11, SOFA, lean)
	for s in [-1.0, 1.0]:
		kit.rbox(Vector3(0.87 * s, 0.66, 0.0), Vector3(0.28, 0.5, 0.9), 0.12, SOFA)
		# seat and back cushions
		kit.rbox(Vector3(0.37 * s, 0.6, -0.07), Vector3(0.72, 0.2, 0.68), 0.09, CUSHION)
		kit.rbox(Vector3(0.37 * s, 0.93, 0.2), Vector3(0.7, 0.46, 0.17), 0.08, CUSHION, lean)
	# one mustard throw pillow, propped in the corner
	kit.rbox(Vector3(-0.52, 0.86, 0.02), Vector3(0.36, 0.36, 0.14), 0.065,
		PILLOW, Basis(Vector3.UP, deg_to_rad(-24.0)) * Basis(Vector3.RIGHT, deg_to_rad(16.0)) * Basis(Vector3.FORWARD, deg_to_rad(12.0)))
	add_body(kit.commit())


## A tapered peg with a darker foot.
func _leg(kit: DecoKit, at: Vector3) -> void:
	kit.cone(at, 0.05, 0.05, 0.05, LEG_FOOT, Basis.IDENTITY, 8)
	kit.cone(at + Vector3(0.0, 0.05, 0.0), 0.036, 0.06, LEG_H - 0.04, LEG, Basis.IDENTITY, 8)
