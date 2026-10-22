extends DecoItem
## Glow Pool (Glowshroom Hollow, Zorp's set) - a small round pool of glowing blue water in a slate stone
## basin, like a piece of Zorp's rivers. Spotted mushrooms crowd one side of the rim, two flat little caps
## float on the water and slowly turn, and a few glowing spores rise off it.

const CAP := Color("#9a82cc")
const CAP_DARK := Color("#7a66ad")
const STEM := Color("#dcd3e3")
const SPOT := Color("#ece4f2")
const GILL := Color("#7fc8f0")
const WATER := Color("#6fb8e6")
const STONE := Color("#77729a")
const STONE_DARK := Color("#5f5a82")
const WATER_Y := 0.13
const RIM_R := 0.83

var _float: Node3D


func _init() -> void:
	footprint = 1.0
	collide_radius = 0.82
	collide_height = 0.25


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	# --- the stone basin -----------------------------------------------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.9, 0.0), Vector2(0.95, 0.08), Vector2(0.92, 0.16), Vector2(RIM_R, 0.2),
		Vector2(0.75, 0.17), Vector2(0.72, 0.1), Vector2(0.0, 0.1)]), 30, Transform3D.IDENTITY, STONE)
	# rim stones
	for st in [[0.4, 0.13, 1.3], [1.5, 0.1, 1.5], [2.5, 0.14, 1.2], [4.0, 0.11, 1.4], [5.2, 0.12, 1.3]]:
		var a: float = st[0]
		var r: float = st[1]
		kit.sphere(Vector3(cos(a) * RIM_R, 0.19, sin(a) * RIM_R), r, STONE_DARK, Vector3(float(st[2]), 0.55, 1.0), 10,
			Basis(Vector3.UP, -a))
	# --- mushrooms crowding the back rim ---------------------------------------------------------------------
	for m in [[2.0, 0.11, 0.24, 0.3], [2.35, 0.075, 0.15, 1.7], [1.7, 0.06, 0.11, 3.1]]:
		var a2: float = m[0]
		var b := Vector3(cos(a2) * (RIM_R + 0.04), 0.17, sin(a2) * (RIM_R + 0.04))
		var r2: float = m[1]
		var h: float = m[2]
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r2 * 0.45, 0.0), Vector2(r2 * 0.32, h * 0.6), Vector2(r2 * 0.3, h),
			Vector2(0.0, h)]), 8, Transform3D(Basis.IDENTITY, b), STEM)
		_cap(kit, glow, b + Vector3(0.0, h, 0.0), r2, r2 * 0.7, CAP, 4 if r2 > 0.1 else 2, m[3], 14 if r2 > 0.1 else 10)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.0, "Gills", 0.5, 0.25)

	# --- the water: one glowing disc that breathes slowly -------------------------------------------------------
	var water := DecoKit.new()
	water.lathe(PackedVector2Array([Vector2(0.74, WATER_Y), Vector2(0.0, WATER_Y)]), 30, Transform3D.IDENTITY, WATER)
	add_glow(water.commit(), 1.9, "Water", 0.45, 0.2)

	# --- two flat caps floating on it, slowly going round ---------------------------------------------------------
	_float = pivot("Float")
	var fk := DecoKit.new()
	var fg := DecoKit.new()
	_cap(fk, fg, Vector3(0.3, WATER_Y + 0.005, -0.12), 0.12, 0.035, CAP_DARK, 3, 0.9, 12)
	_cap(fk, fg, Vector3(-0.28, WATER_Y + 0.005, 0.2), 0.09, 0.028, CAP, 2, 2.2, 10)
	add_body(fk.commit(), "Lily", _float)
	add_particles(8, 3.2, Vector3(0.0, WATER_Y + 0.05, 0.0), Color("#8fd4f5"), 0.06, 0.22, 25.0, 0.03, 0.5)
	# No OmniLight on purpose: at night a lamp light turns nearby crochet (toon) surfaces black in stitch-row
	# stripes - measured 2026-10-21 on the existing Reading Lamp and Cosmic Mushrooms too, both renderers, and
	# gone the moment the light is removed. The emissive parts and the ground pool carry the night glow.
	add_ground_glow(1.9, Color("#7fc8f0"), 0.22)
	animate()


func _animate(time: float, _delta: float) -> void:
	_float.rotation.y = time * 0.07


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
