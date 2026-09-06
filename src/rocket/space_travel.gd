extends Node3D
## The middle leg of the rocket journey, and (when nothing is in flight) the solar-system map.
##
## A warm sun at the origin, four miniature globes on fixed orbits (styled from their PlanetData),
## dotted orbit rings and a shader starfield sky.
##
## JOURNEY MODE (docs/STYLE_GUIDE.md R2.5) is what normally happens. The pad has already asked
## where you are going and the rocket is already in the air, so there is no map to drive: this
## scene picks the flight up mid-climb and hands it on mid-descent. `RocketJourney` carries the
## seam frame across each cut, and three things make the cuts invisible:
##
##   * SystemRoot. The sun, the globes, the orbits, the rocket and the camera all live under one
##     node, and that node is rotated so the seam camera ends up with exactly the WORLD basis it
##     had on the planet. Map geometry is untouched; the star field (which is world-oriented, and
##     uses the same cell scales in both sky shaders) lines up pixel for pixel.
##   * Entry offsets. Each globe starts at the position that reproduces where that world was
##     hanging in the planet's sky - same direction, same apparent size - and eases onto its real
##     orbit over SETTLE_SECONDS while the camera is already moving.
##   * The Environment and the sky are the planet's own on the seam frame (`ground_match` in
##     space_sky.gdshader) and relax into the map's look afterwards; the same ramp runs backwards
##     before the arrival cut, retuned to the DESTINATION's palette.
##
## MAP MODE is still here for `--orbit` / `--from=` showcases and for anything that loads this
## scene without a journey record: the old cream card, arrow-key destination cycling and Esc.
##
## CLI flags (OS user args, after `--`):
##   --from=<planet_id>   start docked at that planet (defaults to GameState.previous_planet_id)
##   --orbit              showcase camera: a slow wide orbit of the whole system, input ignored
##   --globe=<id>         park on a globe's terminator for measurement
##
## Perf: the stars are a sky shader (no meshes), the globes are 4 spheres, the orbit rings are line
## primitives. Everything else is a handful of quads and one particle system.

const SKY_SHADER := preload("res://src/rocket/space_sky.gdshader")
const STREAK_SHADER := preload("res://src/rocket/star_streak.gdshader")
const ROCKET_SCENE := preload("res://src/rocket/rocket_model.tscn")
const GLOBE_SCRIPT := preload("res://src/rocket/space_globe.gd")
const UI_SCRIPT := preload("res://src/rocket/space_map_ui.gd")
const PAUSE_SCENE := "res://src/ui/pause/pause_menu.tscn"
const WORLD_SCENE := "res://src/world/world.tscn"

const SUN_RADIUS := 3.1
const SUN_COLOR := Color("#ffe6ad")
const SUN_CORE := Color("#fff3d2")
const ROCKET_SCALE := 0.46
const SWOOP_SECONDS := 0.6
const LIFTOFF_SECONDS := 0.9
const CRUISE_SECONDS := 4.9
## The arrival orbit is the hero beat of the whole trip, so it gets real screen time and a framed
## camera. At 1.2 s with a chase camera and a full 360 deg sweep it measured 98.5% of pixels under
## luma 0.15 — a black screen (rocket critic).
## Long enough that the beat has room to breathe AND that a capture aimed anywhere in the second
## half of the flight lands on the hero framing rather than on the scene-transition fade.
const ORBIT_SECONDS := 3.0
## How far round the destination the rocket sweeps during that beat.
const ORBIT_SWEEP_DEG := 285.0
## Chase camera: a three-quarter REAR view. Mostly behind (so the destination you are flying at is
## in frame and visibly grows) but well off the axis, so it is not looking up the exhaust and the
## whole silhouette — nose, fins and plume — still reads. RocketJourney.CHASE_* are these numbers
## divided by ROCKET_SCALE, which is how the planet scene puts the rocket on the same pixels.
const CHASE_BACK := 4.14
const CHASE_UP := 1.61
const CHASE_SIDE := 3.22
const CHASE_LEAD := 1.38
const MAX_BANK_DEG := 42.0

# --------------------------------------------------------------------------- journey mode
## The whole space leg is one crossing: the climb hands the rocket over already in flight and this
## flies it to the destination's doorstep, where the REAL planet takes over and grows the rest of
## the way. There is no hero orbit here — the hero beat belongs on the world you are landing on,
## not on a 2 m stand-in, and moving it to the planet scene is also what lets the arrival cut hide
## (the seam is a 7 deg disc of matched size and colour, not a close-up of a stylised globe).
const JOURNEY_CRUISE_SECONDS := 6.4
## The ground sky, the post stack and the destination's own lighting are eased back in over the last
## of the cruise, so the seam frame is already painting what the planet is about to build.
const ENTRY_MATCH_SECONDS := 1.8
## RING PROPORTIONS ARE NOW THE SAME EVERYWHERE. src/world/planet_ring.gd is 28 m / 39 m on a 13 m
## planet; src/world/sky_bodies.gd mirrors that as 2.15 / 3.00, and src/rocket/space_globe.gd now
## does too (it was 1.7 / 2.9). So the band no longer changes size across either cut and no longer
## has to be faded in to hide it — only its TILT, which the sky picks per body, is reconciled, by
## `_ring_seam_basis`.


## planet id -> {"radius", "angle_deg", "orbit", "y", "desc"}
const LAYOUT := {
	"home": {"radius": 2.2, "orbit": 20.0, "angle_deg": 24.0, "y": 0.6,
		"desc": "Home sweet orbit."},
	"zorp": {"radius": 1.9, "orbit": 28.5, "angle_deg": 118.0, "y": -1.7,
		"desc": "Zorp's violet world. Glowing rivers!"},
	"bolt": {"radius": 1.9, "orbit": 36.5, "angle_deg": 214.0, "y": 1.5,
		"desc": "Bolt's chrome world. Mind the gears."},
	"hub": {"radius": 3.2, "orbit": 47.0, "angle_deg": 318.0, "y": -0.9,
		"desc": "Starport Plaza. Shops & town hall."},
}
const ORDER: Array[String] = ["home", "zorp", "bolt", "hub"]

## Planet the rocket is docked at (empty = read GameState.previous_planet_id, then "home").
@export var origin_id: String = ""
## Showcase mode: the camera orbits the whole system slowly and input is ignored.
@export var orbit_showcase: bool = false
## Measurement rig: park the camera exactly 90 deg from the sun on this globe, so the terminator
## runs down the middle of the frame and a critic can measure the lit and night hemispheres from
## one screenshot. Empty = off. (`--globe=zorp`)
@export var terminator_probe: String = ""
## Showcase / test rig: "<from>><to>" (e.g. "home>zorp") synthesises a departure record so journey
## mode runs standalone, without a planet scene to hand one over. (`--journey=home>zorp`)
@export var journey_preview: String = ""

var _globes: Dictionary = {}          # planet_id -> SpaceGlobe
## Everything that belongs to the solar system. Rotating this node re-aims the whole map under a
## fixed sky, which is how the seam camera keeps the world basis it had on the planet.
var _system: Node3D
var _camera: Camera3D
var _sun: Node3D
var _sun_light: OmniLight3D
## A stand-in for the PLANET's sun, faded in on the seam frames. The map lights the rocket with a
## close omni at the star; a planet lights it with a distant directional from a completely different
## direction, and a hero object flipping which side it is lit from is the loudest thing a hidden cut
## can do. This carries the far side's key light across, and fades back out into the map's own.
var _seam_key: DirectionalLight3D
var _ground_sun := Vector3.UP
var _rocket: RocketModel
var _streaks: GPUParticles3D
var _ui: SpaceMapUI
var _origin: String = "home"
var _focus: String = "home"
var _destinations: Array[String] = []
var _dest_index := 0
var _cam_from := Transform3D.IDENTITY
var _cam_to := Transform3D.IDENTITY
var _swoop: Tween
var _flying := false
var _input_locked := false
var _time := 0.0
var _orbit_angle := 0.0
var _loop_player: AudioStreamPlayer
var _path: PackedVector3Array = PackedVector3Array()
var _flight_up := Vector3.UP
var _prev_forward := Vector3.FORWARD
var _bank := 0.0
var _chase_pos := Vector3.ZERO
var _chase_look := Vector3.ZERO
## +1 / -1: which flank the chase camera rides on. Locked at the start of a flight to the side the
## SUN is on, so the camera always looks AWAY from the star and the rocket is never silhouetted
## against the blown-out sun disc (the home->bolt route used to fly right across it).
var _chase_side := 1.0
var _orbiting := false
var _orbit_centre := Vector3.ZERO
var _orbit_x := Vector3.RIGHT
var _orbit_y := Vector3.FORWARD
var _orbit_r := 4.0
var _orbit_a0 := 0.0
var _hero_eye := Vector3.ZERO
var _pause: PauseMenu
## Safety net for `_go_back`: if the scene change never happens, input is unlocked again rather
## than leaving the player in a map that ignores every key.
var _back_watchdog := 0.0

# --------------------------------------------------------------------------- journey state
var _journey := false
var _journey_dest := ""
## True while this scene holds the "cutscene" modal gate (journey mode only).
var _cutscene := false
var _sky_mat: ShaderMaterial
var _env: Environment
## 1 on the seam frame, 0 once the map's own look has taken over.
var _match := 0.0
## The chase reference frame handed over by the planet scene ("up" and the flank the camera rides
## on), eased onto this map's own over SETTLE_SECONDS. Blending the RULE rather than correcting the
## RESULT is what removes the first-frame drift: on frame 0 the rule reproduces the seam exactly.
var _ref_up := Vector3.UP
var _ref_flank := Vector3.RIGHT
var _ref_blend := 1.0
## globe id -> the offset that puts it where that world hung in the planet's sky, eased to zero.
var _globe_entry: Dictionary = {}
## planet_id -> Vector3: the ring plane normal the planet's SKY was drawing on the departure seam,
## in SystemRoot-local coordinates.
var _globe_ring_seam: Dictionary = {}
## planet_id -> Vector3: the ring plane normal that globe should settle at once the seam has relaxed
## (its own, or the one `_align_destination_ring` picked for the world we are flying to).
var _globe_ring_home: Dictionary = {}
var _entry_decay := 0.0
## True while the arrival entry ramp is bringing the ground sky back IN (so the relax pass leaves it).
var _entering := false
## Cached prediction of the destination's sky, post stack and sun direction (map space).
var _predicted_sky: Dictionary = {}
var _dest_post: Dictionary = {}
var _predicted_sun := Vector3.ZERO
## World basis of the departure seam camera. Every camera-local direction in the record is turned
## back into world space through this, so the sun and moons stay put as the camera swings.
var _seam_world_basis := Basis.IDENTITY
## Post-processing the planet handed us, so `_set_match` can cross-fade between it and the map look
## instead of guessing at numbers the environment builder owns.
var _ground_post: Dictionary = {}


func _ready() -> void:
	name = "SpaceTravel"
	_parse_args()
	if journey_preview.contains(">") and not RocketJourney.pending("depart"):
		var parts := journey_preview.split(">")
		RocketJourney.synthesise(parts[0].strip_edges(), parts[1].strip_edges())
	_journey = RocketJourney.pending("depart") and not orbit_showcase and terminator_probe == ""
	if _journey:
		_origin = RocketJourney.from_id
		_journey_dest = RocketJourney.to_id
	else:
		RocketJourney.clear()
		_origin = origin_id
		if _origin == "":
			_origin = GameState.previous_planet_id
	if not LAYOUT.has(_origin):
		_origin = "home"
	_focus = _origin
	for id in ORDER:
		if id != _origin:
			_destinations.append(id)

	# Space is night: emissives (rivers, seams, engine glow) run at full strength here — but see
	# `_set_match`, which walks this back to the PLANET's night factor on the seam frames so the
	# rocket's plume does not brighten the instant the cut lands.
	# ARCHITECTURE §9.1 assigns `astro_night` to the environment builder, but this scene has no
	# Environment node at all, and the global keeps whatever value the daylight planet we just left
	# wrote into it — so without this line every emissive in space runs at its DAY scale. Flagged for
	# the orchestrator: the clean fix is an environment-owned "space" mode we can ask for.
	RenderingServer.global_shader_parameter_set(&"astro_night", 1.0)
	_system = Node3D.new()
	_system.name = "SystemRoot"
	add_child(_system)
	_build_environment()
	_build_sun()
	_build_globes()
	_build_orbits()
	_build_camera()
	_build_rocket()
	_ui = UI_SCRIPT.new()
	_ui.name = "MapUI"
	add_child(_ui)
	if _journey:
		# No card and no controls in journey mode - there is nothing to choose out here, the pad
		# already asked. Just the two HUD chips, easing in so the arrival cut has them already up.
		_ui.set_card_visible(false)
		_ui.show_flight_chrome()
	else:
		_refresh_card()
		if orbit_showcase:
			_ui.set_hint("showcase orbit")
	_build_pause()
	AudioManager.play_music("space", 1.2)
	EventBus.travel_started.emit(_origin, _journey_dest)
	if terminator_probe != "" and LAYOUT.has(terminator_probe):
		_park_on_terminator(terminator_probe)
	elif _journey:
		_begin_journey()


func _process(delta: float) -> void:
	_time += delta
	if orbit_showcase:
		_orbit_showcase_camera(delta)
		return
	# The pause menu is checked FIRST and works in every state, flight included. The space map used
	# to have no menu at all: if anything went wrong here the only way out was to force-quit.
	_read_pause()
	_relax_seam(delta)
	if _back_watchdog > 0.0:
		_back_watchdog -= delta
		if _back_watchdog <= 0.0 and is_inside_tree():
			push_warning("SpaceTravel: return-to-planet did not happen — unlocking input.")
			_input_locked = false
	if _flying:
		_update_chase(delta)
		return
	if _input_locked or _journey:
		return
	_read_input()


## Instantiates the shared pause overlay (UI builder's scene) on its own always-processing layer.
func _build_pause() -> void:
	if orbit_showcase or not ResourceLoader.exists(PAUSE_SCENE):
		return
	var layer := CanvasLayer.new()
	layer.name = "PauseLayer"
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_pause = load(PAUSE_SCENE).instantiate() as PauseMenu
	layer.add_child(_pause)


## The pause hotkey works on the standalone map (which the player drives, and which used to have no
## way out but force-quit) but NOT during the continuous journey, which is a cutscene: `_journey`
## raises the same `EventBus.ui_modal_opened("cutscene")` gate the boarding sequence does, and this
## returns on it. Pausing mid-cruise froze the whole trip (integration critic).
func _read_pause() -> void:
	if _pause == null or _pause.is_open or get_tree().paused:
		return
	if EventBus.is_modal_open() or SceneRouter.is_busy():
		return
	if Input.is_action_just_pressed("pause"):
		_pause.open()


# ============================================================================= cutscene gate
## The cruise is a cutscene: no pause, no bag, no hotkeys, exactly as on the pad either side of it.
## EventBus clears modals on every scene change, so the count cannot leak across the arrival cut,
## but `_end_cutscene` still runs on every exit path including `_exit_tree`.
func _begin_cutscene() -> void:
	if _cutscene:
		return
	_cutscene = true
	EventBus.ui_modal_opened.emit("cutscene")


func _end_cutscene() -> void:
	if not _cutscene:
		return
	_cutscene = false
	EventBus.ui_modal_closed.emit("cutscene")


func _exit_tree() -> void:
	_end_cutscene()
	# Only when this scene is going away WITHOUT handing over: a normal arrival keeps the prewarmed
	# destination alive until the pad on the far side has finished building it.
	if not RocketJourney.switching:
		RocketJourney.release_prewarm()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			origin_id = a.substr(7)
		elif a == "--orbit":
			orbit_showcase = true
		elif a.begins_with("--globe="):
			terminator_probe = a.substr(8)
		elif a.begins_with("--journey="):
			journey_preview = a.substr(10)


# ============================================================================= build
func _build_environment() -> void:
	# In journey mode the planet's own Environment comes across the cut with us — tonemap, glow,
	# adjustments and the day/night colour-correction LUT included — so the post stack cannot
	# change on the seam frame. `_relax_seam` eases it into the map's look afterwards.
	var env: Environment = null
	if _journey and RocketJourney.env != null:
		env = RocketJourney.env.duplicate() as Environment
	if env == null:
		env = Environment.new()
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("#272444")
		env.ambient_light_energy = 0.18
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.0
		env.tonemap_white = 6.0
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.06
		env.adjustment_saturation = 1.04
		_apply_map_glow(env)
	env.background_mode = Environment.BG_SKY
	if not _journey:
		env.fog_enabled = false
		env.ssao_enabled = false
	var sky := Sky.new()
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = SKY_SHADER
	sky.sky_material = _sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	env.sky = sky
	_env = env
	_ground_post = {
		"glow_hdr_threshold": env.glow_hdr_threshold,
		"glow_intensity": env.glow_intensity,
		"glow_strength": env.glow_strength,
		"ambient_color": env.ambient_light_color,
		"ambient_energy": env.ambient_light_energy,
		"ambient_sky": env.ambient_light_sky_contribution,
		"saturation": env.adjustment_saturation,
		"night": float(RocketJourney.sky.get("night", 1.0)) if _journey else 1.0,
	}
	if _journey:
		# The origin planet's key light, so the seam frame's rocket is lit the way it just was.
		var origin_path := "res://src/planet/data/%s.tres" % _origin
		if ResourceLoader.exists(origin_path):
			var od: PlanetData = load(origin_path)
			var opal := EnvPalette.new()
			opal.build(od)
			var ot := EnvPalette.t(GameState.time_of_day)
			_ground_post["sun_color"] = opal.sun_color.sample(ot)
			_ground_post["sun_energy"] = opal.sun_energy.sample_baked(ot)
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)


## The map's own bloom: tight, so the engine and the sun do not become huge soft discs that swallow
## whatever is in front of them.
func _apply_map_glow(env: Environment) -> void:
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 1.3
	env.glow_hdr_scale = 1.1
	env.glow_intensity = 0.62
	env.glow_strength = 1.0
	env.glow_bloom = 0.01
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 0.8)
	env.set_glow_level(2, 1.0)
	env.set_glow_level(3, 0.6)
	env.set_glow_level(4, 0.28)
	env.set_glow_level(5, 0.08)
	env.set_glow_level(6, 0.0)


func _build_sun() -> void:
	_sun = Node3D.new()
	_sun.name = "Sun"
	_system.add_child(_sun)
	var core := MaterialLib.glow(SUN_CORE, 2.0, SUN_COLOR).duplicate() as ShaderMaterial
	core.set_shader_parameter("emission_day_scale", 1.0)
	core.set_shader_parameter("emission_cap", 2.6)
	var body := RocketMeshLib.mi(RocketMeshLib.sphere(SUN_RADIUS, 36, 18), core, _sun, Vector3.ZERO, "Core")
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Two soft additive halo billboards so the sun bleeds light into the nebula.
	for i in 2:
		var r := SUN_RADIUS * (1.25 + 0.7 * float(i))
		var quad := QuadMesh.new()
		quad.size = Vector2(r * 2.0, r * 2.0)
		quad.material = MaterialLib.glow_sprite(SUN_COLOR, 0.38 - 0.24 * float(i),
			{"softness": 0.5 + 0.32 * float(i), "core": 0.34 - 0.28 * float(i)})
		var halo := MeshInstance3D.new()
		halo.name = "Halo%d" % i
		halo.mesh = quad
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sun.add_child(halo)

	# The key light is radial (an omni at the sun) so every globe is lit from the star you can see;
	# a very weak directional adds a cool fill so night sides read as form instead of black holes.
	_sun_light = OmniLight3D.new()
	_sun_light.name = "SunLight"
	_sun_light.light_color = Color("#fff0cf")
	_sun_light.light_energy = 2.5
	_sun_light.light_specular = 0.4
	_sun_light.omni_range = 160.0
	_sun_light.omni_attenuation = 0.22
	_sun_light.shadow_enabled = false
	_sun.add_child(_sun_light)
	_seam_key = DirectionalLight3D.new()
	_seam_key.name = "SeamKey"
	_seam_key.light_energy = 0.0
	_seam_key.light_specular = 0.2
	_seam_key.shadow_enabled = false
	_seam_key.light_color = Color("#fff4d6")
	add_child(_seam_key)

	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.light_color = Color("#6f7ac0")
	fill.light_energy = 0.16
	fill.light_specular = 0.0
	fill.shadow_enabled = false
	# Set explicitly rather than with look_at_from_position: this node lives under SystemRoot, so
	# its transform is map-local and a global aim would be wrong once the system is rotated.
	fill.transform = Transform3D(RocketJourney.look_basis(Vector3(-14.0, -30.0, -22.0), Vector3.UP),
		Vector3(0.0, 30.0, 0.0))
	_system.add_child(fill)


func _build_globes() -> void:
	for id: String in ORDER:
		var path := "res://src/planet/data/%s.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var data: PlanetData = load(path)
		var globe: SpaceGlobe = GLOBE_SCRIPT.new()
		_system.add_child(globe)
		globe.setup(data, float(LAYOUT[id]["radius"]))
		globe.position = _planet_pos(id)
		globe.set_sun_direction(-globe.position)
		_globes[id] = globe


func _build_orbits() -> void:
	var mat := MaterialLib.flat_unlit(Color(0.62, 0.68, 1.0, 0.16))
	var root := Node3D.new()
	root.name = "Orbits"
	_system.add_child(root)
	# In journey mode the dotted rings are map furniture: they would appear out of nowhere on the
	# seam frame, where the planet sky has nothing like them.
	root.visible = not _journey
	for id: String in ORDER:
		var mi := RocketMeshLib.mi(RocketMeshLib.dashed_ring(float(LAYOUT[id]["orbit"]), 132, 0.45),
			mat, root, Vector3(0.0, float(LAYOUT[id]["y"]), 0.0), "Orbit_" + id)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = RocketJourney.FLIGHT_FOV
	_camera.near = 0.05
	_camera.far = 900.0
	_camera.current = true
	var attr := CameraAttributesPractical.new()
	attr.auto_exposure_enabled = false
	attr.dof_blur_far_enabled = false
	attr.dof_blur_near_enabled = false
	_camera.attributes = attr
	_system.add_child(_camera)
	_camera.transform = _view_for(_focus)


func _build_rocket() -> void:
	_rocket = ROCKET_SCENE.instantiate() as RocketModel
	_rocket.name = "Rocket"
	_rocket.scale = Vector3.ONE * ROCKET_SCALE
	_system.add_child(_rocket)
	if not _journey:
		_dock_rocket(_origin)
		_rocket.set_engine(false)
	_rocket.set_light_range_scale(0.16)
	_rocket.set_local_lights_enabled(false)
	_rocket.set_smoke_enabled(false)
	# Nothing docks out here: the boarding ladder stays stowed for the whole cruise.
	_rocket.set_ladder_deployed(false)
	# Low: against a black starfield an additive plume at planet-side brightness blooms into a red
	# disc twice the size of the rocket and you lose the hero of the shot.
	_rocket.set_flame_intensity(0.30)
	var blocker := _rocket.get_node_or_null("Blocker")
	if blocker != null:
		blocker.queue_free()

	_streaks = GPUParticles3D.new()
	_streaks.name = "StarStreaks"
	_streaks.amount = 170
	_streaks.lifetime = 0.85
	_streaks.local_coords = false
	_streaks.emitting = false
	_streaks.visibility_aabb = AABB(Vector3(-90.0, -90.0, -90.0), Vector3(180.0, 180.0, 180.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 11.0
	pm.direction = Vector3(0.0, 0.0, 1.0)
	pm.spread = 9.0
	pm.initial_velocity_min = 30.0
	pm.initial_velocity_max = 58.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.45
	pm.scale_max = 1.1
	pm.particle_flag_align_y = true
	var grad := Gradient.new()
	grad.set_color(0, Color(0.72, 0.86, 1.0, 0.0))
	grad.set_color(1, Color(1.0, 0.92, 0.78, 0.0))
	grad.add_point(0.2, Color(0.86, 0.93, 1.0, 0.95))
	grad.add_point(0.7, Color(1.0, 0.90, 0.76, 0.55))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	_streaks.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 1.9)
	var smat := ShaderMaterial.new()
	smat.shader = STREAK_SHADER
	quad.material = smat
	_streaks.draw_pass_1 = quad
	_system.add_child(_streaks)


# ============================================================================= geometry helpers
func _planet_pos(id: String) -> Vector3:
	var e: Dictionary = LAYOUT[id]
	var a := deg_to_rad(float(e["angle_deg"]))
	var r := float(e["orbit"])
	return Vector3(cos(a) * r, float(e["y"]), sin(a) * r)


func _globe_radius(id: String) -> float:
	return float(LAYOUT[id]["radius"])


## Hero framing for one planet: slightly on the sunward side and off to one flank, so the globe is
## mostly lit but keeps a dark limb and a visible terminator.
func _view_for(id: String) -> Transform3D:
	var p := _planet_pos(id)
	var r := _globe_radius(id)
	var to_sun := (-p).normalized()
	var side := to_sun.cross(Vector3.UP)
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	side = side.normalized()
	var eye := p + to_sun * (r * 0.45) + side * (r * 3.9) + Vector3.UP * (r * 1.45)
	# Aim just below the globe centre: enough to lift the planet clear of the card at the bottom of
	# the screen, but not so much that the rocket parked on the globe's upper limb is clipped by the
	# top edge of the frame.
	var look := p + Vector3.DOWN * (r * 0.18)
	return Transform3D(RocketJourney.look_basis(look - eye, Vector3.UP), eye)


## Framed hero view of the destination for the arrival orbit: on the SUNWARD side and close in, so
## the face pointing at the camera is the lit one and the globe fills a good part of the frame.
func _arrival_view(id: String) -> Transform3D:
	var p := _planet_pos(id)
	var r := _globe_radius(id)
	var to_sun := (-p).normalized()
	var side := to_sun.cross(Vector3.UP)
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	side = side.normalized()
	var eye := p + to_sun * (r * 3.0) + side * (r * 3.2) + Vector3.UP * (r * 1.30)
	return Transform3D(RocketJourney.look_basis(p - eye, Vector3.UP), eye)


func _dock_rocket(id: String) -> void:
	var p := _planet_pos(id)
	var r := _globe_radius(id)
	var view := _view_for(id)
	# Park it on the limb facing the camera so it is always readable against the globe.
	var out := ((view.origin - p).normalized() * 0.78 + Vector3.UP * 0.62).normalized()
	_flight_up = out
	var face := (view.origin - p).cross(out)
	if face.length_squared() < 0.0001:
		face = Vector3.RIGHT
	var basis := RocketJourney.look_basis(-face.normalized(), out).scaled(Vector3.ONE * ROCKET_SCALE)
	_rocket.transform = Transform3D(basis, p + out * (r + 0.05))


# ============================================================================= input / focus
func _read_input() -> void:
	if EventBus.is_modal_open() or SceneRouter.is_busy():
		return
	if Input.is_action_just_pressed("cancel"):
		_go_back()
		return
	if Input.is_action_just_pressed("interact"):
		_confirm()
		return
	var step := 0
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("camera_right"):
		step = 1
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("camera_left"):
		step = -1
	if step != 0:
		_cycle(step)


func _cycle(step: int) -> void:
	if _destinations.is_empty():
		return
	if _focus == _origin:
		_dest_index = 0 if step > 0 else _destinations.size() - 1
	else:
		_dest_index = wrapi(_dest_index + step, 0, _destinations.size())
	_set_focus(_destinations[_dest_index])
	UIStyle.play_tick()


func _confirm() -> void:
	if _focus == _origin:
		# Standing on your own planet: nudge to the first destination rather than doing nothing.
		_cycle(1)
		return
	_start_flight(_focus)


func _go_back() -> void:
	if _input_locked or SceneRouter.is_busy():
		return
	_input_locked = true
	_back_watchdog = 3.0
	UIStyle.play_cancel()
	AudioManager.play_music("", 0.8)
	SceneRouter.go_to_planet(_origin, true)


func _set_focus(id: String) -> void:
	_focus = id
	_refresh_card()
	if _swoop != null and _swoop.is_valid():
		_swoop.kill()
	_cam_from = _camera.transform
	_cam_to = _view_for(id)
	_swoop = create_tween()
	_swoop.tween_method(_swoop_step, 0.0, 1.0, SWOOP_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _swoop_step(k: float) -> void:
	var pos := _cam_from.origin.lerp(_cam_to.origin, k)
	var q := _cam_from.basis.get_rotation_quaternion().slerp(_cam_to.basis.get_rotation_quaternion(), k)
	_camera.transform = Transform3D(Basis(q), pos)


func _refresh_card() -> void:
	if _ui == null:
		return
	var data: PlanetData = (_globes[_focus] as SpaceGlobe).data if _globes.has(_focus) else null
	var display := Hud.planet_display_name(_focus) if data != null else _focus.capitalize()
	_ui.show_planet(display, str(LAYOUT[_focus]["desc"]), _focus == _origin)


# ============================================================================= journey mode
## Rebuilds the seam frame: the rocket and camera go where the planet scene's were (in the camera's
## own coordinates), the whole system is rotated so the camera keeps its world basis, and every
## globe is parked where that world hung in the planet's sky before easing onto its real orbit.
func _begin_journey() -> void:
	_input_locked = true
	_begin_cutscene()
	var dest := _journey_dest if LAYOUT.has(_journey_dest) else _destinations[0]
	_journey_dest = dest
	var p0 := _planet_pos(_origin)
	var p3 := _planet_pos(dest)

	# Where the flight starts, map-locally: well out from the origin globe, lifted high above the
	# ecliptic and on the far side of it from the star, so the seam frame is looking into empty sky
	# rather than into the sun - the climb it is continuing from deliberately ends the same way.
	var to_dest := (p3 - p0).normalized()
	var out_from_sun := p0.normalized()
	var out := (to_dest * 0.26 + Vector3.UP * 0.86 + out_from_sun * 0.46).normalized()
	var start_dist := clampf(RocketJourney.seam_distance(_globe_radius(_origin)),
		_globe_radius(_origin) * 4.0, p0.distance_to(p3) * 0.40)
	var cam_pos := p0 + out * start_dist

	# The rocket's world nose direction is fixed by the record; choose the map orientation that
	# points it along the START of the cruise arc (which already bows up and away from the star),
	# with the camera as upright as that allows. Aiming it straight at the destination instead put
	# the sun in the middle of the seam frame on any route that crosses the system.
	var nose_local := RocketJourney.rocket_basis.y.normalized()
	_build_path(cam_pos, dest)
	var heading := (_path[1] - _path[0]).normalized()
	var cam_basis := _basis_pointing(nose_local, heading)
	var cam_xf := Transform3D(cam_basis, cam_pos)
	_camera.transform = cam_xf
	_camera.fov = RocketJourney.FLIGHT_FOV
	_rocket.transform = RocketJourney.read_rocket(cam_xf, ROCKET_SCALE)
	_rocket.set_engine(true, RocketJourney.engine_power)
	_rocket.set_flame_scale(RocketJourney.flame_scale)
	_prev_forward = _rocket.basis.y.normalized()

	# The sky is world-oriented: rotate the whole solar system so the camera keeps exactly the basis
	# it had over the planet, and the star field carries across the cut unmoved.
	_seam_world_basis = RocketJourney.cam_basis.orthonormalized()
	_system.transform = Transform3D(_seam_world_basis * cam_basis.inverse(), Vector3.ZERO)

	# Which flank the seam camera is already on, so the chase does not swing to the other side of
	# the rocket the moment the cut lands.
	var nose := _rocket.basis.y.normalized()
	var map_flank := nose.cross(Vector3.UP)
	_chase_side = 1.0
	if map_flank.length_squared() > 0.0005:
		_chase_side = signf((cam_pos - _rocket.position).dot(map_flank.normalized()))
		if _chase_side == 0.0:
			_chase_side = 1.0

	_seed_globe_entry(cam_xf)
	_align_destination_ring(dest)
	_apply_sky_match(RocketJourney.sky, 1.0)
	_set_match(1.0)
	_entry_decay = 1.0
	# Adopt the planet's chase reference frame, then ease onto the map's over the settle.
	_ref_up = (cam_basis * RocketJourney.up_ref).normalized()
	_ref_flank = (cam_basis * RocketJourney.flank).normalized()
	_ref_blend = 0.0
	_chase_pos = cam_pos
	_chase_look = _rocket.position + _rocket.basis.y.normalized() * CHASE_LEAD
	RocketJourney.leg = ""
	RocketJourney.switching = false

	# The engine loop is still running on the AudioManager autoload from the climb; re-fading the
	# same player keeps the sound continuous instead of restarting it.
	_loop_player = AudioManager.start_loop("rocket_loop", -9.0, 0.3)
	_flying = true
	# Deferred, so the cruise tween is created after this frame's tween step: the FIRST frame the
	# new scene draws has to be the seam frame exactly, with nothing moved yet.
	call_deferred("_fly_journey", dest, heading)


## An orthonormal basis B with `B * nose_local == heading`, rolled so its +Y is as close to world up
## as that constraint allows — the orientation the map would naturally have had.
func _basis_pointing(nose_local: Vector3, heading: Vector3) -> Basis:
	var b := Basis.IDENTITY
	var axis := nose_local.cross(heading)
	if axis.length_squared() > 1e-10:
		b = Basis(axis.normalized(), acos(clampf(nose_local.dot(heading), -1.0, 1.0)))
	elif nose_local.dot(heading) < 0.0:
		var any := nose_local.cross(Vector3.UP)
		if any.length_squared() < 1e-8:
			any = nose_local.cross(Vector3.RIGHT)
		b = Basis(any.normalized(), PI)
	# Roll about the heading until the camera's own up is as upright as possible.
	var y := b.y - heading * b.y.dot(heading)
	var want := Vector3.UP - heading * Vector3.UP.dot(heading)
	if y.length_squared() > 1e-8 and want.length_squared() > 1e-8:
		y = y.normalized()
		want = want.normalized()
		b = Basis(heading, atan2(y.cross(want).dot(heading), y.dot(want))) * b
	return b.orthonormalized()


## Parks each globe where that world was hanging in the planet's sky - same camera-local direction,
## same apparent size - as an offset from its real orbit position. `_relax_seam` eases the offsets
## away while the camera is already moving, so nobody sees a planet slide.
func _seed_globe_entry(cam_xf: Transform3D) -> void:
	_globe_entry.clear()
	_globe_ring_seam.clear()
	_globe_ring_home.clear()
	for entry: Dictionary in RocketJourney.bodies:
		var id := str(entry.get("id", ""))
		if not _globes.has(id):
			continue
		var ang := float(entry.get("angle", 0.0))
		if ang < 0.0005:
			continue
		var dir: Vector3 = cam_xf.basis * (entry.get("dir") as Vector3)
		var want := cam_xf.origin + dir.normalized() * RocketJourney.distance_for_angle(_globe_radius(id), ang)
		_globe_entry[id] = want - _planet_pos(id)
		var g := _globes[id] as SpaceGlobe
		g.position = want
		g.set_sun_direction(-g.position)
		# The sky these globes are standing in for has no orbiting moons and no mesh cloud puffs
		# (R2.1: airless worlds, moons live in the sky shader), so a seeded globe must not sprout
		# any on the cut frame. `_relax_seam` brings them back once the arrangement has moved on.
		g.set_extras_visible(false)
		# ...and wear the tone the sky was painting it in, for the same reason.
		g.set_sky_tone(1.0)
		# The band no longer has to be faded in: SpaceGlobe draws it at the same 2.15 - 3.00 radii
		# the sky does, so the only thing left to reconcile is its TILT, which the sky picks per
		# body. Wear the sky's on the seam frame and roll back to the map's over the settle.
		# Applied here as well as in `_relax_seam`: this scene is installed mid-frame, so its first
		# `_process` may not run before the seam frame is drawn, and the seam frame is the one that
		# has to be right.
		if g.data != null and g.data.has_ring and entry.has("ring_normal"):
			# `ring_normal` is camera-LOCAL, and `cam_xf` is the camera's transform INSIDE SystemRoot,
			# so one multiply lands it in SystemRoot space — the same conversion `dir` gets above.
			# (`_align_destination_ring` needs the extra `_system` inverse because its normal starts
			# out in the seam WORLD frame, not the camera's.)
			_globe_ring_seam[id] = (cam_xf.basis * (entry.get("ring_normal") as Vector3)).normalized()
			g.set_ring_normal(_globe_ring_seam[id])


## Eases everything that was pinned to the seam back to this scene's own look: the globes onto
## their orbits, the sky and post stack into the map's, and the camera's borrowed roll out.
## Turns the destination globe's ring so that, once the system rotation is applied, its plane normal
## points where the real planet's ring normal will point. Without this, Bolt's ring - which reaches
## 2.9 planet radii and fills a good part of the frame on approach - swings through a quarter turn
## across the arrival cut.
func _align_destination_ring(dest: String) -> void:
	var globe := _globes.get(dest) as SpaceGlobe
	if globe == null or globe.data == null or not globe.data.has_ring:
		return
	var world_normal := RocketJourney.ring_normal(globe.data)
	# Recorded rather than applied, because the DEPARTURE seam may also have an opinion about this
	# same globe (a ringed world you can see in the sky of the planet you are leaving). The seam
	# tilt wins on the cut frame; `_relax_seam` then eases to this one, which is the tilt the
	# arrival cut needs. Applied straight away when there is no seam tilt to defer to.
	_globe_ring_home[dest] = (_system.transform.basis.inverse() * world_normal).normalized()
	if not _globe_ring_seam.has(dest):
		globe.set_ring_normal(_globe_ring_home[dest])


func _relax_seam(delta: float) -> void:
	if _entry_decay > 0.0:
		_entry_decay = maxf(_entry_decay - delta / RocketJourney.SETTLE_SECONDS, 0.0)
		var k := _entry_decay * _entry_decay * (3.0 - 2.0 * _entry_decay)
		if _entry_decay <= 0.0:
			k = 0.0
		for id: String in _globe_entry:
			var g := _globes[id] as SpaceGlobe
			g.position = _planet_pos(id) + (_globe_entry[id] as Vector3) * k
			g.set_sun_direction(-g.position)
			g.set_extras_visible(k < 0.5)
			g.set_sky_tone(k)
			if _globe_ring_seam.has(id):
				# Ease the borrowed sky tilt back to whatever this globe should settle at: its own,
				# or the arrival-aligned one if this is the world we are flying to.
				var home: Vector3 = _globe_ring_home.get(id, g.ring_rest_normal())
				g.set_ring_normal(home.slerp(_globe_ring_seam[id] as Vector3, clampf(k, 0.0, 1.0)))
	if _ref_blend < 1.0:
		_ref_blend = minf(_ref_blend + delta / RocketJourney.SETTLE_SECONDS, 1.0)
	if _match > 0.0 and not _entering:
		_set_match(maxf(_match - delta / RocketJourney.SETTLE_SECONDS, 0.0))


## Cross-fades the sky and the post stack between the ground look (1) and the map look (0).
func _set_match(m: float) -> void:
	_match = clampf(m, 0.0, 1.0)
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("ground_match", _match)
	# Every emissive in the game scales with this. Space runs it at 1 (full glow); a daylit planet
	# runs it near 0, so leaving it at 1 across a cut makes the engine plume flare the moment the
	# scene changes. Ride it back to whatever the planet on the far side is using.
	RenderingServer.global_shader_parameter_set(&"astro_night",
		lerpf(1.0, float(_ground_post.get("night", 1.0)), _match))
	if _env == null or _ground_post.is_empty():
		return
	# Cross-fade between the planet's post stack (captured, not guessed) and the map's. Everything
	# else the Environment carries - the colour-correction LUT, contrast, saturation, tonemap - is
	# left exactly as the planet had it, which is also what the destination rebuilds from its own
	# palette, so it is right at both ends.
	_env.glow_hdr_threshold = lerpf(1.3, float(_ground_post["glow_hdr_threshold"]), _match)
	_env.glow_intensity = lerpf(0.62, float(_ground_post["glow_intensity"]), _match)
	_env.glow_strength = lerpf(1.0, float(_ground_post["glow_strength"]), _match)
	_env.ambient_light_color = Color("#272444").lerp(_ground_post["ambient_color"] as Color, _match)
	_env.ambient_light_energy = lerpf(0.18, float(_ground_post["ambient_energy"]), _match)
	_env.ambient_light_sky_contribution = lerpf(0.0, float(_ground_post["ambient_sky"]), _match)
	_env.adjustment_saturation = lerpf(1.04, float(_ground_post["saturation"]), _match)
	# Hand the rocket's key light over to the planet's sun as the match comes up, and take the map's
	# close omni down with it, so the lit side of the hull does not swap across the cut.
	if _seam_key != null and _ground_sun.length_squared() > 0.5:
		_seam_key.light_color = _ground_post.get("sun_color", Color("#fff4d6"))
		_seam_key.light_energy = float(_ground_post.get("sun_energy", 1.0)) * _match
		_seam_key.visible = _seam_key.light_energy > 0.01
		_seam_key.global_transform = Transform3D(
			RocketJourney.look_basis(-_ground_sun, Vector3.UP), Vector3.ZERO)
	if _sun_light != null:
		_sun_light.light_energy = lerpf(2.5, 0.5, _match)
	var ring_night := lerpf(0.42, float(_ground_post.get("night", 0.42)), _match)
	var globe := _globes.get(_journey_dest) as SpaceGlobe
	if globe != null and globe.data != null and globe.data.has_ring:
		globe.set_ring_lighting(_ground_sun, ring_night)
	# Any NEIGHBOUR whose ring we borrowed off the departing planet's sky gets the same treatment:
	# the sky lights its band with the live sun, and an unlit band reads a shade paler on the seam
	# frame than the one it is standing in for.
	for id: String in _globe_ring_seam:
		if id == _journey_dest:
			continue
		var n_globe := _globes.get(id) as SpaceGlobe
		if n_globe != null:
			n_globe.set_ring_lighting(_ground_sun, ring_night)


## Writes one sky snapshot into the space sky's ground-match uniforms.
func _apply_sky_match(snap: Dictionary, strength: float) -> void:
	if _sky_mat == null:
		return
	var basis := _seam_world_basis
	_sky_mat.set_shader_parameter("ground_match", strength)
	_sky_mat.set_shader_parameter("g_zenith", snap.get("zenith_color", Color(0.039, 0.059, 0.180)))
	_sky_mat.set_shader_parameter("g_milky", snap.get("milky_way_color", Color(0.34, 0.33, 0.56)))
	_sky_mat.set_shader_parameter("g_star_brightness", snap.get("star_brightness", 2.0))
	_sky_mat.set_shader_parameter("g_display_cap", snap.get("display_cap", 0.82))
	_sky_mat.set_shader_parameter("g_night", snap.get("night", 1.0))
	_sky_mat.set_shader_parameter("g_moon_size", snap.get("moon_size", 0.055))
	_sky_mat.set_shader_parameter("g_moon_count", snap.get("moon_count", 0))
	_sky_mat.set_shader_parameter("g_moon_color", snap.get("moon_color", Color(1.0, 0.96, 0.82)))
	_sky_mat.set_shader_parameter("g_moon_b_color", snap.get("moon_b_color", Color(0.85, 0.9, 1.0)))
	_sky_mat.set_shader_parameter("g_sun_color", snap.get("sun_color", Color(1.0, 0.96, 0.85)))
	_sky_mat.set_shader_parameter("g_sun_disc", snap.get("sun_disc_size", 0.026))
	# Directions were recorded in the seam camera's frame; put them back into world space through
	# whatever basis this camera has now.
	for pair in [["g_sky_up", "sky_up"], ["g_sky_east", "sky_east"], ["g_sun_dir", "sun_dir"],
			["g_moon_a", "moon_dir_a"], ["g_moon_b", "moon_dir_b"]]:
		var v: Variant = snap.get(pair[1])
		if v != null:
			var world_v := (basis * (v as Vector3)).normalized()
			_sky_mat.set_shader_parameter(pair[0], world_v)
			if pair[1] == "sun_dir":
				_ground_sun = world_v
	# The sun disc is only painted when we know where it will be on the far side: on the departure
	# cut the climb deliberately ends looking away from the star, so leaving it dark is right there,
	# and on the arrival cut `_predict_sky` works out where the destination's sun will be.
	_sky_mat.set_shader_parameter("g_sun_vis", float(snap.get("sun_visible", 0.0)) * strength)


# ============================================================================= flight
func _start_flight(dest: String) -> void:
	if _flying or _input_locked:
		return
	_flying = true
	_input_locked = true
	if _swoop != null and _swoop.is_valid():
		_swoop.kill()
	UIStyle.play_confirm()
	# Same trick as the journey's pad launch: the destination is known seconds before we need it, so
	# every scene the arrival will load goes onto the loader threads now (RocketJourney.prewarm_*).
	RocketJourney.prewarm_destination(dest)
	_ui.set_card_visible(false)
	_ui.toast("Flying to %s…" % Hud.planet_display_name(dest), "star")
	EventBus.travel_started.emit(_origin, dest)
	_fly(dest)


func _fly(dest: String) -> void:
	var start := _rocket.position
	var p3 := _planet_pos(dest)
	var r3 := _globe_radius(dest)

	# 1. lift off the docked planet along the local up
	_rocket.set_engine(true, 0.8)
	_rocket.set_flame_scale(0.35)
	AudioManager.play_sfx("rocket_ignite", -3.0)
	_loop_player = AudioManager.start_loop("rocket_loop", -9.0, 0.4)
	var lift := create_tween()
	lift.tween_property(_rocket, "position", start + _flight_up * (_globe_radius(_origin) * 1.5 + 2.0),
		LIFTOFF_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Seed the chase camera AT its wanted offset. Seeding it with the map's hero view (~30 units away
	# at the destination) and lerping at 5.5/s dragged it straight through the hull for the first
	# second of every flight (rocket critic, crit_trip_home/12_flight_lift.png).
	_seed_chase()
	await lift.finished
	if not is_inside_tree():
		return
	await _cruise_and_arrive(dest, p3, r3, CRUISE_SECONDS)
	if not is_inside_tree():
		return
	AudioManager.stop_loop("rocket_loop", 0.4)
	AudioManager.play_music("", 0.8)
	SceneRouter.go_to_planet(dest, true)


## The journey's middle leg: no liftoff (we are already flying) and no hero orbit (that happens on
## the real planet). One long banked crossing with the destination growing ahead, ending on its
## doorstep, and then the destination scene is installed mid-air.
func _fly_journey(dest: String, heading: Vector3 = Vector3.ZERO) -> void:
	# One clear frame first: the seam frame has to be drawn with nothing moved, so the picture the
	# planet scene just handed over is the picture this scene starts from. Then as many more as the
	# swap's own stall needs - see `_await_steady_frame`.
	await _await_steady_frame()
	if not is_inside_tree():
		return
	_build_path(_rocket.position, dest, heading, true)
	_rocket.set_engine(true, 1.0)
	# Ease the plume rather than snapping it: at a seam the rocket that just crossed the cut has a
	# particular plume length, and a step change in it is exactly the sort of thing that gives a
	# hidden cut away. The star streaks wait until the seam frame is well past for the same reason.
	var plume := create_tween()
	plume.tween_method(_rocket.set_flame_scale, _rocket.flame_scale(), 0.70, 0.6).set_trans(Tween.TRANS_SINE)
	plume.tween_callback(func() -> void:
		if is_instance_valid(_streaks):
			_streaks.emitting = true)
	var cruise := create_tween()
	cruise.tween_method(_cruise_step, 0.0, 1.0, JOURNEY_CRUISE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _loop_player != null and is_instance_valid(_loop_player):
		var pitch := create_tween()
		pitch.tween_property(_loop_player, "pitch_scale", 1.3, JOURNEY_CRUISE_SECONDS * 0.7).set_trans(Tween.TRANS_SINE)
	# Fade the destination's own sky, lighting and post stack back in over the last of the run.
	var match_in := create_tween()
	match_in.tween_interval(JOURNEY_CRUISE_SECONDS - ENTRY_MATCH_SECONDS)
	# The planet scene has no star streaks, so they have to be gone - not just switched off - before
	# the seam frame. Stopping the emitter a lifetime and a half early lets the last ones die out.
	match_in.tween_callback(func() -> void:
		if is_instance_valid(_streaks):
			_streaks.emitting = false)
	match_in.tween_method(_entry_match.bind(dest), 0.0, 1.0, ENTRY_MATCH_SECONDS).set_trans(Tween.TRANS_SINE)
	await cruise.finished
	if not is_inside_tree():
		return
	_entry_match(1.0, dest)
	_arrive(dest)


## Holds the seam frame until the frame clock is back to normal, so the scene-swap stall and the
## first-draw shader compiles behind it are paid on a HELD picture rather than over the first tenth
## of a second of the cruise. The mirror of `rocket_pad.gd::_await_steady_frame`; the two are
## deliberately the same shape and the same numbers.
const SEAM_STEADY_MS := 26.0
const SEAM_STEADY_FRAMES := 8

func _await_steady_frame() -> void:
	for i in SEAM_STEADY_FRAMES:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		if get_process_delta_time() * 1000.0 <= SEAM_STEADY_MS:
			return


## Cross-fades this scene into the destination planet's own look as the cruise runs out: its sky
## palette, the post stack, and the globe's terminator (predicted from the destination's PlanetData
## and the clock, see RocketJourney.predict_sun_dir) so the lit face on the seam frame is the lit
## face the real world is about to show.
func _entry_match(m: float, dest: String) -> void:
	_entering = m > 0.0 and m < 1.0
	var snap := _predict_sky(dest)
	if not _dest_post.is_empty():
		# From here the "ground" we are matching is the DESTINATION, not the planet we left.
		_ground_post = _dest_post
	_apply_sky_match(snap, m)
	_set_match(m)
	var globe := _globes.get(dest) as SpaceGlobe
	if globe == null:
		return
	# The map globes carry orbiting moons and mesh cloud puffs; the worlds they stand in for carry
	# neither, so they go while the two are supposed to be the same picture.
	globe.set_extras_visible(m < 0.5)
	var map_sun := (-globe.position).normalized()
	if _predicted_sun.length_squared() > 0.5:
		globe.set_sun_direction(map_sun.slerp(_predicted_sun, m).normalized())


## Shared by both modes: the long banked cruise with the destination growing ahead, then the hero
## orbit across its lit face.
func _cruise_and_arrive(dest: String, p3: Vector3, r3: float, cruise_seconds: float,
		launch_dir: Vector3 = Vector3.ZERO) -> void:
	_build_path(_rocket.position, dest, launch_dir)
	_rocket.set_engine(true, 1.0)
	# Ease the plume rather than snapping it: at a seam the rocket that just crossed the cut has a
	# particular plume length, and a step change in it is exactly the sort of thing that gives a
	# hidden cut away. The star streaks wait until the seam frame is well past for the same reason.
	var plume := create_tween()
	plume.tween_method(_rocket.set_flame_scale, _rocket.flame_scale(), 0.70, 0.6) \
		.set_trans(Tween.TRANS_SINE)
	plume.tween_callback(func() -> void:
		if is_instance_valid(_streaks):
			_streaks.emitting = true)
	var cruise := create_tween()
	cruise.tween_method(_cruise_step, 0.0, 1.0, cruise_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _loop_player != null and is_instance_valid(_loop_player):
		var pitch := create_tween()
		pitch.tween_property(_loop_player, "pitch_scale", 1.35, cruise_seconds * 0.8).set_trans(Tween.TRANS_SINE)
	await cruise.finished
	if not is_inside_tree():
		return

	# the hero beat: decelerate, frame the destination and sweep round its LIT face
	_streaks.emitting = false
	_rocket.set_flame_scale(0.40)
	_rocket.set_engine(true, 0.55)
	if _loop_player != null and is_instance_valid(_loop_player):
		var down := create_tween()
		down.tween_property(_loop_player, "pitch_scale", 0.85, ORBIT_SECONDS).set_trans(Tween.TRANS_SINE)
	_begin_orbit(dest, p3, r3 + 1.6)
	var circle := create_tween()
	circle.tween_method(_orbit_step, 0.0, 1.0, ORBIT_SECONDS).set_trans(Tween.TRANS_SINE)
	await circle.finished
	_orbiting = false


## Writes the seam frame and installs the destination planet mid-air. No fade: the planet scene
## rebuilds this exact picture on its first frame (see rocket_pad.gd `_prepare_journey_arrival`).
func _arrive(dest: String) -> void:
	_end_cutscene()
	var cam_xf := _camera.global_transform
	RocketJourney.leg = "arrive"
	RocketJourney.from_id = _origin
	RocketJourney.to_id = dest
	RocketJourney.cam_basis = cam_xf.basis.orthonormalized()
	RocketJourney.write_rocket(cam_xf, _rocket.global_transform, ROCKET_SCALE)
	var sys := _system.global_transform.basis
	RocketJourney.write_frame(cam_xf, sys * Vector3.UP,
		sys * ((_rocket.basis.y.normalized().cross(Vector3.UP)).normalized() * _chase_side))
	RocketJourney.flame_scale = 0.70
	RocketJourney.engine_power = 1.0
	var inv := cam_xf.basis.orthonormalized().inverse()
	var centre := _system.global_transform * _planet_pos(dest)
	RocketJourney.focus_dir = (inv * (centre - cam_xf.origin).normalized()).normalized()
	RocketJourney.focus_angle = RocketJourney.angular_radius(_globe_radius(dest),
		cam_xf.origin.distance_to(centre))
	RocketJourney.bodies = []
	RocketJourney.switching = true

	GameState.previous_planet_id = _origin
	GameState.current_planet_id = dest
	GameState.set_flag("spawn_at_pad", true)
	AudioManager.play_music("", 0.8)
	EventBus.travel_finished.emit(dest)
	RocketJourney.swap_scene(get_tree(), WORLD_SCENE, true)


## The sky the destination planet is about to paint, predicted from its own PlanetData through the
## environment builder's public EnvPalette, so the seam frame is already the right colour.
## Only the parts that do not depend on the planet's local frame are predicted: the sun and moon
## discs are left dark, and the entry beat is framed away from the star for that reason.
func _predict_sky(dest: String) -> Dictionary:
	if not _predicted_sky.is_empty():
		return _predicted_sky
	var snap := RocketJourney.sky.duplicate()
	var path := "res://src/planet/data/%s.tres" % dest
	if not ResourceLoader.exists(path):
		_predicted_sky = snap
		return snap
	var data: PlanetData = load(path)
	var pal := EnvPalette.new()
	pal.build(data)
	var t := EnvPalette.t(GameState.time_of_day)
	snap["zenith_color"] = pal.sky_zenith.sample(t)
	snap["night"] = pal.night.sample_baked(t)
	snap["sun_color"] = data.sun_color.lerp(Color.WHITE, 0.35)
	# The moons ride in the destination's own local frame, which we do not model; drawing the ones
	# we left behind would be worse than drawing none.
	snap["moon_count"] = 0
	# Where the destination's sun will be, in ITS world space (see RocketJourney.predict_sun_dir).
	var world_sun := RocketJourney.predict_sun_dir(data, GameState.time_of_day)
	_predicted_sun = (_system.transform.basis.inverse() * world_sun).normalized()
	# `_apply_sky_match` maps camera-local directions back out through the seam basis, so hand it
	# the sun in that frame.
	snap["sun_dir"] = _seam_world_basis.inverse() * (_system.global_transform.basis * _predicted_sun)
	snap["sun_visible"] = 1.0 if pal.sun_energy.sample_baked(t) > 0.02 else 0.0
	# The post stack the destination is about to build, so the seam frame is graded like it.
	_dest_post = {
		"sun_color": pal.sun_color.sample(t),
		"sun_energy": pal.sun_energy.sample_baked(t),
		"glow_hdr_threshold": _ground_post.get("glow_hdr_threshold", 1.15),
		"glow_intensity": pal.glow_intensity.sample_baked(t),
		"glow_strength": _ground_post.get("glow_strength", 0.65),
		"ambient_color": pal.ambient.sample(t),
		"ambient_energy": pal.ambient_energy.sample_baked(t),
		"ambient_sky": _ground_post.get("ambient_sky", 0.10),
		"saturation": pal.saturation.sample_baked(t),
		"night": pal.night.sample_baked(t),
	}
	_predicted_sky = snap
	return snap


## The long banked bezier across the system, from `a` to a point just off the destination.
## `launch_dir`, when given, forces the first control point onto that heading so the arc starts
## exactly along the direction the rocket is already pointing - which is what keeps the seam frame
## from being followed by a lurch as the cruise takes over.
func _build_path(a: Vector3, dest: String, launch_dir: Vector3 = Vector3.ZERO,
		to_doorstep: bool = false) -> void:
	var p3 := _planet_pos(dest)
	var r3 := _globe_radius(dest)
	var arrive_dir := ((a - p3).normalized() * 0.5 + Vector3.UP * 0.7).normalized()
	var b := p3 + arrive_dir * (r3 + 2.4)
	if to_doorstep:
		# Journey mode ends on the line the planet scene is going to descend along, so the camera
		# ends up over the right part of the destination and the pad is a short arc away. The
		# direction is derived from the destination's own PlanetData, exactly as rocket_pad.gd
		# derives it, and mapped back through the system rotation into map space.
		arrive_dir = _approach_dir_map(dest)
		b = p3 + arrive_dir * RocketJourney.arrive_distance(r3)
	var chord := b - a
	# Bow the arc AWAY from the star: a path that swings past the sun puts the rocket inside the
	# glare and you lose the hero of the shot.
	var mid := (a + b) * 0.5
	var outward := mid
	var chord_n := chord.normalized()
	outward -= chord_n * outward.dot(chord_n)
	if outward.length_squared() < 0.5:
		outward = chord.cross(Vector3.UP)
	if outward.length_squared() < 0.5:
		outward = Vector3.RIGHT
	# Arc outward AND over the top of the system: two planets on opposite orbits are almost in line
	# with the star, and a straight run puts the rocket inside the sun's glare for the whole cruise.
	var bow := outward.normalized() * chord.length() * 0.40
	var arc_up := Vector3.UP * chord.length() * 0.30
	var p1 := a + chord * 0.26 + bow + arc_up
	if launch_dir.length_squared() > 0.5:
		p1 = a + launch_dir.normalized() * a.distance_to(p1)
	var p2 := b - chord * 0.26 + bow * 0.62 + arc_up * 0.70
	if to_doorstep:
		# Come in nose-down at the planet, so the seam frame already reads as the start of a descent
		# and the planet scene can simply carry on down the same line.
		p2 = b + arrive_dir * (chord.length() * 0.24)
	_path = PackedVector3Array([a, p1, p2, b])


## The direction the destination's arrival descent comes in from, expressed in MAP space.
func _approach_dir_map(dest: String) -> Vector3:
	var path := "res://src/planet/data/%s.tres" % dest
	if not ResourceLoader.exists(path):
		return (Vector3.UP * 0.7 + Vector3.RIGHT * 0.7).normalized()
	var data: PlanetData = load(path)
	var world_dir := RocketJourney.approach_dir(data.pad_dir, data.spawn_dir)
	return (_system.transform.basis.inverse() * world_dir).normalized()


func _cruise_step(k: float) -> void:
	var pos := _path[0].bezier_interpolate(_path[1], _path[2], _path[3], k)
	# Central difference, clamped INSIDE the curve at both ends. A one-sided lookahead collapses to
	# zero on the last step (k + 0.02 clamps back to k), and the fallback attitude it then used was
	# recorded as the seam nose - which sent the whole arrival descent off on the wrong heading.
	var t1 := minf(k + 0.02, 1.0)
	var t0 := maxf(t1 - 0.04, 0.0)
	var fwd := _path[0].bezier_interpolate(_path[1], _path[2], _path[3], t1) \
		- _path[0].bezier_interpolate(_path[1], _path[2], _path[3], t0)
	if fwd.length_squared() < 1e-8:
		fwd = _rocket.basis.y.normalized()
	_aim_rocket(pos, fwd.normalized())


## Seeds the chase camera exactly where `_update_chase` wants it, and picks the flank it rides on:
## the side the SUN is on, so the camera looks away from the star for the whole flight.
func _seed_chase() -> void:
	var fwd := _rocket.basis.y.normalized()
	var side := fwd.cross(Vector3.UP)
	if side.length_squared() < 0.0005:
		side = fwd.cross(Vector3.FORWARD)
	side = side.normalized()
	# The sun is at the origin; a camera offset TOWARD it is a camera looking AWAY from it.
	_chase_side = 1.0 if side.dot(-_rocket.position.normalized()) >= 0.0 else -1.0
	_chase_pos = _rocket.position - fwd * CHASE_BACK + Vector3.UP * CHASE_UP + side * (CHASE_SIDE * _chase_side)
	_chase_look = _rocket.position + fwd * CHASE_LEAD
	if (_chase_look - _chase_pos).length_squared() > 0.0001:
		_camera.transform = RocketJourney.flight_frame(_chase_pos, _chase_look, _rocket.position, Vector3.UP)


## Sets up the arrival orbit: a plane tilted off the hero camera's view direction, so the rocket
## sweeps across the globe's lit face, ducks behind it once and comes back out.
func _begin_orbit(dest: String, centre: Vector3, orbit_r: float) -> void:
	var view := _arrival_view(dest)
	_hero_eye = view.origin
	_orbit_centre = centre
	_orbit_r = orbit_r
	var view_dir := (centre - _hero_eye).normalized()
	var cam_right := view.basis.x.normalized()
	# Tilt off the view axis so the orbit reads as a real orbit rather than a flat ring.
	var axis := view_dir.rotated(cam_right, deg_to_rad(34.0)).normalized()
	_orbit_x = cam_right - axis * cam_right.dot(axis)
	if _orbit_x.length_squared() < 0.0005:
		_orbit_x = Vector3.UP - axis * Vector3.UP.dot(axis)
	_orbit_x = _orbit_x.normalized()
	_orbit_y = axis.cross(_orbit_x).normalized()
	# Enter the orbit from wherever the cruise left the rocket, so there is no jump cut.
	var here := (_rocket.position - centre)
	here -= axis * here.dot(axis)
	if here.length_squared() < 0.0005:
		here = _orbit_x
	here = here.normalized()
	_orbit_a0 = atan2(here.dot(_orbit_y), here.dot(_orbit_x))
	_orbiting = true


func _orbit_step(k: float) -> void:
	var a := _orbit_a0 + deg_to_rad(ORBIT_SWEEP_DEG) * k
	var pos := _orbit_centre + (_orbit_x * cos(a) + _orbit_y * sin(a)) * _orbit_r
	var b := a + 0.06
	var next := _orbit_centre + (_orbit_x * cos(b) + _orbit_y * sin(b)) * _orbit_r
	_aim_rocket(pos, (next - pos).normalized())


## Moves the rocket to `pos` facing `fwd`, rolling into the turn (banked like an aircraft).
func _aim_rocket(pos: Vector3, fwd: Vector3) -> void:
	var turn := _prev_forward.cross(fwd)
	_prev_forward = fwd
	var target_bank := clampf(-turn.dot(Vector3.UP) * 26.0, -1.0, 1.0) * deg_to_rad(MAX_BANK_DEG)
	_bank = lerpf(_bank, target_bank, 0.12)
	# The rocket model points +Y (nose up), so travel direction becomes its local up.
	var nose := fwd
	var roll_ref := Vector3.UP
	if _ref_blend < 1.0:
		var w := _ref_blend * _ref_blend * (3.0 - 2.0 * _ref_blend)
		roll_ref = _ref_up.slerp(Vector3.UP, w).normalized()
	var right := nose.cross(roll_ref)
	if right.length_squared() < 0.0005:
		right = nose.cross(Vector3.FORWARD)
	right = right.normalized()
	var back := right.cross(nose).normalized()
	var basis := Basis(right, nose, back).rotated(nose, _bank)
	_rocket.transform = Transform3D(basis.scaled(Vector3.ONE * ROCKET_SCALE), pos)
	# Streak emitter: +Z must point backwards along the flight path (built by hand — looking_at()
	# with an up vector parallel to the target is undefined).
	var sz := -nose
	var sy := sz.cross(right)
	_streaks.transform = Transform3D(Basis(right, sy, sz), pos - nose * 1.5)


func _update_chase(delta: float) -> void:
	var fwd := _rocket.basis.y.normalized()
	var up := Vector3.UP
	var side := fwd.cross(Vector3.UP)
	if side.length_squared() < 0.0005:
		side = fwd.cross(Vector3.FORWARD)
	side = side.normalized() * _chase_side
	if _ref_blend < 1.0:
		# Still crossing over from the planet's reference frame (see `_ref_up`).
		var w := _ref_blend * _ref_blend * (3.0 - 2.0 * _ref_blend)
		up = _ref_up.slerp(up, w).normalized()
		side = _ref_flank.slerp(side, w).normalized()
	# Three-quarter rear view: straight-behind puts the camera up the exhaust and the flame bloom
	# swallows the rocket.
	var want := _rocket.position - fwd * CHASE_BACK + up * CHASE_UP + side * CHASE_SIDE
	var look_at := _rocket.position + fwd * CHASE_LEAD
	if _orbiting:
		# Ease out of the chase into the framed hero shot of the destination.
		want = _hero_eye
		look_at = _orbit_centre
	var k := 1.0 - exp((-6.0 if _orbiting else -5.5) * delta)
	_chase_pos = _chase_pos.lerp(want, k)
	_chase_look = _chase_look.lerp(look_at, 1.0 - exp((-6.5 if _orbiting else -7.0) * delta))
	var dir := _chase_look - _chase_pos
	if dir.length_squared() < 0.0001:
		return
	var ref_up := up
	if absf(dir.normalized().dot(up)) > 0.995:
		ref_up = side
	if _orbiting:
		_camera.transform = Transform3D(RocketJourney.look_basis(dir, ref_up), _chase_pos)
		return
	# Same aim clamp the planet scene's flight camera runs, so the rocket cannot leave the frame
	# here either and the two agree across the seam.
	_camera.transform = RocketJourney.flight_frame(_chase_pos, _chase_look, _rocket.position, ref_up)


## Measurement framing: dead abeam of the sun, so exactly half the globe is lit.
func _park_on_terminator(id: String) -> void:
	_input_locked = true
	orbit_showcase = false
	var p := _planet_pos(id)
	var r := _globe_radius(id)
	var to_sun := (-p).normalized()
	var side := to_sun.cross(Vector3.UP)
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	_camera.transform = Transform3D(RocketJourney.look_basis(-side.normalized(), Vector3.UP),
		p + side.normalized() * (r * 3.6))
	_rocket.visible = false
	if _ui != null:
		_ui.set_card_visible(false)
		_ui.set_hint("")
	set_process(false)


# ============================================================================= showcase camera
func _orbit_showcase_camera(delta: float) -> void:
	_orbit_angle += delta * 0.12
	var r := 62.0
	var eye := Vector3(cos(_orbit_angle) * r, 20.0 + sin(_orbit_angle * 0.7) * 6.0, sin(_orbit_angle) * r)
	var look := Vector3(0.0, 0.0, 0.0)
	_camera.transform = Transform3D(RocketJourney.look_basis(look - eye, Vector3.UP), eye)
