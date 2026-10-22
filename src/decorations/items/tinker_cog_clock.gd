extends DecoItem
## Cog Clock (Tinker Workshop, Bolt's set) - a standing clock on a brass cog plinth. The face is open: a
## brass hoop with twelve bolt heads for the hours, and behind the hands two meshing cogs that really
## turn. A little brass bell on top. Watching it tick is the whole point.

const BRASS := Color("#c9a35e")
const BRASS_DARK := Color("#a5824a")
const RIVET := Color("#dcc48e")
const STEEL := Color("#9aa3b0")
const STEEL_DARK := Color("#6d7686")
const ORANGE := Color("#c79469")
const FACE := Color("#5b6475")
const C := Vector3(0.0, 1.22, 0.0)
const R := 0.3
const BIG_R := 0.13
const BIG_T := 12
const SMALL_R := 0.07
const SMALL_T := 7
## Big cog spin, rad/s; the small one follows at the tooth ratio so they stay meshed.
const SPIN := 0.35

var _big: Node3D
var _small: Node3D
var _minute: Node3D
var _hour: Node3D


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.28
	collide_height = 1.6


func _build() -> void:
	var kit := DecoKit.new()
	var metal := DecoKit.new()
	var face := Basis(Vector3.RIGHT, deg_to_rad(90.0))
	# --- cog plinth and post ---------------------------------------------------------------------
	metal.extrude(_cog_poly(0.22, 0.035, 10), 0.06,
		BRASS, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0.0, 0.03, 0.0)))
	for i in 6:
		var a := TAU * float(i) / 6.0
		_rivet(kit, Vector3(cos(a) * 0.2, 0.062, sin(a) * 0.2), Vector3.UP, 0.015)
	metal.lathe(PackedVector2Array([Vector2(0.0, 0.06), Vector2(0.09, 0.06), Vector2(0.06, 0.16), Vector2(0.045, 0.3),
		Vector2(0.04, C.y - R + 0.02), Vector2(0.0, C.y - R + 0.02)]), 12, Transform3D.IDENTITY, STEEL)
	for y in [0.3, C.y - R - 0.04]:
		metal.torus(Vector3(0.0, y, 0.0), 0.05, 0.018, BRASS_DARK, Basis.IDENTITY, 12, 4)
	# --- the clock head: a thin drum, a brass hoop, twelve bolt-head hours ---------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, -0.025), Vector2(R - 0.01, -0.025), Vector2(R - 0.01, 0.025),
		Vector2(0.0, 0.025)]), 26, Transform3D(face, C + Vector3(0.0, 0.0, 0.03)), FACE)
	metal.torus(C + Vector3(0.0, 0.0, -0.01), R, 0.035, BRASS, face, 26, 5)
	for i in 12:
		var a2 := TAU * float(i) / 12.0
		var big := i % 3 == 0
		_rivet(kit, C + Vector3(cos(a2) * R, sin(a2) * R, -0.045), Vector3.FORWARD, 0.024 if big else 0.016,
			BRASS_DARK if big else RIVET)
	# --- the bell on top -------------------------------------------------------------------------------
	metal.bar(C + Vector3(0.0, R, 0.0), C + Vector3(0.0, R + 0.08, 0.0), 0.014, STEEL_DARK, 6)
	metal.dome(C + Vector3(0.0, R + 0.07, 0.0), 0.075, BRASS, 0.9, Basis.IDENTITY, 14)
	_rivet(kit, C + Vector3(0.0, R + 0.14, 0.0), Vector3.UP, 0.018)
	add_body(kit.commit())
	add_metal(metal.commit())

	# --- two meshing cogs on the face, and the hands -------------------------------------------------------
	var big_at := C + Vector3(-0.05, 0.03, -0.015)
	var dir := Vector2(cos(deg_to_rad(-42.0)), sin(deg_to_rad(-42.0)))
	var gap := BIG_R + SMALL_R + 0.028
	var small_at := big_at + Vector3(dir.x * gap, dir.y * gap, -0.012)
	_big = _cog_part("BigCog", big_at, BIG_R, BIG_T, BRASS)
	_small = _cog_part("SmallCog", small_at, SMALL_R, SMALL_T, BRASS_DARK)
	_minute = _hand("Minute", 0.23, 0.02, ORANGE, -0.07)
	_hour = _hand("Hour", 0.15, 0.026, STEEL, -0.06)
	_hour.rotation.z = 1.9
	var cap := DecoKit.new()
	cap.rbox(C + Vector3(0.0, 0.0, -0.085), Vector3(0.05, 0.05, 0.03), 0.025, RIVET, Basis.IDENTITY, 0)
	add_metal(cap.commit(), "HandCap")
	animate()


func _animate(_time: float, delta: float) -> void:
	_big.rotate_object_local(Vector3.BACK, SPIN * delta)
	_small.rotate_object_local(Vector3.BACK, -SPIN * float(BIG_T) / float(SMALL_T) * delta)
	_minute.rotate_object_local(Vector3.BACK, -0.12 * delta)
	_hour.rotate_object_local(Vector3.BACK, -0.01 * delta)


## A face cog turning on its own pivot at `at`: toothed rim, spokes cut as a hub ring, a bolt-head axle.
func _cog_part(part: String, at: Vector3, r: float, teeth: int, col: Color) -> Node3D:
	var p := pivot(part, at)
	var g := DecoKit.new()
	g.extrude(_cog_poly(r, r * 0.22 + 0.006, teeth), 0.022, col, Transform3D.IDENTITY)
	g.torus(Vector3(0.0, 0.0, -0.012), r * 0.55, 0.01, col.darkened(0.15), Basis(Vector3.RIGHT, deg_to_rad(90.0)), 12, 3)
	g.rbox(Vector3(0.0, 0.0, -0.014), Vector3(0.03, 0.03, 0.016), 0.015, STEEL_DARK, Basis.IDENTITY, 0)
	add_metal(g.commit(), "Cog", p)
	return p


## A clock hand of length `length` on a pivot at the face centre, pointing up at rotation 0.
func _hand(part: String, length: float, width: float, col: Color, z: float) -> Node3D:
	var p := pivot(part, C + Vector3(0.0, 0.0, z))
	var h := DecoKit.new()
	h.rbox(Vector3(0.0, length * 0.42, 0.0), Vector3(width, length, 0.012), width * 0.45, col, Basis.IDENTITY, 0)
	h.extrude(PackedVector2Array([Vector2(-width * 1.1, 0.0), Vector2(width * 1.1, 0.0), Vector2(0.0, width * 2.0)]),
		0.012, col, Transform3D(Basis.IDENTITY, Vector3(0.0, length * 0.9, 0.0)))
	add_body(h.commit(), "Hand", p)
	return p


## A round bolt head (the set's rivet motif) at `p`, domed along `n`.
func _rivet(kit: DecoKit, p: Vector3, n: Vector3, r: float, col: Color = RIVET) -> void:
	kit.rbox(p, Vector3(r * 2.0, r * 0.9, r * 2.0), r, col, DecoKit.axis_basis(n), 0)


## The set's cog outline: square-shouldered trapezoid teeth, four points a tooth (a third cheaper than
## DecoKit.gear_poly, and a crisper, machined read).
static func _cog_poly(r: float, tooth: float, teeth: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var step := TAU / float(teeth)
	for i in teeth:
		var a0 := step * float(i)
		for f in [[0.0, r], [0.16, r + tooth], [0.44, r + tooth], [0.6, r]]:
			var a: float = a0 + step * float(f[0])
			out.append(Vector2(cos(a), sin(a)) * float(f[1]))
	return out
