extends DecoItem
## Gear Stool (Tinker Workshop, Bolt's set) - a fat brass cog for a seat with a round leather cushion
## buttoned on top, three splayed steel legs joined by a brace ring, and a ring of round bolt heads around
## the cog. Knee-high next to the astronaut.
##
## TINKER GRAMMAR (shared by all seven pieces): brass cogs + steel tube frames, round bolt heads as
## rivets on every joint, warm orange/leather accents, one warm bulb where there is a light.

const BRASS := Color("#c9a35e")
const BRASS_DARK := Color("#a5824a")
const RIVET := Color("#dcc48e")
const STEEL := Color("#9aa3b0")
const STEEL_DARK := Color("#6d7686")
const LEATHER := Color("#ad7862")
const SEAT_Y := 0.31


func _init() -> void:
	footprint = 0.45
	collide_radius = 0.24
	collide_height = 0.45


func _build() -> void:
	var kit := DecoKit.new()
	var metal := DecoKit.new()
	# --- three splayed legs, brass feet, a brace ring --------------------------------------------
	for i in 3:
		var a := TAU * float(i) / 3.0 + PI / 2.0
		var o := Vector3(cos(a), 0.0, sin(a))
		metal.tube(o * 0.11 + Vector3(0.0, SEAT_Y, 0.0), o * 0.2 + Vector3(0.0, 0.03, 0.0), 0.024, STEEL, 8)
		kit.sphere(o * 0.205 + Vector3(0.0, 0.025, 0.0), 0.034, BRASS_DARK, Vector3(1.0, 0.7, 1.0), 8)
		_rivet(kit, o * 0.153 + Vector3(0.0, 0.135, 0.0) + o * 0.02, o, 0.016)
	metal.torus(Vector3(0.0, 0.135, 0.0), 0.155, 0.013, STEEL_DARK, Basis.IDENTITY, 16, 4)
	# --- the cog seat, its hub underneath ---------------------------------------------------------
	metal.extrude(_cog_poly(0.19, 0.04, 10), 0.07,
		BRASS, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0.0, SEAT_Y + 0.035, 0.0)))
	metal.lathe(PackedVector2Array([Vector2(0.0, SEAT_Y - 0.03), Vector2(0.11, SEAT_Y - 0.03),
		Vector2(0.12, SEAT_Y + 0.0), Vector2(0.0, SEAT_Y + 0.0)]), 14, Transform3D.IDENTITY, STEEL_DARK)
	# bolt heads around the cog, between the cushion and the teeth
	for i in 10:
		var a2 := TAU * (float(i) + 0.5) / 10.0
		_rivet(kit, Vector3(cos(a2) * 0.172, SEAT_Y + 0.07, sin(a2) * 0.172), Vector3.UP, 0.014)
	# --- the cushion: a fat leather puck with piping and a centre button ---------------------------
	kit.sphere(Vector3(0.0, SEAT_Y + 0.105, 0.0), 0.15, LEATHER, Vector3(1.0, 0.36, 1.0), 16)
	kit.torus(Vector3(0.0, SEAT_Y + 0.1, 0.0), 0.145, 0.014, LEATHER.darkened(0.14), Basis.IDENTITY, 16, 3)
	_rivet(kit, Vector3(0.0, SEAT_Y + 0.155, 0.0), Vector3.UP, 0.022, BRASS)
	add_body(kit.commit())
	add_metal(metal.commit())


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
