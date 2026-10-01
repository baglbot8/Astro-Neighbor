extends DecoItem
## Potted Plant Trio (cozy home set) - three clay pots huddled together: a tall leafy one at the back,
## a round cactus with a flower hat, and a pancake plant holding its coin leaves out on thin stems.

const POT_CREAM := Color("#dccfb0")
const POT_ORANGE := Color("#c9805e")
const POT_TEAL := Color("#7fb5ad")
const BAND := Color("#b3a27e")
const SOIL := Color("#6d5f52")
const STEM := Color("#6f9e6a")
const LEAF := Color("#7fb07a")
const LEAF_DARK := Color("#5f9263")
const LEAF_LIGHT := Color("#9cc68a")
const CACTUS := Color("#86ad7a")
const BLOOM := Color("#d98f9c")
const BLOOM_EYE := Color("#e3c877")


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.42
	collide_height = 0.7


func _build() -> void:
	var kit := DecoKit.new()
	# --- back pot: the tall leafy one ---------------------------------------------------------------
	var a := Vector3(0.0, 0.0, 0.16)
	_pot(kit, a, 0.21, 0.3, POT_CREAM, POT_TEAL)
	var top := a + Vector3(0.0, 0.27, 0.0)
	JungleMeshes.tube(kit, PackedVector3Array([top, top + Vector3(0.0, 0.42, 0.0)]), PackedFloat32Array([0.024, 0.016]),
		PackedColorArray([STEM]), 5, false)
	for i in 6:
		var az := TAU * float(i) / 6.0 + 0.4
		var tilt := 0.5 + 0.22 * float(i % 2)
		var o := Vector3(cos(az), 0.0, sin(az))
		var dir := (Vector3.UP * cos(tilt) + o * sin(tilt)).normalized()
		var base := top + Vector3(0.0, 0.12 + 0.05 * float(i), 0.0)
		kit.sphere(base + dir * 0.19, 0.2, LEAF if i % 2 == 0 else LEAF_DARK, Vector3(0.46, 1.0, 0.13), 8,
			_leaf_basis(az, tilt))
	kit.sphere(top + Vector3(0.0, 0.6, 0.0), 0.13, LEAF_LIGHT, Vector3(0.42, 1.0, 0.16), 8, _leaf_basis(1.2, 0.12))
	# --- front left pot: a round cactus in a flower hat ---------------------------------------------
	var b := Vector3(-0.27, 0.0, -0.17)
	_pot(kit, b, 0.15, 0.2, POT_ORANGE, POT_CREAM)
	kit.sphere(b + Vector3(0.0, 0.3, 0.0), 0.13, CACTUS, Vector3(1.0, 1.12, 1.0), 12)
	kit.sphere(b + Vector3(0.12, 0.31, 0.02), 0.06, CACTUS.darkened(0.08), Vector3(1.0, 1.2, 1.0), 8)
	var flat := Basis(Vector3.RIGHT, deg_to_rad(-90.0)) * Basis(Vector3.RIGHT, 0.25)
	kit.extrude(_flower(0.085), 0.026, BLOOM, Transform3D(flat, b + Vector3(0.0, 0.455, 0.0)))
	kit.extrude(DecoKit.round_rect_poly(0.056, 0.056, 0.028, 2), 0.034, BLOOM_EYE, Transform3D(flat, b + Vector3(0.0, 0.462, 0.0)))
	# --- front right pot: a pancake plant ---------------------------------------------------------
	var c := Vector3(0.27, 0.0, -0.14)
	_pot(kit, c, 0.17, 0.24, POT_TEAL, POT_CREAM)
	var heart := c + Vector3(0.0, 0.22, 0.0)
	for i in 7:
		var az3 := TAU * float(i) / 7.0 + 0.2
		var o3 := Vector3(cos(az3), 0.0, sin(az3))
		var reach := 0.13 + 0.04 * float(i % 3)
		var tip := heart + o3 * reach + Vector3(0.0, 0.1 + 0.07 * float((i * 2) % 3), 0.0)
		JungleMeshes.tube(kit, PackedVector3Array([heart, tip]), PackedFloat32Array([0.01, 0.008]), PackedColorArray([STEM]), 4, false)
		kit.sphere(tip, 0.075, LEAF_LIGHT if i % 2 == 0 else LEAF, Vector3(1.0, 0.2, 1.0), 8,
			Basis(Vector3.UP.cross(o3).normalized(), 0.35))
	add_body(kit.commit())


## A clay pot standing at `c`: tapered wall, a fat rim, a painted band and dark soil inside.
func _pot(kit: DecoKit, c: Vector3, r: float, h: float, col: Color, band: Color) -> void:
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(r * 0.66, 0.0), Vector2(r * 0.9, h * 0.78), Vector2(r * 1.06, h * 0.8),
		Vector2(r * 1.06, h), Vector2(r * 0.84, h), Vector2(r * 0.84, h * 0.9), Vector2(0.0, h * 0.9)]),
		15, Transform3D(Basis.IDENTITY, c), col)
	kit.disc(c + Vector3(0.0, h * 0.9 + 0.003, 0.0), r * 0.84, SOIL, Basis.IDENTITY, 15)
	kit.torus(c + Vector3(0.0, h * 0.4, 0.0), r * 0.79, 0.014, band, Basis.IDENTITY, 15, 3)


## A basis whose +Y leans `tilt` away from upright toward azimuth `az`, with its thin Z axis facing out
## (so a sphere squashed in Z becomes a leaf blade that shows its face to the viewer).
static func _leaf_basis(az: float, tilt: float) -> Basis:
	var o := Vector3(cos(az), 0.0, sin(az))
	return Basis(Vector3.UP.cross(o).normalized(), tilt) * Basis(Vector3.UP, PI * 0.5 - az)


## A five-petal flower outline (XY): one closed polygon, so a bloom costs one extrude instead of five
## spheres (the first build spent 1,080 of this item's triangles on three flowers).
static func _flower(r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		out.append(Vector2(cos(a), sin(a)) * r * (0.6 + 0.4 * absf(cos(a * 2.5))))
	return out
