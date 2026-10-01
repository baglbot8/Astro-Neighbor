extends DecoItem
## Wind Chime (cozy home set) - a shepherd's-hook post with a chime hanging from the crook: a wooden cap,
## five pipes cut to five lengths, and a little star sail on the clapper string that catches the breeze.
## The whole chime sways and the sail turns; the star glows softly after dark.

const POST := Color("#7d7890")
const POST_DARK := Color("#5f5a70")
const ACCENT := Color("#c9ad6a")
const WOOD := Color("#b89a74")
const WOOD_DARK := Color("#93775a")
const PIPES := [Color("#c6d0e0"), Color("#d9c27a"), Color("#b9c4d8"), Color("#d2b262"), Color("#c6d0e0")]
const STRING := Color("#5f5a70")
const SAIL := Color("#e3c877")
const HOOK_X := 0.42
const HOOK_Y := 1.6

var _chime: Node3D
var _sail: Node3D


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.24
	collide_height = 1.7


func _build() -> void:
	var kit := DecoKit.new()
	# --- a stepped foot ----------------------------------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.26, 0.0), Vector2(0.24, 0.05), Vector2(0.14, 0.08), Vector2(0.13, 0.14),
		Vector2(0.06, 0.17), Vector2(0.0, 0.17)]), 16, Transform3D.IDENTITY, POST_DARK)
	kit.torus(Vector3(0.0, 0.05, 0.0), 0.24, 0.028, ACCENT, Basis.IDENTITY, 16, 4)
	# --- the post and its crook: straight up, over in a half circle, and a small curl back down --------
	var pts := PackedVector3Array([Vector3(0.0, 0.14, 0.0), Vector3(0.0, 0.9, 0.0), Vector3(0.0, HOOK_Y, 0.0)])
	var rad := PackedFloat32Array([0.04, 0.034, 0.03])
	var r := HOOK_X * 0.5
	for i in range(1, 9):
		var a := PI - PI * float(i) / 8.0
		pts.append(Vector3(r + cos(a) * r, HOOK_Y + sin(a) * r, 0.0))
		rad.append(lerpf(0.03, 0.022, float(i) / 8.0))
	pts.append(Vector3(HOOK_X - 0.03, HOOK_Y - 0.08, 0.0))
	rad.append(0.02)
	JungleMeshes.tube(kit, pts, rad, PackedColorArray([POST]), 7, true)
	kit.torus(Vector3(0.0, 0.6, 0.0), 0.04, 0.02, ACCENT, Basis.IDENTITY, 12, 4)
	kit.torus(Vector3(0.0, HOOK_Y - 0.04, 0.0), 0.034, 0.018, POST_DARK, Basis.IDENTITY, 12, 4)
	# a leaf curl off the post, the bit of garden ironwork that makes it a garden hook
	JungleMeshes.tube(kit, PackedVector3Array([Vector3(0.0, 1.1, 0.0), Vector3(-0.12, 1.2, 0.0), Vector3(-0.17, 1.32, 0.0),
		Vector3(-0.1, 1.4, 0.0), Vector3(-0.05, 1.34, 0.0)]), PackedFloat32Array([0.02, 0.018, 0.016, 0.013, 0.01]),
		PackedColorArray([POST_DARK]), 5, true)
	add_body(kit.commit())

	# --- the chime, on a pivot at the crook ------------------------------------------------------------
	_chime = pivot("Chime", Vector3(HOOK_X - 0.03, HOOK_Y - 0.1, 0.0))
	var ch := DecoKit.new()
	ch.bar(Vector3.ZERO, Vector3(0.0, -0.1, 0.0), 0.008, STRING, 6)
	ch.lathe(PackedVector2Array([
		Vector2(0.0, -0.15), Vector2(0.14, -0.15), Vector2(0.15, -0.13), Vector2(0.13, -0.1), Vector2(0.0, -0.09)]),
		14, Transform3D.IDENTITY, WOOD)
	ch.sphere(Vector3(0.0, -0.085, 0.0), 0.03, WOOD_DARK, Vector3.ONE, 6)
	for i in 5:
		var a2 := TAU * float(i) / 5.0 + 0.3
		var p := Vector3(cos(a2) * 0.1, -0.15, sin(a2) * 0.1)
		var l := 0.26 + 0.045 * float((i * 2) % 5)
		ch.bar(p, p + Vector3(0.0, -0.05, 0.0), 0.005, STRING, 6)
		ch.bar(p + Vector3(0.0, -0.05, 0.0), p + Vector3(0.0, -0.05 - l, 0.0), 0.024, PIPES[i], 7)
	ch.bar(Vector3(0.0, -0.15, 0.0), Vector3(0.0, -0.62, 0.0), 0.005, STRING, 6)
	ch.sphere(Vector3(0.0, -0.36, 0.0), 0.045, WOOD_DARK, Vector3(1.0, 0.7, 1.0), 8)
	add_body(ch.commit(), "ChimeBody", _chime)

	_sail = pivot("Sail", Vector3(0.0, -0.7, 0.0), _chime)
	var glow := DecoKit.new()
	glow.extrude(DecoKit.star_poly(0.1, 0.045, 5), 0.03, SAIL)
	add_glow(glow.commit(), 1.8, "Star", 0.7, 0.2, 0.0, _sail)
	animate()


func _animate(t: float, _delta: float) -> void:
	_chime.rotation.z = sin(t * 1.15) * deg_to_rad(5.0) + sin(t * 2.7) * deg_to_rad(1.5)
	_chime.rotation.x = sin(t * 0.83 + 1.0) * deg_to_rad(4.0)
	_sail.rotation.y = sin(t * 0.9) * 1.4
