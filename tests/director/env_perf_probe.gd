extends Node
## Environment perf probe: injected into /root/World by a Director "call" step
## ({"call": {"node": "/root/World", "method": "_spawn_optional",
##            "args": ["res://tests/director/env_perf_probe.tscn", "EnvPerf"]}}).
##
## Samples the viewport's measured CPU and GPU render time every frame after a short warm-up and
## prints mean / p95 once. Used to prove a shadow-quality change did not cost frame budget.
##
## V-sync is switched off and the fps cap lifted while the probe lives, otherwise every frame reads
## back as a flat 16.6 ms and real headroom is invisible.

const WARMUP_SEC := 1.5
const SAMPLE_SEC := 4.0

var _elapsed := 0.0
var _cpu: PackedFloat32Array = PackedFloat32Array()
var _gpu: PackedFloat32Array = PackedFloat32Array()
var _fps: PackedFloat32Array = PackedFloat32Array()
var _draws: PackedFloat32Array = PackedFloat32Array()
var _reported := false
var _vp: RID


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)
	print("ENVPERF probe armed (vsync off)")


func _process(delta: float) -> void:
	if _reported:
		return
	_elapsed += delta
	if _elapsed < WARMUP_SEC:
		return
	if _elapsed < WARMUP_SEC + SAMPLE_SEC:
		_cpu.append(float(RenderingServer.viewport_get_measured_render_time_cpu(_vp)))
		_gpu.append(float(RenderingServer.viewport_get_measured_render_time_gpu(_vp)))
		_fps.append(float(Performance.get_monitor(Performance.TIME_FPS)))
		_draws.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		return
	_report()


## Prints the collected frame-cost statistics exactly once.
func _report() -> void:
	_reported = true
	RenderingServer.viewport_set_measure_render_time(_vp, false)
	if _cpu.is_empty():
		print("ENVPERF no samples")
		return
	print("ENVPERF n=%d | cpu_ms mean=%.3f p95=%.3f | gpu_ms mean=%.3f p95=%.3f | fps mean=%.1f min=%.1f | draws=%.0f" % [
		_cpu.size(), _mean(_cpu), _pct(_cpu, 0.95), _mean(_gpu), _pct(_gpu, 0.95),
		_mean(_fps), _min(_fps), _mean(_draws)])


static func _mean(a: PackedFloat32Array) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / float(a.size())


static func _max(a: PackedFloat32Array) -> float:
	var m := -INF
	for v in a:
		m = maxf(m, v)
	return m


static func _min(a: PackedFloat32Array) -> float:
	var m := INF
	for v in a:
		m = minf(m, v)
	return m


static func _pct(a: PackedFloat32Array, p: float) -> float:
	var c := a.duplicate()
	c.sort()
	var i := clampi(int(round(p * float(c.size() - 1))), 0, c.size() - 1)
	return c[i]
