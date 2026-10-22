extends DecoItem
## Crystal Shelf (Glowshroom Hollow, Zorp's set) - a tall pale mushroom stem with three flat cap shelves
## growing off it, each one spotted round the rim with blue gills underneath, each holding a little
## cluster of glowing crystals. A spotted cap crowns the top.

const CAP := Color("#9a82cc")
const CAP_DARK := Color("#7a66ad")
const STEM := Color("#dcd3e3")
const STEM_DARK := Color("#bdb2cc")
const SPOT := Color("#ece4f2")
const GILL := Color("#7fc8f0")
const CRYSTAL_A := Color("#7fc8f0")
const CRYSTAL_B := Color("#a58fe0")
const TOP := 1.4
## Shelves: height, radius, sideways offset of the shelf centre from the stem.
const SHELVES := [[0.42, 0.32, 0.05], [0.8, 0.27, -0.05], [1.12, 0.21, 0.04]]


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.34
	collide_height = 1.55


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	# --- the stem ----------------------------------------------------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.19, 0.035), Vector2(0.11, 0.1), Vector2(0.075, 0.22),
		Vector2(0.065, 0.7), Vector2(0.055, 1.2), Vector2(0.06, TOP), Vector2(0.0, TOP)]), 14, Transform3D.IDENTITY, STEM)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.9
		kit.rbox(Vector3(cos(a) * 0.17, 0.02, sin(a) * 0.17), Vector3(0.15, 0.055, 0.1), 0.045, STEM_DARK, Basis(Vector3.UP, -a), 0)
	# --- three cap shelves, each with a crystal cluster ----------------------------------------------------
	for si in SHELVES.size():
		var s: Array = SHELVES[si]
		var y: float = s[0]
		var r: float = s[1]
		var c := Vector3(float(s[2]), y, 0.0)
		kit.lathe(PackedVector2Array([Vector2(0.05, -0.03), Vector2(r * 0.9, -0.04), Vector2(r, -0.012), Vector2(r * 0.97, 0.018),
			Vector2(r * 0.88, 0.032), Vector2(0.0, 0.034)]), 18, Transform3D(Basis.IDENTITY, c), CAP if si != 1 else CAP_DARK)
		glow.lathe(PackedVector2Array([Vector2(0.07, -0.033), Vector2(r * 0.5, -0.04), Vector2(r * 0.88, -0.044)]), 18,
			Transform3D(Basis.IDENTITY, c), GILL)
		var nsp := 5 - si
		for k in nsp:
			var ph := TAU * float(k) / float(nsp) + float(si) * 0.6
			var o := Vector3(cos(ph), 0.0, sin(ph))
			var sp := r * 0.12
			kit.rbox(c + o * r * 0.955 + Vector3(0.0, 0.012, 0.0), Vector3(sp * 2.0, sp * 0.5, sp * 2.0), sp, SPOT,
				DecoKit.axis_basis((o + Vector3(0.0, 0.9, 0.0)).normalized()), 0)
		# crystals stand on the front half of the shelf, where the camera sees them
		var cl := c + Vector3(-float(s[2]) * 1.6 + r * 0.25 * (1.0 if si % 2 == 0 else -1.0), 0.034, -r * 0.45)
		_crystal(glow, cl, 0.065, 0.25 - 0.04 * float(si), 0.0, 0.0, CRYSTAL_A if si % 2 == 0 else CRYSTAL_B)
		_crystal(glow, cl + Vector3(0.075, 0.0, 0.035), 0.045, 0.16, 0.35, 0.3, CRYSTAL_B if si % 2 == 0 else CRYSTAL_A)
		_crystal(glow, cl + Vector3(-0.07, 0.0, 0.03), 0.04, 0.12, 0.4, 3.4, CRYSTAL_A)
	# --- the crowning cap -----------------------------------------------------------------------------------
	_cap(kit, glow, Vector3(0.0, TOP - 0.01, 0.0), 0.2, 0.14, CAP, 6, 1.1, 18)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.3, "Crystals", 0.9, 0.3)
	# No OmniLight on purpose: at night a lamp light turns nearby crochet (toon) surfaces black in stitch-row
	# stripes - measured 2026-10-21 on the existing Reading Lamp and Cosmic Mushrooms too, both renderers, and
	# gone the moment the light is removed. The emissive parts and the ground pool carry the night glow.
	add_ground_glow(1.0, Color("#7fc8f0"), 0.18)


## A faceted crystal point standing on `p`: a six-sided prism and its tip (crystal facets are the one place
## flat shading is allowed).
func _crystal(k: DecoKit, p: Vector3, r: float, h: float, tilt: float, az: float, col: Color) -> void:
	k.lathe(PackedVector2Array([Vector2(r, 0.0), Vector2(r * 0.85, h), Vector2(0.0, h + r * 1.6)]), 8,
		Transform3D(DecoKit.tilt_basis(tilt, az), p), col, false)


## A spotted mushroom cap (the set's motif) whose rim sits at `base`, with glowing blue gills under it.
func _cap(kit: DecoKit, glow: DecoKit, base: Vector3, r: float, h: float, col: Color, spots: int, seed_a: float, segs: int) -> void:
	var prof := PackedVector2Array([Vector2(r * 0.96, -h * 0.08)])
	for i in 7:
		var a := PI * 0.5 * float(i) / 6.0
		prof.append(Vector2(cos(a) * r, sin(a) * h))
	kit.lathe(prof, segs, Transform3D(Basis.IDENTITY, base), col)
	glow.lathe(PackedVector2Array([Vector2(r * 0.22, 0.0), Vector2(r * 0.6, -h * 0.05), Vector2(r * 0.95, -h * 0.08)]), segs,
		Transform3D(Basis.IDENTITY, base), GILL)
	for k in spots:
		var th := lerpf(0.3, 1.1, fmod(float(k) * 0.618 + 0.2, 1.0))
		var ph := seed_a + float(k) * 2.39996
		var n := Vector3(sin(th) * cos(ph) / r, cos(th) / h, sin(th) * sin(ph) / r).normalized()
		var p := base + Vector3(r * sin(th) * cos(ph), h * cos(th), r * sin(th) * sin(ph))
		var s := r * 0.16
		kit.rbox(p, Vector3(s * 2.0, s * 0.55, s * 2.0), s, SPOT, DecoKit.axis_basis(n), 0)
