extends DecoItem
## Tinker Workbench (Tinker Workshop, Bolt's set) - a thick wooden top on four riveted steel legs, brass
## corner plates, a vice bolted to one end, a clamp lamp with a brass shade on the other, a brass cog and a
## blueprint on the top, an orange toolbox on the shelf below, and one big bolt standing upright that
## never gets used.

const BRASS := Color("#c9a35e")
const BRASS_DARK := Color("#a5824a")
const RIVET := Color("#dcc48e")
const STEEL := Color("#9aa3b0")
const STEEL_DARK := Color("#6d7686")
const ORANGE := Color("#c79469")
const WOOD := Color("#a8825c")
const WOOD_DARK := Color("#8a6a4a")
const PAPER := Color("#9fb3c8")
const INK := Color("#e3e8ef")
const BULB := Color("#f0c987")
const TOP_Y := 0.62
const HALF_W := 0.66
const HALF_D := 0.3
const LAMP_AT := Vector3(-0.4, TOP_Y + 0.5, -0.02)


func _init() -> void:
	footprint = 0.9
	collide_radius = 0.6
	collide_height = 0.75


func _build() -> void:
	var kit := DecoKit.new()
	var metal := DecoKit.new()
	# --- the top: thick planks, brass corner plates with bolt heads -----------------------------------
	_slab(kit, Vector3(0.0, TOP_Y - 0.04, 0.0), Vector3(HALF_W * 2.0, 0.08, HALF_D * 2.0), 0.04, WOOD)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3((HALF_W - 0.06) * sx, TOP_Y - 0.04, (HALF_D - 0.06) * sz)
			_slab(metal, c + Vector3(0.05 * sx, 0.0, 0.0), Vector3(0.04, 0.1, 0.16), 0.012, BRASS)
			_rivet(kit, c + Vector3(0.072 * sx, 0.0, 0.0), Vector3(sx, 0.0, 0.0), 0.017)
			# --- a leg under each corner -----------------------------------------------------------
			var leg := Vector3((HALF_W - 0.1) * sx, 0.0, (HALF_D - 0.08) * sz)
			metal.bar(leg, leg + Vector3(0.0, TOP_Y - 0.08, 0.0), 0.034, STEEL, 8)
			_rivet(kit, leg + Vector3(0.0, 0.012, 0.0), Vector3.UP, 0.05, STEEL_DARK)
	# --- the lower shelf, and an orange toolbox on it ------------------------------------------------
	_slab(kit, Vector3(0.0, 0.17, 0.0), Vector3(HALF_W * 2.0 - 0.14, 0.035, HALF_D * 2.0 - 0.08), 0.02, WOOD_DARK)
	var tb := Vector3(0.22, 0.19, 0.02)
	_slab(kit, tb + Vector3(0.0, 0.08, 0.0), Vector3(0.36, 0.16, 0.2), 0.03, ORANGE)
	metal.bar(tb + Vector3(-0.1, 0.17, 0.0), tb + Vector3(0.1, 0.17, 0.0), 0.012, STEEL_DARK, 6)
	for sx2 in [-1.0, 1.0]:
		_rivet(kit, tb + Vector3(0.12 * sx2, 0.11, -0.102), Vector3.FORWARD, 0.014)
	# --- the vice on the right end --------------------------------------------------------------------
	var v := Vector3(HALF_W - 0.1, TOP_Y, -HALF_D + 0.06)
	_slab(metal, v + Vector3(0.0, 0.035, 0.04), Vector3(0.14, 0.07, 0.16), 0.02, STEEL_DARK)
	_slab(metal, v + Vector3(0.0, 0.11, 0.08), Vector3(0.16, 0.1, 0.05), 0.015, STEEL)
	_slab(metal, v + Vector3(0.0, 0.11, -0.03), Vector3(0.16, 0.1, 0.05), 0.015, STEEL)
	metal.bar(v + Vector3(0.0, 0.08, -0.03), v + Vector3(0.0, 0.08, -0.17), 0.012, STEEL_DARK, 6)
	metal.bar(v + Vector3(-0.09, 0.08, -0.17), v + Vector3(0.09, 0.08, -0.17), 0.01, STEEL_DARK, 6)
	for sx3 in [-1.0, 1.0]:
		kit.rbox(v + Vector3(0.1 * sx3, 0.08, -0.17), Vector3(0.044, 0.044, 0.044), 0.022, ORANGE, Basis.IDENTITY, 0)
	_rivet(kit, v + Vector3(0.0, 0.11, -0.058), Vector3.FORWARD, 0.016)
	# --- on the top: a brass cog, a blueprint, a few bolts and the big one -------------------------------
	metal.extrude(_cog_poly(0.11, 0.028, 9), 0.03, BRASS,
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0.12, TOP_Y + 0.015, -0.06)))
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.04, 0.034), Vector2(0.0, 0.034)]),
		8, Transform3D(Basis.IDENTITY, Vector3(0.12, TOP_Y, -0.06)), STEEL_DARK)
	var bp := Basis(Vector3.UP, 0.18)
	kit.rbox(Vector3(-0.12, TOP_Y + 0.004, 0.08), Vector3(0.36, 0.008, 0.26), 0.003, PAPER, bp, 0)
	kit.torus(Vector3(-0.12, TOP_Y + 0.01, 0.08), 0.07, 0.006, INK, bp, 12, 3)
	kit.rbox(Vector3(-0.12, TOP_Y + 0.01, 0.08), Vector3(0.26, 0.004, 0.008), 0.002, INK, bp, 0)
	for p in [Vector3(0.3, 0.0, 0.12), Vector3(0.27, 0.0, 0.02)]:
		_rivet(kit, p + Vector3(0.0, TOP_Y + 0.01, 0.0), Vector3.UP, 0.022, STEEL)
	var bolt := Vector3(0.42, TOP_Y, 0.14)
	metal.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.03, 0.18), Vector2(0.0, 0.18)]),
		8, Transform3D(Basis.IDENTITY, bolt), STEEL)
	metal.lathe(PackedVector2Array([Vector2(0.0, 0.17), Vector2(0.06, 0.17), Vector2(0.06, 0.21), Vector2(0.045, 0.235),
		Vector2(0.0, 0.24)]), 6, Transform3D(Basis.IDENTITY, bolt), BRASS_DARK, true)
	# --- the clamp lamp: clamp, two arms, a brass shade over a warm bulb -----------------------------------
	var cl := Vector3(-0.4, TOP_Y, 0.22)
	_slab(metal, cl + Vector3(0.0, 0.03, 0.0), Vector3(0.08, 0.06, 0.08), 0.015, STEEL_DARK)
	metal.bar(cl + Vector3(0.0, 0.05, 0.0), cl + Vector3(0.0, 0.36, 0.0), 0.016, STEEL, 8)
	kit.rbox(cl + Vector3(0.0, 0.36, 0.0), Vector3(0.06, 0.06, 0.06), 0.03, ORANGE, Basis.IDENTITY, 0)
	metal.bar(cl + Vector3(0.0, 0.36, 0.0), LAMP_AT + Vector3(0.0, 0.06, 0.0), 0.014, STEEL, 8)
	metal.lathe(PackedVector2Array([Vector2(0.0, 0.085), Vector2(0.045, 0.085), Vector2(0.1, 0.0), Vector2(0.11, 0.0),
		Vector2(0.05, 0.1), Vector2(0.0, 0.1)]), 12, Transform3D(Basis.IDENTITY, LAMP_AT), BRASS, true)
	metal.torus(LAMP_AT, 0.11, 0.012, BRASS_DARK, Basis.IDENTITY, 14, 3)
	_rivet(kit, LAMP_AT + Vector3(0.0, 0.105, 0.0), Vector3.UP, 0.02)
	add_body(kit.commit())
	add_metal(metal.commit())

	var glow := DecoKit.new()
	glow.sphere(LAMP_AT + Vector3(0.0, -0.005, 0.0), 0.05, BULB, Vector3(1.0, 0.9, 1.0), 10)
	add_glow(glow.commit(), 2.2, "Bulb", 0.0, 0.0)
	# No OmniLight on purpose: at night a lamp light turns nearby crochet (toon) surfaces black in stitch-row
	# stripes - measured 2026-10-21 on the existing Reading Lamp and Cosmic Mushrooms too, both renderers, and
	# gone the moment the light is removed. The emissive parts and the ground pool carry the night glow.
	add_ground_glow(1.2, Color("#e8bd7c"), 0.2)


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
