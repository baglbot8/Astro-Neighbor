class_name PlanetMeshBuilder
extends RefCounted
## Builds displaced icospheres (planet ground, water shell) from a height callable.
## Every vertex is placed at `dir * height_func.call(dir)` so the mesh matches Planet.height_at exactly.
## Smooth vertex normals are generated in C++ via SurfaceTool (fast even at 80k triangles).

const _ICO_T := 1.6180339887498949  # (1 + sqrt(5)) / 2

const _BASE_VERTS: Array[Vector3] = [
	Vector3(-1.0, _ICO_T, 0.0), Vector3(1.0, _ICO_T, 0.0), Vector3(-1.0, -_ICO_T, 0.0), Vector3(1.0, -_ICO_T, 0.0),
	Vector3(0.0, -1.0, _ICO_T), Vector3(0.0, 1.0, _ICO_T), Vector3(0.0, -1.0, -_ICO_T), Vector3(0.0, 1.0, -_ICO_T),
	Vector3(_ICO_T, 0.0, -1.0), Vector3(_ICO_T, 0.0, 1.0), Vector3(-_ICO_T, 0.0, -1.0), Vector3(-_ICO_T, 0.0, 1.0),
]

## Faces wound CLOCKWISE when seen from outside (Godot front-face convention).
const _BASE_FACES: PackedInt32Array = [
	0, 5, 11, 0, 1, 5, 0, 7, 1, 0, 10, 7, 0, 11, 10,
	1, 9, 5, 5, 4, 11, 11, 2, 10, 10, 6, 7, 7, 8, 1,
	3, 4, 9, 3, 2, 4, 3, 6, 2, 3, 8, 6, 3, 9, 8,
	4, 5, 9, 2, 11, 4, 6, 10, 2, 8, 7, 6, 9, 1, 8,
]

## Unit-sphere icosphere topology: returns {"dirs": PackedVector3Array, "indices": PackedInt32Array}.
## Results are cached per subdivision level because several meshes (ground, water) share the topology.
static var _topology_cache: Dictionary = {}

static func icosphere_topology(subdivisions: int) -> Dictionary:
	if _topology_cache.has(subdivisions):
		return _topology_cache[subdivisions]
	var verts := PackedVector3Array()
	for v in _BASE_VERTS:
		verts.append(v.normalized())
	var faces := _BASE_FACES.duplicate()
	for _level in subdivisions:
		var cache: Dictionary = {}
		var new_faces := PackedInt32Array()
		new_faces.resize(faces.size() * 4)
		var out := 0
		var fi := 0
		while fi < faces.size():
			var a := faces[fi]
			var b := faces[fi + 1]
			var c := faces[fi + 2]
			var ab := _midpoint(a, b, verts, cache)
			var bc := _midpoint(b, c, verts, cache)
			var ca := _midpoint(c, a, verts, cache)
			new_faces[out] = a; new_faces[out + 1] = ab; new_faces[out + 2] = ca
			new_faces[out + 3] = b; new_faces[out + 4] = bc; new_faces[out + 5] = ab
			new_faces[out + 6] = c; new_faces[out + 7] = ca; new_faces[out + 8] = bc
			new_faces[out + 9] = ab; new_faces[out + 10] = bc; new_faces[out + 11] = ca
			out += 12
			fi += 3
		faces = new_faces
	var result := {"dirs": verts, "indices": faces}
	_topology_cache[subdivisions] = result
	return result

static func _midpoint(a: int, b: int, verts: PackedVector3Array, cache: Dictionary) -> int:
	var key := (mini(a, b) << 32) | maxi(a, b)
	if cache.has(key):
		return cache[key]
	var m := ((verts[a] + verts[b]) * 0.5).normalized()
	var idx := verts.size()
	verts.append(m)
	cache[key] = idx
	return idx

## Builds a displaced sphere. height_func(dir: Vector3) -> float gives the distance from the center.
## color_func(dir: Vector3) -> Color (optional) bakes per-vertex data into COLOR.
static func build(subdivisions: int, height_func: Callable, color_func: Callable = Callable()) -> ArrayMesh:
	var topo := icosphere_topology(subdivisions)
	var dirs: PackedVector3Array = topo["dirs"]
	var indices: PackedInt32Array = topo["indices"]
	var count := dirs.size()
	var verts := PackedVector3Array()
	verts.resize(count)
	var colors := PackedColorArray()
	var bake_colors := color_func.is_valid()
	if bake_colors:
		colors.resize(count)
	for i in count:
		var d := dirs[i]
		verts[i] = d * float(height_func.call(d))
		if bake_colors:
			colors[i] = color_func.call(d)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	if bake_colors:
		arrays[Mesh.ARRAY_COLOR] = colors
	var raw := ArrayMesh.new()
	raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Smooth normals in C++ (SurfaceTool averages normals of vertices that share a position).
	var st := SurfaceTool.new()
	st.create_from(raw, 0)
	st.generate_normals()
	var mesh := st.commit()
	return mesh

## Convenience: plain unit-direction sphere scaled by `r` (used for water shells with vertex colors).
static func build_sphere(subdivisions: int, r: float, color_func: Callable = Callable()) -> ArrayMesh:
	return build(subdivisions, func(_d: Vector3) -> float: return r, color_func)
