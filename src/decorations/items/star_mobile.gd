extends DecoItem
## Star Mobile (cozy home set) - a nursery mobile grown to garden size: a cream pole with a slowly turning
## crown of four bowed arms, and from them hang a big star, a crescent moon, a ringed planet, a cloud and
## two small stars, each on its own string at its own height. The stars and the moon glow at night.

const POLE := Color("#e3d7bc")
const POLE_DARK := Color("#bfae8a")
const BASE := Color("#93775a")
const ACCENT := Color("#7fb5ad")
const ARM := Color("#b89a74")
const STRING := Color("#6f6a80")
const STAR := Color("#e3c877")
const MOON := Color("#ead9a8")
const PLANET := Color("#a595cf")
const RING := Color("#d98f9c")
const CLOUD := Color("#dfe4ea")
const HUB_Y := 1.92
const ARM_R := 0.52

var _crown: Node3D


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.3
	collide_height = 2.0


func _build() -> void:
	var kit := DecoKit.new()
	# --- a stepped wooden foot and the pole ----------------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.3, 0.0), Vector2(0.28, 0.06), Vector2(0.18, 0.09), Vector2(0.17, 0.16),
		Vector2(0.08, 0.2), Vector2(0.0, 0.2)]), 18, Transform3D.IDENTITY, BASE)
	kit.torus(Vector3(0.0, 0.06, 0.0), 0.28, 0.03, ACCENT, Basis.IDENTITY, 18, 4)
	kit.cone(Vector3(0.0, 0.18, 0.0), 0.06, 0.04, HUB_Y - 0.18, POLE, Basis.IDENTITY, 12)
	kit.torus(Vector3(0.0, 0.55, 0.0), 0.062, 0.026, ACCENT, Basis.IDENTITY, 14, 4)
	kit.torus(Vector3(0.0, 1.3, 0.0), 0.05, 0.022, POLE_DARK, Basis.IDENTITY, 14, 4)
	add_body(kit.commit())

	# --- the turning crown: hub, finial, four bowed arms ------------------------------------------------
	_crown = pivot("Crown", Vector3(0.0, HUB_Y, 0.0))
	var cr := DecoKit.new()
	cr.sphere(Vector3.ZERO, 0.09, ACCENT, Vector3(1.0, 0.8, 1.0), 10)
	cr.cone(Vector3(0.0, 0.05, 0.0), 0.04, 0.0, 0.16, POLE_DARK, Basis.IDENTITY, 8)
	var tips: Array[Vector3] = []
	var mids: Array[Vector3] = []
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		var o := Vector3(cos(a), 0.0, sin(a))
		var pts := PackedVector3Array()
		for k in 6:
			var t := float(k) / 5.0
			pts.append(o * ARM_R * t + Vector3(0.0, 0.1 * sin(t * PI) - 0.06 * t * t, 0.0))
		JungleMeshes.tube(cr, pts, PackedFloat32Array([0.022, 0.02, 0.018, 0.016, 0.014, 0.012]), PackedColorArray([ARM]), 6, false)
		cr.sphere(pts[5], 0.03, ACCENT, Vector3.ONE, 6)
		tips.append(pts[5])
		mids.append(pts[3])
	var glow := DecoKit.new()
	# tip 0: the big star
	var p := _hang(cr, tips[0], 0.42)
	glow.extrude(DecoKit.star_poly(0.15, 0.068, 5), 0.06, STAR, Transform3D(Basis(Vector3.UP, 0.4), p))
	# tip 1: the crescent moon
	p = _hang(cr, tips[1], 0.62)
	glow.extrude(DecoKit.crescent_poly(0.14, 0.115, 0.085, 10), 0.07, MOON,
		Transform3D(Basis(Vector3.UP, -0.9) * Basis(Vector3.FORWARD, deg_to_rad(-24.0)), p))
	# tip 2: the ringed planet
	p = _hang(cr, tips[2], 0.5)
	cr.sphere(p, 0.105, PLANET, Vector3.ONE, 12)
	cr.torus(p, 0.16, 0.018, RING, Basis(Vector3.RIGHT, 0.45) * Basis(Vector3.BACK, 0.25), 18, 3)
	# tip 3: the cloud
	p = _hang(cr, tips[3], 0.74)
	cr.sphere(p, 0.085, CLOUD, Vector3(1.0, 0.85, 0.8), 8)
	cr.sphere(p + Vector3(0.09, -0.02, 0.0), 0.065, CLOUD, Vector3(1.0, 0.85, 0.8), 8)
	cr.sphere(p + Vector3(-0.09, -0.025, 0.0), 0.06, CLOUD, Vector3(1.0, 0.85, 0.8), 8)
	# two small stars from the arm middles
	for k in 2:
		p = _hang(cr, mids[k * 2 + 1], 0.86 - 0.4 * float(k))
		glow.extrude(DecoKit.star_poly(0.085, 0.04, 5), 0.04, STAR.lightened(0.15), Transform3D(Basis(Vector3.UP, 1.2 + float(k)), p))
	add_body(cr.commit(), "CrownBody", _crown)
	add_glow(glow.commit(), 2.2, "Charms", 0.8, 0.2, 0.0, _crown)
	# No OmniLight: anywhere inside the crown is within half a metre of the pole, and toon_soft's light()
	# renders a surface that close to an omni as navy-black bands (first build, night frame). The charms
	# are emissive and the ground pool carries the glow.
	add_ground_glow(1.4, Color("#e3cd8f"), 0.24)
	animate()


## Hangs a string of length `l` from `from` (crown space); returns where the charm goes.
func _hang(kit: DecoKit, from: Vector3, l: float) -> Vector3:
	kit.bar(from, from + Vector3(0.0, -l + 0.06, 0.0), 0.006, STRING, 6)
	return from + Vector3(0.0, -l, 0.0)


func _animate(t: float, _delta: float) -> void:
	_crown.rotation.y = t * 0.3
	_crown.rotation.z = sin(t * 0.7) * deg_to_rad(1.5)
