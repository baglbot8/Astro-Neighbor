extends DecoItem
## Terracotta Bench (Long Dusk set, Fen) - a long low bench of warm clay that curves gently round
## whoever sits on it, standing on three pot-bellied clay feet, with rolled ends and a woven seat in
## slate and sand. The two end feet wear the set's woven band.

const CLAY := Color("#ba8d76")
const CLAY_DARK := Color("#9c7a68")
const CLAY_LIGHT := Color("#d2a88e")
const SAND := Color("#e2c6a0")
const SLATE := Color("#7889a3")
## The bench bends round a circle this far behind its front (it hugs the viewer, ends come forward).
const ARC_R := 2.2
const HALF_ANGLE := 0.34
const SEAT_Y := 0.27


func _init() -> void:
	footprint = 0.85
	collide_radius = 0.6
	collide_height = 0.5


## Point on the bench's centre line at arc angle `t`, and the basis that runs along it there.
func _arc(t: float) -> Vector3:
	return Vector3(ARC_R * sin(t), 0.0, -ARC_R + ARC_R * cos(t) + 0.06)


func _build() -> void:
	var kit := DecoKit.new()
	# --- three clay feet: flared foot, pinched waist, flared top (like little pots) -----------------
	for t in [-HALF_ANGLE * 0.82, 0.0, HALF_ANGLE * 0.82]:
		var p := _arc(t)
		kit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.15, 0.0), Vector2(0.15, 0.03), Vector2(0.1, 0.1), Vector2(0.11, 0.17),
			Vector2(0.15, 0.22), Vector2(0.0, 0.22)]), 14, Transform3D(Basis.IDENTITY, p), CLAY_DARK)
		if absf(t) > 0.01:
			_weave_ring(kit, p + Vector3(0.0, 0.115, 0.0), 0.105, 0.055, 8)
	# --- the seat slab, in five gently turned segments that overlap into one curve ---------------------
	var segs := 5
	for i in segs:
		var t2 := lerpf(-HALF_ANGLE, HALF_ANGLE, (float(i) + 0.5) / float(segs))
		var b := Basis(Vector3.UP, t2)
		var seg_w := 2.0 * HALF_ANGLE * ARC_R / float(segs) + 0.05
		kit.rbox(_arc(t2) + Vector3(0.0, SEAT_Y - 0.03, 0.0), Vector3(seg_w, 0.09, 0.44), 0.035, CLAY, b, 1)
		# woven seat: three tabs deep, alternately over and under, slate and sand
		for k in 3:
			var over := (i + k) % 2 == 0
			var off := b * Vector3(0.0, 0.0, (float(k) - 1.0) * 0.125)
			var col: Color = SLATE if over else SAND
			kit.extrude(_rect(seg_w * 0.9, 0.115), 0.035 if over else 0.028, col,
				Transform3D(b * Basis(Vector3.RIGHT, deg_to_rad(-90.0)), _arc(t2) + off + Vector3(0.0, SEAT_Y + 0.05 + (0.006 if over else 0.0), 0.0)))
	# --- rolled ends: a clay scroll at each end of the seat -------------------------------------------
	for s in [-1.0, 1.0]:
		var te: float = s * HALF_ANGLE
		var be := Basis(Vector3.UP, te)
		var pe := _arc(te) + be * Vector3(s * 0.03, SEAT_Y + 0.03, 0.0)
		kit.tube(pe + be * Vector3(0.0, 0.0, -0.21), pe + be * Vector3(0.0, 0.0, 0.21), 0.062, CLAY_LIGHT, 12, 2)
		kit.torus(pe + be * Vector3(0.0, 0.0, -0.15), 0.063, 0.013, CLAY_DARK, be * Basis(Vector3.RIGHT, deg_to_rad(90.0)), 10, 3)
		kit.torus(pe + be * Vector3(0.0, 0.0, 0.15), 0.063, 0.013, CLAY_DARK, be * Basis(Vector3.RIGHT, deg_to_rad(90.0)), 10, 3)
	add_body(kit.commit())


## LONG DUSK MOTIF - the woven band: over-under tabs in slate and sand round a clay curve, held between
## two dark clay cords. Every piece in the set wears one.
func _weave_ring(kit: DecoKit, c: Vector3, r: float, h: float, n: int) -> void:
	kit.torus(c - Vector3(0.0, h * 0.5, 0.0), r, h * 0.13, CLAY_DARK, Basis.IDENTITY, int(float(n) * 1.5), 3)
	kit.torus(c + Vector3(0.0, h * 0.5, 0.0), r, h * 0.13, CLAY_DARK, Basis.IDENTITY, int(float(n) * 1.5), 3)
	for i in n:
		var a := TAU * (float(i) + 0.5) / float(n)
		var o := Vector3(cos(a), 0.0, sin(a))
		var lift := h * 0.14 * (1.0 if i % 2 == 0 else -1.0)
		var col: Color = SLATE if i % 2 == 0 else SAND
		kit.rbox(c + o * r + Vector3(0.0, lift, 0.0), Vector3(TAU * r / float(n) * 1.02, h * 0.62, h * 0.3), h * 0.1,
			col, Basis(Vector3.UP, -a - PI * 0.5), 0)


## A plain rectangle polygon, w x d, for the flat woven tabs (12 triangles extruded, a third of a
## rounded one, and the weave reads as strips anyway).
static func _rect(w: float, d: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w * 0.5, -d * 0.5), Vector2(w * 0.5, -d * 0.5), Vector2(w * 0.5, d * 0.5),
		Vector2(-w * 0.5, d * 0.5)])
