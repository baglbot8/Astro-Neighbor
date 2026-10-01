extends DecoItem
## Campfire Ring (cozy home set) - a ring of chunky stones around a teepee of logs with a real, warm
## orange fire in it, a log stool on either side, and a marshmallow stick stuck in the ground ready to
## go. The Plasma Campfire is the cold blue one; this is the one you sit by.

const STONE := Color("#b4b0bd")
const STONE_DARK := Color("#8f8a9c")
const ASH := Color("#4f4a5c")
const BARK := Color("#8a6f58")
const BARK_DARK := Color("#6f5848")
const CUT := Color("#d6c19a")
const RING := Color("#b89a74")
const FLAME := Color("#dd9a5c")
const FLAME_HOT := Color("#ecd08a")
const STICK := Color("#93775a")
const MALLOW := Color("#ece4d4")

var _flame: Node3D


func _init() -> void:
	footprint = 1.15
	collide_radius = 0.6
	collide_height = 0.4


func _build() -> void:
	var kit := DecoKit.new()
	kit.disc(Vector3(0.0, 0.02, 0.0), 0.46, ASH, Basis.IDENTITY, 18)
	# --- eight chunky stones, no two the same size ------------------------------------------------------
	for i in 8:
		var a := TAU * float(i) / 8.0 + 0.2
		var sz := Vector3(0.3 + 0.04 * float(i % 3), 0.17 + 0.035 * float((i * 2) % 3), 0.22 + 0.03 * float(i % 2))
		kit.rbox(Vector3(cos(a) * 0.5, sz.y * 0.5 - 0.01, sin(a) * 0.5), sz, 0.085,
			STONE if i % 2 == 0 else STONE_DARK, Basis(Vector3.UP, PI * 0.5 - a + 0.15 * float(i % 3 - 1)))
	# --- a teepee of four logs with pale cut ends ---------------------------------------------------------
	for i in 4:
		var a2 := TAU * float(i) / 4.0 + 0.6
		var o := Vector3(cos(a2), 0.0, sin(a2))
		var foot := o * 0.3 + Vector3(0.0, 0.05, 0.0)
		var tip := o * -0.05 + Vector3(0.0, 0.46, 0.0)
		kit.bar(foot, tip, 0.055, BARK if i % 2 == 0 else BARK_DARK, 8)
		var ax := (tip - foot).normalized()
		kit.disc(tip + ax * 0.003, 0.05, CUT, DecoKit.axis_basis(ax), 8)
	# --- two log stools ------------------------------------------------------------------------------
	for s in [-1.0, 1.0]:
		var c := Vector3(0.94 * s, 0.0, 0.06 * s)
		kit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.185, 0.05), Vector2(0.185, 0.27), Vector2(0.175, 0.3),
			Vector2(0.0, 0.3)]), 14, Transform3D(Basis.IDENTITY, c), BARK)
		kit.disc(c + Vector3(0.0, 0.303, 0.0), 0.17, CUT, Basis.IDENTITY, 14)
		kit.torus(c + Vector3(0.0, 0.305, 0.0), 0.1, 0.008, RING, Basis.IDENTITY, 12, 3)
		kit.sphere(c + Vector3(0.0, 0.306, 0.0), 0.03, RING, Vector3(1.0, 0.25, 1.0), 6)
		kit.tube(c + Vector3(-0.19 * s, 0.14, 0.02), c + Vector3(-0.25 * s, 0.2, 0.03), 0.022, BARK_DARK, 5, 1)
	# --- the marshmallow stick, stuck in the ground and leaning in toward the fire ------------------------
	var s0 := Vector3(0.5, 0.0, -0.56)
	var s1 := Vector3(0.2, 0.62, -0.2)
	kit.bar(s0, s1, 0.013, STICK, 6)
	var sd := (s1 - s0).normalized()
	for k in 2:
		kit.rbox(s1 - sd * (0.06 + 0.1 * float(k)), Vector3(0.085, 0.085, 0.085), 0.03, MALLOW, DecoKit.axis_basis(sd), 0)
	add_body(kit.commit())

	# --- the fire ---------------------------------------------------------------------------------
	_flame = pivot("Flame", Vector3(0.0, 0.1, 0.0))
	var glow := DecoKit.new()
	glow.cone(Vector3.ZERO, 0.21, 0.0, 0.66, FLAME, Basis.IDENTITY, 10)
	glow.cone(Vector3(0.07, 0.0, 0.05), 0.12, 0.0, 0.42, FLAME, Basis(Vector3.BACK, -0.25), 8)
	glow.cone(Vector3(-0.08, 0.0, -0.03), 0.11, 0.0, 0.36, FLAME, Basis(Vector3.BACK, 0.3), 8)
	glow.cone(Vector3(0.0, 0.03, 0.0), 0.12, 0.0, 0.42, FLAME_HOT, Basis.IDENTITY, 8)
	glow.sphere(Vector3(0.0, 0.07, 0.0), 0.19, FLAME_HOT, Vector3(1.0, 0.55, 1.0), 10)
	add_glow(glow.commit(), 3.0, "Fire", 5.0, 0.25, 0.0, _flame)

	add_particles(12, 1.6, Vector3(0.0, 0.5, 0.0), Color("#e0a860"), 0.08, 0.7, 20.0, 0.3, 0.1)
	add_light(Vector3(0.0, 0.5, 0.0), Color("#e0a05c"), 2.8, 7.5)
	add_ground_glow(1.9, Color("#e0a05c"), 0.3)
	animate()


func _animate(t: float, _delta: float) -> void:
	var s := 1.0 + sin(t * 6.7) * 0.08 + sin(t * 10.9) * 0.05
	_flame.scale = Vector3(1.0 / sqrt(s), s, 1.0 / sqrt(s))
	_flame.rotation.y = sin(t * 1.9) * 0.3
