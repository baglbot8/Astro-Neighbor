extends DecoItem
## Antenna Tree — a chrome trunk with three tiers of mint dish-leaves and blinking bulbs on the tips.
##
## BUDGET: this was the worst item in the set at 5,046 triangles (budget 2,000, docs/ARCHITECTURE.md
## 10). Nearly half of that was nine leaves that each carried a full torus rim on top of a six-point
## lathed dish. The dish now bakes its own rim as a second colour band in the same lathe, the tiers
## are 3/3/2 instead of 3/3/3 (which reads better anyway — a tree tapers), and every ring runs at the
## resolution the shape needs rather than the resolution it inherited.

const TRUNK := Color("#a8b8cc")
const TRUNK_DARK := Color("#6f819c")
const LEAF := Color("#7fd8d0")
const LEAF_DARK := Color("#4fa79f")
## [height, reach, leaves, angle offset] per tier, top tier deliberately thinner.
const TIERS := [[0.66, 0.62, 3, 0.0], [1.25, 0.5, 3, 1.05], [1.78, 0.36, 2, 2.1]]


func _init() -> void:
	footprint = 0.85
	collide_radius = 0.42
	collide_height = 2.2


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.44, 0.0), Vector2(0.34, 0.14), Vector2(0.22, 0.26), Vector2(0.0, 0.3)]),
		14, Transform3D.IDENTITY, TRUNK_DARK)
	kit.cone(Vector3(0.0, 0.2, 0.0), 0.17, 0.1, 2.1, TRUNK, Basis.IDENTITY, 11)
	for i in 3:
		kit.torus(Vector3(0.0, 0.5 + float(i) * 0.6, 0.0), 0.15 - float(i) * 0.014, 0.035, TRUNK_DARK, Basis.IDENTITY, 12, 4)

	var glow := DecoKit.new()
	for tier in TIERS:
		var y: float = tier[0]
		var reach: float = tier[1]
		var n: int = tier[2]
		for k in n:
			var a: float = TAU * float(k) / float(n) + float(tier[3])
			var dir := Vector3(cos(a), 0.0, sin(a))
			var tip: Vector3 = Vector3(0.0, y, 0.0) + dir * reach + Vector3(0.0, reach * 0.42, 0.0)
			kit.tube(Vector3(0.0, y, 0.0) + dir * 0.1, tip, 0.032, TRUNK, 6)
			# Dish leaf pointing up-and-out. Two lathes, not a lathe plus a torus: the outer band IS
			# the rim, so the leaf keeps its crisp dark edge for a third of the triangles.
			var basis := DecoKit.tilt_basis(deg_to_rad(38.0), a + PI * 0.5)
			kit.lathe(PackedVector2Array([Vector2(0.0, 0.06), Vector2(0.13, 0.02), Vector2(0.24, 0.0)]),
				11, Transform3D(basis, tip), LEAF)
			kit.lathe(PackedVector2Array([Vector2(0.24, 0.0), Vector2(0.27, 0.03), Vector2(0.23, 0.05)]),
				10, Transform3D(basis, tip), LEAF_DARK)
			glow.sphere(tip + basis * Vector3(0.0, 0.1, 0.0), 0.05, Color("#d9bf61"), Vector3.ONE, 7)
	kit.sphere(Vector3(0.0, 2.3, 0.0), 0.09, TRUNK_DARK, Vector3(1.0, 0.8, 1.0), 9)
	kit.tube(Vector3(0.0, 2.3, 0.0), Vector3(0.0, 2.58, 0.0), 0.02, TRUNK, 6)
	glow.sphere(Vector3(0.0, 2.62, 0.0), 0.07, Color("#d94646"), Vector3.ONE, 8)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.4, "Bulbs", 1.9, 0.55, 1.0)
	add_light(Vector3(0.0, 1.6, 0.0), Color("#d9bd79"), 0.9, 4.5)
