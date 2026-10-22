extends DecoItem
## River-Stone Table (Glowshroom Hollow, Zorp's set) - a smooth oval river stone for a top, a thin
## glowing blue stream winding across it, set on a fat flared mushroom stem with a skirt. Two little
## spotted mushrooms sprout at its foot. Waist-high next to the astronaut.

const CAP := Color("#9a82cc")
const STEM := Color("#dcd3e3")
const STEM_DARK := Color("#bdb2cc")
const SPOT := Color("#ece4f2")
const GILL := Color("#7fc8f0")
const STREAM := Color("#7fc8f0")
const STONE := Color("#77729a")
const STONE_DARK := Color("#5f5a82")
const TOP_Y := 0.6
const OVAL := 0.72


func _init() -> void:
	footprint = 0.8
	collide_radius = 0.5
	collide_height = 0.62


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	var oval := Transform3D(Basis.from_scale(Vector3(1.0, 1.0, OVAL)), Vector3.ZERO)
	# --- the stone top: flat on top, a soft rounded edge ------------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, TOP_Y - 0.075), Vector2(0.4, TOP_Y - 0.075), Vector2(0.47, TOP_Y - 0.055),
		Vector2(0.5, TOP_Y - 0.03), Vector2(0.48, TOP_Y - 0.008), Vector2(0.43, TOP_Y), Vector2(0.0, TOP_Y)]), 26, oval, STONE)
	# blue gills under the rim, like a cap
	glow.lathe(PackedVector2Array([Vector2(0.16, TOP_Y - 0.078), Vector2(0.3, TOP_Y - 0.08), Vector2(0.42, TOP_Y - 0.074)]), 22,
		oval, GILL)
	# --- the stream: a meander inlaid across the top, glowing, with two pebbles on its banks ---------------
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := 18
	for i in n + 1:
		var t := float(i) / float(n)
		var x := lerpf(-0.4, 0.4, t)
		var edge := sqrt(maxf(0.0, 1.0 - pow(x / 0.43, 2.0)))
		var z := 0.07 * sin(t * TAU * 1.25 + 0.4) * edge
		var w := 0.03 * (0.55 + 0.45 * edge)
		left.append(Vector2(x, z + w))
		right.append(Vector2(x, z - w))
	var poly := PackedVector2Array()
	for p in left:
		poly.append(p)
	for i2 in range(right.size() - 1, -1, -1):
		poly.append(right[i2])
	glow.extrude(poly, 0.006, STREAM, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(90.0)), Vector3(0.0, TOP_Y + 0.003, 0.0)))
	kit.sphere(Vector3(-0.16, TOP_Y + 0.008, 0.1), 0.04, STONE_DARK, Vector3(1.2, 0.45, 1.0), 8)
	kit.sphere(Vector3(0.2, TOP_Y + 0.008, -0.12), 0.032, STEM_DARK, Vector3(1.3, 0.45, 1.0), 8)
	# --- the stem with a skirt -----------------------------------------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.24, 0.0), Vector2(0.23, 0.04), Vector2(0.15, 0.1), Vector2(0.105, 0.2),
		Vector2(0.095, 0.36), Vector2(0.11, TOP_Y - 0.12), Vector2(0.17, TOP_Y - 0.07), Vector2(0.0, TOP_Y - 0.07)]), 18,
		Transform3D.IDENTITY, STEM)
	kit.lathe(PackedVector2Array([Vector2(0.1, 0.4), Vector2(0.16, 0.35), Vector2(0.175, 0.345), Vector2(0.165, 0.37),
		Vector2(0.1, 0.42)]), 16, Transform3D.IDENTITY, STEM_DARK)
	# --- two little mushrooms at the foot ---------------------------------------------------------------------
	for m in [[Vector3(0.27, 0.0, -0.14), 0.075, 0.13, 0.5], [Vector3(-0.23, 0.0, -0.2), 0.06, 0.1, 2.1]]:
		var b: Vector3 = m[0]
		var r: float = m[1]
		var h: float = m[2]
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.45, 0.0), Vector2(r * 0.32, h * 0.6), Vector2(r * 0.3, h),
			Vector2(0.0, h)]), 8, Transform3D(Basis.IDENTITY, b), STEM)
		_cap(kit, glow, b + Vector3(0.0, h, 0.0), r, r * 0.7, CAP, 3, m[3], 12)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.2, "Stream", 0.7, 0.25)
	# No OmniLight on purpose: at night a lamp light turns nearby crochet (toon) surfaces black in stitch-row
	# stripes - measured 2026-10-21 on the existing Reading Lamp and Cosmic Mushrooms too, both renderers, and
	# gone the moment the light is removed. The emissive parts and the ground pool carry the night glow.
	add_ground_glow(1.0, Color("#7fc8f0"), 0.16)


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
