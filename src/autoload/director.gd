extends Node
## Automated test driver. Lets critics and CI play the game without a human.
##
## Usage:
##   godot --path . res://src/world/world.tscn --write-movie /tmp/out/run.png --quit-after 300 --fixed-fps 30 -- --director=res://tests/director/walk_and_jump.json
##   godot --path . res://src/world/world.tscn -- --director=res://tests/director/walk_and_jump.json --quit-at=12
##
## Timeline JSON: array of steps, each with "t" (seconds since scene start) and one op:
##   {"t": 0.5, "press": "move_forward"}      hold an action down
##   {"t": 2.5, "release": "move_forward"}    let go
##   {"t": 3.0, "tap": "jump"}                press+release (one frame)
##   {"t": 4.0, "capture": "after_jump"}      save PNG to --capture-dir (default user://captures) as <name>.png
##   {"t": 5.0, "call": {"node": "/root/World/Player", "method": "teleport_to_dir", "args": [[0,1,0]]}}
##   {"t": 6.0, "set": {"node": "/root/World", "property": "some_prop", "value": 1}}
##   {"t": 7.0, "log": "checkpoint reached"}
##   {"t": 8.0, "quit": true}
## Extra CLI flags: --quit-at=SECONDS  --capture-dir=/abs/path  --planet=zorp  --new-game  --time=20.5  --campaign
##
## Director also writes user://director_log.txt with every step and any script errors it observed.

var _steps: Array = []
var _time := 0.0
var _index := 0
var _active := false
var _quit_at := -1.0
var _capture_dir := "user://captures"
var _campaign := false
var _log: FileAccess

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--director="):
			_load_timeline(a.substr(11))
		elif a.begins_with("--quit-at="):
			_quit_at = float(a.substr(10))
		elif a.begins_with("--capture-dir="):
			_capture_dir = a.substr(14)
		elif a.begins_with("--planet="):
			GameState.current_planet_id = a.substr(9)
		elif a == "--new-game":
			GameState.reset_new_game()
		elif a.begins_with("--time="):
			GameState.time_of_day = float(a.substr(7))
		elif a == "--campaign":
			_campaign = true
	if _active or _quit_at > 0.0:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_dir))
		_log = FileAccess.open("user://director_log.txt", FileAccess.WRITE)
		_write_log("Director armed. steps=%d quit_at=%.2f" % [_steps.size(), _quit_at])

func _load_timeline(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Director: timeline not found: " + path)
		return
	var txt := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Director: timeline must be a JSON array")
		return
	_steps = parsed
	_steps.sort_custom(func(a, b): return float(a.get("t", 0)) < float(b.get("t", 0)))
	_active = true

func is_active() -> bool:
	return _active

## True when a timeline opts into the Stranded campaign's gates with the "--campaign" user arg - the
## same opt-in shape as "--intro" (intro_director.gd, _intro_allowed). Campaign gates are OFF whenever
## a Director timeline runs unless this is true, so every existing timeline keeps today's open world
## (docs/BUILD_PLAN.md, "Rules for every phase"). Read it through CampaignData.gates_on(), not directly.
func campaign_opt_in() -> bool:
	return _campaign

func _process(delta: float) -> void:
	if not (_active or _quit_at > 0.0):
		return
	_time += delta
	while _index < _steps.size() and float(_steps[_index].get("t", 0.0)) <= _time:
		_run_step(_steps[_index])
		_index += 1
	if _quit_at > 0.0 and _time >= _quit_at:
		_write_log("quit-at reached (%.2fs)" % _time)
		_finish()

func _run_step(s: Dictionary) -> void:
	if s.has("press"):
		Input.action_press(s["press"])
		_write_log("press %s" % s["press"])
	elif s.has("release"):
		Input.action_release(s["release"])
		_write_log("release %s" % s["release"])
	elif s.has("tap"):
		Input.action_press(s["tap"])
		_write_log("tap %s" % s["tap"])
		await get_tree().process_frame
		Input.action_release(s["tap"])
	elif s.has("capture"):
		await capture(str(s["capture"]))
	elif s.has("call"):
		var c: Dictionary = s["call"]
		var n := get_node_or_null(NodePath(str(c.get("node", ""))))
		if n == null:
			_write_log("call FAILED: node not found %s" % c.get("node", ""))
			return
		var args: Array = c.get("args", [])
		var conv: Array = []
		for a in args:
			conv.append(_convert_arg(a))
		_write_log("call %s.%s(%s)" % [c.get("node"), c.get("method"), str(conv)])
		n.callv(str(c.get("method", "")), conv)
	elif s.has("set"):
		var c2: Dictionary = s["set"]
		var n2 := get_node_or_null(NodePath(str(c2.get("node", ""))))
		if n2:
			n2.set(str(c2.get("property", "")), _convert_arg(c2.get("value")))
			_write_log("set %s.%s" % [c2.get("node"), c2.get("property")])
	elif s.has("log"):
		_write_log("LOG: " + str(s["log"]))
	elif s.has("quit"):
		_finish()

func _convert_arg(a):
	if typeof(a) == TYPE_ARRAY and a.size() == 3 and typeof(a[0]) in [TYPE_FLOAT, TYPE_INT]:
		return Vector3(a[0], a[1], a[2])
	return a

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := _capture_dir.path_join(name + ".png")
	var err := img.save_png(path)
	_write_log("capture %s -> %s (%s)" % [name, ProjectSettings.globalize_path(path), error_string(err)])

func _write_log(msg: String) -> void:
	var line := "[%7.2f] %s" % [_time, msg]
	print("DIRECTOR " + line)
	if _log:
		_log.store_line(line)
		_log.flush()

func _finish() -> void:
	_write_log("done")
	if _log:
		_log.close()
		_log = null
	_active = false
	_quit_at = -1.0
	get_tree().quit()
