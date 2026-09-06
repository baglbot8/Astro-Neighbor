class_name PlanetPuffTree
extends StaticBody3D
## A puff tree (or any shakeable tree prop). Call shake() for a wobble + leaf burst — the player
## builder may call it when the player bumps/shakes the tree.

var leaf_color: Color = Color("#4fb054")
var _mesh: MeshInstance3D
var _leaves: GPUParticles3D
var _wobble_tween: Tween

func setup(mesh: MeshInstance3D, leaf: Color, canopy_height: float) -> void:
	_mesh = mesh
	leaf_color = leaf
	_leaves = GPUParticles3D.new()
	_leaves.name = "LeafBurst"
	_leaves.emitting = false
	_leaves.one_shot = true
	_leaves.explosiveness = 0.9
	_leaves.amount = 26
	_leaves.lifetime = 1.6
	_leaves.local_coords = true
	_leaves.position = Vector3(0.0, canopy_height, 0.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 1.0
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 80.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 2.6
	pm.gravity = Vector3(0.0, -3.5, 0.0)
	pm.angular_velocity_min = -220.0
	pm.angular_velocity_max = 220.0
	pm.damping_min = 0.8
	pm.damping_max = 1.4
	pm.scale_min = 0.7
	pm.scale_max = 1.2
	var g := Gradient.new()
	g.set_color(0, leaf)
	g.set_color(1, Color(leaf.r, leaf.g, leaf.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	_leaves.process_material = pm
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 0.09
	leaf_mesh.height = 0.06
	leaf_mesh.radial_segments = 8
	leaf_mesh.rings = 4
	leaf_mesh.material = PlanetPropMeshes.puff_material(Color.WHITE)
	_leaves.draw_pass_1 = leaf_mesh
	add_child(_leaves)

## Wobble the canopy and burst leaves.
func shake() -> void:
	if _mesh == null:
		return
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()
	_wobble_tween = create_tween()
	_wobble_tween.tween_method(_apply_wobble, 0.0, 1.0, 0.8)
	if _leaves:
		_leaves.restart()
		_leaves.emitting = true

func _apply_wobble(t: float) -> void:
	var decay := (1.0 - t)
	var a := sin(t * TAU * 3.2) * 0.09 * decay
	_mesh.rotation = Vector3(a, 0.0, a * 0.7)
	var s := 1.0 + sin(t * TAU * 3.2 + 0.5) * 0.04 * decay
	_mesh.scale = Vector3(_mesh.scale.x, _mesh.scale.x * s, _mesh.scale.x)
