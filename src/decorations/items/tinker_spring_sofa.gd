extends DecoItem
## Spring Sofa (Tinker Workshop, Bolt's set) - a leather two-seater on a riveted steel base that sits on
## four big coil springs. Rolled arms capped with brass cogs, a buttoned back with bolt-head buttons. The
## whole sofa bobs very gently on its springs: every sit is a small bounce.

const BRASS := Color("#c9a35e")
const BRASS_DARK := Color("#a5824a")
const RIVET := Color("#dcc48e")
const STEEL := Color("#9aa3b0")
const STEEL_DARK := Color("#6d7686")
const LEATHER := Color("#ad7862")
const LEATHER_DARK := Color("#936453")
const ORANGE := Color("#c79469")
## Spring height at rest; the body sits on top of them.
const SPRING_H := 0.17
const HALF_W := 0.74
const HALF_D := 0.34
## Bob of the body on its springs, metres and rad/s.
const BOB := 0.012
const BOB_SPEED := 1.7

var _body_pivot: Node3D
var _springs: Node3D


func _init() -> void:
	footprint = 0.95
	collide_radius = 0.65
	collide_height = 0.95


func _build() -> void:
	# --- four coil springs on brass foot plates ----------------------------------------------------------
	_springs = pivot("Springs")
	var sp := DecoKit.new()
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3((HALF_W - 0.16) * sx, 0.0, (HALF_D - 0.12) * sz)
			sp.rbox(c + Vector3(0.0, 0.01, 0.0), Vector3(0.18, 0.02, 0.18), 0.01, BRASS_DARK, Basis.IDENTITY, 0)
			var pts := PackedVector3Array()
			var n := 18
			for k in n + 1:
				var t := float(k) / float(n)
				var a := t * TAU * 2.25
				pts.append(c + Vector3(cos(a) * 0.065, 0.025 + t * (SPRING_H - 0.04), sin(a) * 0.065))
			JungleMeshes.tube(sp, pts, PackedFloat32Array([0.014]), PackedColorArray([STEEL]), 4, false)
	add_metal(sp.commit(), "Coils", _springs)

	_body_pivot = pivot("Seat", Vector3(0.0, SPRING_H, 0.0))
	var kit := DecoKit.new()
	var metal := DecoKit.new()
	# --- the riveted steel base ------------------------------------------------------------------------------
	metal.rbox(Vector3(0.0, 0.06, 0.0), Vector3(HALF_W * 2.0, 0.12, HALF_D * 2.0), 0.04, STEEL_DARK)
	for i in 5:
		var x := lerpf(-HALF_W + 0.12, HALF_W - 0.12, float(i) / 4.0)
		_rivet(kit, Vector3(x, 0.06, -HALF_D - 0.004), Vector3.FORWARD, 0.017)
	for sx2 in [-1.0, 1.0]:
		_rivet(kit, Vector3((HALF_W + 0.004) * sx2, 0.06, 0.0), Vector3(sx2, 0.0, 0.0), 0.017)
	# --- seat cushions, back, rolled arms ---------------------------------------------------------------------
	for sx3 in [-1.0, 1.0]:
		kit.rbox(Vector3(0.3 * sx3, 0.18, -0.03), Vector3(0.6, 0.14, 0.56), 0.06, LEATHER)
	kit.rbox(Vector3(0.0, 0.4, HALF_D - 0.09), Vector3(HALF_W * 2.0 - 0.18, 0.44, 0.16), 0.07, LEATHER,
		Basis(Vector3.RIGHT, deg_to_rad(-8.0)))
	# buttoned back: a row of bolt-head buttons
	for i2 in 4:
		var bx := lerpf(-0.45, 0.45, float(i2) / 3.0)
		_rivet(kit, Vector3(bx, 0.44, HALF_D - 0.175), Vector3(0.0, 0.14, -1.0).normalized(), 0.02, BRASS)
	for sx4 in [-1.0, 1.0]:
		var ax: float = (HALF_W - 0.05) * sx4
		kit.tube(Vector3(ax, 0.32, -HALF_D + 0.04), Vector3(ax, 0.32, HALF_D - 0.02), 0.1, LEATHER_DARK, 12, 2)
		kit.rbox(Vector3(ax, 0.2, 0.0), Vector3(0.14, 0.18, HALF_D * 2.0 - 0.06), 0.05, LEATHER_DARK)
		# brass cog caps on the arm ends, facing out the front
		metal.extrude(_cog_poly(0.085, 0.022, 8), 0.025, BRASS,
			Transform3D(Basis.IDENTITY, Vector3(ax, 0.32, -HALF_D + 0.02)))
		_rivet(kit, Vector3(ax, 0.32, -HALF_D + 0.002), Vector3.FORWARD, 0.022, BRASS_DARK)
	add_body(kit.commit(), "Body", _body_pivot)
	add_metal(metal.commit(), "Metal", _body_pivot)
	animate()


func _animate(time: float, _delta: float) -> void:
	var b := sin(time * BOB_SPEED) * BOB
	_body_pivot.position.y = SPRING_H + b
	_springs.scale.y = (SPRING_H + b) / SPRING_H


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
