extends Node3D
## R2.9 proof sheet: the same five materials with surface detail OFF (back row) and ON (front row),
## lit by the real game environment at the gameplay camera distance.

## `skin` (kind 7) and `scales` (kind 8) are the two character surfaces. They are here so the cast
## can be tuned against a side-by-side instead of by eye on a whole neighbour: the two are NOT
## interchangeable and the difference is the reason Fen is not on `skin`. sd_skin's spot term fires
## on ~5 % of the surface, while sd_scales tints and bump-perturbs EVERY fragment — so a strength
## that is safe on skin renders as bubbles on scales, and the pair only makes sense seen together.
const KINDS := ["cloth", "metal", "wood", "rock", "foliage", "skin", "scales"]
const COLORS := [Color("#e6e2d4"), Color("#8fa3bf"), Color("#a8734b"), Color("#9c968c"),
	Color("#4d9e83"), Color("#9a6fd0"), Color("#5b9bd6")]
## Row geometry is DERIVED, not hard-coded, because this sheet has grown twice. The camera below is
## framed from the same numbers, so adding an eighth kind re-lays the row instead of running it off
## the side of the frame.
const SLAB_W := 1.5
const GAP := 0.28

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
	# Pull back far enough that the whole row is inside the horizontal frustum, with a 12 % margin.
	# Half-width at the slabs is tan(fov/2) * z * aspect, so z = need / (tan(22.5) * aspect).
	var need := (_pitch() * float(KINDS.size() - 1) + SLAB_W) * 0.5 * 1.12
	cam.position = Vector3(0.0, 2.75, maxf(8.4, need / (tan(deg_to_rad(22.5)) * (16.0 / 9.0))))
	cam.rotation_degrees = Vector3(-4.0, 0.0, 0.0)
	add_child(cam)


static func _pitch() -> float:
	return SLAB_W + GAP


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
	mi.position = Vector3((float(i) - float(KINDS.size() - 1) * 0.5) * _pitch(),
		1.75 if detailed else 3.75, 0.0)
	add_child(mi)
	var label := Label3D.new()
	label.text = ("%s  ON" % KINDS[i]) if detailed else ("%s  off" % KINDS[i])
	label.font_size = 42
	label.pixel_size = 0.0026
	label.position = mi.position + Vector3(0, -1.02, 0.25)
	label.modulate = Color("#f2ead6")
	label.outline_size = 14
	add_child(label)
