extends "res://tests/director/cam_fade_probe.gd"
## CamFadeBenchProbe (was FrameBenchProbe in the lead's cost measurement) - measures real per-frame wall-clock time (Time.get_ticks_usec() deltas) at a
## fixed camera spot, to check whether a shader that CAN discard (but whose branch is never taken
## here, cam_fade stays 0.0) costs GPU time on a tile-based renderer.
##
## Extends CamFadeProbe purely to reuse its stage()/_snap_to_target() camera placement — none of
## the occluder-fade logic is touched or measured here.
##
## Usage via Director "call" steps:
##   stage("Lamp")        -- park player+camera at a fixed plaza spot (inherited from CamFadeProbe)
##   start_bench()         -- run WARMUP+MEASURE at current scaling_3d_scale, then again at 2.0,
##                            print two "FRAMEBENCH report[...]" lines, then quit the process.

const WARMUP := 300
const MEASURE := 900
const SCALE_2 := 2.0

enum Phase { IDLE, WARM1, MEAS1, WARM2, MEAS2, DONE }
var _phase := Phase.IDLE
var _count := 0
var _times_us: Array = []
var _last_tick := 0
var _scale1 := 0.0


func start_bench() -> void:
	_scale1 = get_viewport().scaling_3d_scale
	print("FRAMEBENCH start_bench scale1=%.3f warmup=%d measure=%d" % [_scale1, WARMUP, MEASURE])
	_phase = Phase.WARM1
	_count = 0
	_times_us.clear()
	_last_tick = Time.get_ticks_usec()


func _process(_delta: float) -> void:
	if _phase == Phase.IDLE or _phase == Phase.DONE:
		return
	var now := Time.get_ticks_usec()
	var dt_us := now - _last_tick
	_last_tick = now
	match _phase:
		Phase.WARM1:
			_count += 1
			if _count >= WARMUP:
				_phase = Phase.MEAS1
				_count = 0
				_times_us.clear()
		Phase.MEAS1:
			_times_us.append(dt_us)
			_count += 1
			if _count >= MEASURE:
				_report("scale=%.2f" % _scale1)
				get_viewport().scaling_3d_scale = SCALE_2
				print("FRAMEBENCH scale_set to=%.3f" % get_viewport().scaling_3d_scale)
				_phase = Phase.WARM2
				_count = 0
		Phase.WARM2:
			_count += 1
			if _count >= WARMUP:
				_phase = Phase.MEAS2
				_count = 0
				_times_us.clear()
		Phase.MEAS2:
			_times_us.append(dt_us)
			_count += 1
			if _count >= MEASURE:
				_report("scale=%.2f" % SCALE_2)
				_phase = Phase.DONE
				print("FRAMEBENCH all_done")
				get_tree().quit()


func _report(tag: String) -> void:
	var arr: Array = _times_us.duplicate()
	arr.sort()
	var n := arr.size()
	var sum := 0.0
	for v in arr:
		sum += float(v)
	var mean_ms := (sum / n) / 1000.0
	var median_ms: float
	if n % 2 == 1:
		median_ms = float(arr[n / 2]) / 1000.0
	else:
		median_ms = (float(arr[n / 2 - 1]) + float(arr[n / 2])) / 2.0 / 1000.0
	var p95_idx := int(ceil(0.95 * n)) - 1
	p95_idx = clampi(p95_idx, 0, n - 1)
	var p95_ms := float(arr[p95_idx]) / 1000.0
	var min_ms := float(arr[0]) / 1000.0
	var max_ms := float(arr[n - 1]) / 1000.0
	print("FRAMEBENCH report[%s] n=%d median_ms=%.4f mean_ms=%.4f p95_ms=%.4f min_ms=%.4f max_ms=%.4f" % [
		tag, n, median_ms, mean_ms, p95_ms, min_ms, max_ms])


## First-fade hitch (E2). GPU-bound at scaling_3d_scale 2.0: stages `name_fragment`, keeps it out of
## the rig's sight-line query while 240 baseline frames are timed, then lets the probe see it and times
## the next 30 frames - the first fade of the process, which is where the material copies are made.
## Prints the baseline median / p95 and each following frame, marking the frame the copies appeared.
func hitch_test(name_fragment: String) -> void:
	get_viewport().scaling_3d_scale = SCALE_2
	var prop := stage(name_fragment)
	if prop == null or not (prop is CollisionObject3D):
		print("FRAMEBENCH hitch: nothing staged")
		get_tree().quit()
		return
	var id := prop.get_instance_id()
	var q: PhysicsShapeQueryParameters3D = _rig.get("_sight_query")
	q.exclude = [(prop as CollisionObject3D).get_rid()]
	var faded: Dictionary = _rig.get("_faded")
	for k: int in faded:
		(faded[k] as Dictionary)["want"] = 0.0
	for i in range(90):
		await get_tree().process_frame
	print("FRAMEBENCH hitch entries_before=%d" % (_rig.get("_faded") as Dictionary).size())
	var base: Array = []
	var last := Time.get_ticks_usec()
	for i in range(240):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		base.append(now - last)
		last = now
	q.exclude = []
	var after: Array[String] = []
	var swap_at := -1
	for i in range(30):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var f: Dictionary = _rig.get("_faded")
		var has_swaps := f.has(id) and (f[id] as Dictionary).has("swaps")
		var has_t := f.has(id) and float((f[id] as Dictionary)["t"]) > 0.0
		if swap_at < 0 and (has_swaps or (has_t and not (_rig.get("_dither_fade") == true))):
			swap_at = i
		after.append("%.2f%s" % [(now - last) / 1000.0, "*" if swap_at == i else ""])
		last = now
	base.sort()
	var med := float(base[base.size() / 2]) / 1000.0
	var p95 := float(base[int(0.95 * base.size())]) / 1000.0
	print("FRAMEBENCH hitch prop=%s dither=%s base_median_ms=%.3f base_p95_ms=%.3f first_fade_frame=%d next30_ms=[%s]" % [
		str(prop.name), str(_rig.get("_dither_fade")), med, p95, swap_at, ", ".join(after)])
	get_tree().quit()
