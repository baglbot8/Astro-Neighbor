extends DecoItem
## Space Dome Tent — a fat sunshine-yellow habitat dome with a lit doorway, a porthole and a vent mast.

const CANVAS := Color("#d9a838")
const CANVAS_DARK := Color("#f0a92e")
const SEAM := Color("#d96143")
const METAL := Color("#8fa3bf")
const INSIDE := Color("#3a2f45")


func _init() -> void:
	footprint = 1.3
	collide_radius = 1.1
	collide_height = 1.3


func _build() -> void:
	var kit := DecoKit.new()
	kit.dome(Vector3(0.0, 0.03, 0.0), 1.18, CANVAS, 1.12, Basis.IDENTITY, 30)
	kit.lathe(PackedVector2Array([Vector2(1.22, 0.0), Vector2(1.24, 0.09), Vector2(1.16, 0.16)]), 30, Transform3D.IDENTITY, CANVAS_DARK)
	kit.torus(Vector3(0.0, 0.06, 0.0), 1.2, 0.06, METAL, Basis.IDENTITY, 30, 4)
	# seam ribs: thin extruded arcs following the dome profile
	for i in 3:
		var b := Basis(Vector3.UP, PI * float(i) / 3.0)
		kit.extrude(_rib_poly(), 0.07, SEAM, Transform3D(b, Vector3(0.0, 0.03, 0.0)))
	# doorway facing -Z
	kit.rbox(Vector3(0.0, 0.42, -1.02), Vector3(0.78, 0.86, 0.28), 0.14, CANVAS_DARK)
	kit.rbox(Vector3(0.0, 0.4, -1.14), Vector3(0.54, 0.72, 0.1), 0.1, INSIDE)
	# vent mast
	kit.cone(Vector3(0.0, 1.24, 0.0), 0.14, 0.1, 0.22, METAL, Basis.IDENTITY, 12)
	kit.tube(Vector3(0.0, 1.42, 0.0), Vector3(0.0, 1.72, 0.0), 0.025, METAL)
	kit.sphere(Vector3(0.0, 1.76, 0.0), 0.06, SEAM)
	# guy ropes and pegs
	for i in 3:
		var a2 := TAU * float(i) / 3.0 + 0.9
		var top := Vector3(cos(a2) * 0.72, 1.02, sin(a2) * 0.72)
		var peg := Vector3(cos(a2) * 1.6, 0.0, sin(a2) * 1.6)
		kit.bar(top, peg, 0.016, Color("#4a4655"), 5)
		kit.cone(peg, 0.05, 0.02, 0.14, METAL, Basis.IDENTITY, 8)
	add_body(kit.commit())

	add_glass(_porthole_glass(), Color("#5db2d9"), 0.3, "Porthole")

	var glow := DecoKit.new()
	glow.disc(Vector3(0.0, 0.06, -1.13), 0.24, Color("#d9bf61"), Basis(Vector3.RIGHT, deg_to_rad(-90.0)), 14)
	glow.torus(Vector3(0.86, 0.72, -0.62), 0.19, 0.035, Color("#65c5d9"), Basis(Vector3.UP, deg_to_rad(-52.0)) * Basis(Vector3.RIGHT, deg_to_rad(90.0)), 16)
	add_glow(glow.commit(), 2.2, "Windows", 0.0, 0.0)
	add_light(Vector3(0.0, 0.5, -1.2), Color("#d9af70"), 1.4, 4.0)


## Half-arc band hugging the dome profile (x = radius, y = height), used as a seam rib.
func _rib_poly() -> PackedVector2Array:
	var out := PackedVector2Array()
	var steps := 16
	for i in steps + 1:
		var a: float = lerpf(-PI * 0.5, PI * 0.5, float(i) / float(steps))
		out.append(Vector2(sin(a) * 1.205, cos(a) * 1.205 * 1.12))
	for i in steps + 1:
		var a2: float = lerpf(PI * 0.5, -PI * 0.5, float(i) / float(steps))
		out.append(Vector2(sin(a2) * 1.16, cos(a2) * 1.16 * 1.12))
	return out


func _porthole_glass() -> ArrayMesh:
	var g := DecoKit.new()
	g.disc(Vector3(0.86, 0.72, -0.62), 0.18, Color.WHITE, Basis(Vector3.UP, deg_to_rad(-52.0)) * Basis(Vector3.RIGHT, deg_to_rad(90.0)), 16)
	return g.commit()
