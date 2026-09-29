class_name MeteorRock
extends Planet
## THE METEOR ITSELF (docs/STORY_HOME_SPEC.md 9.2; builder METEOR, 2026-09-28): the small, strange rock the
## player lands on for the survey. It is a `Planet` only so the player's spherical gravity, the safari camera
## and PlanetSafari's helpers work on it unchanged (PlanetBody reads `up_at`, `surface_point`,
## `surface_transform`, `height_at`, `radius`). It never joins the "planet" group and never runs Planet's own
## `_ready` (no PlanetData, no props, no NPC homes): `build()` makes one ground mesh and its trimesh collider.
##
## THE GROUND is a cube-sphere displaced by `height_at` - a calm base with low swells and a few shallow
## craters, so the horizon stays a clean arc (STYLE_GUIDE "Terrain") and the walk never snags. The look
## (dark crust, glowing seams) is meteor_crust.gdshader.

const CRUST_SHADER := preload("res://src/meteor_survey/meteor_crust.gdshader")
## Cube-sphere cells per face edge: 48 -> 27,648 triangles, a vertex every ~0.6 m on an 18 m rock.
const GRID := 48
## Low swells (m) and the crater dips (m). Small on purpose: a lumpy horizon reads as noise.
const SWELL_M := 0.45
const CRATER_DEPTH_M := 0.55

var _swell: FastNoiseLite
var _craters: Array = []   # [{dir, ang}]


func _ready() -> void:
	# Deliberately NOT Planet._ready (see the header).
	collision_layer = 1
	collision_mask = 0


func build(r: float, crater_dirs: Array) -> void:
	radius = r
	_swell = FastNoiseLite.new()
	_swell.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_swell.seed = 2809
	_swell.frequency = 0.9
	for d: Vector3 in crater_dirs:
		_craters.append({"dir": d.normalized(), "ang": deg_to_rad(9.0)})
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [
		[Vector3.RIGHT, Vector3.UP, Vector3.BACK], [Vector3.LEFT, Vector3.UP, Vector3.FORWARD],
		[Vector3.UP, Vector3.BACK, Vector3.RIGHT], [Vector3.DOWN, Vector3.FORWARD, Vector3.RIGHT],
		[Vector3.BACK, Vector3.UP, Vector3.LEFT], [Vector3.FORWARD, Vector3.UP, Vector3.RIGHT],
	]
	for f: Array in faces:
		var n: Vector3 = f[0]
		var a: Vector3 = f[1]
		var b: Vector3 = f[2]
		var pts: Array = []
		for j in range(GRID + 1):
			var row: Array = []
			for i in range(GRID + 1):
				var u := float(i) / GRID * 2.0 - 1.0
				var v := float(j) / GRID * 2.0 - 1.0
				# Equal-angle cube mapping: cells stay near-square across the face.
				var p := (n + a * tan(v * PI * 0.25) + b * tan(u * PI * 0.25)).normalized()
				row.append(p)
			pts.append(row)
		for j in range(GRID):
			for i in range(GRID):
				var q := [pts[j][i], pts[j][i + 1], pts[j + 1][i + 1], pts[j + 1][i]]
				_tri(st, q[0], q[1], q[2])
				_tri(st, q[0], q[2], q[3])
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Crust"
	mi.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = CRUST_SHADER
	mi.material_override = mat
	add_child(mi)
	surface_mesh = mi
	var cs := CollisionShape3D.new()
	cs.name = "Collider"
	cs.shape = mesh.create_trimesh_shape()
	add_child(cs)


## Winding checked so the outward face is the front one.
func _tri(st: SurfaceTool, d0: Vector3, d1: Vector3, d2: Vector3) -> void:
	var p0 := d0 * height_at(d0)
	var p1 := d1 * height_at(d1)
	var p2 := d2 * height_at(d2)
	var fn := (p1 - p0).cross(p2 - p0)
	var order := [d0, d1, d2] if fn.dot(p0) < 0.0 else [d0, d2, d1]
	for d: Vector3 in order:
		st.set_normal(ground_normal_at(d))
		st.set_uv(Vector2(d.x, d.z))
		st.add_vertex(d * height_at(d))


func height_at(dir: Vector3) -> float:
	var d := dir.normalized()
	var h := radius
	if _swell != null:
		h += SWELL_M * _swell.get_noise_3dv(d * 3.0)
	for c: Dictionary in _craters:
		var ang := acos(clampf(d.dot(c["dir"] as Vector3), -1.0, 1.0))
		var k := ang / float(c["ang"])
		if k < 1.4:
			# A bowl with a soft raised rim: -depth at the centre, a small lip at k ~ 1.1.
			h += CRATER_DEPTH_M * (-(1.0 - smoothstep(0.0, 1.0, k)) + 0.35 * exp(-pow((k - 1.1) / 0.18, 2.0)))
	return h


## The ground's own normal at `dir`, by finite differences of height_at (smooth shading everywhere).
func ground_normal_at(dir: Vector3) -> Vector3:
	var d := dir.normalized()
	var t1 := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2 := d.cross(t1).normalized()
	var e := 0.25 / maxf(radius, 1.0)
	var p0 := d * height_at(d)
	var pa := (d + t1 * e).normalized()
	var pb := (d + t2 * e).normalized()
	var n := (pa * height_at(pa) - p0).cross(pb * height_at(pb) - p0).normalized()
	return n if n.dot(d) > 0.0 else -n
