extends DecoItem
## Hammock (cozy home set) - two wooden posts on cross feet, leaning away from each other, with a striped
## cloth sling hung between them on fanned ropes. A pillow at one end, a little lantern on the left post.
## The sling rocks very gently. Runs along X; you look at it from -Z.

const WOOD := Color("#b89a74")
const WOOD_DARK := Color("#93775a")
const CAP := Color("#7fb5ad")
const ROPE := Color("#cdbf9f")
const CLOTH := Color("#e3d7bc")
const STRIPE := Color("#c9805e")
const STRIPE_B := Color("#7fb5ad")
const PILLOW := Color("#cf8f86")
const LANTERN := Color("#6f6a80")
const LIGHT := Color("#e3c877")
const HOOK_X := 1.02
const HOOK_Y := 1.02
const SLING_X := 0.74
const SEGS := 12

var _sling: Node3D


func _init() -> void:
	footprint = 1.3
	collide_radius = 0.62
	collide_height = 0.9


func _build() -> void:
	var kit := DecoKit.new()
	for s in [-1.0, 1.0]:
		var foot := Vector3(1.16 * s, 0.0, 0.0)
		var top := Vector3(HOOK_X * s, HOOK_Y + 0.14, 0.0)
		# cross foot, post, cap, hook ring
		kit.rbox(foot + Vector3(0.0, 0.05, 0.0), Vector3(0.16, 0.1, 0.78), 0.04, WOOD_DARK, Basis.IDENTITY, 0)
		kit.tube(foot + Vector3(0.0, 0.05, 0.0), top, 0.06, WOOD, 9)
		kit.tube(foot + Vector3(0.0, 0.08, -0.3), foot.lerp(top, 0.42), 0.032, WOOD_DARK, 6, 1)
		kit.tube(foot + Vector3(0.0, 0.08, 0.3), foot.lerp(top, 0.42), 0.032, WOOD_DARK, 6, 1)
		kit.sphere(top + Vector3(0.0, 0.03, 0.0), 0.085, CAP, Vector3.ONE, 10)
		kit.torus(Vector3(HOOK_X * s - 0.05 * s, HOOK_Y, 0.0), 0.04, 0.012, LANTERN, Basis(Vector3.BACK, deg_to_rad(90.0)), 10, 3)
	# the lantern on the left post: a short arm, a cage, a cap
	var lp := Vector3(-HOOK_X - 0.2, HOOK_Y - 0.06, 0.0)
	kit.tube(Vector3(-HOOK_X - 0.02, HOOK_Y + 0.1, 0.0), lp + Vector3(0.0, 0.16, 0.0), 0.016, LANTERN, 6, 1)
	kit.bar(lp + Vector3(0.0, 0.16, 0.0), lp + Vector3(0.0, 0.08, 0.0), 0.008, LANTERN, 6)
	kit.cone(lp + Vector3(0.0, 0.05, 0.0), 0.075, 0.02, 0.05, LANTERN, Basis.IDENTITY, 8)
	kit.lathe(PackedVector2Array([Vector2(0.0, -0.085), Vector2(0.06, -0.085), Vector2(0.06, -0.065), Vector2(0.0, -0.065)]),
		8, Transform3D(Basis.IDENTITY, lp), LANTERN)
	add_body(kit.commit())

	# --- the sling, on a pivot at hook height so it can rock about the line between the two hooks --------
	_sling = pivot("Sling", Vector3(0.0, HOOK_Y, 0.0))
	var sl := DecoKit.new()
	var prev: Array[Vector3] = []
	for i in SEGS + 1:
		var x := lerpf(-SLING_X, SLING_X, float(i) / float(SEGS))
		var u := 1.0 - pow(absf(x) / SLING_X, 2.0)      # 0 at the ends, 1 in the middle
		var y := -0.16 - 0.36 * u
		var hw := lerpf(0.13, 0.4, pow(u, 0.6))
		var cup := 0.13 * pow(u, 0.6)
		var row: Array[Vector3] = []
		for k in 5:
			var v := float(k) / 4.0 * 2.0 - 1.0          # -1..1 across the cloth
			row.append(Vector3(x, y + cup * v * v, hw * v))
		if i > 0:
			for k in 4:
				var col: Color = CLOTH
				if k == 0 or k == 3:
					col = STRIPE if (i % 2 == 0) else STRIPE_B
				sl.quad(prev[k], row[k], row[k + 1], prev[k + 1], col)
		prev = row
	for s in [-1.0, 1.0]:
		var ex: float = SLING_X * s
		sl.tube(Vector3(ex, -0.16 + 0.004, -0.15), Vector3(ex, -0.16 + 0.004, 0.15), 0.022, WOOD_DARK, 6, 1)
		for z in [-0.13, 0.0, 0.13]:
			sl.bar(Vector3(HOOK_X * s - 0.05 * s, 0.0, 0.0), Vector3(ex, -0.16, z), 0.009, ROPE, 6)
	# a pillow at the right end, and a folded blanket near the middle
	sl.sphere(Vector3(0.42, -0.34, 0.0), 0.17, PILLOW, Vector3(0.8, 0.42, 1.25), 10, Basis(Vector3.BACK, 0.38))
	sl.rbox(Vector3(-0.22, -0.455, 0.0), Vector3(0.3, 0.06, 0.36), 0.03, STRIPE_B, Basis(Vector3.BACK, -0.12), 0)
	sl.rbox(Vector3(-0.22, -0.42, 0.0), Vector3(0.24, 0.04, 0.3), 0.02, CLOTH, Basis(Vector3.BACK, -0.12), 0)
	add_body(sl.commit(), "SlingBody", _sling)

	var glow := DecoKit.new()
	glow.sphere(lp + Vector3(0.0, -0.01, 0.0), 0.05, LIGHT, Vector3(1.0, 1.15, 1.0), 8)
	add_glow(glow.commit(), 2.4, "Lantern", 0.9, 0.2)
	add_light(lp, Color("#e0c487"), 1.4, 4.5)
	animate()


func _animate(t: float, _delta: float) -> void:
	_sling.rotation.x = sin(t * 0.9) * deg_to_rad(4.0)
