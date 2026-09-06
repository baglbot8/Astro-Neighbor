extends Node3D
## R2.9 proof sheet: the same five materials with surface detail OFF (back row) and ON (front row),
## lit by the real game environment at the gameplay camera distance.

const KINDS := ["cloth", "metal", "wood", "rock", "foliage"]
const COLORS := [Color("#e6e2d4"), Color("#8fa3bf"), Color("#a8734b"), Color("#9c968c"), Color("#4d9e83")]

func _ready() -> void:
	var env_path := "res://src/world/environment.tscn"
	if ResourceLoader.exists(env_path):
		var e: Node = load(env_path).instantiate()
		e.name = "Environment"
		add_child(e)
		if e.has_method("set_time"):
			e.call_deferred("set_time", 13.0)
	for i in KINDS.size():
		_slab(i, false)
		_slab(i, true)
	var cam := Camera3D.new()
	cam.fov = 45.0
	cam.current = true
	cam.position = Vector3(0.0, 2.75, 8.4)
	cam.rotation_degrees = Vector3(-4.0, 0.0, 0.0)
	add_child(cam)


func _slab(i: int, detailed: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.5, 1.5, 0.35)
	mi.mesh = bm
	var opts: Dictionary = {}
	if detailed:
		opts["surface"] = KINDS[i]
		opts["surface_far"] = 26.0
		if KINDS[i] == "wood":
			opts["grain_dir"] = Vector3(0, 1, 0)
	if KINDS[i] == "metal":
		mi.material_override = MaterialLib.metal(COLORS[i], opts if detailed else {"surface": "none"})
	else:
		mi.material_override = MaterialLib.toon(COLORS[i], opts)
	mi.position = Vector3(-3.9 + i * 1.95, 1.75 if detailed else 3.75, 0.0)
	add_child(mi)
	var label := Label3D.new()
	label.text = ("%s  ON" % KINDS[i]) if detailed else ("%s  off" % KINDS[i])
	label.font_size = 42
	label.pixel_size = 0.0026
	label.position = mi.position + Vector3(0, -1.02, 0.25)
	label.modulate = Color("#f2ead6")
	label.outline_size = 14
	add_child(label)
