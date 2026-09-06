extends PlanetBody
## Smoke test body: walks forward around the planet forever, jumps every 2 s. Verifies PlanetBody math.
var t := 0.0
var jumps := 0
var samples: Array = []
func _ready() -> void:
	super._ready()
	planet = get_node("/root/Smoke/Planet")
	var cap := MeshInstance3D.new()
	var m := CapsuleMesh.new(); m.radius = 0.35; m.height = 1.2
	cap.mesh = m; cap.position.y = 0.6
	cap.material_override = MaterialLib.toon(Color("#ff7a59"))
	add_child(cap)
	var col := CollisionShape3D.new(); var cs := CapsuleShape3D.new(); cs.radius = 0.35; cs.height = 1.2; col.shape = cs; col.position.y = 0.6
	add_child(col)
	place_on_planet(Vector3(0, 1, 0), Vector3.FORWARD)
func _physics_process(delta: float) -> void:
	t += delta
	align_to_planet()
	apply_planet_gravity(delta)
	set_tangent_velocity(surface_forward() * 4.2)
	if is_on_floor() and fmod(t, 2.0) < delta:
		do_jump(); jumps += 1
	move_and_slide()
	if fmod(t, 0.5) < delta:
		var h := (global_position - planet.global_position).length() - planet.radius
		samples.append("%.1fs h=%.2f floor=%s up_dot=%.3f" % [t, h, is_on_floor(), up.dot(global_transform.basis.y)])
	if t > 12.0:
		for s in samples: print("SMOKE " + s)
		print("SMOKE jumps=%d final_dir=%s" % [jumps, str(current_dir())])
		get_tree().quit()
