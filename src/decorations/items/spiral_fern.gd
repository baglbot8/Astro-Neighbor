extends DecoItem
## Spiral Fern (Moss's stall, The Tangle) - a garden-sized cousin of the Tangle's spiral plants: one
## stem climbing in a slow helix out of a moss mound and rolling over into a fiddlehead curl round a
## small glowing bud, with three leaves up the stem and two baby croziers at its foot.
## Built with the planet's own tube/blade builders (JungleMeshes) so it reads as a piece of that world.

const MOUND := Color("#5f7d4e")
const MOUND_DARK := Color("#4c6641")
const STEM := Color("#5f8e76")
const TIP := Color("#8cb99a")
const LEAF := Color("#5d9a80")
const BUD := Color("#bfe3b0")


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.28
	collide_height = 1.2


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	# --- a low moss mound with a few lumps, so it sits IN the ground rather than on it ----------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.36, 0.0), Vector2(0.33, 0.05),
		Vector2(0.22, 0.10), Vector2(0.0, 0.12)]), 14, Transform3D.IDENTITY, MOUND)
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.4
		kit.sphere(Vector3(cos(a) * 0.24, 0.06, sin(a) * 0.24), 0.09, MOUND_DARK if i % 2 == 0 else MOUND,
			Vector3(1.0, 0.55, 1.0), 8)
	# --- the helix ---------------------------------------------------------------------------------
	var h := 1.05
	var turns := 1.35
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var cols := PackedColorArray()
	var n := 22
	for i in n + 1:
		var t := float(i) / float(n)
		var a := TAU * turns * t
		var rr := 0.13 * (1.0 - 0.5 * t)
		pts.append(Vector3(cos(a) * rr, 0.08 + h * t, sin(a) * rr))
		radii.append(lerpf(0.055, 0.028, t))
		cols.append(STEM.lerp(TIP, t * t))
	# the curl: a planar spiral rolling over the top
	var last := pts[n]
	var fwd := Vector3(cos(TAU * turns), 0.0, sin(TAU * turns))
	for i in range(1, 11):
		var s := float(i) / 10.0
		var ang := s * PI * 1.7
		var rad := 0.16 * (1.0 - 0.55 * s)
		pts.append(last + fwd * sin(ang) * rad + Vector3(0.0, (1.0 - cos(ang)) * rad * 0.9, 0.0))
		radii.append(lerpf(0.028, 0.013, s))
		cols.append(TIP)
	JungleMeshes.tube(kit, pts, radii, cols, 7, true)
	glow.sphere(last + fwd * 0.08 + Vector3(0.0, 0.12, 0.0), 0.075, BUD, Vector3(1.0, 1.15, 1.0), 10)
	# --- three leaves up the stem -------------------------------------------------------------------
	var lw := PackedFloat32Array([0.02, 0.07, 0.09, 0.075, 0.04, 0.0])
	for k in 3:
		var idx := 4 + k * 5
		var p := pts[idx]
		var o := Vector3(p.x, 0.0, p.z).normalized()
		if o.length_squared() < 0.01:
			o = Vector3.RIGHT
		JungleMeshes.blade(kit, p, o, 0.36 - 0.05 * float(k), lw, 0.08, 0.12, 0.3, LEAF.darkened(0.06),
			LEAF.lightened(0.08), 0.12)
	# --- two baby croziers at the foot ---------------------------------------------------------------
	for k in 2:
		var a := 2.2 + 2.1 * float(k)
		var o := Vector3(cos(a), 0.0, sin(a))
		var cp := PackedVector3Array()
		var cr := PackedFloat32Array()
		var cc := PackedColorArray()
		var hh := 0.22 + 0.06 * float(k)
		for i in 5:
			var t := float(i) / 4.0
			cp.append(o * (0.18 + 0.04 * t) + Vector3(0.0, 0.08 + hh * t, 0.0))
			cr.append(0.018)
			cc.append(STEM.lerp(TIP, t * 0.6))
		var top := cp[4]
		for i in range(1, 7):
			var s := float(i) / 6.0
			var ang := s * PI * 1.8
			var rad := 0.05 * (1.0 - 0.6 * s)
			cp.append(top + o * sin(ang) * rad + Vector3(0.0, (1.0 - cos(ang)) * rad, 0.0))
			cr.append(lerpf(0.018, 0.009, s))
			cc.append(TIP)
		JungleMeshes.tube(kit, cp, cr, cc, 5, true)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.0, "Bud", 0.7, 0.3)
	add_ground_glow(0.7, Color("#a8d9b0"), 0.18)
