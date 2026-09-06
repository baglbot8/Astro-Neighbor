extends Node3D
## showcase/characters_lineup.tscn — every neighbour standing on a REAL planet under the REAL
## `src/world/environment.tscn`, cycling through the whole animation set.
##
## This scene used to build its own flat white sky (`PlayerShowcaseEnv`) and judged eight Zorp and
## nine Bolt iterations inside it. That showcase measured luma p05 0.787, range 0.167, value 0.966,
## saturation 0.267 and 23.1 % blown highlights — it failed all four palette gates in
## docs/QUALITY_BAR.md, so every colour tuned in it shipped 0.11-0.20 saturation below spec. Per the
## rule in docs/AGENT_WORKFLOW.md ("Your showcase scene MUST match gameplay lighting") the lighting
## here is now literally the game's: the same Planet, the same Environment node, the same camera
## pitch (28 deg) and FOV (45) as `CameraRig`.
##
##   tools/capture.sh showcase/characters_lineup.tscn lineup 120
##   tools/capture.sh showcase/characters_lineup.tscn zorp_face 90 "" --face=zorp
##   tools/capture.sh showcase/characters_lineup.tscn zorp_back 60 "" --face=zorp --back
##   tools/capture.sh showcase/characters_lineup.tscn pip_far 60 "" --face=pip --gameplay
## User args: --face=<id> · --back · --gameplay (6.5 m / 28 deg) · --dist=<m> · --freeze
##            --state=<name> · --stats · --planet=<id> · --time=<hour> · --shadow-cheat
##
## `--shadow-cheat` re-enables `ChibiModel.head_shadow_cheat` (docs/OPEN_ISSUES.md issue 1, now
## RESOLVED and reverted, so the flag ships false). It exists so the revert can be re-measured as a
## controlled A/B — same camera, same frame, one flag — with `tools/hf_noise.py`.

const PLANET_SCENE := "res://src/planet/planet.tscn"
const ENV_SCENE := "res://src/world/environment.tscn"
const STATES: PackedStringArray = ["idle", "walk", "talk", "wave", "happy", "think", "surprised", "dance"]
const STATE_SECONDS := 2.0
const TURN_SPEED := 0.5
## Gameplay camera constants, copied from CameraRig so the framing is provably the same.
const GAMEPLAY_PITCH_DEG := 28.0
const GAMEPLAY_FOV := 45.0
const GAMEPLAY_DIST := 6.5
## Face close-up: near eye level so eye spacing can be measured without foreshortening.
const FACE_PITCH_DEG := 10.0
const FACE_DIST := 2.05
const LINEUP_PITCH_DEG := 20.0
const LINEUP_DIST := 8.6
const SPACING_M := 1.45
## Mid-morning, so every capture has the same daylight unless --time= says otherwise.
const DEFAULT_HOUR := 10.5

const ORDER: Array[String] = ["zorp", "bolt", "pip", "pop", "stella", "mayor_orbit", "dj_nova"]
const LABELS := {
	"zorp": "Zorp", "bolt": "Bolt", "pip": "Pip", "pop": "Pop",
	"stella": "Stella", "mayor_orbit": "Mayor Orbit", "dj_nova": "DJ Nova",
}

var _models: Array[CharacterModel] = []
var _pivots: Array[Node3D] = []
var _state_index := 0
var _state_timer := 0.0
var _turn := TURN_SPEED
var _forced_state := ""
var _label: Label3D
var _shadow_cheat := false
var _planet: Planet


func _ready() -> void:
	name = "World"
	var face_id := ""
	var back := false
	var gameplay := false
	var dist := -1.0
	var planet_id := "home"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--face="):
			face_id = a.substr(7)
		elif a == "--back":
			back = true
		elif a == "--gameplay":
			gameplay = true
		elif a.begins_with("--dist="):
			dist = a.substr(7).to_float()
		elif a == "--freeze":
			_turn = 0.0
		elif a.begins_with("--state="):
			_forced_state = a.substr(8)
		elif a.begins_with("--planet="):
			planet_id = a.substr(9)
		elif a.begins_with("--time="):
			GameState.time_of_day = a.substr(7).to_float()
		elif a == "--shadow-cheat":
			_shadow_cheat = true

	GameState.current_planet_id = planet_id
	if not _has_arg("--time="):
		GameState.time_of_day = DEFAULT_HOUR
	_spawn_planet(planet_id)
	_spawn_env()

	var ids: Array[String] = ORDER.duplicate()
	if face_id != "" and LABELS.has(face_id):
		ids = [face_id] as Array[String]
	var single := ids.size() == 1

	# the lineup stands on the planet's spawn disc, spread along its local X axis
	var center_dir: Vector3 = _planet.data.spawn_dir.normalized()
	var forward := Vector3.FORWARD
	var center_xf := _planet.surface_transform(center_dir, forward)
	var right := center_xf.basis.x
	var up := center_xf.basis.y
	var x0 := -SPACING_M * (ids.size() - 1) * 0.5

	for i in ids.size():
		var offset := x0 + SPACING_M * i
		var dir := (center_dir + right * (offset / _planet.radius)).normalized()
		var pivot := Node3D.new()
		pivot.name = "Stand_" + ids[i]
		add_child(pivot)
		# align every neighbour to the CENTRE up vector so a lineup does not fan outward, but put
		# their feet on the real surface height, so nothing floats or sinks.
		pivot.global_transform = Transform3D(center_xf.basis, _planet.surface_point(dir))
		pivot.rotate_object_local(Vector3.UP, PI)   # face the front camera; --back moves the CAMERA
		var m := NpcModels.make(ids[i])
		if _shadow_cheat and m is ChibiModel:
			(m as ChibiModel).head_shadow_cheat = true
		pivot.add_child(m)
		_models.append(m)
		_pivots.append(pivot)
		if not single:
			add_child(_make_label(str(LABELS[ids[i]]), pivot.position + up * 1.78, 30))

	_label = _make_label(_forced_state if _forced_state != "" else "idle", _planet.surface_point(center_dir) + up * 2.35, 36)
	add_child(_label)

	var focus_h := 0.72
	var pitch := LINEUP_PITCH_DEG
	var cam_dist := LINEUP_DIST + maxf(0.0, float(ids.size() - 7)) * SPACING_M
	if single:
		if gameplay:
			pitch = GAMEPLAY_PITCH_DEG
			cam_dist = GAMEPLAY_DIST
			focus_h = 1.0
		else:
			pitch = FACE_PITCH_DEG
			cam_dist = FACE_DIST
			focus_h = 0.945 * maxf(_models[0].body_scale, 0.1)
	if dist > 0.0:
		cam_dist = dist
	if ids.size() > 1:
		cam_dist = maxf(cam_dist, SPACING_M * ids.size() * 0.72)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.fov = GAMEPLAY_FOV
	cam.current = true
	add_child(cam)
	var target := _planet.surface_point(center_dir) + up * focus_h
	var back_dir := center_xf.basis.z * (-1.0 if back else 1.0)
	var eye := target + back_dir * cos(deg_to_rad(pitch)) * cam_dist + up * sin(deg_to_rad(pitch)) * cam_dist
	cam.look_at_from_position(eye, target, up)

	_apply_state(0)
	if OS.get_cmdline_user_args().has("--stats"):
		_print_stats(ids)


static func _has_arg(prefix: String) -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return true
	return false


func _spawn_planet(planet_id: String) -> void:
	var path := "res://src/planet/data/%s.tres" % planet_id
	var data: PlanetData = load(path) as PlanetData if ResourceLoader.exists(path) else PlanetData.new()
	if not ResourceLoader.exists(path):
		data.id = planet_id
	if ResourceLoader.exists(PLANET_SCENE):
		_planet = load(PLANET_SCENE).instantiate()
	else:
		_planet = Planet.new()
	_planet.name = "Planet"
	_planet.data = data
	add_child(_planet)


func _spawn_env() -> void:
	if not ResourceLoader.exists(ENV_SCENE):
		push_warning("lineup_showcase: %s is missing — lighting will NOT match gameplay" % ENV_SCENE)
		return
	var env: Node = load(ENV_SCENE).instantiate()
	env.name = "Environment"
	add_child(env)


## QA helper (`--stats`): prints the triangle count of every model so the <= 6k budget is checkable.
func _print_stats(ids: Array[String]) -> void:
	for i in _models.size():
		print("MODEL %-12s tris=%d" % [ids[i], _count_tris(_models[i])])


static func _count_tris(root: Node) -> int:
	var total := 0
	if root is MeshInstance3D:
		var mesh: Mesh = (root as MeshInstance3D).mesh
		if mesh != null:
			for surf in mesh.get_surface_count():
				var arrays: Array = mesh.surface_get_arrays(surf)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				if idx.size() > 0:
					@warning_ignore("integer_division")
					total += idx.size() / 3
				else:
					var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					@warning_ignore("integer_division")
					total += verts.size() / 3
	for c: Node in root.get_children():
		total += _count_tris(c)
	return total


func _make_label(text: String, pos: Vector3, size: int) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = int(size * 0.28)
	l.pixel_size = 0.0055
	l.modulate = Color("#fff8e1")
	l.outline_modulate = Color("#6b5232")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	return l


func _apply_state(i: int) -> void:
	_state_index = i % STATES.size()
	var st := _forced_state if _forced_state != "" else String(STATES[_state_index])
	_label.text = st
	for m: CharacterModel in _models:
		m.set_state(st)


func _process(delta: float) -> void:
	if _forced_state == "":
		_state_timer += delta
		if _state_timer >= STATE_SECONDS:
			_state_timer -= STATE_SECONDS
			_apply_state(_state_index + 1)
	for p: Node3D in _pivots:
		p.rotate_object_local(Vector3.UP, _turn * delta)
	for m: CharacterModel in _models:
		m.tick(delta, 1.0 if m.get_state() == "walk" else 0.0)
