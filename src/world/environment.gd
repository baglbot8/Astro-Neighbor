extends Node3D
## Sky, sun, moon, fog, post-processing, the day/night clock, the neighbouring worlds and night
## life for the current planet. world.gd instantiates this as /root/World/Environment right after
## the Planet. Reads PlanetData from /root/World/Planet (or a node in group "planet" exposing
## `data`), falling back to defaults so showcase scenes run standalone.
##
## THIN ATMOSPHERE (STYLE_GUIDE R2.1). These are tiny airless worlds and the player is in a
## pressure suit, so there is no blue dome and no clouds: deep space overhead, a thin dusty band
## hugging the limb, stars visible day and night, and the three neighbouring worlds always hanging
## in the sky (see sky_bodies.gd). The old puffy cloud shells are gone.
##
## The sun and moons orbit in the PLAYER'S LOCAL FRAME (up = planet normal under the player,
## east = parallel-transported tangent) so noon is always overhead and dusk always sits on the
## horizon wherever you stand on the sphere.
##
## Public API:
##   set_time(hour)                 jump the clock to hour (0..24)
##   get_phase() -> String          "dawn" | "day" | "dusk" | "night"
##   get_sun_direction() -> Vector3 unit vector pointing TOWARD the sun (world space)
##   get_night_factor() -> float    0 in full day, 1 in full night
##   set_space_blend(t) / get_space_blend()   0 = on the surface, 1 = full space (rocket climb)
##   time_scale                     1.0 = a 10 minute day, 0.0 = frozen
## Emits EventBus.time_of_day_changed every ~0.05 h and EventBus.day_phase_changed on phase change.

## One in-game day in real seconds (10 minutes).
const DAY_LENGTH_SEC := 600.0
const EMIT_STEP_HOURS := 0.05
const SKY_SHADER := preload("res://src/shaders/sky.gdshader")
const VIGNETTE_SHADER := preload("res://src/shaders/vignette.gdshader")
## Sun arc: rises in the local south-east, peaks 52 deg up leaning south-west (upper-left-behind the
## default camera, so cast shadows fall toward the viewer like the reference), sets north-west.
## The sun crosses the sky between these hours. It sets at 19.8 (not 18.0) so the 18-20 "dusk"
## phase is a real golden hour with long readable shadows instead of an already-dark sky.
const SUN_RISE_HOUR := 5.6
const SUN_SET_HOUR := 19.8
const SUN_RISE_AZ_DEG := -45.0
const SUN_PEAK_AZ_DEG := -135.0
## Default noon elevation. Per-world now: `PlanetData.sun_peak_elev_deg` (52.0 default, so the four
## shipped worlds are byte-identical). Fen ships 11.0 for a sun that never leaves the horizon.
const SUN_PEAK_ELEV_DEG := 52.0
## Below this sun elevation, shadows run so long that the default 25 m shadow range clips them
## mid-frame (at 11 deg a 4.5 m prop throws 23 m), so the range is widened. See `_build_lights`.
const LOW_SUN_ELEV_DEG := 20.0
const LOW_SUN_SHADOW_DISTANCE := 34.0
const SHADOW_DISTANCE := 25.0
## Moon arcs are tuned to the real gameplay rig (camera_rig.gd: 28 deg pitch, 45 deg FOV): the top of
## the screen sits ~5.5 deg BELOW local horizontal and the planet's limb ~24 deg below, so the moon
## has to ride between roughly -10 and -16 deg to be inside the frame and clear of the ground.
## Azimuths stay within ~35 deg of local north so the moon is in shot for a north-facing camera.
const MOON_RISE_AZ_DEG := 55.0
const MOON_PEAK_AZ_DEG := 125.0
const MOON_RISE_ELEV_DEG := -11.0
const MOON_PEAK_ELEV_DEG := -15.0
const MOON_B_RISE_AZ_DEG := 38.0
const MOON_B_PEAK_AZ_DEG := 104.0
const MOON_B_RISE_ELEV_DEG := -19.0
const MOON_B_PEAK_ELEV_DEG := -22.0
const MOON_B_PHASE_OFFSET := 0.5
## Moonlight arrives from high up even though the moon disc sits low in frame: a fill light coming
## from below the horizon would leave the whole ground unlit and cast shadows upward.
const MOON_LIGHT_ELEV_DEG := 38.0
## Distance ahead of a gameplay camera where the player stands (used when no player exists).
const CAMERA_LOOK_DISTANCE := 6.5
const TONEMAP_WHITE := 6.0
## Brightest display value the painted sky may reach. 0.82 display == ~1.10 HDR through the inverse
## ACES curve, which keeps the whole painted sky just under GLOW_THRESHOLD (so only the sun, the
## moons and real emissives bloom).
const SKY_DISPLAY_CAP := 0.82
const GLOW_THRESHOLD := 1.15
const UP_SMOOTHING := 4.0
const PLAYER_SEARCH_INTERVAL := 0.5
## Star brightness in full daylight, relative to night. Never 0: with no air to scatter them out,
## the stars stay up all day (R2.1) - they just have to sit under the sunlit ground, not over it.
const STAR_DAY_SCALE := 0.55
const STAR_BRIGHTNESS := 2.0
## The milky band. Same tone as src/rocket/space_sky.gdshader so both skies are the same galaxy.
const MILKY_WAY_COLOR := Color(0.34, 0.33, 0.56)
## Angle (radians) the deep zenith tone is reached at, and where the mid tone sits. Small on
## purpose: the gameplay rig only ever sees ~18 deg of sky above the limb, and the frame has to run
## from dusty rim to near-black inside that.
const SKY_MID_HEIGHT := 0.10
const SKY_ZENITH_HEIGHT := 0.45
## How long the neighbouring worlds keep re-reading the camera bearing and the sky wedge before
## freezing them. Long enough for the camera rig to finish settling onto the spawn facing and for
## the smoothed local `up` to converge — 0.4 s was not, and on the hub (whose spawn_dir is tilted)
## the whole constellation locked ~26 deg off and slid a body out of the establishing shot.
const BODY_AZ_LOCK_SEC := 1.5
## Name of the global shader parameter that carries the night factor to every shader.
const NIGHT_PARAM := &"astro_night"
# RETIRED: COMPAT_AMBIENT_SCALE. There was a `const COMPAT_AMBIENT_SCALE` here, a multiplier on
# ambient_light_energy applied only under Compatibility. It sat at 1.0 (a no-op) for a long time
# after the value it once carried (0.75) was traced to glow, and it is now gone. DO NOT REVIVE IT.
#
# It was aimed at a real symptom - the browser build's ground reads far too pale - but it is the
# wrong lever, and the measurement says so unambiguously. Setting it to 0.15 takes the home
# planet's GROUND luma GAP from 46 down to 2.8, which looks like a fix, while pushing the
# saturation GAP from 0.0097 to 0.1135: it buys a luma match by desaturating the whole world.
# That is a constant tuned on one crop against one error, exactly like `compat_gain` and the three
# palette "fixes" that were all reverted. Ambient is not the culprit either: measured in
# isolation on a 385,201-pixel ground mask, ambient-only is byte-identical on both renderers
# (60,68,77 against 60,68,77). The pale ground came from the shadow additive pass blending in
# sRGB-encoded space (see _apply below), and that has a cause-level fix with no free parameter.
# If the browser still looks wrong after this, the answer is to finish converting the remaining
# shaders, not to re-add a scalar here.

## True on a phone or in the browser: see _apply_quality_profile in the Platform autoload.
var _low_power := false
## True ONLY under the Compatibility (WebGL2) renderer. Turns off real-time cast shadows on the
## sun and the moon. Set in _ready() from Platform; see the long note above _apply() for why.
var _no_cast_shadows := false
## Colour grade LUT (see _grade_lut). Sampled per channel, so each stop shapes R, G and B separately.
const GRADE_OFFSETS := [0.0, 0.25, 0.6, 1.0]
## The top stop is deliberately BELOW 1.0. R2.6: "no near-clipping whites - cap ~0.92". The grade
## is the one lever the environment owns that touches every 3D surface at once, so it carries the
## highlight shoulder for the whole world: sand, white suits, chrome and specular hits now land
## around luma 0.80-0.85 instead of clipping. NOTE it cannot reach the HUD - CanvasLayer UI is
## composited after the WorldEnvironment's tonemap and adjustments, so the cream panels keep their
## authored near-white and are the only thing left above luma 0.92 in a gameplay frame.
const GRADE_DAY := [
	Color(0.020, 0.012, 0.045), Color(0.205, 0.195, 0.228),
	Color(0.655, 0.648, 0.656), Color(0.945, 0.932, 0.900)]
const GRADE_NIGHT := [
	Color(0.115, 0.105, 0.200), Color(0.300, 0.385, 0.428),
	Color(0.575, 0.595, 0.652), Color(0.930, 0.930, 0.958)]
## Night-factor step that forces the grade LUT to be rebuilt (keeps it off the per-frame path).
const GRADE_STEP := 0.02

## Speed of the clock. 1.0 = 600 s per day. 0.0 freezes time (showcases).
@export var time_scale := 1.0
## When set, used instead of looking up the planet (showcase scenes).
@export var data_override: PlanetData
## Showcase override for the ring plane tilt in degrees. Negative = use the world's own
## `PlanetData.ring_tilt_deg` (42.0 default = Bolt's hoop; Grig ships 86.0, near edge-on).
@export var ring_tilt_deg := -1.0
## Master switch for the vignette overlay.
@export var vignette_enabled := true

var planet_data: PlanetData
var planet_radius: float = 16.0
var palette := EnvPalette.new()

var _hour: float = 9.5
var _last_emit_hour: float = -1.0
var _phase: String = ""
var _up := Vector3.UP
var _east := Vector3.RIGHT
var _sun_dir := Vector3.UP
var _moon_dir_a := Vector3.FORWARD
var _moon_dir_b := Vector3.FORWARD
var _moon_light_dir := Vector3.UP
var _night: float = 0.0
var _grade_night: float = -1.0
var _player: Node3D
var _player_search_timer := 0.0
## Anchor (player position on the sphere) cached once per frame — several systems ask for it.
var _anchor := Vector3.UP
## Camera position (world) cached once per frame; the sky's limb maths and the neighbouring
## worlds are both anchored to the eye, not to the player's feet.
var _eye := Vector3.UP * 20.0
## Unit vector from the eye toward the planet centre, and the planet's angular radius (radians).
var _limb_dir := Vector3.DOWN
var _limb_angle := 0.9
## Angle from the limb up to the top of the frame (radians) — the whole visible sky wedge.
var _band_top := 0.32
## 0 = standing on the surface, 1 = full space. Driven by the rocket's climb (set_space_blend).
var _space_blend := 0.0
## Local azimuth (deg) the camera faced when the world opened. The neighbouring worlds are placed
## relative to it so they are always in the establishing shot - see sky_bodies.gd. Tracked for the
## first BODY_AZ_LOCK_SEC while the camera rig settles, then frozen so the bodies stop following.
var _body_az_origin := 90.0
var _body_az_lock := 0.0

var _world_env: WorldEnvironment
var _env: Environment
var _sky_mat: ShaderMaterial
var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _cam_attr: CameraAttributesPractical
var _vignette_mat: ShaderMaterial
var _vignette_layer: CanvasLayer
var _night_life: NightLife
var _ring: PlanetRing
var _sky_bodies: SkyBodies

func _ready() -> void:
	_low_power = Platform.is_compatibility_renderer() or Platform.is_mobile()
	_no_cast_shadows = Platform.is_compatibility_renderer()
	planet_data = data_override if data_override != null else _find_planet_data()
	planet_radius = planet_data.radius
	palette.build(planet_data)
	_build_environment()
	_build_lights()
	_build_vignette()
	_build_ring()
	_build_sky_bodies()
	_build_night_life()
	_hour = fposmod(GameState.time_of_day, 24.0)
	_last_emit_hour = _hour
	_init_frame()
	_apply(_hour)
	_phase = _phase_for(_hour)
	EventBus.day_phase_changed.emit.call_deferred(_phase)

func _process(delta: float) -> void:
	_update_frame(delta)
	if time_scale > 0.0:
		_advance(delta * time_scale * 24.0 / DAY_LENGTH_SEC)
	_apply(_hour)

# ----------------------------------------------------------------------------- public API
## Jumps the clock to `hour` (wrapped to 0..24) and re-lights the scene immediately.
func set_time(hour: float) -> void:
	_hour = fposmod(hour, 24.0)
	GameState.time_of_day = _hour
	_last_emit_hour = _hour
	_apply(_hour)
	EventBus.time_of_day_changed.emit(_hour)
	_check_phase()

## Current phase name: "dawn" (5-7), "day" (7-18), "dusk" (18-20) or "night" (20-5).
func get_phase() -> String:
	return _phase_for(_hour)

## Unit vector pointing from the scene toward the sun (world space).
func get_sun_direction() -> Vector3:
	return _sun_dir

## Current hour (0..24).
func get_hour() -> float:
	return _hour

## 0 in full day, 1 in full night (stars, fireflies, moons follow this).
func get_night_factor() -> float:
	return _night

## Local "up" the sky is oriented around (planet normal under the player, smoothed).
func get_sky_up() -> Vector3:
	return _up

## Blends the sky from ground level (0) to full space (1) for the rocket's climb (R2.5).
##
## At 0 the thin dust band hugs the limb, stars run at STAR_DAY_SCALE by day, distance fog and the
## vignette are on. At 1 the band is gone, the whole dome is the deep-space navy the solar-system
## map uses, stars are at full brightness and fog is off. Everything in between cross-fades, so the
## rocket can simply tween this from 0 to 1 as it climbs and the sky darkens continuously with no
## cut. The limb itself needs no help: it is derived from the real camera position every frame, so
## the horizon band automatically shrinks and slides down as the planet falls away below you.
func set_space_blend(t: float) -> void:
	_space_blend = clampf(t, 0.0, 1.0)

## Current climb-to-space blend (0 on the surface, 1 in full space).
func get_space_blend() -> float:
	return _space_blend

## Ids of the neighbouring worlds currently drawn in the sky.
func get_sky_body_ids() -> PackedStringArray:
	return _sky_bodies.visible_ids() if _sky_bodies != null else PackedStringArray()


## World-space unit direction to a neighbouring world hanging in the sky, or Vector3.ZERO if it is
## not currently drawn. Requested by the rocket builder so the launch climb can aim at the world
## the player can actually see, instead of looking up the "SkyBodies/Sky_<id>" node by name.
func get_sky_body_direction(id: String) -> Vector3:
	return _sky_bodies.direction_of(id) if _sky_bodies != null else Vector3.ZERO


## Forces a full re-apply of sky, lights, fog and grade for the current hour. The arrival half of
## a rocket journey needs the environment settled before its very first frame, otherwise the seam
## shows one frame of the previous scene's lighting. Cheaper than waiting a frame and safe to call
## any time.
func refresh() -> void:
	_apply(_hour)

# ----------------------------------------------------------------------------- clock
func _advance(hours: float) -> void:
	var prev := _hour
	_hour += hours
	if _hour >= 24.0 or _hour < 0.0:
		# A single frame may span several days when time_scale is cranked up (showcases, tests),
		# so count every day that rolled over, not just one.
		GameState.day_count += int(floor(_hour / 24.0))
		_hour = fposmod(_hour, 24.0)
		_last_emit_hour = _hour - EMIT_STEP_HOURS
	GameState.time_of_day = _hour
	if absf(_hour - _last_emit_hour) >= EMIT_STEP_HOURS or _hour < prev:
		_last_emit_hour = _hour
		EventBus.time_of_day_changed.emit(_hour)
	_check_phase()

func _check_phase() -> void:
	var p := _phase_for(_hour)
	if p != _phase:
		_phase = p
		EventBus.day_phase_changed.emit(p)

static func _phase_for(hour: float) -> String:
	var h := fposmod(hour, 24.0)
	if h >= 5.0 and h < 7.0:
		return "dawn"
	if h >= 7.0 and h < 18.0:
		return "day"
	if h >= 18.0 and h < 20.0:
		return "dusk"
	return "night"

# ----------------------------------------------------------------------------- local frame
func _find_planet_data() -> PlanetData:
	var p := get_node_or_null("/root/World/Planet")
	if p == null:
		p = get_tree().get_first_node_in_group("planet")
	if p != null:
		var d: Variant = p.get("data")
		if d is PlanetData:
			return d as PlanetData
		var r: Variant = p.get("radius")
		var pd := PlanetData.new()
		if r != null and (r is float or r is int):
			pd.radius = float(r)
		return pd
	return PlanetData.new()

func _anchor_position() -> Vector3:
	if is_instance_valid(_player):
		return _player.global_position
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var look := cam.global_position - cam.global_transform.basis.z * CAMERA_LOOK_DISTANCE
		if look.length_squared() > 1.0:
			return look.normalized() * planet_radius
	return Vector3.UP * planet_radius

## Eye position used by the sky. The real camera when there is one (the limb has to be measured
## from where the player actually looks), the player's head otherwise.
func _eye_position() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		return cam.global_position
	return _anchor + _up * 4.0

## Recomputes where the planet's silhouette sits in the sky. Everything that hugs the horizon is
## expressed as an angle above THIS limb rather than above the local horizontal, because on a 16 m
## planet seen from the gameplay rig the limb is ~24 deg BELOW local horizontal — a band painted at
## elevation 0 would be entirely off-screen. It also makes the sky correct for free as the rocket
## climbs: the angular radius shrinks and the band follows the planet down.
func _update_limb() -> void:
	_eye = _eye_position()
	var d := _eye.length()
	if d < 0.001:
		_limb_dir = -_up
		_limb_angle = 1.4
		return
	_limb_dir = -_eye / d
	_limb_angle = asin(clampf(planet_radius / maxf(d, planet_radius * 1.0001), 0.0, 1.0))
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		# Top edge of the frame: the camera's forward tipped up by half the vertical FOV.
		var half_fov := deg_to_rad(cam.fov) * 0.5
		var basis := cam.global_transform.basis
		var top_dir := (-basis.z * cos(half_fov) + basis.y * sin(half_fov)).normalized()
		_band_top = maxf(acos(clampf(top_dir.dot(_limb_dir), -1.0, 1.0)) - _limb_angle, 0.05)

func _init_frame() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	var a := _anchor_position()
	_anchor = a
	_up = a.normalized() if a.length_squared() > 0.0001 else Vector3.UP
	_east = Vector3.RIGHT - _up * _up.dot(Vector3.RIGHT)
	if _east.length_squared() < 0.001:
		_east = Vector3.FORWARD - _up * _up.dot(Vector3.FORWARD)
	_east = _east.normalized()
	_update_limb()

func _update_frame(delta: float) -> void:
	if not is_instance_valid(_player):
		_player_search_timer -= delta
		if _player_search_timer <= 0.0:
			_player_search_timer = PLAYER_SEARCH_INTERVAL
			_player = get_tree().get_first_node_in_group("player") as Node3D
	var a := _anchor_position()
	if a.length_squared() < 0.0001:
		return
	_anchor = a
	var target_up := a.normalized()
	var w := clampf(delta * UP_SMOOTHING, 0.0, 1.0)
	_up = _up.slerp(target_up, w).normalized()
	# Parallel-transport east so the sun's azimuth never jumps as the player walks.
	_east = (_east - _up * _up.dot(_east))
	if _east.length_squared() < 0.0001:
		_east = Vector3.RIGHT - _up * _up.dot(Vector3.RIGHT)
	_east = _east.normalized()
	_update_limb()
	if _body_az_lock < BODY_AZ_LOCK_SEC:
		_body_az_lock += delta
		_track_opening_bearing()
		if _sky_bodies != null:
			_sky_bodies.resolve_band(_up, _east, _body_az_origin, _limb_dir, _limb_angle, _band_top)

## Reads the camera's horizontal bearing in the local frame, in the same convention the sky shader
## uses (degrees from local east toward local north).
func _track_opening_bearing() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		# No camera yet: keep waiting rather than freezing on the default.
		_body_az_lock = 0.0
		return
	var fwd := -cam.global_transform.basis.z
	var flat := fwd - _up * _up.dot(fwd)
	if flat.length_squared() < 0.0001:
		return
	flat = flat.normalized()
	var north := _up.cross(_east)
	_body_az_origin = rad_to_deg(atan2(flat.dot(north), flat.dot(_east)))

func _compute_bodies(hour: float) -> void:
	var theta := (hour - SUN_RISE_HOUR) / (SUN_SET_HOUR - SUN_RISE_HOUR) * PI
	var peak_elev := SUN_PEAK_ELEV_DEG
	if planet_data != null:
		peak_elev = planet_data.sun_peak_elev_deg
	_sun_dir = _arc_dir(theta, SUN_RISE_AZ_DEG, SUN_PEAK_AZ_DEG, peak_elev)
	var theta_m := (hour - 18.5) / 12.0 * PI
	_moon_dir_a = _arc_dir(theta_m, MOON_RISE_AZ_DEG, MOON_PEAK_AZ_DEG, MOON_PEAK_ELEV_DEG, MOON_RISE_ELEV_DEG)
	_moon_dir_b = _arc_dir(theta_m + MOON_B_PHASE_OFFSET, MOON_B_RISE_AZ_DEG, MOON_B_PEAK_AZ_DEG,
		MOON_B_PEAK_ELEV_DEG, MOON_B_RISE_ELEV_DEG)
	_moon_light_dir = _lift(_moon_dir_a, MOON_LIGHT_ELEV_DEG)

## Direction of a body on an arc in the local frame. theta = 0 at the rise point, PI/2 at the peak,
## PI at the set point. Azimuths are degrees from local east toward north; elevations are degrees
## above the local horizontal (negative = below it, which is where the moons live so they land
## inside the gameplay frame).
func _arc_dir(theta: float, rise_az_deg: float, peak_az_deg: float, peak_elev_deg: float, rise_elev_deg: float = 0.0) -> Vector3:
	var rise := _lift(_east.rotated(_up, deg_to_rad(rise_az_deg)), rise_elev_deg)
	var peak := _lift(_east.rotated(_up, deg_to_rad(peak_az_deg)), peak_elev_deg)
	return (rise * cos(theta) + peak * sin(theta)).normalized()

## Takes the horizontal part of `dir` and tilts it to `elev_deg` above the local horizontal.
func _lift(dir: Vector3, elev_deg: float) -> Vector3:
	var flat := dir - _up * _up.dot(dir)
	if flat.length_squared() < 0.0001:
		flat = _east
	flat = flat.normalized()
	var e := deg_to_rad(elev_deg)
	return (_up * sin(e) + flat * cos(e)).normalized()

# ----------------------------------------------------------------------------- building
func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = SKY_SHADER
	sky.sky_material = _sky_mat
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Was 0.4, when the sky was a bright blue dome that supplied a lot of free fill. A deep-space
	# sky supplies almost none, so the palette's ambient colour now carries the shadow side (its
	# energy curve was raised to match) and only a tenth comes from the sky — enough for the warm
	# limb band to tint the ground at dawn and dusk, not enough to crush the shadows.
	_env.ambient_light_sky_contribution = 0.10
	_env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.tonemap_exposure = 1.0
	_env.tonemap_white = TONEMAP_WHITE
	# Bloom is deliberately gentle (style guide: strength ~0.6, threshold ~1.0). The threshold sits
	# just above the painted sky's HDR value so only the sun, moons and real emissives glow, and the
	# luminance cap stops a lamp core from smearing a white disc over half the screen.
	# GLOW OFF ON MOBILE / IN THE BROWSER. Seven glow levels with additive blending is a large
	# fill-rate cost, and on a real iPhone it also bloomed the whole picture into white — the
	# player's report was that everything looked bright and 'blurred with whites'. Compatibility
	# supports fewer glow modes than Forward+ anyway, so this is not the look it is on desktop.
	_env.glow_enabled = not _low_power
	_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	_env.glow_hdr_threshold = GLOW_THRESHOLD
	_env.glow_hdr_scale = 1.0
	_env.glow_hdr_luminance_cap = 5.0
	_env.glow_strength = 0.65
	_env.glow_bloom = 0.02
	_env.set_glow_level(0, 0.0)
	_env.set_glow_level(1, 0.7)
	_env.set_glow_level(2, 1.0)
	_env.set_glow_level(3, 0.5)
	_env.set_glow_level(4, 0.25)
	_env.set_glow_level(5, 0.1)
	_env.set_glow_level(6, 0.0)
	# SSAO is UNSUPPORTED under Compatibility — asking for it there only costs setup and misleads
	# anyone reading this. Measured: disabling it changes a Forward+ frame by 0.000, because the
	# ground and foliage shaders drive their own AO channel.
	_env.ssao_enabled = not _low_power
	_env.ssao_radius = 0.8
	_env.ssao_intensity = 1.1
	_env.ssao_power = 1.5
	_env.ssao_detail = 0.4
	_env.ssao_horizon = 0.06
	_env.ssao_sharpness = 0.98
	_env.ssao_light_affect = 0.0
	_env.ssao_ao_channel_affect = 0.0
	_env.ssil_enabled = false
	_env.sdfgi_enabled = false
	_env.ssr_enabled = false
	_env.volumetric_fog_enabled = false
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_depth_begin = 18.0
	_env.fog_depth_end = 64.0
	_env.fog_depth_curve = 1.3
	_env.fog_sky_affect = 0.0
	# Aerial perspective mixes the SKY colour into distant surfaces. With a deep-space sky that
	# would paint the far hillside navy, so it is nearly off; the little that remains keeps the
	# far rim from detaching from the horizon band.
	_env.fog_aerial_perspective = 0.08
	_env.fog_sun_scatter = 0.0
	_env.fog_light_energy = 1.0
	_env.adjustment_enabled = true
	_env.adjustment_brightness = 1.0
	_env.adjustment_contrast = 1.04
	_env.adjustment_saturation = 1.08
	_update_grade(0.0)

	_cam_attr = CameraAttributesPractical.new()
	_cam_attr.auto_exposure_enabled = false
	_cam_attr.exposure_multiplier = 1.0
	# Far DOF is OFF at every hour now. The sky sits at the far plane and stars are visible in
	# daylight too (R2.1), so any far blur turns crisp pinpoints into 3-4 px blobs — and it would
	# soften the neighbouring worlds, which live 140 m out. See EnvPalette.dof_amount.
	_cam_attr.dof_blur_far_enabled = false
	_cam_attr.dof_blur_far_distance = 30.0
	_cam_attr.dof_blur_far_transition = 26.0
	_cam_attr.dof_blur_amount = 0.0

	_world_env = WorldEnvironment.new()
	_world_env.name = "WorldEnvironment"
	_world_env.environment = _env
	_world_env.camera_attributes = _cam_attr
	add_child(_world_env)

## 1D per-channel colour grade. Day: lifted violet blacks, warm whites — the gentle "photo" look the
## reference has. Night: the whole frame is washed toward teal-navy with lifted blacks, which is how
## the reference night shots read (grass dark teal, sand lavender, nothing pure black). The two are
## cross-faded by the night factor; the texture is only rebuilt when the factor actually moves.
static func _grade_lut(night: float) -> GradientTexture1D:
	var g := Gradient.new()
	var offsets := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in GRADE_DAY.size():
		offsets.append(float(GRADE_OFFSETS[i]))
		cols.append((GRADE_DAY[i] as Color).lerp(GRADE_NIGHT[i] as Color, night))
	g.offsets = offsets
	g.colors = cols
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	return tex

## Rebuilds the colour grade only when the night factor has moved enough to matter.
func _update_grade(night: float) -> void:
	if absf(night - _grade_night) < GRADE_STEP and _env.adjustment_color_correction != null:
		return
	_grade_night = night
	_env.adjustment_color_correction = _grade_lut(night)

## Builds the sun and the moon fill light.
##
## SHADOW SETTINGS — read this before touching them (docs/OPEN_ISSUES.md issue 1).
## `light_angular_distance` MUST stay 0 on both lights. Any value above zero switches Godot's
## directional shadow to the PCSS path, which first runs a blocker search over a disk rotated by a
## hash of `gl_FragCoord` and bails out with "fully lit" when that disk happens to miss. On a large
## smooth surface crossing the terminator - the player's helmet, a visor, a shirt, a tree canopy -
## that is a per-pixel coin flip, so it renders a full-amplitude dot grid locked to the screen, and
## the grid crawls whenever the surface moves under it. That was the "golf ball" stipple.
## With the blocker search gone, `shadow_blur` alone sets the (uniform) penumbra width, which is
## what the ACNH reference looks like anyway, and it is CHEAPER: one PCF loop instead of two.
##
## `directional_shadow_max_distance` 25 covers everything a planet camera can see (the horizon on
## the biggest planet, R=26, is ~12 m out) and nearly doubles shadow-texel density versus 42, which
## is what lets `shadow_normal_bias` come down from 1.8 - high enough to peter-pan a shadow off the
## astronaut's boots - to 1.0 without acne returning on flat ground.
func _build_lights() -> void:
	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	# Resting state only. `_apply()` rewrites this every frame (and once from _ready() before the
	# first frame is drawn), including the Compatibility gate - see the note above _apply().
	_sun.shadow_enabled = not _no_cast_shadows
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_sun.directional_shadow_split_1 = 0.3
	# A low sun stretches every shadow: at 11 deg the caster-to-shadow ratio is 5.1x, so a 4.5 m
	# prop reaches 23 m and the 25 m range would cut the colonnade's shadow bars off mid-pan.
	var shadow_dist := SHADOW_DISTANCE
	if planet_data != null and planet_data.sun_peak_elev_deg < LOW_SUN_ELEV_DEG:
		shadow_dist = LOW_SUN_SHADOW_DISTANCE
	_sun.directional_shadow_max_distance = shadow_dist
	_sun.directional_shadow_fade_start = 0.8
	_sun.directional_shadow_blend_splits = true
	_sun.light_angular_distance = 0.0
	_sun.shadow_bias = 0.03
	_sun.shadow_normal_bias = 1.0
	_sun.shadow_blur = 0.7
	_sun.light_specular = 0.6
	add_child(_sun)

	_moon = DirectionalLight3D.new()
	_moon.name = "MoonLight"
	_moon.shadow_enabled = false
	_moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_moon.directional_shadow_split_1 = 0.3
	_moon.directional_shadow_max_distance = shadow_dist
	_moon.directional_shadow_fade_start = 0.8
	_moon.directional_shadow_blend_splits = true
	_moon.light_angular_distance = 0.0
	_moon.shadow_bias = 0.04
	_moon.shadow_normal_bias = 1.2
	_moon.shadow_blur = 1.1
	_moon.shadow_opacity = 0.6
	_moon.light_specular = 0.3
	add_child(_moon)

func _build_vignette() -> void:
	_vignette_layer = CanvasLayer.new()
	_vignette_layer.name = "VignetteLayer"
	_vignette_layer.layer = 0
	add_child(_vignette_layer)
	var rect := ColorRect.new()
	rect.name = "Vignette"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = VIGNETTE_SHADER
	rect.material = _vignette_mat
	rect.visible = vignette_enabled
	_vignette_layer.add_child(rect)

## The three neighbouring worlds hanging in the sky (R2.1). See sky_bodies.gd.
func _build_sky_bodies() -> void:
	_sky_bodies = SkyBodies.new()
	_sky_bodies.name = "SkyBodies"
	add_child(_sky_bodies)
	_sky_bodies.setup(planet_data.id)

func _build_ring() -> void:
	if not planet_data.has_ring:
		return
	_ring = PlanetRing.new()
	_ring.name = "Ring"
	# Per-world since R2.10. The 1.7 / 2.9 / 42.0 defaults reproduce Bolt's shipped hoop exactly;
	# Grig ships 1.22 / 1.52 / 86.0, a near edge-on razor band that reads as a different object.
	# src/rocket/space_globe.gd and src/world/sky_bodies.gd now read the same three fields, so the
	# ring no longer changes size across the journey cut.
	_ring.inner_radius = planet_radius * planet_data.ring_inner_scale
	_ring.outer_radius = planet_radius * planet_data.ring_outer_scale
	_ring.ring_color = planet_data.ring_color
	_ring.tilt_deg = ring_tilt_deg if ring_tilt_deg >= 0.0 else planet_data.ring_tilt_deg
	add_child(_ring)

func _build_night_life() -> void:
	_night_life = NightLife.new()
	_night_life.name = "NightLife"
	_night_life.planet_radius = planet_radius
	add_child(_night_life)

# ----------------------------------------------------------------------------- per-frame apply
## WEB PARITY, ROOT CAUSE (docs/OPEN_ISSUES.md 32). Under Godot's Compatibility (WebGL2) renderer a
## directional light with `shadow_enabled = true` is drawn in a SEPARATE ADDITIVE PASS, and that
## pass is combined with the base pass in sRGB-ENCODED space instead of linear space:
##
##     C_linear = s2l( l2s(ambient) + l2s(direct) )      instead of      ambient + direct
##
## Measured on showcase/planet_home.tscn with grass_planet patched to a flat albedo, median over a
## 385,201-pixel ground mask:
##
##     run                Forward+       Compatibility    C/F linear
##     ambient only     60, 68, 77       60, 68, 77         1.000
##     direct only      83, 78, 69       82, 79, 70         1.026
##     BOTH            101,102,101      142,146,146         2.163
##
## Forward+ is exactly additive (both / (amb + dir) = 0.992); Compatibility gives 2.114. Either
## term ALONE is exact, because l2s(0) = 0 makes a single non-zero term round-trip perfectly -
## which is why every isolated harness matched and this took so long to find. The single toggle
## that flips it is `shadow_enabled`: with shadows off, both renderers agree (F+ 101,102,101
## against C 101,103,101). A zero-free-parameter prediction test at three ambient energies landed
## within 1 code value on both renderers at every level (F+ 92.0/103.1/121.8 predicted against
## 91/102/121 measured; C 126.4/147.0/174.5 against 126/146/174).
##
## So on Compatibility we simply do not take that pass: `_no_cast_shadows`. There is no constant
## and nothing tuned. Measured effect on the region-masked GROUND MAE (F+ against Compatibility,
## 3 planets x 3 hours, this exact fix):
##
##           dawn (h 6.5)      noon (h 13)       dusk (h 19)
##     home  41.5 ->  6.2      48.7 ->  6.7      36.6 ->  5.5
##     hub   47.4 -> 20.6      30.5 -> 10.0      39.2 -> 15.1
##     zorp  52.1 ->  8.8      33.5 ->  2.4      45.2 ->  3.9
##
## and the GROUND saturation gap, which is the number COMPAT_AMBIENT_SCALE would have wrecked:
##     home noon 0.1813 -> 0.0229    hub noon 0.1439 -> 0.0045    zorp noon 0.1608 -> 0.0070
##
## Every figure above is the mean of two independent captures that agreed to within 0.06 codes.
## Forward+ is untouched (the gate is false there): F+ before against F+ after is bit-identical on
## home dawn and noon, and elsewhere differs only on 0.1-0.3% of pixels with p95 = 0, which is the
## known capture jitter.
##
## The residual - hub is the worst of the three, and its ground p95 is still 144.7 against 187.8 -
## is the 28 shaders that have not had the pc_s2l/pc_l2s conversion yet plus the frozen sky shader
## (the SKY region does not move at all here: home noon 19.30 -> 19.30). The answer to that
## residual is to finish the conversion, NOT to add a scalar here.
##
## THIS MUST LIVE AT THE PER-FRAME WRITE, not in _build_lights(). `_apply()` runs from _process()
## every frame and rewrites `shadow_enabled` from the sun energy curve, so a one-shot edit at build
## time is silently undone before anything is drawn. Three rounds of false negatives came from
## exactly that. `_build_lights` still sets it, but only as the resting state of a light that
## `_apply()` immediately overwrites in _ready().
##
## OTHER LIGHTS: the additive pass is triggered by SHADOWS, not by the light type, so every
## shadow-caster in the game has this bug. Audited 2026-09-08: the sun and the moon here are the
## only two. Every OmniLight3D and SpotLight3D in the tree already sets `shadow_enabled = false`
## explicitly - hub building_base.gd:340,360, event_space.gd:324,338 (the party spots and omnis),
## planet_props.gd:220, deco_item.gd:154, night_life via those, and the whole rocket rig. Nothing
## in night_life casts. The hub, which has the most omnis of any scene, was measured anyway and
## improves by the same mechanism (noon GROUND MAE 30.5 -> 10.0), which is what you would expect
## if the directional sun were the only caster.
##
## The moon is gated off the same way, and off the SAME `sun_casts` intent rather than off
## `_sun.shadow_enabled`. Reading the result instead of the intent would invert the moon: at noon
## on Compatibility `_sun.shadow_enabled` is false, so the moon would switch its own shadows ON and
## reintroduce the bug. Night was measured to confirm the gate reaches the moon at all:
## home h=2, GROUND MAE 22.89 -> 4.41.
##
## COST, honestly: the browser build loses real-time cast shadows, and this is a real loss, not a
## free win. The player keeps ground contact - src/player/blob_shadow.gdshader draws a blob under
## the boots and it is clearly visible at noon and at dusk with cast shadows off. Props have NO
## equivalent. Looked at, dawn/noon/dusk, both renderers: on the open planets (home, zorp) the
## trees and rocks still read as planted, because their trunks meet the ground and the canopy
## self-shading carries the form. On the HUB PLAZA it is visible: the bench loses both its cast
## shadow and its contact darkening and reads as sitting slightly above the tiles, and at dusk the
## long raking shadow bars the lamp posts and the colonnade threw across the plaza - a real part of
## that scene's mood - are simply gone. If that matters more than parity, the next move is a
## prop-side blob shadow like the player's, NOT turning this gate back off.
func _apply(hour: float) -> void:
	_compute_bodies(hour)
	var t := EnvPalette.t(hour)
	_night = palette.night.sample_baked(t)
	var sun_col := palette.sun_color.sample(t)
	var sun_energy := palette.sun_energy.sample_baked(t)
	var moon_energy := palette.moon_energy.sample_baked(t)
	var zenith := palette.sky_zenith.sample(t)
	var mid := palette.sky_mid.sample(t)
	var limb := palette.sky_limb.sample(t)
	var haze := palette.haze.sample(t)
	var glow_col := palette.sun_glow_color.sample(t)
	var glow := palette.sun_glow.sample_baked(t)
	var wisp_col := palette.wisp_color.sample(t)
	var fog_col := palette.fog.sample(t)

	# --- lights
	_sun.light_color = sun_col
	_sun.light_energy = sun_energy
	var sun_on := sun_energy > 0.02
	_sun.visible = sun_on
	if sun_on:
		_sun.global_transform = Transform3D(_light_basis(_sun_dir), Vector3.ZERO)
	# `sun_casts` is the artistic intent (is the sun high enough to throw a shadow); the renderer
	# gate is applied separately so the moon still reads the intent rather than the result - if it
	# read `_sun.shadow_enabled` it would switch its own shadows ON at noon on Compatibility.
	var sun_casts := sun_energy > 0.08
	_sun.shadow_enabled = sun_casts and not _no_cast_shadows
	_moon.light_color = palette.moon_light.sample(t)
	_moon.light_energy = moon_energy
	var moon_on := moon_energy > 0.02
	_moon.visible = moon_on
	if moon_on:
		_moon.global_transform = Transform3D(_light_basis(_moon_light_dir), Vector3.ZERO)
	_moon.shadow_enabled = moon_on and not sun_casts and not _no_cast_shadows

	# --- environment
	_env.ambient_light_color = palette.ambient.sample(t)
	# NO renderer-specific scale here, deliberately - see the retired COMPAT_AMBIENT_SCALE note at
	# the top of this file. The old "ambient is stronger under Compatibility" reading was an
	# artefact: it obtained "ambient" by differencing two runs, and the sRGB-encoded shadow blend
	# inflates that difference by exactly the factor it was being blamed for. Ambient measured in
	# isolation is byte-identical on both renderers.
	_env.ambient_light_energy = palette.ambient_energy.sample_baked(t)
	_env.fog_light_color = fog_col
	# What little haze there is belongs to the surface; by the time the rocket is in space there
	# is nothing left to scatter.
	_env.fog_density = palette.fog_density.sample_baked(t) * (1.0 - _space_blend)
	_env.glow_intensity = palette.glow_intensity.sample_baked(t)
	_env.adjustment_saturation = palette.saturation.sample_baked(t)
	_update_grade(_night)
	var dof := palette.dof_amount.sample_baked(t)
	_cam_attr.dof_blur_far_enabled = dof > 0.002
	_cam_attr.dof_blur_amount = dof
	# Every shader that changes with the clock (toon emission, visor highlight) reads this.
	RenderingServer.global_shader_parameter_set(NIGHT_PARAM, _night)

	# --- sky
	_sky_mat.set_shader_parameter("sky_up", _up)
	_sky_mat.set_shader_parameter("sky_east", _east)
	_sky_mat.set_shader_parameter("limb_dir", _limb_dir)
	_sky_mat.set_shader_parameter("limb_angle", _limb_angle)
	_sky_mat.set_shader_parameter("sun_dir", _sun_dir)
	_sky_mat.set_shader_parameter("moon_dir_a", _moon_dir_a)
	_sky_mat.set_shader_parameter("moon_dir_b", _moon_dir_b)
	_sky_mat.set_shader_parameter("moon_count", planet_data.moon_count)
	# Three sky uniforms that were declared but never set for any planet before R2.10. The
	# defaults below are the shader's own, so the shipped four are byte-identical; Fen ships a
	# 0.082 sun disc (3.2x) and Grig 0.155 moons. Set beside moon_count rather than once at build
	# time so a showcase that swaps `data_override` at runtime picks them up too.
	_sky_mat.set_shader_parameter("sun_disc_size", planet_data.sun_disc_size)
	_sky_mat.set_shader_parameter("moon_size", planet_data.moon_size)
	_sky_mat.set_shader_parameter("star_density", planet_data.star_density)
	_sky_mat.set_shader_parameter("zenith_color", zenith)
	_sky_mat.set_shader_parameter("mid_color", mid)
	_sky_mat.set_shader_parameter("limb_color", limb)
	_sky_mat.set_shader_parameter("haze_color", haze)
	_sky_mat.set_shader_parameter("haze_strength", palette.haze_strength.sample_baked(t))
	_sky_mat.set_shader_parameter("haze_width", palette.haze_width.sample_baked(t))
	_sky_mat.set_shader_parameter("mid_height", SKY_MID_HEIGHT)
	_sky_mat.set_shader_parameter("zenith_height", SKY_ZENITH_HEIGHT)
	_sky_mat.set_shader_parameter("sun_color", sun_col.lerp(Color.WHITE, 0.35))
	_sky_mat.set_shader_parameter("sun_glow_color", glow_col)
	_sky_mat.set_shader_parameter("sun_glow", glow)
	_sky_mat.set_shader_parameter("wisp_color", wisp_col)
	_sky_mat.set_shader_parameter("wisp_amount", palette.wisp_amount.sample_baked(t))
	_sky_mat.set_shader_parameter("milky_way_color", MILKY_WAY_COLOR)
	_sky_mat.set_shader_parameter("star_brightness", STAR_BRIGHTNESS)
	_sky_mat.set_shader_parameter("star_day", STAR_DAY_SCALE)
	_sky_mat.set_shader_parameter("night", _night)
	_sky_mat.set_shader_parameter("space_blend", _space_blend)
	_sky_mat.set_shader_parameter("tonemap_white", TONEMAP_WHITE)
	_sky_mat.set_shader_parameter("display_cap", SKY_DISPLAY_CAP)

	# --- neighbouring worlds
	if _sky_bodies != null:
		var clock: float = float(GameState.day_count) * 24.0 + hour
		_sky_bodies.update_state(_eye, _up, _east, _body_az_origin, _sun_dir, _night, clock,
			sun_col.lerp(Color.WHITE, 0.5))

	# --- ring / night life / vignette
	if _ring != null:
		_ring.update_lighting(_sun_dir if sun_on else _moon_light_dir, _night)
	_night_life.update_state(_night, _anchor, _up, _east, planet_radius)
	if _vignette_mat != null:
		_vignette_mat.set_shader_parameter("strength", palette.vignette.sample_baked(t))

## Basis whose -Z points along -dir_to_body (i.e. the light shines from the body).
static func _light_basis(dir_to_body: Vector3) -> Basis:
	var fwd := -dir_to_body.normalized()
	var ref_up := Vector3.UP if absf(fwd.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	return Basis.looking_at(fwd, ref_up)
