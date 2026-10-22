extends DecoItem
## Helper Arm (Tinker Workshop BONUS, from Bolt) - a little robot arm bolted to a riveted steel crate,
## sorting bolts all day: it dips into the orange tray of mixed bolts, swings across, and drops them in the
## brass tray where they stand in a neat row. Cog joints at the shoulder and elbow, an orange upper arm, a
## steel forearm, a two-claw gripper, a blinking warm status light on the front.

const BRASS := Color("#c9a35e")
const BRASS_DARK := Color("#a5824a")
const RIVET := Color("#dcc48e")
const STEEL := Color("#9aa3b0")
const STEEL_DARK := Color("#6d7686")
const ORANGE := Color("#c79469")
const LIGHT := Color("#f0b874")
const TOP_Y := 0.38
const SHOULDER := Vector3(0.0, TOP_Y + 0.12, 0.12)
const L1 := 0.3
const L2 := 0.26
## Yaw that points the arm at each tray (the trays sit forward-left and forward-right of the turret).
const REACH_YAW := 0.95
const CYCLE := 0.6

var _yaw: Node3D
var _shoulder: Node3D
var _elbow: Node3D
var _claws: Array[Node3D] = []


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.42
	collide_height = 1.0


func _build() -> void:
	var kit := DecoKit.new()
	var metal := DecoKit.new()
	# --- the crate -----------------------------------------------------------------------------------
	metal.rbox(Vector3(0.0, TOP_Y * 0.5, 0.0), Vector3(0.8, TOP_Y, 0.52), 0.04, STEEL)
	kit.rbox(Vector3(0.0, TOP_Y * 0.42, -0.262), Vector3(0.72, 0.07, 0.01), 0.004, ORANGE, Basis.IDENTITY, 0)
	for sx in [-1.0, 1.0]:
		for y in [0.06, TOP_Y - 0.06]:
			_rivet(kit, Vector3(0.35 * sx, y, -0.262), Vector3.FORWARD, 0.017)
	metal.extrude(_cog_poly(0.06, 0.018, 8), 0.02, BRASS,
		Transform3D(Basis.IDENTITY, Vector3(-0.2, TOP_Y * 0.42 + 0.075, -0.265)))
	# --- the two trays: mixed bolts, sorted bolts -------------------------------------------------------------
	var tray_l := Vector3(-0.24, TOP_Y, -0.08)
	var tray_r := Vector3(0.24, TOP_Y, -0.08)
	for t in [[tray_l, ORANGE], [tray_r, BRASS_DARK]]:
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.11, 0.0), Vector2(0.13, 0.06), Vector2(0.115, 0.06),
			Vector2(0.1, 0.015), Vector2(0.0, 0.015)]), 12, Transform3D(Basis.IDENTITY, t[0]), t[1])
	for i in 4:
		var a := float(i) * 2.4
		var rr := 0.035 + 0.025 * float(i % 3)
		_rivet(kit, tray_l + Vector3(cos(a) * rr, 0.03 + 0.008 * float(i % 2), sin(a) * rr), Vector3(cos(a), 2.0, sin(a)).normalized(),
			0.02, STEEL if i % 2 == 0 else RIVET)
	for i2 in 3:
		var bp := tray_r + Vector3(-0.05 + 0.05 * float(i2), 0.015, 0.0)
		metal.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.012, 0.0), Vector2(0.012, 0.07), Vector2(0.0, 0.07)]),
			6, Transform3D(Basis.IDENTITY, bp), STEEL)
		_rivet(kit, bp + Vector3(0.0, 0.075, 0.0), Vector3.UP, 0.02, STEEL)
	# --- the turret --------------------------------------------------------------------------------------------
	metal.lathe(PackedVector2Array([Vector2(0.0, TOP_Y), Vector2(0.11, TOP_Y), Vector2(0.1, TOP_Y + 0.05), Vector2(0.07, TOP_Y + 0.07),
		Vector2(0.0, TOP_Y + 0.07)]), 16, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, SHOULDER.z)), BRASS)
	for i3 in 3:
		var a3 := TAU * float(i3) / 3.0 + PI / 6.0
		_rivet(kit, Vector3(cos(a3) * 0.095, TOP_Y + 0.05, SHOULDER.z + sin(a3) * 0.095), Vector3(cos(a3), 1.0, sin(a3)).normalized(), 0.013)
	add_body(kit.commit())
	add_metal(metal.commit())

	# --- the arm: yaw -> shoulder cog -> upper arm -> elbow cog -> forearm -> gripper ----------------------------
	_yaw = pivot("Yaw", Vector3(0.0, TOP_Y + 0.07, SHOULDER.z))
	var yk := DecoKit.new()
	yk.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.05, 0.05), Vector2(0.0, 0.05)]), 12,
		Transform3D.IDENTITY, STEEL_DARK)
	for sx2 in [-1.0, 1.0]:
		yk.rbox(Vector3(0.05 * sx2, 0.05, 0.0), Vector3(0.022, 0.09, 0.07), 0.01, STEEL_DARK, Basis.IDENTITY, 0)
	add_metal(yk.commit(), "Turret", _yaw)
	_shoulder = pivot("Shoulder", Vector3(0.0, SHOULDER.y - (TOP_Y + 0.07), 0.0), _yaw)
	var uk := DecoKit.new()
	_joint(uk)
	uk.tube(Vector3.ZERO, Vector3(0.0, L1, 0.0), 0.032, ORANGE, 8)
	add_metal(uk.commit(), "UpperArm", _shoulder)
	_elbow = pivot("Elbow", Vector3(0.0, L1, 0.0), _shoulder)
	var fk := DecoKit.new()
	_joint(fk)
	fk.tube(Vector3.ZERO, Vector3(0.0, L2, 0.0), 0.025, STEEL, 8)
	fk.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.03, 0.04), Vector2(0.0, 0.04)]), 10,
		Transform3D(Basis.IDENTITY, Vector3(0.0, L2 - 0.01, 0.0)), BRASS_DARK)
	# the bolt it is carrying
	fk.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.011, 0.0), Vector2(0.011, 0.06), Vector2(0.0, 0.06)]), 6,
		Transform3D(Basis.IDENTITY, Vector3(0.0, L2 + 0.03, 0.0)), STEEL)
	fk.rbox(Vector3(0.0, L2 + 0.035, 0.0), Vector3(0.036, 0.016, 0.036), 0.016, STEEL, Basis.IDENTITY, 0)
	add_metal(fk.commit(), "Forearm", _elbow)
	for s in [-1.0, 1.0]:
		var cp := pivot("Claw", Vector3(0.026 * s, L2 + 0.03, 0.0), _elbow)
		var ck := DecoKit.new()
		ck.tube(Vector3.ZERO, Vector3(0.012 * s, 0.05, 0.0), 0.011, STEEL_DARK, 6, 1)
		ck.tube(Vector3(0.012 * s, 0.05, 0.0), Vector3(-0.004 * s, 0.085, 0.0), 0.009, STEEL_DARK, 6, 1)
		add_metal(ck.commit(), "Claw", cp)
		cp.set_meta("side", s)
		_claws.append(cp)

	# --- the status light ------------------------------------------------------------------------------------
	var glow := DecoKit.new()
	glow.sphere(Vector3(0.2, TOP_Y * 0.42 + 0.075, -0.266), 0.03, LIGHT, Vector3(1.0, 1.0, 0.6), 10)
	add_glow(glow.commit(), 2.3, "Status", 1.4, 0.7, 1.0)
	add_ground_glow(0.9, Color("#e8bd7c"), 0.16)
	_animate(0.0, 0.0)
	animate()


func _animate(time: float, _delta: float) -> void:
	var ph := sin(time * CYCLE)
	# Dwell at each tray (|ph| near 1), lift high while it swings across.
	var at_tray := pow(absf(ph), 6.0)
	_yaw.rotation.y = REACH_YAW * ph
	var reach := lerpf(0.16, 0.27, at_tray)
	var height := lerpf(0.22, 0.03, at_tray)
	var d := clampf(sqrt(reach * reach + height * height), 0.08, L1 + L2 - 0.002)
	var bend := PI - acos(clampf((L1 * L1 + L2 * L2 - d * d) / (2.0 * L1 * L2), -1.0, 1.0))
	var elev := atan2(height, reach) + acos(clampf((L1 * L1 + d * d - L2 * L2) / (2.0 * L1 * d), -1.0, 1.0))
	_shoulder.rotation.x = -(PI * 0.5 - elev)
	_elbow.rotation.x = -bend
	# claws open on the swing, close round the bolt at the trays
	var open := (1.0 - at_tray) * 0.35
	for c in _claws:
		c.rotation.z = -float(c.get_meta("side")) * open


## A cog joint (the set's motif) around a pivot's origin, axle along X, with a bolt head each side.
func _joint(k: DecoKit) -> void:
	k.extrude(_cog_poly(0.045, 0.014, 6), 0.05, BRASS, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO))
	for s in [-1.0, 1.0]:
		k.rbox(Vector3(0.03 * s, 0.0, 0.0), Vector3(0.016, 0.03, 0.03), 0.015, RIVET, Basis.IDENTITY, 0)


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
