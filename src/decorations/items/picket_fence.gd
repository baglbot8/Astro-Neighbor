extends DecoItem
## Picket Fence (cozy home set) - a short run of cream pickets with rounded tops that dip in the middle
## (a scallop), two chunkier end posts with teal ball caps, two rails, and a vine with three blooms
## climbing in from the left post. Put two or three side by side for a garden edge.

const PICKET := Color("#e3d7bc")
const PICKET_SHADE := Color("#cfc1a3")
const RAIL := Color("#bfae8a")
const CAP := Color("#7fbdb4")
const VINE := Color("#6f9e6a")
const LEAF := Color("#8fbd80")
const BLOOM := Color("#d98f9c")
const BLOOM_EYE := Color("#e3c877")
const HALF := 0.74


func _init() -> void:
	footprint = 0.8
	collide_radius = 0.5
	collide_height = 0.75


func _build() -> void:
	var kit := DecoKit.new()
	# --- two rails behind the pickets ---------------------------------------------------------------
	for y in [0.2, 0.5]:
		kit.rbox(Vector3(0.0, y, 0.04), Vector3(HALF * 2.0, 0.07, 0.05), 0.02, RAIL, Basis.IDENTITY, 0)
	# --- six pickets, tallest by the posts and lowest in the middle ---------------------------------
	var n := 6
	for i in n:
		var x := lerpf(-0.5, 0.5, float(i) / float(n - 1))
		var t := absf(x) / 0.5
		var h := 0.6 + 0.16 * t * t
		kit.extrude(_picket(0.14, h), 0.05, PICKET if i % 2 == 0 else PICKET_SHADE,
			Transform3D(Basis.IDENTITY, Vector3(x, 0.03, -0.01)))
	# --- end posts: a foot block, a square post, a ball cap ------------------------------------------
	for s in [-1.0, 1.0]:
		kit.rbox(Vector3(HALF * s, 0.06, 0.0), Vector3(0.22, 0.12, 0.22), 0.04, RAIL, Basis.IDENTITY, 0)
		kit.rbox(Vector3(HALF * s, 0.44, 0.0), Vector3(0.15, 0.86, 0.15), 0.05, PICKET)
		kit.rbox(Vector3(HALF * s, 0.87, 0.0), Vector3(0.19, 0.05, 0.19), 0.02, RAIL, Basis.IDENTITY, 0)
		kit.sphere(Vector3(HALF * s, 0.95, 0.0), 0.085, CAP, Vector3.ONE, 10)
	# --- the vine: up the left post, then wandering along the front of the pickets --------------------
	var z := -0.075
	var pts := PackedVector3Array([
		Vector3(-HALF - 0.02, 0.02, -0.1), Vector3(-HALF + 0.03, 0.3, -0.1), Vector3(-HALF + 0.02, 0.6, -0.1),
		Vector3(-0.52, 0.66, z), Vector3(-0.3, 0.5, z), Vector3(-0.1, 0.55, z), Vector3(0.08, 0.42, z),
		Vector3(0.24, 0.47, z)])
	JungleMeshes.tube(kit, pts, PackedFloat32Array([0.022, 0.02, 0.018, 0.016, 0.014, 0.012, 0.01, 0.008]),
		PackedColorArray([VINE]), 5, true)
	for k in [1, 2, 4, 6, 7]:
		var up := 1.0 if k % 2 == 0 else -1.0
		kit.sphere(pts[k] + Vector3(0.03, 0.05 * up, -0.015), 0.055, LEAF, Vector3(1.0, 0.6, 0.3), 6,
			Basis(Vector3.BACK, 0.6 * up))
	for k in [2, 3, 5]:
		var c: Vector3 = pts[k] + Vector3(0.0, 0.03, -0.035)
		kit.extrude(_flower(0.075), 0.022, BLOOM, Transform3D(Basis(Vector3.BACK, 0.5 * float(k)), c))
		kit.extrude(DecoKit.round_rect_poly(0.05, 0.05, 0.025, 2), 0.03, BLOOM_EYE, Transform3D(Basis.IDENTITY, c + Vector3(0.0, 0.0, -0.004)))
	add_body(kit.commit())


## One picket outline (XY): a plank `w` wide and `h` tall with a half-round top.
static func _picket(w: float, h: float) -> PackedVector2Array:
	var r := w * 0.5
	var out := PackedVector2Array([Vector2(-r, 0.0), Vector2(r, 0.0)])
	for i in 7:
		var a := PI * float(i) / 6.0
		out.append(Vector2(cos(a) * r, h - r + sin(a) * r))
	return out


## A five-petal flower outline (XY): one closed polygon, so a bloom costs one extrude instead of five
## spheres (the first build spent 1,080 of this item's triangles on three flowers).
static func _flower(r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		out.append(Vector2(cos(a), sin(a)) * r * (0.6 + 0.4 * absf(cos(a * 2.5))))
	return out
