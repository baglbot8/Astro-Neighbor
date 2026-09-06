extends Node3D
## showcase/player_walk.tscn — a 16 m planet with the player + camera rig, driven by
## tests/director/player_walk.json. Root is named "World" so Director paths match the real game.
##
## It uses the REAL src/world/environment.tscn by default. docs/AGENT_WORKFLOW.md: a showcase whose
## lighting differs from the game is worse than no showcase, and this one exists specifically to
## judge how the suit reads while moving.
## Flags (after "--"): --flat-env falls back to the standalone showcase sky (isolating a shading
## bug), --no-ext also skips planet.tscn, --debug prints a trace every 0.5 s.

var planet: Planet
var player: Player
var camera_rig: CameraRig
var _debug := false
var _debug_t := 0.0
var _use_ext := true


func _ready() -> void:
	name = "World"
	var args := OS.get_cmdline_user_args()
	_debug = args.has("--debug")
	_use_ext = not args.has("--no-ext")
	var ext_env := not args.has("--flat-env") and _use_ext
	var data := PlanetData.new()
	data.id = "showcase"
	data.radius = 16.0
	if _use_ext and ResourceLoader.exists("res://src/planet/planet.tscn"):
		planet = load("res://src/planet/planet.tscn").instantiate() as Planet
	else:
		planet = Planet.new()
	planet.name = "Planet"
	planet.data = data
	add_child(planet)
	if not planet.is_in_group("planet"):
		planet.add_to_group("planet")

	if not ext_env or not ResourceLoader.exists("res://src/world/environment.tscn"):
		PlayerShowcaseEnv.add_to(self)
	else:
		var env: Node = load("res://src/world/environment.tscn").instantiate()
		env.name = "Environment"
		add_child(env)

	player = load("res://src/player/player.tscn").instantiate() as Player
	player.name = "Player"
	add_child(player)
	player.planet = planet
	player.place_on_planet(Vector3.UP, Vector3.FORWARD)
	EventBus.player_spawned.emit(player)
	if _debug:
		print("DEBUG spawn pos=%s height_at(UP)=%.3f radius=%.2f" % [str(player.global_position), planet.height_at(Vector3.UP), planet.radius])

	camera_rig = load("res://src/player/camera_rig.tscn").instantiate() as CameraRig
	camera_rig.name = "CameraRig"
	add_child(camera_rig)

	_add_test_sign()
	EventBus.interact_prompt_changed.connect(func(t: String) -> void: print("PROMPT '%s'" % t))
	player.interact_target_changed.connect(func(t: Interactable) -> void: print("TARGET %s" % (t.name if t else "none")))


## A little signpost with an Interactable so the prompt / focus path can be exercised.
func _add_test_sign() -> void:
	var dir := Vector3(0.0, 1.0, -0.19).normalized()
	var xf := planet.surface_transform(dir, Vector3.FORWARD)
	var sign_root := Node3D.new()
	sign_root.name = "TestSign"
	sign_root.transform = xf
	add_child(sign_root)
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.07
	pm.bottom_radius = 0.09
	pm.height = 1.0
	pm.radial_segments = 16
	post.mesh = pm
	post.position.y = 0.5
	post.material_override = MaterialLib.toon(Color("#a8734b"))
	sign_root.add_child(post)
	var board := MeshInstance3D.new()
	board.mesh = AstronautModel.rounded_box_mesh(Vector3(0.9, 0.5, 0.1), 0.04)
	board.position = Vector3(0.0, 1.15, 0.0)
	board.material_override = MaterialLib.toon(Color("#efe0b5"))
	sign_root.add_child(board)
	var it := Interactable.new()
	it.name = "SignInteractable"
	it.prompt_text = "Read"
	it.reach = 2.4
	it.require_facing = true
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.6
	cs.shape = sh
	it.add_child(cs)
	it.position.y = 0.8
	sign_root.add_child(it)
	it.interacted.connect(func(_p: Node3D) -> void: print("SIGN INTERACTED"))


## `--debug` also keeps a per-frame histogram of the animation state, printed on the way out. It is
## the only way to catch a state that is being *interrupted* rather than never entered: a sprint
## whose "run" pose is replaced by "land" every time the boots skip a bump looks wrong on screen but
## reads as perfectly healthy in a 2 Hz debug line.
var _state_hist: Dictionary = {}


func _exit_tree() -> void:
	if not _debug or _state_hist.is_empty():
		return
	var total := 0
	for k: String in _state_hist:
		total += int(_state_hist[k])
	var keys: Array = _state_hist.keys()
	keys.sort_custom(func(a, b): return int(_state_hist[a]) > int(_state_hist[b]))
	var parts: Array[String] = []
	for k: String in keys:
		parts.append("%s %.0f%%" % [k, 100.0 * float(_state_hist[k]) / float(total)])
	print("DEBUG state histogram (%d frames): %s" % [total, ", ".join(parts)])


func _physics_process(delta: float) -> void:
	if not _debug:
		return
	var st := player.get_model().get_state()
	_state_hist[st] = int(_state_hist.get(st, 0)) + 1
	_debug_t += delta
	if fmod(_debug_t, 0.5) < delta:
		var r := (player.global_position - planet.global_position).length()
		var cam := camera_rig.get_camera()
		print("DEBUG t=%.1f r=%.2f h=%.2f floor=%s vel=%.2f state=%s cam_d=%.2f" % [_debug_t, r, r - planet.height_at(planet.dir_of(player.global_position)), player.is_on_floor(), player.velocity.length(), player.get_model().get_state(), (cam.global_position - player.global_position).length()])
		var it := get_node_or_null("TestSign/SignInteractable") as Interactable
		if it:
			var to := it.global_position - player.global_position
			var t := to - player.up * to.dot(player.up)
			print("DEBUG   sign dist=%.2f facing=%.2f groups=%s enabled=%s" % [to.length(), player.surface_forward().dot(t.normalized()), str(it.get_groups()), it.enabled])
