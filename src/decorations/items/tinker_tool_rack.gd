extends DecoItem
## Tool Rack (Tinker Workshop, Bolt's set) - a wooden pegboard between two riveted steel posts, a brass
## cog crest on top. Every tool has its own hook: two spanners, a hammer, a screwdriver, and a little
## shelf at the bottom with a tin of bolts and a spare cog. Bolt checks.

const BRASS := Color("#c9a35e")
const BRASS_DARK := Color("#a5824a")
const RIVET := Color("#dcc48e")
const STEEL := Color("#9aa3b0")
const STEEL_DARK := Color("#6d7686")
const ORANGE := Color("#c79469")
const WOOD := Color("#a8825c")
const WOOD_DARK := Color("#8a6a4a")
const HOLE := Color("#5e4a3a")
const BOARD_Y := 0.84
const FRONT := -0.035


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.4
	collide_height = 1.45


func _build() -> void:
	var kit := DecoKit.new()
	var metal := DecoKit.new()
	# --- two posts on splayed feet ----------------------------------------------------------------
	for s in [-1.0, 1.0]:
		var x: float = 0.45 * s
		metal.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.032, 0.0), Vector2(0.03, 1.32),
			Vector2(0.0, 1.32)]), 10, Transform3D(Basis.IDENTITY, Vector3(x, 0.0, 0.0)), STEEL)
		_slab(kit, Vector3(x, 0.035, 0.0), Vector3(0.09, 0.07, 0.46), 0.03, STEEL_DARK)
		for zz in [-0.2, 0.2]:
			_rivet(kit, Vector3(x, 0.075, zz), Vector3.UP, 0.026, BRASS_DARK)
		kit.rbox(Vector3(x, 1.34, 0.0), Vector3(0.09, 0.09, 0.09), 0.045, BRASS, Basis.IDENTITY, 0)
	# --- the pegboard, brass edge rails, a grid of peg holes ----------------------------------------
	_slab(kit, Vector3(0.0, BOARD_Y, 0.0), Vector3(0.86, 0.04, 0.9), 0.03, WOOD, Basis(Vector3.RIGHT, PI * 0.5))
	for y2 in [BOARD_Y - 0.45, BOARD_Y + 0.45]:
		metal.bar(Vector3(-0.44, y2, 0.0), Vector3(0.44, y2, 0.0), 0.022, BRASS_DARK, 8)
	var flat := Basis(Vector3.RIGHT, deg_to_rad(-90.0))
	for r in 3:
		for c in 4:
			kit.disc(Vector3(-0.39 + 0.26 * float(c), BOARD_Y - 0.3 + 0.3 * float(r) + 0.06 * float(c % 2), -0.021), 0.013, HOLE, flat, 6)
	for x2 in [-0.4, 0.4]:
		for y3 in [BOARD_Y - 0.4, BOARD_Y + 0.4]:
			_rivet(kit, Vector3(x2, y3, -0.025), Vector3.FORWARD, 0.016)
	# --- cog crest on top ---------------------------------------------------------------------------
	metal.extrude(_cog_poly(0.12, 0.03, 8), 0.04, BRASS,
		Transform3D(Basis.IDENTITY, Vector3(0.0, BOARD_Y + 0.56, 0.0)))
	metal.lathe(PackedVector2Array([Vector2(0.0, -0.035), Vector2(0.05, -0.035), Vector2(0.05, 0.035),
		Vector2(0.0, 0.035)]), 12, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(90.0)), Vector3(0.0, BOARD_Y + 0.56, 0.0)),
		STEEL_DARK)
	_rivet(kit, Vector3(0.0, BOARD_Y + 0.56, -0.04), Vector3.FORWARD, 0.022, BRASS_DARK)
	# --- tools, each on its own hook ----------------------------------------------------------------
	_spanner(kit, metal, Vector3(-0.29, BOARD_Y + 0.12, FRONT), 0.42, 0.06)
	_spanner(kit, metal, Vector3(-0.17, BOARD_Y + 0.1, FRONT), 0.34, 0.05)
	# hammer: wooden handle, steel head, hanging head-up
	var hm := Vector3(0.02, BOARD_Y, FRONT)
	_hook(metal, hm + Vector3(0.0, 0.26, 0.0))
	kit.bar(hm + Vector3(0.0, -0.17, -0.01), hm + Vector3(0.0, 0.23, -0.01), 0.02, WOOD_DARK, 8)
	_slab(metal, hm + Vector3(0.0, 0.25, -0.015), Vector3(0.2, 0.065, 0.065), 0.022, STEEL_DARK)
	# screwdriver: an orange handle and a steel shaft
	var sd := Vector3(0.22, BOARD_Y, FRONT)
	_hook(metal, sd + Vector3(0.0, 0.24, 0.0))
	kit.bar(sd + Vector3(0.0, 0.08, -0.015), sd + Vector3(0.0, 0.22, -0.015), 0.03, ORANGE, 8)
	metal.bar(sd + Vector3(0.0, -0.17, -0.015), sd + Vector3(0.0, 0.09, -0.015), 0.011, STEEL, 6)
	# a coil of wire
	_hook(metal, Vector3(0.33, BOARD_Y + 0.26, FRONT))
	metal.torus(Vector3(0.33, BOARD_Y + 0.17, FRONT - 0.02), 0.07, 0.016, ORANGE.darkened(0.12),
		Basis(Vector3.RIGHT, deg_to_rad(90.0)), 12, 3)
	# --- the bottom shelf: a tin of bolts and a spare cog ----------------------------------------------
	var sh := Vector3(0.0, BOARD_Y - 0.36, -0.1)
	_slab(kit, sh + Vector3(0.0, 0.0, 0.0), Vector3(0.9, 0.035, 0.18), 0.02, WOOD_DARK)
	var tin := sh + Vector3(-0.2, 0.018, 0.0)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.07, 0.09), Vector2(0.06, 0.09),
		Vector2(0.06, 0.07), Vector2(0.0, 0.07)]), 10, Transform3D(Basis.IDENTITY, tin), ORANGE)
	for i in 3:
		var a := TAU * float(i) / 3.0
		_rivet(kit, tin + Vector3(cos(a) * 0.03, 0.08, sin(a) * 0.03), Vector3.UP, 0.016, STEEL)
	metal.extrude(_cog_poly(0.06, 0.02, 7), 0.025, BRASS_DARK,
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-75.0)), sh + Vector3(0.16, 0.06, 0.02)))
	add_body(kit.commit())
	add_metal(metal.commit())


## Open-ended spanner hanging head-up from a hook at `top`: a flat bar handle and a ring head.
func _spanner(kit: DecoKit, metal: DecoKit, top: Vector3, length: float, head: float) -> void:
	_hook(metal, top + Vector3(0.0, 0.0, 0.0))
	_slab(metal, top + Vector3(0.0, -length * 0.5 + head * 0.6, -0.01), Vector3(0.04, 0.016, length - head), 0.012, STEEL,
		Basis(Vector3.RIGHT, PI * 0.5))
	metal.torus(top + Vector3(0.0, -head * 0.2, -0.01), head * 0.75, head * 0.28, STEEL,
		Basis(Vector3.RIGHT, deg_to_rad(90.0)), 10, 3)
	metal.torus(top + Vector3(0.0, -length + head * 0.9, -0.01), head * 0.55, head * 0.24, STEEL,
		Basis(Vector3.RIGHT, deg_to_rad(90.0)), 8, 3)
	kit.disc(top + Vector3(0.0, -length * 0.5 + head * 0.6, -0.019), 0.012, RIVET,
		Basis(Vector3.RIGHT, deg_to_rad(-90.0)), 6)


## A short steel peg sticking out of the board at `p`.
func _hook(metal: DecoKit, p: Vector3) -> void:
	metal.tube(Vector3(p.x, p.y, -0.015), Vector3(p.x, p.y + 0.012, p.z - 0.035), 0.008, STEEL_DARK, 6, 1)


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


## A flat-sided plank or block with rounded corners seen from above: 44 triangles instead of a level-1
## rbox's 80. `size` is width, thickness (Y) and depth.
func _slab(kit: DecoKit, center: Vector3, size: Vector3, r: float, col: Color, basis: Basis = Basis.IDENTITY) -> void:
	kit.extrude(DecoKit.round_rect_poly(size.x, size.z, r, 2), size.y, col,
		Transform3D(basis * Basis(Vector3.RIGHT, -PI * 0.5), center))
