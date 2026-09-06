extends Node
## Final-critic probe: find whatever is drawing hard-edged cream quads in mid-air on the meadow.
## Dumps every GPUParticles3D (emitting state, draw-pass mesh class) and every visible
## MeshInstance3D whose origin sits more than `MIN_ALT` metres above the planet surface.

const MIN_ALT := 0.9


func dump_particles() -> void:
	var n := 0
	for node in _all(get_tree().root):
		if node is GPUParticles3D:
			var p := node as GPUParticles3D
			var m: Mesh = p.draw_pass_1
			print("QP particles %s emitting=%s amount=%d mesh=%s vis=%s path=%s" % [
				p.name, str(p.emitting), p.amount,
				("null" if m == null else m.get_class()), str(p.visible), str(p.get_path())])
			n += 1
	print("QP particle systems: %d" % n)


func dump_airborne() -> void:
	var planet := get_tree().get_first_node_in_group("planet")
	if planet == null:
		print("QP no planet")
		return
	var radius: float = planet.get("radius")
	var n := 0
	for node in _all(get_tree().root):
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			if not mi.is_visible_in_tree():
				continue
			var gp := mi.global_position
			var d := gp.normalized()
			var surf: float = radius
			if planet.has_method("height_at"):
				surf = planet.call("height_at", d)
			var alt := gp.length() - surf
			if alt > MIN_ALT and gp.length() < radius + 12.0:
				var mesh_name := "null" if mi.mesh == null else mi.mesh.get_class()
				print("QP airborne %-16s alt=%.2f mesh=%s mat=%s path=%s" % [
					mi.name, alt, mesh_name,
					("override" if mi.material_override != null else "-"), str(mi.get_path())])
				n += 1
	print("QP airborne meshes: %d" % n)


func _all(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		for c in n.get_children():
			stack.append(c)
	return out


## MultiMeshInstance3D instances whose origin floats above the surface (a bad transform in a
## MultiMesh is invisible to `dump_airborne`, which only walks MeshInstance3D).
func dump_multimesh() -> void:
	var planet := get_tree().get_first_node_in_group("planet")
	if planet == null:
		return
	var radius: float = planet.get("radius")
	for node in _all(get_tree().root):
		if node is MultiMeshInstance3D:
			var mmi := node as MultiMeshInstance3D
			var mm := mmi.multimesh
			if mm == null:
				continue
			var bad := 0
			var worst := 0.0
			var worst_at := Vector3.ZERO
			for i in mm.instance_count:
				var xf: Transform3D = mmi.global_transform * mm.get_instance_transform(i)
				var o := xf.origin
				if not is_finite(o.x) or not is_finite(o.y) or not is_finite(o.z):
					bad += 1
					continue
				var surf: float = radius
				if planet.has_method("height_at"):
					surf = planet.call("height_at", o.normalized())
				var alt := o.length() - surf
				if alt > worst:
					worst = alt
					worst_at = o
			print("QP mm %-14s n=%d worst_alt=%.2f at=%s nan=%d path=%s" % [
				mmi.name, mm.instance_count, worst, str(worst_at.snapped(Vector3(0.1, 0.1, 0.1))), bad, str(mmi.get_path())])


## Histogram of DecorationManager.spot_block_reason over a uniform sample of the sphere, so a critic
## can say what fraction of a planet will actually accept a decoration.
func placement_survey(footprint: float = 0.6, n: int = 4000) -> void:
	var dm := get_node_or_null("/root/World/Decorations")
	if dm == null or not dm.has_method("spot_block_reason"):
		print("QP survey: no DecorationManager")
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var hist := {}
	for i in n:
		var v := Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		if v.length_squared() < 0.0001:
			continue
		var reason: String = dm.call("spot_block_reason", v.normalized(), footprint, "")
		hist[reason] = int(hist.get(reason, 0)) + 1
	var keys: Array = hist.keys()
	keys.sort()
	var line := "QP placement_survey footprint=%.2f n=%d planet=%s :" % [footprint, n, GameState.current_planet_id]
	for k in keys:
		line += "  %s=%.1f%%" % [("FREE" if k == "" else k), 100.0 * float(hist[k]) / float(n)]
	print(line)


## Triangle budget check (ARCHITECTURE §10: characters <= 6k tris, props <= 2k, planet <= 80k).
func tri_count(root_path: String) -> void:
	var root := get_node_or_null(NodePath(root_path))
	if root == null:
		print("QP tri_count: no %s" % root_path)
		return
	var tris := 0
	var meshes := 0
	for n in _all(root):
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var m: Mesh = (n as MeshInstance3D).mesh
			meshes += 1
			for s in m.get_surface_count():
				var arrays := m.surface_get_arrays(s)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				if idx.size() > 0:
					tris += idx.size() / 3
				else:
					var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					tris += v.size() / 3
		elif n is MultiMeshInstance3D:
			var mmi := n as MultiMeshInstance3D
			if mmi.multimesh != null and mmi.multimesh.mesh != null:
				var mm: Mesh = mmi.multimesh.mesh
				var per := 0
				for s2 in mm.get_surface_count():
					var a2 := mm.surface_get_arrays(s2)
					var i2: PackedInt32Array = a2[Mesh.ARRAY_INDEX] if a2.size() > Mesh.ARRAY_INDEX and a2[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
					per += (i2.size() / 3) if i2.size() > 0 else ((a2[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
				tris += per * mmi.multimesh.instance_count
				meshes += 1
	print("QP tri_count %s: %d tris across %d mesh nodes" % [root_path, tris, meshes])
