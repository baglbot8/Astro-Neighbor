extends DecoItem
## Dusk Lantern (Long Dusk set, Fen) - a round clay gourd-lantern pricked all over with little holes,
## standing on a low flared clay stand. The set's woven band runs round its belly; a clay loop handle
## sits on top. At night every hole glows and it spills warm dots of light on the ground.

const CLAY := Color("#ba8d76")
const CLAY_DARK := Color("#9c7a68")
const CLAY_LIGHT := Color("#d2a88e")
const SAND := Color("#e2c6a0")
const SLATE := Color("#7889a3")
const HOLE := Color("#f0b878")
const FLAME := Color("#f3c58e")
const LIGHT := Color("#e8a85c")
## Lantern body: bottom of the gourd and its widest point.
const BODY_Y := 0.36
const BELLY_Y := 0.6
const BELLY_R := 0.21


func _init() -> void:
	footprint = 0.45
	collide_radius = 0.26
	collide_height = 1.0


func _build() -> void:
	var kit := DecoKit.new()
	# --- the stand: a flared foot, a pinched waist, a dished top -------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.23, 0.0), Vector2(0.22, 0.05), Vector2(0.13, 0.12), Vector2(0.09, 0.22),
		Vector2(0.12, 0.31), Vector2(0.18, 0.35), Vector2(0.17, 0.375), Vector2(0.0, 0.37)]), 18, Transform3D.IDENTITY, CLAY_DARK)
	# --- the gourd body, open at the top ------------------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, BODY_Y), Vector2(0.11, BODY_Y), Vector2(0.18, BODY_Y + 0.08), Vector2(BELLY_R, BELLY_Y),
		Vector2(0.19, BELLY_Y + 0.12), Vector2(0.13, BELLY_Y + 0.21), Vector2(0.09, BELLY_Y + 0.26),
		Vector2(0.105, BELLY_Y + 0.29), Vector2(0.09, BELLY_Y + 0.305), Vector2(0.075, BELLY_Y + 0.3)]),
		20, Transform3D.IDENTITY, CLAY)
	_weave_ring(kit, Vector3(0.0, BELLY_Y, 0.0), BELLY_R, 0.07, 14)
	# loop handle over the mouth, and a little clay bead on it
	kit.torus(Vector3(0.0, BELLY_Y + 0.37, 0.0), 0.09, 0.016, CLAY_DARK, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 14, 4)
	kit.sphere(Vector3(0.0, BELLY_Y + 0.465, 0.0), 0.028, CLAY_LIGHT, Vector3.ONE, 8)
	add_body(kit.commit())

	# --- the holes: rings of glowing dots above and below the band, and the glow in the mouth --------
	var glow := DecoKit.new()
	_hole_ring(glow, BODY_Y + 0.11, 0.185, 9, 0.0, 0.03)
	_hole_ring(glow, BELLY_Y + 0.09, 0.197, 10, 0.3, 0.032)
	_hole_ring(glow, BELLY_Y + 0.17, 0.155, 8, 0.0, 0.025)
	glow.disc(Vector3(0.0, BELLY_Y + 0.29, 0.0), 0.078, FLAME, Basis.IDENTITY, 12)
	add_glow(glow.commit(), 2.6, "Holes", 0.7, 0.18)
	add_light(Vector3(0.0, BELLY_Y + 0.05, 0.0), LIGHT, 2.2, 5.5)
	add_ground_glow(1.25, LIGHT, 0.3)


## A ring of `n` glowing holes at height `y` on a body of radius `r` there (discs facing outward).
func _hole_ring(kit: DecoKit, y: float, r: float, n: int, phase: float, size: float) -> void:
	for i in n:
		var a := TAU * (float(i) + phase) / float(n)
		var o := Vector3(cos(a), 0.0, sin(a))
		# disc faces +Y; turn +Y to the outward normal
		kit.disc(Vector3(0.0, y, 0.0) + o * (r + 0.004), size, HOLE, DecoKit.axis_basis(o), 6)


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
