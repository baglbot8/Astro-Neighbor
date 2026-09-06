extends Node
## Test rig for the rocket round trip. Not part of the game: a Director timeline injects it and
## calls `report("tag")` before and after a trip so the run itself proves that flying home -> zorp
## -> bolt -> hub -> home does not quietly lose stardust, inventory, placed decorations or favours,
## and does not leave a modal or a frozen player behind.
##
## Injected with:
##   {"call": {"node": "/root/World", "method": "_spawn_optional",
##             "args": ["res://src/rocket/journey_probe.tscn", "JourneyProbe"]}}
## then driven with:
##   {"call": {"node": "/root/World/JourneyProbe", "method": "report", "args": ["before"]}}
##
## Everything it prints is a plain `print`, so it never trips `tools/check.sh`'s error grep.

## Rolling frame-time window, so `report` can quote an average rather than whatever one frame the
## Director happened to land on (which is usually the frame the probe itself was spawned in).
var _samples: PackedFloat32Array = PackedFloat32Array()
var _max_ms := 0.0

# --------------------------------------------------------------------------- continuous frame trace
## `persist()` reparents this node to /root so it OUTLIVES the two scene swaps a journey makes
## (pad -> space -> destination). A probe parented under /root/World dies with the scene, which is
## exactly the seam we most need numbers for: the swap frame itself is the one that stalls.
##
## Times are WALL CLOCK (`Time.get_ticks_usec`), not `delta`, because a `--write-movie` capture runs
## at a fixed delta and would report a perfectly smooth journey no matter how badly it hitched. Run
## the trace WINDOWED (no --write-movie) for real numbers.
const TRACE_CAP := 24000
var _persist := false
var _tracing := false
var _last_usec := 0
var _t0_usec := 0
var _trace_ms: PackedFloat32Array = PackedFloat32Array()
var _trace_t: PackedFloat32Array = PackedFloat32Array()
var _marks: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Move to /root so the trace survives `RocketJourney.swap_scene`. Call it right after spawning;
## every later Director call must then address `/root/JourneyProbe`, not `/root/World/JourneyProbe`.
func persist() -> void:
	if _persist:
		return
	_persist = true
	call_deferred("_detach")
	print("PROBE persist -> /root/JourneyProbe")


func _detach() -> void:
	var root := get_tree().root
	if get_parent() != root:
		reparent(root)


## Begin (or restart) the per-frame trace. `tag` names the run in the printed table.
func trace_start(tag: String = "run") -> void:
	_tracing = true
	_trace_ms.clear()
	_trace_t.clear()
	_marks.clear()
	_t0_usec = Time.get_ticks_usec()
	_last_usec = _t0_usec
	_marks.append([0.0, tag + ":start"])
	print("PROBE trace start [%s]" % tag)


## Label the current moment so a spike can be located in the journey rather than just counted.
func mark(label: String) -> void:
	if not _tracing:
		return
	_marks.append([float(Time.get_ticks_usec() - _t0_usec) / 1e6, label])


func _process(delta: float) -> void:
	var ms := delta * 1000.0
	_samples.append(ms)
	_max_ms = maxf(_max_ms, ms)
	if _samples.size() > 120:
		_samples.remove_at(0)
	if _tracing:
		var now := Time.get_ticks_usec()
		var wall := float(now - _last_usec) / 1000.0
		_last_usec = now
		if _trace_ms.size() < TRACE_CAP:
			_trace_ms.append(wall)
			_trace_t.append(float(now - _t0_usec) / 1e6)
		_auto_mark()


## Marks phase changes the probe can see from outside: which scene is current, which planet
## GameState thinks we are on, and which leg of the journey is running. Automatic, so a spike lands
## on the exact frame boundary instead of on whatever the Director happened to log nearby.
var _phase_key := ""

func _auto_mark() -> void:
	var scene := get_tree().current_scene
	var pad := get_node_or_null("/root/World/Rocket")
	var stage := "-"
	if pad != null:
		if GameState.flag("rocket_arriving"):
			stage = "descent"
		elif bool(pad.get("_cutscene")):
			stage = "launch"
		else:
			stage = "ground"
	var key := "%s/%s/%s%s" % [scene.name if scene != null else "none",
		GameState.current_planet_id, RocketJourney.leg, stage]
	if key == _phase_key:
		return
	_phase_key = key
	_marks.append([float(Time.get_ticks_usec() - _t0_usec) / 1e6, key])


## The whole point of the rig: percentiles plus every hitch, each located against the nearest mark.
## `spike_ms` is the "the player would feel that" threshold; 33 ms is two dropped frames at 60.
func trace_report(spike_ms: float = 33.0) -> void:
	_tracing = false
	var n := _trace_ms.size()
	if n < 8:
		print("PROBE trace: not enough samples (%d)" % n)
		return
	# Frame 0 measures from trace_start to the first _process, which is not a frame time.
	var sorted := PackedFloat32Array(_trace_ms.slice(1))
	sorted.sort()
	var m := sorted.size()
	var total := 0.0
	for v in sorted:
		total += v
	print("PROBE TRACE  frames=%d  span=%.1fs  mean=%.2f  median=%.2f  p95=%.2f  p99=%.2f  max=%.2f (ms)"
		% [m, _trace_t[n - 1], total / float(m), sorted[m / 2], sorted[mini(m - 1, int(m * 0.95))],
		sorted[mini(m - 1, int(m * 0.99))], sorted[m - 1]])
	var over := 0
	for v in sorted:
		if v > spike_ms:
			over += 1
	print("PROBE TRACE  frames over %.0f ms: %d (%.2f%%)" % [spike_ms, over, 100.0 * over / float(m)])
	var listed := 0
	for i in range(1, n):
		if _trace_ms[i] <= spike_ms:
			continue
		listed += 1
		if listed > 40:
			print("PROBE TRACE  ... (more spikes not listed)")
			break
		print("PROBE SPIKE  t=%7.3fs  %8.2f ms   [%s]" % [_trace_t[i], _trace_ms[i], _phase_at(_trace_t[i])])
	if listed == 0:
		print("PROBE TRACE  no frame over %.0f ms" % spike_ms)
	_phase_table()


## Per-phase breakdown. A single median hides a rough stretch inside a smooth journey, and the
## question the user actually asked - "the approach is choppy" - is a question about one phase.
func _phase_table() -> void:
	for mi in _marks.size():
		var t_from := float(_marks[mi][0])
		var t_to := float(_marks[mi + 1][0]) if mi + 1 < _marks.size() else 1e9
		var seg := PackedFloat32Array()
		for i in range(1, _trace_ms.size()):
			if _trace_t[i] >= t_from and _trace_t[i] < t_to:
				seg.append(_trace_ms[i])
		if seg.size() < 4:
			continue
		seg.sort()
		var s := seg.size()
		print("PROBE PHASE  %-34s frames=%4d  median=%6.2f  p95=%6.2f  max=%7.2f ms" %
			[str(_marks[mi][1]), s, seg[s / 2], seg[mini(s - 1, int(s * 0.95))], seg[s - 1]])


func _phase_at(t: float) -> String:
	var label := "?"
	for entry: Array in _marks:
		if float(entry[0]) <= t:
			label = "%s +%.2fs" % [str(entry[1]), t - float(entry[0])]
		else:
			break
	return label


func _avg_ms() -> float:
	if _samples.is_empty():
		return 0.0
	var total := 0.0
	for v in _samples:
		total += v
	return total / float(_samples.size())


## Seeds a known state so the "after" line has something to lose.
func seed() -> void:
	GameState.add_stardust(137)
	GameState.add_item("deco_moon_lamp", 2)
	GameState.add_item("deco_crater_bench", 1)
	GameState.favors["probe_favor"] = {
		"npc": "zorp", "type": "fetch", "target_item": "deco_moon_lamp", "count": 1,
		"progress": 1, "state": "active", "reward_item": "deco_star_projector",
		"reward_stardust": 40, "deliver_to": "zorp",
	}
	print("PROBE seeded")


## One line of everything a trip could plausibly drop.
func report(tag: String = "") -> void:
	var deco := PackedStringArray()
	for pid: String in GameState.placed_decorations:
		deco.append("%s:%d" % [pid, (GameState.placed_decorations[pid] as Array).size()])
	var items := PackedStringArray()
	for id: String in GameState.inventory:
		items.append("%s x%d" % [id, int(GameState.inventory[id])])
	var player := get_node_or_null("/root/World/Player")
	var input_enabled: Variant = player.get("input_enabled") if player != null else null
	print("PROBE[%s] frame_ms avg %.2f max %.2f over %d frames  fps=%.1f  draws=%d" % [tag,
		_avg_ms(), _max_ms, _samples.size(), Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	_samples.clear()
	_max_ms = 0.0
	print("PROBE[%s] planet=%s prev=%s stardust=%d items={%s} placed={%s} favors=%d wardrobe=%d " %
		[tag, GameState.current_planet_id, GameState.previous_planet_id, GameState.stardust,
		", ".join(items), ", ".join(deco), GameState.favors.size(), GameState.wardrobe.size()] +
		"modals=%d input_enabled=%s paused=%s day=%d" %
		[EventBus.open_modals().size(), str(input_enabled), get_tree().paused, GameState.day_count])


## Rocket-model state that a screenshot cannot show from the wrong side of the hull: whether the
## boarding ladder is stowed. It must be DOWN on a parked rocket and UP for the whole flight.
func rocket_state(tag: String = "") -> void:
	var pad := get_node_or_null("/root/World/Rocket")
	if pad == null:
		print("PROBE[%s] rocket: no pad" % tag)
		return
	var model: Node = pad.get("rocket")
	if model == null or not is_instance_valid(model):
		print("PROBE[%s] rocket: no model" % tag)
		return
	var ladder := model.get_node_or_null("Hull/Ladder") as Node3D
	print("PROBE[%s] ladder=%s flame=%.2f busy=%s" % [tag,
		("down" if ladder != null and ladder.visible else ("STOWED" if ladder != null else "missing")),
		float(model.call("flame_scale")), str(pad.get("_busy"))])
