extends DecoItem
## Tea Table (cozy home set) - a low round table on three splayed legs, laid for two: a fat teal teapot,
## two cups on saucers, a plate of biscuits. A floor cushion waits on either side.

const WOOD := Color("#b89a74")
const WOOD_DARK := Color("#93775a")
const CLOTH := Color("#e3d7bc")
const POT := Color("#7fb5ad")
const POT_DARK := Color("#5f9c94")
const CUP := Color("#e6dcc6")
const TEA := Color("#c08a55")
const BISCUIT := Color("#d2b262")
const JAM := Color("#cf7f7a")
const CUSHION_A := Color("#cf8f86")
const CUSHION_B := Color("#a595cf")
const BUTTON := Color("#e3d7bc")
const TOP_Y := 0.4


func _init() -> void:
	footprint = 1.0
	collide_radius = 0.5
	collide_height = 0.5


func _build() -> void:
	var kit := DecoKit.new()
	# --- the table ---------------------------------------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, TOP_Y - 0.07), Vector2(0.4, TOP_Y - 0.07), Vector2(0.47, TOP_Y - 0.04), Vector2(0.47, TOP_Y - 0.01),
		Vector2(0.44, TOP_Y), Vector2(0.0, TOP_Y)]), 22, Transform3D.IDENTITY, WOOD)
	for i in 3:
		var a := TAU * float(i) / 3.0 + PI / 6.0
		var o := Vector3(cos(a), 0.0, sin(a))
		kit.tube(o * 0.27 + Vector3(0.0, TOP_Y - 0.06, 0.0), o * 0.4 + Vector3(0.0, 0.03, 0.0), 0.04, WOOD_DARK, 8)
	kit.disc(Vector3(0.0, TOP_Y + 0.004, 0.0), 0.3, CLOTH, Basis.IDENTITY, 20)
	# --- the teapot: belly, foot, lid with a knob, a curved spout and a loop handle -----------------
	var p := Vector3(0.02, TOP_Y, 0.08)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.075, 0.02), Vector2(0.0, 0.02)]),
		12, Transform3D(Basis.IDENTITY, p), POT_DARK)
	kit.sphere(p + Vector3(0.0, 0.11, 0.0), 0.12, POT, Vector3(1.0, 0.82, 1.0), 14)
	kit.sphere(p + Vector3(0.0, 0.2, 0.0), 0.07, POT_DARK, Vector3(1.0, 0.35, 1.0), 10)
	kit.sphere(p + Vector3(0.0, 0.235, 0.0), 0.024, CUP, Vector3.ONE, 6)
	JungleMeshes.tube(kit, PackedVector3Array([p + Vector3(-0.09, 0.08, 0.0), p + Vector3(-0.16, 0.11, 0.0),
		p + Vector3(-0.19, 0.17, 0.0), p + Vector3(-0.22, 0.2, 0.0)]), PackedFloat32Array([0.034, 0.026, 0.02, 0.017]),
		PackedColorArray([POT]), 7, true)
	kit.torus(p + Vector3(0.13, 0.12, 0.0), 0.055, 0.015, POT_DARK, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 12, 4)
	# --- two cups on saucers, and a plate of biscuits ----------------------------------------------
	_cup(kit, Vector3(-0.22, TOP_Y, -0.2), 0.6)
	_cup(kit, Vector3(0.26, TOP_Y, -0.14), 2.6)
	var plate := Vector3(-0.02, TOP_Y, -0.3)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.11, 0.016), Vector2(0.0, 0.012)]),
		14, Transform3D(Basis.IDENTITY, plate), CUP)
	for i in 3:
		var a2 := TAU * float(i) / 3.0
		var c := plate + Vector3(cos(a2) * 0.04, 0.022 + 0.008 * float(i), sin(a2) * 0.04)
		kit.lathe(PackedVector2Array([Vector2(0.0, -0.01), Vector2(0.036, -0.01), Vector2(0.036, 0.006), Vector2(0.0, 0.01)]),
			8, Transform3D(Basis.IDENTITY, c), BISCUIT)
		kit.disc(c + Vector3(0.0, 0.011, 0.0), 0.015, JAM, Basis.IDENTITY, 6)
	# --- floor cushions ----------------------------------------------------------------------------
	for s in [-1.0, 1.0]:
		var cc := Vector3(0.73 * s, 0.0, 0.02 * s)
		var col: Color = CUSHION_A if s < 0.0 else CUSHION_B
		kit.sphere(cc + Vector3(0.0, 0.085, 0.0), 0.25, col, Vector3(1.0, 0.36, 1.0), 16)
		kit.torus(cc + Vector3(0.0, 0.085, 0.0), 0.235, 0.022, col.darkened(0.12), Basis.IDENTITY, 18, 3)
		kit.sphere(cc + Vector3(0.0, 0.17, 0.0), 0.032, BUTTON, Vector3(1.0, 0.5, 1.0), 6)
	add_body(kit.commit())


## A cup of tea on a saucer at `c`, its handle turned to angle `yaw`.
func _cup(kit: DecoKit, c: Vector3, yaw: float) -> void:
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.082, 0.014), Vector2(0.0, 0.01)]),
		10, Transform3D(Basis.IDENTITY, c), CUP.darkened(0.08))
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.012), Vector2(0.032, 0.012), Vector2(0.052, 0.075), Vector2(0.044, 0.075), Vector2(0.04, 0.06),
		Vector2(0.0, 0.06)]), 10, Transform3D(Basis.IDENTITY, c), CUP)
	kit.disc(c + Vector3(0.0, 0.063, 0.0), 0.04, TEA, Basis.IDENTITY, 10)
	var o := Vector3(cos(yaw), 0.0, sin(yaw))
	kit.torus(c + o * 0.058 + Vector3(0.0, 0.045, 0.0), 0.02, 0.007, CUP,
		Basis(Vector3.UP, -yaw) * Basis(Vector3.RIGHT, deg_to_rad(90.0)), 8, 3)
