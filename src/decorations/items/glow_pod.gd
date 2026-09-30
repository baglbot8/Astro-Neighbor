extends DecoItem
## Glow Pod (Moss's stall, The Tangle) - one of the Tangle's big seed pods, garden-sized: a faceted,
## ribbed ovoid leaning a little in a dark husk collar, a curly tendril at its tip, and two seams of
## glowing seeds down its sides that breathe slowly after dark.

const SHELL := Color("#b8a3cf")
const SHELL_DARK := Color("#8f7ba8")
const HUSK := Color("#6d5f6e")
const TENDRIL := Color("#6f9a7c")
const SEAM := Color("#a8e6cf")


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.34
	collide_height = 1.0


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	var s := 0.78
	var tilt := Basis(Vector3(1.0, 0.0, 0.3).normalized(), 0.12)
	# the pod: EIGHT facets on purpose - a smooth egg is Cosmo Depot's Alien Egg; this is a seed
	var prof := PackedVector2Array([Vector2(0.0, -0.06), Vector2(0.34, -0.04), Vector2(0.48, 0.28),
		Vector2(0.46, 0.66), Vector2(0.33, 1.00), Vector2(0.13, 1.18), Vector2(0.0, 1.22)])
	for i in prof.size():
		prof[i] = prof[i] * s
	kit.lathe(prof, 11, Transform3D(tilt, Vector3.ZERO), SHELL, false)
	# darker ribs down every other facet edge
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.39
		var pts := PackedVector3Array()
		var radii := PackedFloat32Array()
		var cols := PackedColorArray()
		for j in 6:
			var t := float(j) / 5.0
			var y := lerpf(0.06, 1.08, t) * s
			var rr := (0.48 - 0.35 * pow(absf(t - 0.35) / 0.65, 2.0)) * s
			pts.append(tilt * Vector3(cos(a) * rr, y, sin(a) * rr))
			radii.append(0.022)
			cols.append(SHELL_DARK)
		JungleMeshes.tube(kit, pts, radii, cols, 5, false)
	# the husk collar it sits in, with three torn lobes
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.50 * s, 0.0), Vector2(0.44 * s, 0.16 * s),
		Vector2(0.0, 0.16 * s)]), 10, Transform3D(tilt, Vector3.ZERO), HUSK, false)
	for k in 3:
		var a := TAU * float(k) / 3.0
		var o := Vector3(cos(a), 0.0, sin(a))
		kit.sphere(tilt * (o * 0.42 * s + Vector3(0.0, 0.16 * s, 0.0)), 0.10 * s, HUSK.darkened(0.1),
			Vector3(0.8, 1.3, 0.5), 8, Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, 0.3))
	# the tendril: a curl off the tip
	var tip := tilt * Vector3(0.0, 1.20 * s, 0.0)
	var tp := PackedVector3Array()
	var tr := PackedFloat32Array()
	var tc := PackedColorArray()
	for i in 10:
		var t := float(i) / 9.0
		var ang := t * PI * 1.6
		tp.append(tip + Vector3(sin(ang) * 0.12 * (1.0 - 0.4 * t), 0.02 + 0.16 * t, 0.10 * (1.0 - cos(ang)) * 0.5))
		tr.append(lerpf(0.025, 0.01, t))
		tc.append(TENDRIL)
	JungleMeshes.tube(kit, tp, tr, tc, 5, true)
	# glowing seed seams down two facets
	for k in 2:
		var a := TAU * (float(k) * 0.5 + 0.0625) + 0.39
		for j in 6:
			var t := 0.12 + 0.14 * float(j)
			var y := lerpf(0.26, 0.98, t) * s
			var rr := (0.49 - 0.24 * t * t) * s
			glow.sphere(tilt * Vector3(cos(a) * rr, y, sin(a) * rr), 0.03 * s + 0.004, SEAM, Vector3(1.0, 1.9, 1.0), 6, tilt)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.4, "Seams", 0.45, 0.35)
	add_ground_glow(0.9, Color("#9fd9c0"), 0.2)
