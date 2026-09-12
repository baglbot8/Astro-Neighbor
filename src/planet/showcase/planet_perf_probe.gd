extends Node3D
## Test rig, not part of the game. Answers TWO questions about a planet load, repeatably:
##   1. How long does `src/world/world.gd::_ready()` take, cold and warm, with and without a
##      prebuilt geometry cache?
##   2. How many times did the prop scatter (`PlanetProps.populate`) run for that one visit?
##
## It also dumps the whole scatter - every prop node's local transform, every MultiMesh instance
## transform, and the planet's registered prop dirs and radii - so a change can be proved
## bit-identical by diffing two dumps.
##
## Inert unless `--planetperf` is passed, so `tools/check.sh` runs it like any other showcase.
##
## The real world scene is instantiated at `/root/World`, not under this node: world.gd names itself
## "World" and several systems resolve that absolute path. This node parks itself out of the way.
##
## Usage (headless is the quiet, repeatable way to time CPU work):
##   godot --headless --path . res://showcase/planet_perf.tscn -- --planetperf \
##       --pp-planets=hub,zorp,bolt --pp-reps=3 --pp-out=/abs/path/perf.txt
##   godot --headless --path . res://showcase/planet_perf.tscn -- --planetperf \
##       --pp-planets=hub --pp-reps=1 --pp-dump=/abs/path/scatter_hub.txt
##
## The four phases measured per planet, in this order, after one untimed warm-up visit that pays the
## process's one-time script/resource/class costs:
##   COLD_NOPRE   geometry cache cleared, no prebuild   - today's plain world load (save, title, Director)
##   COLD_PRE     cache cleared, prebuild() first       - today's rocket arrival
##   WARM_NOPRE   cache left warm from the phase above  - a revisit that finds the cache already full
##   WARM_PRE     cache warm, prebuild() called anyway  - `prebuild()` early-returns on a cache hit,
##                so this phase never exercises the prop hand-off. That is what makes it the clean
##                paired control for COLD_PRE: the two differ ONLY by the hand-off and the bake.
## `prebuild_ms` is reported next to `world_ms` because the two together are the honest cost of a
## visit: moving work into prebuild() only helps if prebuild runs somewhere the player cannot feel it.

const WORLD_SCENE := "res://src/world/world.tscn"

var _planets: PackedStringArray = PackedStringArray(["hub", "zorp", "bolt"])
var _reps := 3
var _out_path := ""
var _dump_path := ""
var _lines: PackedStringArray = PackedStringArray()


func _ready() -> void:
	name = "PerfProbe"
	var args := OS.get_cmdline_user_args()
	if not args.has("--planetperf"):
		return
	for a in args:
		if a.begins_with("--pp-planets="):
			_planets = a.substr(13).split(",", false)
		elif a.begins_with("--pp-reps="):
			_reps = maxi(1, int(a.substr(10)))
		elif a.begins_with("--pp-out="):
			_out_path = a.substr(9)
		elif a.begins_with("--pp-dump="):
			_dump_path = a.substr(10)
	_run.call_deferred()


func _run() -> void:
	# `_ready` cannot add a sibling: the tree is still setting this node up and `add_child` fails.
	await get_tree().process_frame
	_say("PP renderer=%s headless=%s" % [
		RenderingServer.get_video_adapter_name() if DisplayServer.get_name() != "headless" else "headless",
		DisplayServer.get_name() == "headless"])
	for pid in _planets:
		var data_path := "res://src/planet/data/%s.tres" % pid
		if not ResourceLoader.exists(data_path):
			_say("PP SKIP %s (no PlanetData)" % pid)
			continue
		# One untimed visit first: it pays for loading every script, scene and shader this planet
		# touches, and those one-time costs would otherwise land entirely on the first timed row.
		await _visit(pid, false, false, "WARMUP", -1)
		for r in _reps:
			await _visit(pid, true, false, "COLD_NOPRE", r)
			await _visit(pid, true, true, "COLD_PRE", r)
			await _visit(pid, false, false, "WARM_NOPRE", r)
			await _visit(pid, false, true, "WARM_PRE", r)
	if _out_path != "":
		var f := FileAccess.open(_out_path, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(_lines) + "\n")
			f.close()
			print("PP wrote ", _out_path)
	get_tree().quit()


## One whole visit: optionally clear the cache, optionally prebuild, then build the real world scene
## and free it again. Returns after the world is gone and the tree has settled.
func _visit(pid: String, clear_cache: bool, prebuild: bool, tag: String, rep: int) -> void:
	GameState.current_planet_id = pid
	if clear_cache:
		Planet._geo_cache.clear()
		Planet._geo_pending.clear()
	var data := load("res://src/planet/data/%s.tres" % pid) as PlanetData
	var calls0 := PlanetProps.populate_calls
	var pre_ms := 0.0
	if prebuild:
		var t0 := Time.get_ticks_usec()
		Planet.prebuild(data)
		pre_ms = float(Time.get_ticks_usec() - t0) / 1000.0
	var packed: PackedScene = load(WORLD_SCENE)
	var t1 := Time.get_ticks_usec()
	var w: Node = packed.instantiate()
	get_tree().root.add_child(w)
	var world_ms := float(Time.get_ticks_usec() - t1) / 1000.0
	var calls := PlanetProps.populate_calls - calls0
	if tag != "WARMUP":
		_say("PP %-10s %-5s rep=%d prebuild_ms=%8.1f world_ms=%8.1f total_ms=%8.1f populate=%d geo_cache=%d" % [
			tag, pid, rep, pre_ms, world_ms, pre_ms + world_ms, calls, Planet._geo_cache.size()])
	if _dump_path != "" and tag == "COLD_PRE" and rep == 0:
		_dump_scatter(w, pid)
	# queue_free, NOT remove_child first: several systems read absolute node paths in their exit
	# handlers, and detaching the subtree before freeing it makes every one of them print an error.
	w.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _say(s: String) -> void:
	print(s)
	_lines.append(s)


# ---------------------------------------------------------------------------------- scatter dump
## Writes every placed thing on the planet in a stable order, at full float precision. Two dumps that
## differ by a single digit mean the scatter changed; identical dumps mean it did not.
func _dump_scatter(world: Node, pid: String) -> void:
	var planet := world.get_node_or_null("Planet") as Planet
	if planet == null:
		print("PP dump: no Planet node")
		return
	var out := PackedStringArray()
	out.append("planet=%s radius=%s" % [pid, str(planet.radius)])
	out.append("--- registered props (dir, footprint) ---")
	for i in planet._prop_dirs.size():
		out.append("prop %d %s %s" % [i, _v3(planet._prop_dirs[i]), str(planet._prop_radii[i])])
	out.append("--- scene tree ---")
	for root_name in ["Props", "Collectibles"]:
		var r := planet.get_node_or_null(root_name) as Node3D
		if r == null:
			out.append("%s: MISSING" % root_name)
			continue
		_walk(r, root_name, out)
	var path := _dump_path
	if _planets.size() > 1:
		path = _dump_path.get_basename() + "_" + pid + "." + _dump_path.get_extension()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(out) + "\n")
		f.close()
		print("PP dumped scatter for %s -> %s (%d lines)" % [pid, path, out.size()])


## Auto-generated node names (`@MultiMeshInstance3D@964`) carry a PROCESS-WIDE counter, so the same
## scatter built at a different moment in the process gets different numbers. Two dumps would then
## differ on every such line while the geometry was identical. Auto names are replaced by the child's
## index under its parent, which is exactly the thing that has to stay the same.
static func _stable_name(n: Node, idx: int) -> String:
	var nm := String(n.name)
	return "#%d:%s" % [idx, n.get_class()] if nm.begins_with("@") else nm


func _walk(n: Node, path: String, out: PackedStringArray) -> void:
	if n is Node3D:
		out.append("%s|%s|%s" % [path, n.get_class(), _xf(n.transform)])
	if n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		if mm != null:
			out.append("%s|MM count=%d" % [path, mm.instance_count])
			for i in mm.instance_count:
				out.append("%s|MM%d|%s|%s" % [path, i, _xf(mm.get_instance_transform(i)),
					str(mm.get_instance_custom_data(i)) if mm.use_custom_data else "-"])
	var i := 0
	for c in n.get_children():
		_walk(c, path + "/" + _stable_name(c, i), out)
		i += 1


func _v3(v: Vector3) -> String:
	return "%.9f,%.9f,%.9f" % [v.x, v.y, v.z]


func _xf(t: Transform3D) -> String:
	return "%s;%s;%s;%s" % [_v3(t.basis.x), _v3(t.basis.y), _v3(t.basis.z), _v3(t.origin)]
