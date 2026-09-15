extends RefCounted
## ShaderWarmup - heat item 5, "warm-up behind the fade" (docs/BUILD_PLAN.md Phase 5, HEAT-LOAD / HLF).
##
## THE RECIPE. Before the player's first steps make a shader compile for real, draw the whole planet
## from two far points for a few frames, behind SceneRouter's still-solid fade, where a stall is
## invisible by design. First prototyped with a throwaway camera on the main viewport
## (.astro_scratch/phase5-understand/heat-hitch/proj/tests/hitch/s_walkwarm.gd): hub first-walk stall
## 818-891 ms -> 270-369 ms; a null control (the same camera swap looking away from the planet) left it
## at 862-915 ms, so it is genuinely DRAWING the shaders that buys the win. The cost moves rather than
## vanishes: one long frame is paid here instead of across the first steps.
##
## HOW IT DRAWS (HLF, 2026-09-14): through two small SubViewports that share the world's World3D, each
## with its own camera, NOT by swapping the main viewport's camera. A SubViewport's camera is current
## only inside that SubViewport, so the camera the player sees - the rig, CrashIntro's shot, the pad's
## flight camera, the finale meeting's - is never touched, nothing has to be "handed back", and
## environment.gd's opening-bearing lock, which reads the MAIN viewport's camera, never sees ours.
## Measured equal to the camera swap: hub, windowed, Compatibility, 2556x1179 --ui=mobile, first-walk
## stall 194 / 207 ms (SubViewports) against 195 / 228 ms (camera swap), interleaved in one lock.
## Adding 14 near-ground views bought nothing (304 ms, and a second run was spoiled by an unrelated
## 1.3 s event), so there are two views, as measured.
##
## WHEN IT RUNS. SceneRouter calls this on every title load and every hop into the world - pad
## arrivals included - but not on a return from the space map. It skips itself in exactly one case:
## while the crash intro is playing (`crash_intro_active`), which the lead's HLF brief asks for. Round 1
## (a camera swap, no skip) moved the crash intro's sky bearing; round 2 skipped whenever ANY modal was
## open, and a pad arrival opens the "cutscene" modal before this runs, so it skipped every pad-arrival
## hop. The test is the crash intro itself, found by its script - never "some modal is open".
##
## ALSO WARMED, in the same frames (HLF item d): a 2 cm copy of every mesh the Environment draws - the
## neighbouring worlds' globes, their rings, the planet's own ring - sharing the real mesh and material,
## so a globe's first swing into frame is not a shader compile; and this planet's mini-game materials
## (best-effort, unmeasured - see `_minigame_materials`). Measured: a globe's first entry into frame
## cost +152-171 ms without this and +0.5-2.6 ms with it (hub, globes kept hidden until a probe camera
## looked at one).
##
## THE FIRST DUSK (HLF round 2). Hub, windowed, Compatibility, 2556x1179, stepping the clock
## 13 -> 17 -> 18.5 -> 19.5, then the same dusk again in the same process: without this the first dusk
## cost +46 ms at 18:30 and +48 ms at 19:30 and the second dusk nothing (+1-5 ms), so it is one-time
## work, not a per-dusk cost. Bisected forward:
##   18:30, the lamps coming on (omni lights 10 -> 12): `_add_lamp_copies`, drawn in a SECOND set of
##     frames after the daytime ones. With it: +1.8-3.2 ms.
##   19:30, the fireflies starting to emit, the moon light and 7 more lamps together. A copy of the
##     moon light changed nothing (47.6 / 48.2 ms), so it is not the moon. `_particle_copies` took it
##     to +22.5-23.5 ms. The rest is NOT a compile: with the real fireflies' `preprocess = 4.0` set to
##     0 by a probe (SYNTHETIC) it is +1.5-2.6 ms. That is 120 simulation steps night_life.gd asks for
##     on the first emit, and a copy cannot pay it for the real node.
## Cost: the hub hop's warm-up went from 640-695 ms to 1013-1030 ms (report total_ms), all behind the
## fade; hub first-walk stall 220-248 ms against 195-196 ms without the dusk copies.
##
## TEMPORARY NODES (HLF item b). Everything this adds lives under ONE holder node, freed exactly once
## and only if it still exists. The scene can be freed while this static coroutine is parked on
## `await tree.process_frame` (a quit, a showcase clearing its children, a scene change) and a static
## coroutine is not cancelled when that happens, so every await is followed by an is_instance_valid
## check before anything is touched. Round 1 threw "queue_free on a previously freed instance" here;
## showcase/hlf_warmup_free.tscn frees the scene under it both ways.
##
## NOT class_name'd. SceneRouter (an autoload) must never write `ShaderWarmup.foo` in its own source -
## call this only through `load(SHADER_WARMUP_SCRIPT).call(name, ...)` (scene_router.gd's
## `_prebuild_current_planet` note, OPEN_ISSUES 45). Every public method is static.
##
## API:
##   enabled() -> bool
##   set_enabled(on: bool) -> void          persisted to user://dev_settings.cfg - NEVER the save file
##   last_report() -> Dictionary            what the most recent run() did (Perf tab)
##   crash_intro_active(tree) -> bool       the skip test, public for probes
##   run(tree: SceneTree) -> void           awaitable; the whole recipe on tree.current_scene

const SETTINGS_PATH := "user://dev_settings.cfg"
const SETTINGS_SECTION := "heat"
const SETTINGS_KEY := "shader_warmup_enabled"

## Read live, by path, never by class name (a missing or reshaped MINIGAME_HOMES just means the
## mini-game step warms nothing).
const DEV_MENU_PATH := "res://src/ui/pause/dev_menu.gd"
const MINIGAME_SYSTEM_PATH := "res://src/minigames/minigame_system.gd"
## The crash intro, identified by its script (intro_director.gd names the node "CrashIntro", the dev
## menu's replay "DevCrashIntro"). By path, never by class name, same reason as above.
const CRASH_INTRO_SCRIPT := "res://src/onboarding/crash_intro.gd"

## The two far viewing directions s_walkwarm.gd measured the recipe with, at 3 planet radii. Not tuned.
const VIEW_DIRS := [Vector3(1, 0.4, 0.3), Vector3(-1, -0.4, -0.3)]
const VIEW_DISTANCE_RADII := 3.0
const VIEW_HOLD_FRAMES := 4
## Each SubViewport is this fraction of the main view per side. Shader compilation does not depend on
## the target size; a small target only keeps the extra draws cheap.
const VIEW_SCALE := 1.0 / 6.0
## The warm-up copies: the "2 cm quad 1 m before the camera" idiom docs/PHASE5_SPEC.md §7 uses.
const COPY_SIZE_M := 0.02
const COPY_DIST_M := 1.0
## Above zero, so a lamp copy is a real lit light; the smallest that is, so it cannot be seen (see
## `_add_lamp_copies`).
const LAMP_COPY_ENERGY := 0.001

## Every planet id this process has already paid the warm-up for once.
static var _warmed_planets: Dictionary = {}
static var _last_report: Dictionary = {"ran": false, "planet": "", "reason": "not_run"}
## null until first read; caches the ConfigFile value for the rest of the process.
static var _enabled_cache: Variant = null

# --------------------------------------------------------------------------------------- settings
static func enabled() -> bool:
	if _enabled_cache == null:
		_enabled_cache = _read_enabled()
	return _enabled_cache


## Saved to user://dev_settings.cfg, a small per-install debug-settings file - NEVER
## user://astro_neighbor_save.json. Survives a restart: a fresh process starts with `_enabled_cache`
## null, so the next `enabled()` call re-reads this file rather than trusting process memory.
static func set_enabled(on: bool) -> void:
	_enabled_cache = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH) # missing file is fine; cfg is just empty
	cfg.set_value(SETTINGS_SECTION, SETTINGS_KEY, on)
	cfg.save(SETTINGS_PATH)


static func _read_enabled() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return true # default on
	return bool(cfg.get_value(SETTINGS_SECTION, SETTINGS_KEY, true))


## A copy of what the most recent `run()` did. Fields: ran (bool), planet (String), reason (String:
## "disabled" | "no_world" | "crash_intro" | "already_warmed" | "no_viewport" | "freed" | "ok"),
## and when it ran: views, sky_meshes, materials_warmed, lamps, particles, total_ms. Only "ran" and "reason" are
## guaranteed present.
static func last_report() -> Dictionary:
	return _last_report.duplicate()


## True while a crash intro that has not finished is in the tree.
static func crash_intro_active(tree: SceneTree) -> bool:
	if tree == null or tree.root == null:
		return false
	for n in tree.root.find_children("*CrashIntro*", "", true, false):
		var s: Variant = n.get_script()
		if s is Script and (s as Script).resource_path == CRASH_INTRO_SCRIPT and n.get("_done") != true:
			return true
	return false

# --------------------------------------------------------------------------------------------- run
## Runs the recipe against `tree.current_scene`. Always safe to call: quietly does nothing when
## disabled, while the crash intro plays, when this planet was already warmed this process, or when
## there is no world.
static func run(tree: SceneTree) -> void:
	var t0 := Time.get_ticks_msec()
	if not enabled():
		_last_report = {"ran": false, "planet": "", "reason": "disabled"}
		return
	var world: Node = tree.current_scene if tree != null else null
	if world == null:
		_last_report = {"ran": false, "planet": "", "reason": "no_world"}
		return
	var pid: String = String(GameState.current_planet_id)
	# Before the "already warmed" test, and without marking the planet warmed.
	if crash_intro_active(tree):
		_last_report = {"ran": false, "planet": pid, "reason": "crash_intro"}
		return
	if _warmed_planets.has(pid):
		_last_report = {"ran": false, "planet": pid, "reason": "already_warmed"}
		return
	var vp: Viewport = world.get_viewport()
	if vp == null or vp.find_world_3d() == null:
		_last_report = {"ran": false, "planet": pid, "reason": "no_viewport"}
		return
	var radius := 10.0
	var planet: Node = world.get_node_or_null("Planet")
	if planet != null:
		var r: Variant = planet.get("radius")
		if r != null and (r is float or r is int):
			radius = float(r)
	var extras: Array = _sky_copies(world.get_node_or_null("Environment"))
	var sky_count := extras.size()
	var mats := _minigame_materials(pid)
	extras.append_array(_material_quads(mats))
	var particle_copies := _particle_copies(world.get_node_or_null("Environment"))

	# Build everything under one holder, synchronously, so nothing can be half-attached at an await.
	var holder := Node.new()
	holder.name = "ShaderWarmup"
	world.add_child(holder)
	var visible_size: Vector2 = vp.get_visible_rect().size
	var size := Vector2i(maxi(64, int(visible_size.x * VIEW_SCALE)), maxi(32, int(visible_size.y * VIEW_SCALE)))
	for i in VIEW_DIRS.size():
		var sv := SubViewport.new()
		sv.name = "View%d" % i
		sv.size = size
		sv.world_3d = vp.find_world_3d()
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		holder.add_child(sv)
		var cam := Camera3D.new()
		cam.far = maxf(radius * 12.0, 50.0)
		sv.add_child(cam)
		var dir: Vector3 = (VIEW_DIRS[i] as Vector3).normalized()
		cam.global_position = dir * radius * VIEW_DISTANCE_RADII
		cam.look_at(Vector3.ZERO, Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT)
		cam.current = true # current inside this SubViewport only
		if i == 0:
			for e in extras:
				cam.add_child(e)
			for pc in particle_copies:
				cam.add_child(pc)
	for i in VIEW_HOLD_FRAMES:
		await tree.process_frame
		if not is_instance_valid(holder) or not holder.is_inside_tree():
			_last_report = {"ran": false, "planet": pid, "reason": "freed"}
			return
	# Second pass, the same number of frames, with the night lamps lit (`_add_lamp_copies`). NOT in the
	# first pass: lit from the start, the warm-up bought the dusk but lost daytime - hub first-walk
	# stall 325-365 ms against 198-230 ms without lamps, a new 127-133 ms stall on the first step
	# (interleaved in one lock). Day first, then lamps, draws both.
	var lamp_count := _add_lamp_copies(world, holder)
	if lamp_count > 0:
		for i in VIEW_HOLD_FRAMES:
			await tree.process_frame
			if not is_instance_valid(holder) or not holder.is_inside_tree():
				_last_report = {"ran": false, "planet": pid, "reason": "freed"}
				return
	holder.queue_free()
	_warmed_planets[pid] = true
	_last_report = {
		"ran": true, "planet": pid, "reason": "ok", "views": VIEW_DIRS.size(),
		"sky_meshes": sky_count, "materials_warmed": mats.size(), "lamps": lamp_count, "particles": particle_copies.size(),
		"total_ms": Time.get_ticks_msec() - t0,
	}


## An emitting copy of every GPUParticles3D under the Environment that is not emitting now (the night
## fireflies, which start at dusk), so its particle process shader and draw shader compile here.
## Unparented until run() hangs them on its first camera. `duplicate(0)` copies every property and
## shares the same process material and meshes, but no script, signal or group. A hand-built copy
## (a few chosen properties) compiled the same shaders but left "1 shaders of type
## ParticlesShaderGLES3 were never freed" at every windowed quit (hub, 7 variants tried); the
## `duplicate(0)` copy does not. Scoped to the Environment on purpose: copies of every
## GPUParticles3D in the hub world (29) cost +0.45 s of warm-up for no dusk gain over this one.
static func _particle_copies(env: Node) -> Array:
	var out: Array = []
	if env == null:
		return out
	for n in env.find_children("*", "GPUParticles3D", true, false):
		var src := n as GPUParticles3D
		if src == null or src.process_material == null or (src.emitting and src.is_visible_in_tree()):
			continue
		var c := src.duplicate(0) as GPUParticles3D
		if c == null:
			continue
		c.name = "WarmParticles"
		c.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -COPY_DIST_M))
		c.visible = true
		c.emitting = true
		out.append(c)
	return out


## A copy of every OmniLight3D and SpotLight3D in the world that is NOT lighting anything right now
## (hidden, or energy 0 - by day, the night lamps), at the same place, range, cull mask and angle,
## added under `holder` so it goes when the holder goes. Under Compatibility each omni or spot light
## is an additive pass with its own shader variant per material, compiled the first time a material
## is drawn inside a lit lamp's range; by day that first time is dusk. The copies' energy is not
## a tuned value: any energy above zero selects the same variant (measured: energy 1.0 and 0.001 both
## took the 18:30 step from +45 ms to +0.4-4.6 ms), and the smallest keeps the copies invisible in
## the main view, which shares this World3D. The real lamps are never touched - deco_item.gd and
## building_base.gd rewrite their energy and visibility from the clock, so an edit there would be
## undone. Returns how many copies were added.
static func _add_lamp_copies(world: Node, holder: Node) -> int:
	var n := 0
	for l in world.find_children("*", "Light3D", true, false):
		if not (l is OmniLight3D or l is SpotLight3D):
			continue
		var src := l as Light3D
		if holder.is_ancestor_of(src) or not src.is_inside_tree():
			continue
		if src.is_visible_in_tree() and src.light_energy > 0.0:
			continue # already lighting: its variants compile in the ordinary warm-up draw
		var c: Light3D
		if src is OmniLight3D:
			var o := OmniLight3D.new()
			o.omni_range = (src as OmniLight3D).omni_range
			o.omni_attenuation = (src as OmniLight3D).omni_attenuation
			c = o
		else:
			var sp := SpotLight3D.new()
			sp.spot_range = (src as SpotLight3D).spot_range
			sp.spot_angle = (src as SpotLight3D).spot_angle
			sp.spot_attenuation = (src as SpotLight3D).spot_attenuation
			c = sp
		c.name = "WarmLamp"
		c.light_color = src.light_color
		c.light_energy = LAMP_COPY_ENERGY
		c.light_specular = src.light_specular
		c.light_cull_mask = src.light_cull_mask
		c.layers = src.layers
		c.shadow_enabled = false
		holder.add_child(c)
		c.global_transform = src.global_transform
		n += 1
	return n


## A 2 cm copy of every MeshInstance3D under the Environment (the neighbouring worlds' globes and
## rings, the planet ring), sharing the real mesh and the real material so the copy draws the SAME
## shader variant the real one will. Unparented until run() hangs them on its first camera.
static func _sky_copies(env: Node) -> Array:
	var out: Array = []
	if env == null:
		return out
	for n in env.find_children("*", "MeshInstance3D", true, false):
		var src := n as MeshInstance3D
		if src == null or src.mesh == null:
			continue
		out.append(_copy_of(src))
	return out


static func _copy_of(src: MeshInstance3D) -> MeshInstance3D:
	var copy := MeshInstance3D.new()
	copy.name = "WarmCopy"
	copy.mesh = src.mesh
	copy.material_override = src.material_override
	for s in src.get_surface_override_material_count():
		copy.set_surface_override_material(s, src.get_surface_override_material(s))
	copy.layers = src.layers
	copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var aabb: AABB = src.mesh.get_aabb()
	var longest: float = aabb.get_longest_axis_size()
	var k: float = COPY_SIZE_M / longest if longest > 0.0001 else 1.0
	copy.scale = Vector3.ONE * k
	copy.position = Vector3(0.0, 0.0, -COPY_DIST_M) - aabb.get_center() * k
	return copy


## One 2 cm quad per material, unparented (see `_sky_copies`).
static func _material_quads(mats: Array) -> Array:
	var out: Array = []
	for m in mats:
		var mesh := MeshInstance3D.new()
		mesh.name = "WarmQuad"
		var quad := QuadMesh.new()
		quad.size = Vector2(COPY_SIZE_M, COPY_SIZE_M)
		mesh.mesh = quad
		mesh.material_override = m
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.position = Vector3(0.0, 0.0, -COPY_DIST_M)
		out.append(mesh)
	return out


## Best-effort, unmeasured (heat_ranked.md item 5: "game parts unmeasured"). Finds whichever
## mini-game calls `planet_id` home (read live from dev_menu.gd's MINIGAME_HOMES), loads that game's
## script BY PATH ONLY, and returns any Material or Shader it keeps as a script constant. Never calls
## `MinigameSystem.start()`: nothing here enters a real game state or fires `started`/`finished`.
static func _minigame_materials(planet_id: String) -> Array:
	var kind := _minigame_kind_for(planet_id)
	if kind == "" or not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return []
	var sys_script: GDScript = load(MINIGAME_SYSTEM_PATH)
	if sys_script == null:
		return []
	var games: Variant = sys_script.get_script_constant_map().get("GAMES", {})
	if not (games is Dictionary):
		return []
	var script_path := String((games as Dictionary).get(kind, ""))
	if script_path == "" or not ResourceLoader.exists(script_path):
		return []
	var game_script: GDScript = load(script_path)
	if game_script == null:
		return []
	return _collect_materials(game_script.get_script_constant_map())


static func _minigame_kind_for(planet_id: String) -> String:
	if not ResourceLoader.exists(DEV_MENU_PATH):
		return ""
	var script: GDScript = load(DEV_MENU_PATH)
	if script == null:
		return ""
	var homes: Variant = script.get_script_constant_map().get("MINIGAME_HOMES", {})
	if not (homes is Dictionary):
		return ""
	for kind in (homes as Dictionary):
		if String((homes as Dictionary)[kind]) == planet_id:
			return String(kind)
	return ""


static func _collect_materials(consts: Dictionary) -> Array:
	var out: Array = []
	for k in consts:
		var v = consts[k]
		if v is Material:
			out.append(v)
		elif v is Shader:
			var sm := ShaderMaterial.new()
			sm.shader = v
			out.append(sm)
	return out
