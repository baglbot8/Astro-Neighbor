extends Node3D
## A HERD: N look-alike creatures drawn as ONE MultiMesh per part (builder P4). A crab is a body and a
## pair of claws; six crabs are two draw calls, not twelve (a character model is ~58 - OPEN_ISSUES 61).
## Every pose is written in WORLD space each frame (this node is top_level at the origin), and a
## creature that is away (hidden in its burrow, not in today's schedule) gets a zero-scale transform.
##
##   var h := Herd.new()
##   h.setup("Crabs", 6, [[body_mesh, metal_mat, true], [claw_mesh, metal_mat, false]], area_aabb)
##   h.pose(i, 0, body_xform); h.pose(i, 1, body_xform * claw_local); h.hide_one(i)
##
## A culling box covers the whole area the herd lives in (custom_aabb), so the engine never has to
## recompute a MultiMesh box from its instances every frame.

static var ZERO := Transform3D(Basis.from_scale(Vector3(0.0001, 0.0001, 0.0001)), Vector3.ZERO)

var count := 0
var _parts: Array[MultiMeshInstance3D] = []


## `parts`: Array of [mesh: Mesh, material: Material, cast_shadow: bool]. `area`: a world AABB that
## contains every pose this herd will ever take.
func setup(label: String, n: int, parts: Array, area: AABB) -> void:
	name = label
	top_level = true
	transform = Transform3D.IDENTITY
	count = n
	for k in parts.size():
		var spec: Array = parts[k]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = spec[0]
		mm.instance_count = n
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "%s_part%d" % [label, k]
		mmi.multimesh = mm
		mmi.material_override = spec[1]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(spec[2]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.custom_aabb = area
		add_child(mmi)
		_parts.append(mmi)


func pose(i: int, part: int, xf: Transform3D) -> void:
	_parts[part].multimesh.set_instance_transform(i, xf)


func hide_one(i: int) -> void:
	for p in _parts:
		p.multimesh.set_instance_transform(i, ZERO)


func part_node(part: int) -> MultiMeshInstance3D:
	return _parts[part]


## A world AABB around `points`, grown by `margin` metres.
static func area_around(points: Array, margin: float) -> AABB:
	var box := AABB(points[0], Vector3.ZERO)
	for p: Vector3 in points:
		box = box.expand(p)
	return box.grow(margin)
