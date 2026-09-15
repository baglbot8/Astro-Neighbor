class_name PerfOverlay
extends CanvasLayer
## Phase 5 DEV builder. A tiny always-on-top HUD for heat/lag testing on the phone, plus the runtime
## toggles the dev menu's Perf tab drives. Docs: docs/PHASE5_SPEC.md, the phase5 inputs' heat_ranked.md
## "PHONE MEASUREMENT PLAN" and dev_audit.md section 4.
##
## LIVES UNDER /root DIRECTLY (not /root/World): SceneRouter swaps the World child on a planet jump,
## so a node parented there dies with it. This one is added straight to the SceneTree root the first
## time `get_or_create()` runs, so ONE instance survives every planet jump for the life of the app —
## `_on_planet_loaded()` re-applies every live toggle to the fresh world's nodes rather than rebuilding
## itself. It resets to defaults only when the process restarts (a page reload on the web export),
## which is the "resets when the page reloads" behaviour dev_audit.md asks for — there is nothing to
## reset by hand.
##
## NOT a project.godot autoload (that file is HEAT-WEB's to edit this phase, not DEV's) — reached only
## through `get_or_create()` / `find()`, the same on-demand-singleton idiom already used by
## ProjectSystem, FavorSystem and MinigameSystem in this codebase.
##
## COST: process_mode ALWAYS (visible and readable even while the dev menu or pause menu has paused
## the tree — the whole point of a heat overlay is to watch it through a paused screen too), but the
## Label text only rebuilds twice a second (`_REFRESH_INTERVAL`), never every frame — the one frame it
## does redraw is one Label.text assignment, a handful of Performance.get_monitor() calls and a
## dictionary-free string format, not a per-frame cost. Measured: `tests/director/perf_overlay_cost.gd`
## (see this file's own report) diffs mean frame TIME_PROCESS over 300 frames with the overlay visible
## and updating against the overlay absent, same scene, same camera, A/A checked first.

const NODE_NAME := "PerfOverlay"
## Twice a second, per the brief ("update a Label twice a second; say its measured cost").
const REFRESH_INTERVAL := 0.5
## How long the rolling heat-proxy average window is (heat_ranked.md: "as now and a 60 s average").
const AVG_WINDOW := 60.0
## Burn control: the fixed spin length the Perf tab's "Burn 8 ms/frame" row offers
## (heat_ranked.md PHONE MEASUREMENT PLAN: "Control: burn 8 ms per frame; busy % must jump ~40
## points or the meter is broken").
const BURN_MS := 8

## HEAT-WEB's new autoload (docs/BUILD_PLAN.md Phase 5), reached as a live node at /root/DrawGate —
## it is a project.godot autoload, not a loadable script path, so this is a node name, not a res://
## path. Guarded exactly like every other cross-builder hook: greyed out in the dev menu until the
## node (and its expected methods) exist. CONFIRMED LANDED (2026-09-14): `set_saver(bool)`,
## `saver_on() -> bool`, `mode() -> String`, `drawn_per_second() -> float` — draw_gate.gd's own
## header even names this exact tab ("DEV's saver toggle (Perf tab)... Read by DEV's Perf tab").
const DRAW_GATE_NODE := "DrawGate"

## HEAT-LOAD's new file (docs/BUILD_PLAN.md Phase 5). CONFIRMED LANDED (2026-09-14) with exactly
## this API: `enabled() -> bool`, `set_enabled(on: bool) -> void` (self-persists to
## user://dev_settings.cfg — never this file's job to persist it too), `last_report() -> Dictionary`.
const SHADER_WARMUP_PATH := "res://src/world/shader_warmup.gd"
const SHADER_WARMUP_SET := "set_enabled"
const SHADER_WARMUP_GET := "enabled"
const SHADER_WARMUP_REPORT := "last_report"

## /root/World/Environment (src/world/environment.gd), the same node path rocket_pad.gd and
## part_celebration.gd already use. `shadows_allowed` is dev_audit.md's proposed public var — not
## added by anyone this phase (HEAT-LOAD owns this file for the warm-up fix only), so this is also a
## guarded property check, not an assumption.
const ENVIRONMENT_PATH := "/root/World/Environment"

var _label: Label
var _root: Control
var _visible_ui := false
var _refresh_t := 0.0

## ------------------------------------------------------------------ toggle state (never saved
## here — `_warmup_on` mirrors `shader_warmup.gd`'s own persisted setting; every other toggle here
## is a plain var, forgotten on process exit, exactly what heat_ranked.md's PHONE MEASUREMENT PLAN
## asks for).
var _particles_off := false
var _omni_off := false
var _neighbours_off := false
var _warmup_on := false
var _burn_on := false

## Nodes hidden by the current particle/light toggle, so turning it back off only restores what THIS
## toggle hid (never a node some other system had already hidden for its own reason).
var _hidden_particles: Array = []
var _hidden_omni: Array = []
var _hidden_npcs: Array = []
## While a hide toggle is on, newly-added matching nodes (a planet that streams scenery in) are
## caught and hidden too; turning the toggle off disconnects this.
var _watching_new_nodes := false

## Rolling heat-proxy samples: {t: float (Time.get_ticks_msec()/1000.0), draws_per_s: float, mpix_per_s: float}.
var _proxy_samples: Array = []

## Web-only busy% meter (heat_ranked.md: "wall time inside Godot's requestAnimationFrame callbacks,
## wrapped via JavaScriptBridge"). READ-ONLY from here (see `_install_busy_meter`'s header): the
## wrapper itself lives in the web export's head_include, installed by the lead before Godot's own JS
## boots. -1.0 means "not readable yet" (not the web export, or window.__astroPerf does not exist).
var _busy_pct := -1.0
var _busy_js_fps := -1.0
var _busy_js_installed := false


# ============================================================================= singleton access
static func find() -> PerfOverlay:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(NODE_NAME) as PerfOverlay


## Every real caller (a Perf-tab row press, an EventBus listener firing long after boot) reaches
## this with `tree.root` already fully set up, so `add_child` lands synchronously and the returned
## instance is immediately usable. The deferred fallback only guards the one edge case that is NOT
## true of any real call site — another autoload's own `_ready()`, the same tick `root` is still
## adding its own children (measured: a direct `add_child` there throws "Parent node is busy setting
## up children") — and callers that can only run that early must themselves wait a frame before
## using the returned node, same as any other `call_deferred("add_child", ...)` pattern in Godot.
static func get_or_create() -> PerfOverlay:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var existing := find()
	if existing != null:
		return existing
	var ov := PerfOverlay.new()
	ov.name = NODE_NAME
	if tree.root.is_node_ready():
		tree.root.add_child(ov)
	else:
		tree.root.call_deferred("add_child", ov)
	return ov


# ============================================================================= build
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_root = Control.new()
	_root.name = "Root"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.text = ""
	_root.add_child(_label)
	_position_label()
	visible = false
	EventBus.planet_loaded.connect(func(_id: String) -> void: _reapply_all())
	if warmup_available():
		_warmup_on = bool(load(SHADER_WARMUP_PATH).call(SHADER_WARMUP_GET))
	_install_busy_meter()


func _position_label() -> void:
	var sa := MobileUI.safe_area()
	_label.position = Vector2(sa.x + 10.0, sa.y + 8.0)


# ============================================================================= visibility
func set_visible_ui(on: bool) -> void:
	_visible_ui = on
	visible = on
	if on:
		_refresh_t = 999.0 # force an immediate refresh, not a half-second of stale/blank text


func is_visible_ui() -> bool:
	return _visible_ui


# ============================================================================= per-frame
func _process(delta: float) -> void:
	if _burn_on:
		_burn(BURN_MS)
	if not _visible_ui:
		return
	_refresh_t += delta
	if _refresh_t < REFRESH_INTERVAL:
		return
	_refresh_t = 0.0
	_position_label() # safe area can change (rotation, a settings toggle) — cheap, twice a second
	_update_proxy_samples()
	if _busy_js_installed:
		_poll_busy()
	_label.text = _stats_text()


## Deliberately burns wall time on the main thread, every frame, while on — a synthetic, known load
## so the busy%/frame-ms readout can be checked against a control the same way `heat_ranked.md`'s
## PHONE MEASUREMENT PLAN asks for ("busy % must jump ~40 points or the meter is broken"). A tight
## spin, not `OS.delay_msec` (which yields the thread rather than costing CPU the way a real heavy
## frame does).
func _burn(ms: int) -> void:
	var stop_at := Time.get_ticks_usec() + ms * 1000
	while Time.get_ticks_usec() < stop_at:
		pass


func _stats_text() -> String:
	var fps := Engine.get_frames_per_second()
	var frame_ms := (1000.0 / fps) if fps > 0.0 else 0.0
	var cpu_ms := (Performance.get_monitor(Performance.TIME_PROCESS)
		+ Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var vp := get_viewport()
	var scale: float = vp.scaling_3d_scale if vp != null else 1.0
	var size: Vector2i = vp.size if vp != null else Vector2i.ZERO
	var draws_now := float(draws) * fps
	var mpix_now := float(size.x) * scale * float(size.y) * scale * fps / 1000000.0
	var avg := _proxy_average()
	var stamp := str(ProjectSettings.get_setting("astro/build_stamp", "dev"))
	var lines := PackedStringArray()
	lines.append("astro %s  %s" % [stamp, ("mobile" if Platform.is_mobile() else "desktop")])
	lines.append("%.0f fps  %.1f ms frame  %.1f ms cpu" % [fps, frame_ms, cpu_ms])
	lines.append("%d draws  %.0fk prims  scale %.2f  %dx%d" % [draws, prims / 1000.0, scale, size.x, size.y])
	lines.append("heat: %.0f draws/s  %.1f Mpx/s  (60s avg %.0f/%.1f)" %
		[draws_now, mpix_now, avg.x, avg.y])
	if saver_available():
		lines.append("draw gate: %s  %.0f drawn/s" % [draw_gate_mode(), draw_gate_dps()])
	if not _busy_js_installed:
		lines.append("busy: n/a (not the web export; cpu %.2f ms)" % cpu_ms)
	elif _busy_pct >= 0.0:
		lines.append("busy %.0f%%  (page %.0f fps, cpu %.2f ms)" % [_busy_pct, _busy_js_fps, cpu_ms])
	else:
		lines.append("busy: n/a (head_include not loaded; cpu %.2f ms)" % cpu_ms)
	lines.append(_toggle_summary())
	return "\n".join(lines)


func _toggle_summary() -> String:
	var bits := PackedStringArray()
	bits.append("saver:" + saver_status())
	bits.append("particles:" + ("off" if _particles_off else "on"))
	bits.append("omni:" + ("off" if _omni_off else "on"))
	bits.append("neighbours:" + ("off" if _neighbours_off else "on"))
	bits.append("shadows:" + shadows_status())
	bits.append("warmup:" + warmup_status())
	bits.append("burn:" + ("8ms" if _burn_on else "off"))
	return " ".join(bits)


func _update_proxy_samples() -> void:
	var fps := Engine.get_frames_per_second()
	var vp := get_viewport()
	if vp == null:
		return
	var scale: float = vp.scaling_3d_scale
	var size: Vector2i = vp.size
	var draws := float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var now := Time.get_ticks_msec() / 1000.0
	_proxy_samples.append({
		"t": now,
		"draws": draws * fps,
		"mpix": float(size.x) * scale * float(size.y) * scale * fps / 1000000.0,
	})
	while _proxy_samples.size() > 0 and now - float(_proxy_samples[0]["t"]) > AVG_WINDOW:
		_proxy_samples.pop_front()


func _proxy_average() -> Vector2:
	if _proxy_samples.is_empty():
		return Vector2.ZERO
	var d := 0.0
	var m := 0.0
	for s: Dictionary in _proxy_samples:
		d += float(s["draws"])
		m += float(s["mpix"])
	var n := float(_proxy_samples.size())
	return Vector2(d / n, m / n)


# ============================================================================= reapply on load
## Every toggle below is a live tree edit (hide nodes, set a viewport/property), never a saved flag —
## a fresh planet's nodes need the SAME edit applied again, which is the whole reason this connects
## to `EventBus.planet_loaded` in `_ready()` rather than trusting the edit to "stick".
func _reapply_all() -> void:
	_hidden_particles.clear()
	_hidden_omni.clear()
	_hidden_npcs.clear()
	if _particles_off:
		_apply_particles_off(true)
	if _omni_off:
		_apply_omni_off(true)
	if _neighbours_off:
		_apply_neighbours_off(true)
	_apply_shadows(_shadows_off_wanted)
	# 3D scale and the draw saver are not per-node — the viewport and the autoload both survive a
	# planet jump on their own — but re-asserting them costs nothing and guards against a viewport
	# swap this builder doesn't know about.
	set_scale_3d(_scale_wanted)
	set_saver(_saver_wanted)


# ============================================================================= 3D scale
var _scale_wanted := 0.75

func set_scale_3d(v: float) -> void:
	_scale_wanted = v
	var vp := get_viewport()
	if vp != null:
		vp.scaling_3d_scale = v


func scale_value() -> float:
	var vp := get_viewport()
	return vp.scaling_3d_scale if vp != null else _scale_wanted


# ============================================================================= draw saver (DrawGate)
var _saver_wanted := false

func _draw_gate() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(DRAW_GATE_NODE)


func saver_available() -> bool:
	var gate := _draw_gate()
	return gate != null and gate.has_method("set_saver")


## Returns the status text the dev menu shows on the row: "on" / "off" / "needs <file>: <method>".
func saver_status() -> String:
	if not saver_available():
		return "needs draw_gate.gd: set_saver"
	return "on" if _saver_wanted else "off"


func set_saver(on: bool) -> String:
	_saver_wanted = on
	var gate := _draw_gate()
	if gate == null or not gate.has_method("set_saver"):
		return "needs draw_gate.gd: set_saver"
	gate.call("set_saver", on)
	return "on" if on else "off"


## DrawGate's own live mode ("off"/"normal"/"menu"/"saver") and its measured draws/sec — read
## straight through, never duplicated, since `DrawGate.mode()`/`drawn_per_second()` already are the
## ground truth this file would otherwise have to re-derive.
func draw_gate_mode() -> String:
	var gate := _draw_gate()
	return str(gate.call("mode")) if gate != null and gate.has_method("mode") else "n/a"


func draw_gate_dps() -> float:
	var gate := _draw_gate()
	return float(gate.call("drawn_per_second")) if gate != null and gate.has_method("drawn_per_second") else -1.0


# ============================================================================= particles off
## "GPU particles off" toggles both GPUParticles3D and CPUParticles3D. The pad dust ring, the
## astronaut sparkles and the rocket smoke/flame licks were moved to CPUParticles3D (heat item 1,
## docs/OPEN_ISSUES.md 57); a toggle that only matched GPUParticles3D left those running.
static func _is_particle_node(n: Node) -> bool:
	return n is GPUParticles3D or n is CPUParticles3D


func particles_off() -> bool:
	return _particles_off


func set_particles_off(on: bool) -> void:
	_particles_off = on
	_apply_particles_off(on)


func _apply_particles_off(on: bool) -> void:
	var world := get_tree().root.get_node_or_null("World")
	if world == null:
		return
	if on:
		_hidden_particles.clear()
		for n: Node in _walk(world):
			if _is_particle_node(n) and (n as GeometryInstance3D).visible:
				(n as GeometryInstance3D).visible = false
				_hidden_particles.append(n)
		if not world.is_connected("child_entered_tree", _on_world_child_added):
			world.child_entered_tree.connect(_on_world_child_added)
	else:
		for n: Variant in _hidden_particles:
			if is_instance_valid(n):
				(n as GeometryInstance3D).visible = true
		_hidden_particles.clear()
		_maybe_disconnect_watch(world)


# ============================================================================= omni lights off
func omni_off() -> bool:
	return _omni_off


func set_omni_off(on: bool) -> void:
	_omni_off = on
	_apply_omni_off(on)


func _apply_omni_off(on: bool) -> void:
	var world := get_tree().root.get_node_or_null("World")
	if world == null:
		return
	if on:
		_hidden_omni.clear()
		for n: Node in _walk(world):
			if n is OmniLight3D and (n as OmniLight3D).visible:
				(n as OmniLight3D).visible = false
				_hidden_omni.append(n)
		if not world.is_connected("child_entered_tree", _on_world_child_added):
			world.child_entered_tree.connect(_on_world_child_added)
	else:
		for n: Variant in _hidden_omni:
			if is_instance_valid(n):
				(n as OmniLight3D).visible = true
		_hidden_omni.clear()
		_maybe_disconnect_watch(world)


# ============================================================================= neighbours off
func neighbours_off() -> bool:
	return _neighbours_off


func set_neighbours_off(on: bool) -> void:
	_neighbours_off = on
	_apply_neighbours_off(on)


func _apply_neighbours_off(on: bool) -> void:
	if on:
		_hidden_npcs.clear()
		for n: Node in get_tree().get_nodes_in_group("npc"):
			if n is Node3D and (n as Node3D).visible:
				(n as Node3D).visible = false
				_hidden_npcs.append(n)
	else:
		for n: Variant in _hidden_npcs:
			if is_instance_valid(n):
				(n as Node3D).visible = true
		_hidden_npcs.clear()


func _on_world_child_added(n: Node) -> void:
	if _particles_off and _is_particle_node(n) and (n as GeometryInstance3D).visible:
		(n as GeometryInstance3D).visible = false
		_hidden_particles.append(n)
	if _omni_off and n is OmniLight3D and (n as OmniLight3D).visible:
		(n as OmniLight3D).visible = false
		_hidden_omni.append(n)


func _maybe_disconnect_watch(world: Node) -> void:
	if not _particles_off and not _omni_off and world != null \
			and world.is_connected("child_entered_tree", _on_world_child_added):
		world.child_entered_tree.disconnect(_on_world_child_added)


func _walk(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in root.get_children():
		out.append(c)
		out.append_array(_walk(c))
	return out


# ============================================================================= shadows (desktop only)
var _shadows_off_wanted := false

## Phone: shadows are already off in gameplay (environment.gd) — this always reports the fixed
## string dev_audit.md's proposal names, never a toggle, on a mobile UI mode.
func shadows_status() -> String:
	if Platform.is_mobile():
		return "off (phone renderer)"
	var env := get_node_or_null(ENVIRONMENT_PATH)
	if env == null or not ("shadows_allowed" in env):
		return "needs environment.gd: shadows_allowed"
	return "off" if _shadows_off_wanted else "on"


func set_shadows_off(on: bool) -> String:
	_shadows_off_wanted = on
	return _apply_shadows(on)


func _apply_shadows(on: bool) -> String:
	if Platform.is_mobile():
		return "off (phone renderer)"
	var env := get_node_or_null(ENVIRONMENT_PATH)
	if env == null or not ("shadows_allowed" in env):
		return "needs environment.gd: shadows_allowed"
	env.set("shadows_allowed", not on)
	return "off" if on else "on"


# ============================================================================= load warm-up (HEAT-LOAD)
func warmup_available() -> bool:
	return ResourceLoader.exists(SHADER_WARMUP_PATH) \
		and (load(SHADER_WARMUP_PATH) as GDScript).has_method(SHADER_WARMUP_SET)


func warmup_status() -> String:
	if not warmup_available():
		return "needs shader_warmup.gd: %s" % SHADER_WARMUP_SET
	return "on" if _warmup_on else "off"


func set_warmup(on: bool) -> String:
	_warmup_on = on
	if not warmup_available():
		return "needs shader_warmup.gd: %s" % SHADER_WARMUP_SET
	# shader_warmup.gd persists this itself (user://dev_settings.cfg, its own header says so) — this
	# file never keeps a second copy.
	load(SHADER_WARMUP_PATH).call(SHADER_WARMUP_SET, on)
	return "on" if on else "off"


## The last real `ShaderWarmup.run()` outcome (planet, reason, timings) — Dictionary, {} if the file
## is missing or nothing has run yet this process. Shown by the Perf tab under the toggle.
func warmup_last_report() -> Dictionary:
	if not ResourceLoader.exists(SHADER_WARMUP_PATH):
		return {}
	var script := load(SHADER_WARMUP_PATH) as GDScript
	if script == null or not script.has_method(SHADER_WARMUP_REPORT):
		return {}
	var r: Variant = script.call(SHADER_WARMUP_REPORT)
	return r if r is Dictionary else {}


# ============================================================================= burn control
func burn_on() -> bool:
	return _burn_on


func set_burn(on: bool) -> void:
	_burn_on = on


# ============================================================================= busy% (web only)
## THIS FILE NO LONGER INSTALLS THE `requestAnimationFrame` WRAPPER ITSELF (Phase 5 DEVF fix,
## 2026-09-14). The round-1 version called `JavaScriptBridge.eval()` to patch
## `window.requestAnimationFrame` from here, in `_ready()` — measured too late: Godot's own web
## runtime resolves and binds `requestAnimationFrame` while it boots, before this Node's `_ready()`
## ever runs, so a wrapper installed at this point only ever wraps calls OTHER page code makes
## afterwards, never the engine's own per-frame callback — the meter reads real numbers but they are
## not Godot's frame cost. Fixed the correct way per docs/BUILD_PLAN.md Phase 5 (DEVF brief): the
## LEAD installs the same idea as a `<script>` in the web export's `head_include`, which runs before
## Godot's module even loads, so ITS wrapper is the one bound as `window.requestAnimationFrame` by
## the time Godot asks for it. That script sets `window.__astroPerf = {busy, fps, frames, acc, t0}`
## (`busy` already 0-100, `fps` already frames/sec, both recomputed every rolling second) — this file
## only ever READS those two fields through `JavaScriptBridge`.
##
## SAY WHAT IS SYNTHETIC: this is still wall time measured inside the real `requestAnimationFrame`
## callback (heat_ranked.md's own definition), not a browser devtools profile. `-1.0` means
## "unreadable" — not the web export, or an export whose head_include predates this fix — and
## `_stats_text()` falls back to the Performance-derived `cpu_ms` already computed each refresh,
## never a fabricated percentage.
func _install_busy_meter() -> void:
	_busy_js_installed = OS.has_feature("web")


func _poll_busy() -> void:
	var busy_v: Variant = JavaScriptBridge.eval("window.__astroPerf ? window.__astroPerf.busy : -1", true)
	var fps_v: Variant = JavaScriptBridge.eval("window.__astroPerf ? window.__astroPerf.fps : -1", true)
	_busy_pct = float(busy_v) if busy_v != null else -1.0
	_busy_js_fps = float(fps_v) if fps_v != null else -1.0


# ============================================================================= debug / test hooks
## One-line dump for a Director probe — every field the checklist needs, in one grep-able line.
func debug_report(tag: String = "") -> void:
	print("PERFOVERLAY %s visible=%s fps=%.1f cpu_ms=%.2f draws=%d scale=%.2f particles_off=%s omni_off=%s neighbours_off=%s shadows=%s saver=%s warmup=%s burn=%s busy=%.1f" % [
		tag, str(_visible_ui), Engine.get_frames_per_second(),
		(Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		scale_value(), str(_particles_off), str(_omni_off), str(_neighbours_off),
		shadows_status(), saver_status(), warmup_status(), str(_burn_on), _busy_pct])
