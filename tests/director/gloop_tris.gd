extends Node
## Counts GloopModel's triangles against the 6000-per-neighbour budget (docs/CAST_VARIETY.md).
func _ready() -> void:
	var m := GloopModel.new()
	add_child(m)
	await get_tree().process_frame
	var tris := _count(m)
	print("GLOOP triangles=", tris, " budget=6000 ", "OK" if tris <= 6000 else "OVER")
	get_tree().quit()
func _count(n: Node) -> int:
	var t := 0
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var mesh: Mesh = (n as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
			if idx.size() > 0:
				t += idx.size() / 3
			else:
				t += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	for c in n.get_children():
		t += _count(c)
	return t
