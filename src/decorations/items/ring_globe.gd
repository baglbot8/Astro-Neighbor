extends DecoItem
## Ring-Planet Globe — a violet world with a golden ring and two tiny moons, spinning on a cream stand.
## A favor-only trophy.

const STAND := Color("#cbbb8b")
const STAND_DARK := Color("#d9c9a0")
const METAL := Color("#b8c4d6")
const WORLD := Color("#845bd9")
const WORLD_DARK := Color("#8a5cf0")
const RING := Color("#d9af4f")

var _globe: Node3D
var _orbit: Node3D


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.44
	collide_height = 1.15


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.46, 0.0), Vector2(0.44, 0.08), Vector2(0.26, 0.16), Vector2(0.2, 0.3), Vector2(0.16, 0.46), Vector2(0.0, 0.48)]), 22, Transform3D.IDENTITY, STAND)
	kit.torus(Vector3(0.0, 0.1, 0.0), 0.44, 0.05, STAND_DARK, Basis.IDENTITY, 22)
	kit.torus(Vector3(0.0, 0.42, 0.0), 0.17, 0.035, METAL, Basis.IDENTITY, 16)
	add_body(kit.commit())

	_globe = pivot("Globe", Vector3(0.0, 0.94, 0.0))
	var g := DecoKit.new()
	g.sphere(Vector3.ZERO, 0.4, WORLD, Vector3.ONE, 22)
	g.sphere(Vector3(0.2, 0.16, -0.28), 0.14, WORLD_DARK, Vector3(1.0, 0.6, 1.0), 12)
	g.sphere(Vector3(-0.26, -0.1, -0.24), 0.12, WORLD_DARK, Vector3(1.0, 0.7, 1.0), 12)
	g.torus(Vector3.ZERO, 0.4, 0.03, WORLD_DARK, Basis(Vector3.RIGHT, deg_to_rad(90.0)) * Basis(Vector3.UP, deg_to_rad(90.0)), 22)
	add_body(g.commit(), "World", _globe)

	var ring := DecoKit.new()
	var tilt := Basis(Vector3.FORWARD, deg_to_rad(22.0))
	ring.lathe(PackedVector2Array([Vector2(0.56, 0.0), Vector2(0.74, 0.0), Vector2(0.74, 0.022), Vector2(0.56, 0.022)]), 30, Transform3D(tilt, Vector3(0.0, 0.94, 0.0)), RING, false, true)
	add_metal(ring.commit(), "Ring")

	_orbit = pivot("Moons", Vector3(0.0, 0.94, 0.0))
	_orbit.rotation = Vector3(deg_to_rad(14.0), 0.0, deg_to_rad(-16.0))
	var m := DecoKit.new()
	m.sphere(Vector3(0.92, 0.0, 0.0), 0.075, Color("#cfcfdf"), Vector3.ONE, 12)
	m.sphere(Vector3(-0.78, 0.0, 0.34), 0.055, Color("#b1b7cf"), Vector3.ONE, 10)
	add_body(m.commit(), "Moons", _orbit)

	var glow := DecoKit.new()
	glow.sphere(Vector3(0.0, 0.44, 0.0), 0.06, Color("#65c5d9"), Vector3(1.0, 0.5, 1.0), 10)
	add_glow(glow.commit(), 2.2, "Base", 1.2, 0.3)
	animate()


func _animate(t: float, _delta: float) -> void:
	_globe.rotation.y = t * 0.5
	_globe.rotation.z = deg_to_rad(22.0)
	_orbit.rotation.y = -t * 0.7
