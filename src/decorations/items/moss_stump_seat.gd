extends DecoItem
## Mossy Stump Seat (Moss's stall, The Tangle) - a short, fat, root-footed stump with a cut top ringed
## in growth lines, wearing a thick moss cushion with a hanging fringe on one side, and a cluster of
## tiny glow caps growing out of the bark.

const BARK := Color("#7a6a5c")
const BARK_DARK := Color("#5e5148")
const CUT := Color("#c7ad86")
const RING := Color("#a88d6c")
const MOSS := Color("#6b8a4e")
const MOSS_LIGHT := Color("#86a35e")
const CAP := Color("#a9dcc4")


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.36
	collide_height = 0.5


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	# --- the stump: flared foot, slightly waisted, a lip at the cut --------------------------------
	var h := 0.42
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.40, 0.0), Vector2(0.34, 0.06),
		Vector2(0.30, 0.16), Vector2(0.30, 0.32), Vector2(0.32, h - 0.02), Vector2(0.30, h), Vector2(0.0, h)]),
		14, Transform3D.IDENTITY, BARK)
	# bark ridges: six vertical strips standing proud, so it reads as bark and not a tin can
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.2
		var o := Vector3(cos(a), 0.0, sin(a))
		JungleMeshes.tube(kit, PackedVector3Array([o * 0.37 + Vector3(0, 0.02, 0), o * 0.31 + Vector3(0, 0.18, 0), o * 0.31 + Vector3(0, 0.36, 0)]),
			PackedFloat32Array([0.035, 0.026, 0.02]), PackedColorArray([BARK_DARK, BARK_DARK, BARK]), 5, false)
	# three roots reaching out
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.9
		var o := Vector3(cos(a), 0.0, sin(a))
		JungleMeshes.tube(kit, PackedVector3Array([o * 0.30 + Vector3(0, 0.10, 0), o * 0.46 + Vector3(0, 0.04, 0), o * 0.58 + Vector3(0, -0.01, 0)]),
			PackedFloat32Array([0.07, 0.045, 0.025]), PackedColorArray([BARK, BARK_DARK, BARK_DARK]), 6, true)
	# the cut face with its growth rings (only the front arc shows: the cushion covers the rest)
	kit.disc(Vector3(0.0, h + 0.003, 0.0), 0.29, CUT, Basis.IDENTITY, 18)
	for r in [0.10, 0.18, 0.25]:
		kit.torus(Vector3(0.0, h + 0.005, 0.0), r, 0.008, RING, Basis.IDENTITY, 16, 3)
	# --- the moss cushion: a soft lumpy pad, set back so the rings peek out at the front -----------
	kit.dome(Vector3(0.03, h, 0.05), 0.25, MOSS, 0.42, Basis.IDENTITY, 14)
	for i in 6:
		var a := TAU * float(i) / 6.0
		kit.sphere(Vector3(0.03 + cos(a) * 0.16, h + 0.05, 0.05 + sin(a) * 0.16), 0.075,
			MOSS_LIGHT if i % 2 == 0 else MOSS, Vector3(1.0, 0.55, 1.0), 8)
	# a fringe of moss hanging over the back edge
	for i in 7:
		var a := PI * 0.15 + PI * 0.7 * float(i) / 6.0
		var o := Vector3(cos(a), 0.0, sin(a))
		var top := o * 0.30 + Vector3(0.0, h - 0.01, 0.0)
		var l := 0.10 + 0.05 * float((i * 3) % 3)
		JungleMeshes.tube(kit, PackedVector3Array([top, top + o * 0.03 - Vector3(0, l * 0.5, 0), top + o * 0.02 - Vector3(0, l, 0)]),
			PackedFloat32Array([0.03, 0.022, 0.012]), PackedColorArray([MOSS, MOSS.darkened(0.08), MOSS.darkened(0.15)]), 5, true)
	# --- tiny glow caps growing out of the bark on the left side --------------------------------------
	for i in 3:
		var y := 0.14 + 0.08 * float(i)
		var a := PI * 1.05 + 0.18 * float(i)
		var o := Vector3(cos(a), 0.0, sin(a))
		var p := o * 0.31 + Vector3(0.0, y, 0.0)
		kit.tube(p, p + o * 0.05 + Vector3(0.0, 0.02, 0.0), 0.012, BARK_DARK, 5, 1)
		glow.dome(p + o * 0.06 + Vector3(0.0, 0.02, 0.0), 0.045 - 0.008 * float(i), CAP, 0.5, Basis.IDENTITY, 10)
	add_body(kit.commit())
	add_glow(glow.commit(), 1.8, "Caps", 0.5, 0.3)
