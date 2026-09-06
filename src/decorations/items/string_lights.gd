extends DecoItem
## String-Lights Pole — a party-light mast with a drooping garland of bulbs that blink out of step.
##
## SHAPE: compared side by side with the ACNH lantern pole, the first version was one thin rod with a
## pancake foot. An AC pole is built out of STAGES you can count from across the plaza: a flared foot,
## a stepped base, a collar where the post narrows, a boxy junction where the arm meets the post, ball
## caps on the arm tips, hanger rings, and a finial on top. Same silhouette family, same bulb count —
## it just has structure now instead of being a stick.

const POLE := Color("#c2ccde")
const POLE_DARK := Color("#8fa3bf")
const METAL := Color("#5f7089")
const ACCENT := Color("#d96143")
const WIRE := Color("#4a4655")
const BULBS := [Color("#d9bf61"), Color("#d95d7c"), Color("#65c5d9"), Color("#7ed957")]
const SPAN := 1.5
const ARM_Y := 2.05
const DROOP := 0.55
## Segments in the hanging garland. Each one is a bar, so this is the item's biggest single cost.
const WIRE_STEPS := 8


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.26
	collide_height = 1.6


func _build() -> void:
	var kit := DecoKit.new()
	# --- foot: a flared plinth with a real step, not a pancake ---------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.34, 0.0), Vector2(0.32, 0.06),
		Vector2(0.22, 0.09), Vector2(0.21, 0.15), Vector2(0.12, 0.19), Vector2(0.0, 0.2)]),
		16, Transform3D.IDENTITY, METAL)
	kit.torus(Vector3(0.0, 0.06, 0.0), 0.32, 0.035, POLE_DARK, Basis.IDENTITY, 16, 4)
	# --- post: tapers, with a collar two thirds up -----------------------------------------------
	kit.cone(Vector3(0.0, 0.16, 0.0), 0.078, 0.052, ARM_Y - 0.16, POLE, Basis.IDENTITY, 12)
	kit.torus(Vector3(0.0, 0.62, 0.0), 0.082, 0.03, ACCENT, Basis.IDENTITY, 14, 4)
	kit.torus(Vector3(0.0, 1.34, 0.0), 0.072, 0.026, POLE_DARK, Basis.IDENTITY, 14, 4)
	# --- junction box where the cross arm meets the post ----------------------------------------
	kit.rbox(Vector3(0.0, ARM_Y - 0.02, 0.0), Vector3(0.15, 0.19, 0.15), 0.045, POLE_DARK, Basis.IDENTITY, 0)
	# --- finial: collar, ball, spike -------------------------------------------------------------
	kit.torus(Vector3(0.0, ARM_Y + 0.1, 0.0), 0.06, 0.024, ACCENT, Basis.IDENTITY, 12, 4)
	kit.sphere(Vector3(0.0, ARM_Y + 0.19, 0.0), 0.062, POLE, Vector3.ONE, 9)
	kit.cone(Vector3(0.0, ARM_Y + 0.23, 0.0), 0.032, 0.0, 0.13, ACCENT, Basis.IDENTITY, 8)
	# --- cross arm with ball caps and hanger rings ----------------------------------------------
	kit.bar(Vector3(-SPAN * 0.5, ARM_Y, 0.0), Vector3(SPAN * 0.5, ARM_Y, 0.0), 0.028, METAL, 8)
	for s in [-1.0, 1.0]:
		kit.sphere(Vector3(SPAN * 0.5 * s, ARM_Y, 0.0), 0.05, POLE, Vector3.ONE, 8)
		kit.torus(Vector3(SPAN * 0.5 * s, ARM_Y - 0.06, 0.0), 0.038, 0.012, METAL,
			Basis(Vector3.RIGHT, deg_to_rad(90.0)), 10, 3)
	# --- garland -----------------------------------------------------------------------------
	var prev := _wire_point(0.0)
	for i in range(1, WIRE_STEPS + 1):
		var p := _wire_point(float(i) / float(WIRE_STEPS))
		kit.bar(prev, p, 0.016, WIRE, 6)
		prev = p
	add_body(kit.commit())

	var glow := DecoKit.new()
	for i in 7:
		var u := (float(i) + 1.0) / 8.0
		var p := _wire_point(u)
		var c: Color = BULBS[i % BULBS.size()]
		glow.sphere(p + Vector3(0.0, -0.1, 0.0), 0.075, c, Vector3(1.0, 1.15, 1.0), 9)
		glow.cone(p + Vector3(0.0, -0.03, 0.0), 0.03, 0.045, 0.05, c, Basis(Vector3.FORWARD, PI), 7)
	add_glow(glow.commit(), 2.6, "Bulbs", 1.7, 0.45)

	add_light(Vector3(0.0, ARM_Y - DROOP, 0.0), Color("#d9af70"), 1.5, 5.5)
	add_ground_glow(1.6, Color("#d9ae6f"), 0.2)


## Catenary-ish sag between the two arm tips.
func _wire_point(u: float) -> Vector3:
	var x: float = lerpf(-SPAN * 0.5, SPAN * 0.5, u)
	return Vector3(x, ARM_Y - sin(u * PI) * DROOP, 0.0)
