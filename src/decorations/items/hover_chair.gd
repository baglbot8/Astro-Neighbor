extends DecoItem
## Hover Chair — a plush bucket seat riding on an anti-gravity ring, bobbing gently in place.

const SEAT := Color("#d95d7c")
const SEAT_DARK := Color("#e0708f")
const FRAME := Color("#c2ccde")
const RING := Color("#65c5d9")

var _rig: Node3D


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.5
	collide_height = 0.95


func _build() -> void:
	_rig = pivot("Rig")
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.42, 0.02), Vector2(0.44, 0.1), Vector2(0.3, 0.16), Vector2(0.0, 0.16)]), 20, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.2, 0.0)), FRAME)
	kit.cone(Vector3(0.0, 0.34, 0.0), 0.12, 0.2, 0.16, FRAME, Basis.IDENTITY, 14)
	kit.rbox(Vector3(0.0, 0.6, 0.0), Vector3(0.78, 0.22, 0.72), 0.11, SEAT)
	kit.rbox(Vector3(0.0, 0.63, 0.0), Vector3(0.6, 0.1, 0.56), 0.05, SEAT_DARK, Basis.IDENTITY, 0)
	var lean := Basis(Vector3.RIGHT, deg_to_rad(-13.0))
	kit.rbox(Vector3(0.0, 0.96, 0.32), Vector3(0.76, 0.62, 0.18), 0.09, SEAT, lean)
	kit.rbox(Vector3(0.0, 0.96, 0.34), Vector3(0.5, 0.44, 0.1), 0.05, SEAT_DARK, lean, 0)
	for s in [-1.0, 1.0]:
		kit.rbox(Vector3(0.44 * s, 0.8, 0.02), Vector3(0.12, 0.12, 0.56), 0.055, FRAME)
	add_body(kit.commit(), "Body", _rig)

	var glow := DecoKit.new()
	glow.torus(Vector3(0.0, 0.2, 0.0), 0.42, 0.055, RING)
	glow.disc(Vector3(0.0, 0.14, 0.0), 0.38, Color("#79c4d9"), Basis(Vector3.RIGHT, PI), 18)
	add_glow(glow.commit(), 2.4, "Thruster", 2.6, 0.32, 0.0, _rig)

	add_ground_glow(1.1, Color("#65c5d9"), 0.26)
	add_light(Vector3(0.0, 0.16, 0.0), Color("#5db2d9"), 0.9, 3.4)
	animate()


func _animate(t: float, _delta: float) -> void:
	_rig.position.y = sin(t * 1.35) * 0.045 + 0.02
	_rig.rotation.z = sin(t * 0.9) * 0.025
	_rig.rotation.x = sin(t * 1.1 + 1.0) * 0.02
