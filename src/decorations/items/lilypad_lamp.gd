extends DecoItem
## Lily-Pad Lamp (Moss's stall, The Tangle) - a curved reed rising out of a mossy root foot, carrying
## a cupped lily pad (with its notch) that holds a glowing bud like a candle. A second, smaller pad
## sprouts halfway up. Warm light at night.

const ROOT := Color("#6d5f52")
const MOSS := Color("#5f7d4e")
const REED := Color("#8fa36a")
const REED_DARK := Color("#6d8452")
const PAD := Color("#5f9e6e")
const PAD_RIM := Color("#4b7d58")
const BUD := Color("#f0d79a")
const PETAL := Color("#dbb3c6")


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.26
	collide_height = 1.5


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	# --- a root foot with three fingers, under a moss cap ------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.24, 0.0), Vector2(0.20, 0.07),
		Vector2(0.11, 0.15), Vector2(0.0, 0.17)]), 12, Transform3D.IDENTITY, ROOT)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.3
		var o := Vector3(cos(a), 0.0, sin(a))
		JungleMeshes.tube(kit, PackedVector3Array([o * 0.08 + Vector3(0, 0.08, 0), o * 0.22 + Vector3(0, 0.04, 0), o * 0.32]),
			PackedFloat32Array([0.05, 0.035, 0.02]), PackedColorArray([ROOT, ROOT.darkened(0.1), ROOT.darkened(0.2)]), 6, true)
	kit.sphere(Vector3(0.0, 0.14, 0.0), 0.13, MOSS, Vector3(1.0, 0.45, 1.0), 10)
	# --- the reed: a gentle S, thinning as it rises -------------------------------------------------
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var cols := PackedColorArray()
	var h := 1.32
	for i in 9:
		var t := float(i) / 8.0
		pts.append(Vector3(0.07 * sin(t * PI * 1.1), 0.12 + h * t, -0.05 * sin(t * PI)))
		radii.append(lerpf(0.035, 0.022, t))
		cols.append(REED_DARK.lerp(REED, t))
	JungleMeshes.tube(kit, pts, radii, cols, 7, false)
	# reed joints: two small rings, the thing that says "reed" and not "stick"
	for t in [0.35, 0.68]:
		var i := int(round(t * 8.0))
		kit.torus(pts[i], radii[i] * 1.05, 0.012, REED_DARK, Basis.IDENTITY, 10, 3)
	var top := pts[8]
	# --- the top pad: cupped, notched, facing up -----------------------------------------------------
	_pad(kit, top + Vector3(0.0, 0.02, 0.0), 0.30, 0.09, 0.0)
	# the bud it holds: a glowing flame-shaped bulb with two petals leaning off it
	glow.sphere(top + Vector3(0.0, 0.15, 0.0), 0.085, BUD, Vector3(1.0, 1.35, 1.0), 12)
	for k in 3:
		var a := TAU * float(k) / 3.0
		var o := Vector3(cos(a), 0.0, sin(a))
		kit.sphere(top + o * 0.07 + Vector3(0.0, 0.10, 0.0), 0.06, PETAL, Vector3(0.55, 1.1, 0.35), 8,
			Basis(o.cross(Vector3.UP).normalized(), 0.45) * Basis(Vector3.UP, -a))
	# --- the lower pad, off to one side on its own short stalk ---------------------------------------
	var mid := pts[4]
	var side := mid + Vector3(0.20, 0.10, 0.06)
	JungleMeshes.tube(kit, PackedVector3Array([mid, mid + Vector3(0.10, 0.08, 0.03), side]),
		PackedFloat32Array([0.018, 0.015, 0.012]), PackedColorArray([REED_DARK, REED, REED]), 5, false)
	_pad(kit, side, 0.17, 0.04, 2.1)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.6, "Bud", 0.6, 0.18)
	add_light(top + Vector3(0.0, 0.16, 0.0), Color("#f0d79a"), 2.0, 5.5)
	add_ground_glow(1.2, Color("#e8cf8f"), 0.22)


## A cupped lily pad centred at `c`: a notched disc whose rim rises by `cup`, with a darker lip.
func _pad(kit: DecoKit, c: Vector3, r: float, cup: float, notch_at: float) -> void:
	var segs := 14
	var notch := 0.46
	for i in segs:
		var a0 := notch_at + notch * 0.5 + (TAU - notch) * float(i) / float(segs)
		var a1 := notch_at + notch * 0.5 + (TAU - notch) * float(i + 1) / float(segs)
		var m0 := c + Vector3(cos(a0) * r * 0.55, cup * 0.35, sin(a0) * r * 0.55)
		var m1 := c + Vector3(cos(a1) * r * 0.55, cup * 0.35, sin(a1) * r * 0.55)
		var p0 := c + Vector3(cos(a0) * r, cup, sin(a0) * r)
		var p1 := c + Vector3(cos(a1) * r, cup, sin(a1) * r)
		var shade := PAD.darkened(0.05 * float(i % 2))
		kit.triangle(c, m0, m1, shade)
		kit.quad(m0, p0, p1, m1, shade.lightened(0.04))
		var q0 := p0 + Vector3(0.0, 0.018, 0.0) + (p0 - c).normalized() * 0.012
		var q1 := p1 + Vector3(0.0, 0.018, 0.0) + (p1 - c).normalized() * 0.012
		kit.quad(p0, q0, q1, p1, PAD_RIM)
