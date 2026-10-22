extends DecoItem
## Long-Shadow Sundial (Long Dusk set bonus, Fen) - a clay pedestal wearing two woven bands, topped by a
## sand dial with slate hour marks and a clay gnomon. A tiny glowing sun drifts slowly round the dial,
## but the long slate shadow never follows it: it always points to the little dusk mark, a half-sun
## sinking into a slate horizon, and only breathes longer and shorter as the sun goes by.

const CLAY := Color("#ba8d76")
const CLAY_DARK := Color("#9c7a68")
const CLAY_LIGHT := Color("#d2a88e")
const SAND := Color("#e2c6a0")
const SLATE := Color("#7889a3")
const SLATE_DARK := Color("#64738c")
const SUNSET := Color("#d99d78")
const SUN := Color("#f1c48a")
const DIAL_Y := 0.75
## Dusk lies to the front-left: the angle (around +Y, from +X towards +Z) the shadow points along.
const DUSK_A := 4.19
const SHADOW_LEN := 0.21

var _shadow: Node3D
var _sun: Node3D
var _bead: Node3D


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.3
	collide_height = 0.85


func _build() -> void:
	var kit := DecoKit.new()
	# --- the pedestal: a clay column with a flared foot and a wide top ---------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.26, 0.0), Vector2(0.25, 0.06), Vector2(0.17, 0.1), Vector2(0.12, 0.22),
		Vector2(0.105, 0.42), Vector2(0.12, 0.55), Vector2(0.2, 0.64), Vector2(0.25, 0.69), Vector2(0.24, 0.715),
		Vector2(0.0, 0.715)]), 20, Transform3D.IDENTITY, CLAY)
	_weave_ring(kit, Vector3(0.0, 0.32, 0.0), 0.108, 0.07, 10)
	_weave_ring(kit, Vector3(0.0, 0.08, 0.0), 0.205, 0.05, 12)
	# --- the dial plate, hour marks, the gnomon --------------------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.705), Vector2(0.29, 0.705), Vector2(0.3, 0.725), Vector2(0.285, DIAL_Y),
		Vector2(0.0, DIAL_Y)]), 22, Transform3D.IDENTITY, SAND)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var o := Vector3(cos(a), 0.0, sin(a))
		var long_mark := i % 3 == 0
		if absf(wrapf(a - DUSK_A, -PI, PI)) < 0.3:
			continue  # the dusk mark stands here
		kit.rbox(o * 0.245 + Vector3(0.0, DIAL_Y, 0.0), Vector3(0.012, 0.012, 0.05 if long_mark else 0.03), 0.004,
			SLATE_DARK, Basis(Vector3.UP, -a + PI * 0.5), 0)
	var dusk := Vector3(cos(DUSK_A), 0.0, sin(DUSK_A))
	var face := Basis(Vector3.UP, -DUSK_A)  # +X now runs towards dusk
	# gnomon: a clay fin, high end turned away from dusk so its shadow falls that way
	kit.extrude(PackedVector2Array([Vector2(-0.16, 0.0), Vector2(0.03, 0.0), Vector2(-0.16, 0.15)]), 0.022, CLAY_DARK,
		Transform3D(face, Vector3(0.0, DIAL_Y, 0.0)))
	# the dusk mark's horizon: a slate bar standing on the rim, the half-sun sinks behind it
	kit.rbox(dusk * 0.262 + Vector3(0.0, DIAL_Y + 0.012, 0.0), Vector3(0.03, 0.026, 0.2), 0.008, SLATE_DARK, face, 1)
	add_body(kit.commit())

	# --- the long shadow, on its own pivot so it can breathe -------------------------------------------
	_shadow = pivot("Shadow", Vector3(0.0, DIAL_Y + 0.003, 0.0))
	_shadow.basis = face
	var sh := DecoKit.new()
	sh.quad(Vector3(0.0, 0.0, -0.022), Vector3(0.0, 0.0, 0.022), Vector3(SHADOW_LEN, 0.0, 0.006),
		Vector3(SHADOW_LEN, 0.0, -0.006), SLATE_DARK, true)
	add_body(sh.commit(), "LongShadow", _shadow)

	# --- glowing bits: the half-sun dusk mark, and the little sun that drifts round ---------------------
	var g := DecoKit.new()
	var half := PackedVector2Array()
	for i in 9:
		var t := PI * float(i) / 8.0
		half.append(Vector2(cos(t) * 0.075, sin(t) * 0.075))
	# standing up on the rim, facing the gnomon, its straight edge just inside the horizon bar
	g.extrude(half, 0.014, SUNSET, Transform3D(face * Basis(Vector3.UP, PI * 0.5), dusk * 0.27 + Vector3(0.0, DIAL_Y + 0.016, 0.0)))
	add_glow(g.commit(), 1.6, "DuskMark", 0.5, 0.25)
	_sun = pivot("SunOrbit", Vector3(0.0, DIAL_Y, 0.0))
	_bead = pivot("Sun", Vector3(0.36, 0.26, 0.0), _sun)
	var sb := DecoKit.new()
	sb.sphere(Vector3.ZERO, 0.045, SUN, Vector3.ONE, 10)
	for i in 8:
		var a2 := TAU * float(i) / 8.0
		var ray := Vector3(cos(a2), sin(a2), 0.0)
		sb.cone(ray * 0.052, 0.014, 0.0, 0.035, SUN, DecoKit.axis_basis(ray), 6)
	add_glow(sb.commit(), 2.2, "SunBead", 1.2, 0.2, 0.0, _bead)
	animate()


func _animate(t: float, _delta: float) -> void:
	_sun.rotation.y = t * 0.22
	_bead.position.y = 0.26 + sin(t * 1.3) * 0.025
	_bead.rotation.y = -t * 0.22  # the rays keep facing the same way as it goes round
	# the shadow never turns; it just stretches a little as the sun swings past the far side
	var away := 0.5 + 0.5 * cos(t * 0.22 - (DUSK_A + PI))
	_shadow.scale = Vector3(0.85 + 0.25 * away, 1.0, 1.0)


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
