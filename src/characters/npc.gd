class_name NPC
extends PlanetBody
## A neighbour who lives on a planet: wanders around home, looks at you when you come close, and
## talks when you press interact (ARCHITECTURE §6).
##
##   idle (2-6 s, looks around; turns to face the player within 5 m)
##     -> wander (walks to a spot inside wander_radius_m of home, avoiding water, props and the
##                reserved building/spawn/pad zones)
##     -> idle ...
##   talking  freezes movement, faces the player and plays the talk animation while lines type.
##
## Public API: `start_conversation(player)`, `wander_enabled(b)`, `face_player()`, `play_emote(n)`.
## A small bobbing "!" floats overhead whenever this neighbour has something to ask or to receive.

@export var npc_id: String = ""
@export var display_name: String = ""
@export var voice_profile: String = "alien"
@export var accent_color: Color = Color("#5b7cff")
@export var wander_radius_m: float = 9.0
@export var walk_speed: float = 2.2

const IDLE_MIN := 2.0
const IDLE_MAX := 6.0
const LOOK_AT_PLAYER_M := 5.0
const ARRIVE_M := 0.45
const TURN_SPEED := 6.0
const FACE_TURN_SPEED := 9.0
const WANDER_TIMEOUT := 14.0
const AVOID_RESERVED_M := 2.6
const AVOID_PROP_M := 1.1
const OWN_ZONE_M := 3.6
const PATH_SAMPLES := 4
## Feet-to-feet distance at which the "Talk" prompt lights up.
const TALK_REACH := 2.2
const MARKER_POLL := 0.45
## Default height of the "!" above a neighbour's feet, in model space (multiplied by body_scale).
## A model whose crown reaches higher than this -- Grig's eye rides a stalk to 1.773 -- exposes
## `marker_clearance() -> float` and the marker is lifted to clear it. See `_ensure_collision`.
const MARKER_HEIGHT := 1.52
const MARKER_CLEARANCE_GAP := 0.18
## Stem and dot of the "!". The 6.3 cm gap between them is what stops the pair reading as one bar.
const MARKER_STEM_Y := 0.105
const MARKER_DOT_Y := -0.085
const BODY_HEIGHT := 1.4
const BODY_RADIUS := 0.34

enum State { IDLE, WANDER, TALKING }

var home_dir: Vector3 = Vector3.UP

var _model: CharacterModel
var _interactable: Interactable
var _state: State = State.IDLE
var _state_timer: float = 0.0
var _target_dir: Vector3 = Vector3.UP
var _placed := false
var _wander_on := true
var _speed_factor: float = 0.0
var _talking := false
var _emote: String = ""
var _emote_timer: float = 0.0
var _last_small_talk: String = ""
var _conversation_running := false
var _marker: Node3D
var _marker_timer: float = 0.0
var _marker_t: float = 0.0
var _favors: FavorSystem
var _player_cache: Node3D
var _face_target: Vector3 = Vector3.ZERO
var _has_face_target := false
var _footstep_surface: String = "grass"
var _rng := RandomNumberGenerator.new()
var _body_scale: float = 1.0
var _marker_h: float = MARKER_HEIGHT


func _ready() -> void:
	super._ready()
	add_to_group("npc")
	collision_layer = 1 << 2                                  # layer 3: npc
	collision_mask = 1 | (1 << 3) | (1 << 6)                   # terrain | decoration | building
	_rng.randomize()
	_apply_data()
	_ensure_model()
	_ensure_collision()
	_ensure_interactable()
	_build_marker()
	_state_timer = _rng.randf_range(IDLE_MIN, IDLE_MAX)


## Fills the exported fields from NpcData when the scene left them blank.
func _apply_data() -> void:
	if npc_id == "":
		npc_id = String(name)
	var d := NpcData.get_data(npc_id)
	if d.is_empty():
		return
	if display_name == "":
		display_name = str(d.get("display_name", npc_id.capitalize()))
	voice_profile = str(d.get("voice_profile", voice_profile))
	accent_color = Color(str(d.get("accent", accent_color.to_html())))
	wander_radius_m = float(d.get("wander_radius_m", wander_radius_m))


func _ensure_model() -> void:
	_model = get_node_or_null("Model") as CharacterModel
	if _model == null:
		for c: Node in get_children():
			if c is CharacterModel:
				_model = c as CharacterModel
				break
	if _model == null:
		_model = NpcModels.make(npc_id)
		_model.name = "Model"
		add_child(_model)
	_model.footstep.connect(_on_footstep)
	_model.emote_finished.connect(_on_emote_finished)


func _ensure_collision() -> void:
	_body_scale = maxf(_model.body_scale, 0.4)
	# Duck-typed so no base class has to grow the method: a model that knows it is taller than the
	# default marker height says so, and everyone else stays byte-identical at 1.52.
	_marker_h = MARKER_HEIGHT
	if _model != null and _model.has_method("marker_clearance"):
		_marker_h = maxf(MARKER_HEIGHT, float(_model.call("marker_clearance")) + MARKER_CLEARANCE_GAP)
	for c: Node in get_children():
		if c is CollisionShape3D:
			return
	var scale_factor := _body_scale
	var shape := CollisionShape3D.new()
	shape.name = "Body"
	var cap := CapsuleShape3D.new()
	cap.radius = BODY_RADIUS * scale_factor
	cap.height = maxf(BODY_HEIGHT * scale_factor, cap.radius * 2.0 + 0.05)
	shape.shape = cap
	shape.position = Vector3(0.0, cap.height * 0.5, 0.0)
	add_child(shape)


func _ensure_interactable() -> void:
	for c: Node in get_children():
		if c is Interactable:
			_interactable = c as Interactable
			break
	if _interactable == null:
		_interactable = Interactable.new()
		_interactable.name = "TalkArea"
		var shape := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = 0.9
		shape.shape = sph
		shape.position = Vector3(0.0, 0.7, 0.0)
		_interactable.add_child(shape)
		add_child(_interactable)
	_interactable.prompt_text = "Talk"
	# feet-to-feet, so 2.6 left ~1.9 m of clear air between the two bodies and the prompt lit up
	# further away than it looked like it should. 2.2 puts you next to the neighbour, as in AC.
	_interactable.reach = TALK_REACH
	_interactable.require_facing = false
	if not _interactable.interacted.is_connected(_on_interacted):
		_interactable.interacted.connect(_on_interacted)


# ============================================================================= public API
## Starts (or re-focuses) a conversation with the player. Safe to call while one is already running.
func start_conversation(player: Player) -> void:
	if _conversation_running:
		return
	_conversation_running = true
	set_talking(true)
	face_player(true)
	await Conversation.run(self, player)
	set_talking(false)
	_has_face_target = false
	_conversation_running = false
	_state = State.IDLE
	_state_timer = _rng.randf_range(IDLE_MIN, IDLE_MAX)
	_refresh_marker()


## Turns wandering on/off (shopkeepers behind a counter, cutscenes).
func wander_enabled(enabled: bool) -> void:
	_wander_on = enabled
	if not enabled and _state == State.WANDER:
		_state = State.IDLE
		_state_timer = _rng.randf_range(IDLE_MIN, IDLE_MAX)


## Freezes movement and plays the talk animation.
func set_talking(talking: bool) -> void:
	_talking = talking
	_state = State.TALKING if talking else State.IDLE
	if talking:
		velocity = Vector3.ZERO


func is_talking() -> bool:
	return _talking


## Snap-turns toward the player (instantly when `instant`, otherwise over the next few frames).
func face_player(instant: bool = false) -> void:
	var p := _player()
	if p == null:
		return
	var to := p.global_position - global_position
	if instant:
		face_direction(to, 1000.0, 1.0)
	else:
		face_direction(to, FACE_TURN_SPEED, get_physics_process_delta_time())


## Turns toward an arbitrary world point over the next few frames. `DialogueRunner` uses it to keep
## the neighbour's front three-quarter view on camera while the box is open, the way AC villagers
## turn toward the camera rather than squarely at the player.
func face_toward_point(world_pos: Vector3) -> void:
	_face_target = world_pos
	_has_face_target = true


## Plays a one-shot emote ("wave", "happy", "think", "surprised").
func play_emote(emote_name: String) -> void:
	if _model == null:
		return
	var dur := _model.emote_duration(emote_name)
	if dur <= 0.0:
		return
	_emote = emote_name
	_emote_timer = dur
	_model.set_state(emote_name)
	if emote_name == "happy":
		AudioManager.play_sfx_at("emote_happy", global_position, -6.0)


func get_model() -> CharacterModel:
	return _model


## The small-talk line this neighbour used last, so the next one is never a repeat.
func last_small_talk() -> String:
	return _last_small_talk


func set_last_small_talk(line: String) -> void:
	_last_small_talk = line


# ============================================================================= loop
func _physics_process(delta: float) -> void:
	if planet == null:
		planet = get_tree().get_first_node_in_group("planet") as Planet
		if planet == null:
			return
	if not _placed:
		_place_home()
	align_to_planet()

	if _emote_timer > 0.0:
		_emote_timer -= delta
		if _emote_timer <= 0.0:
			_emote = ""

	match _state:
		State.TALKING:
			_tick_talking(delta)
		State.WANDER:
			_tick_wander(delta)
		_:
			_tick_idle(delta)

	apply_planet_gravity(delta)
	move_and_slide()
	_update_marker(delta)


func _process(delta: float) -> void:
	if _model == null:
		return
	if _emote == "" and not _talking:
		_model.set_state("walk" if _speed_factor > 0.1 else "idle")
	elif _talking and _emote == "":
		_model.set_state("talk")
	_model.tick(delta, _speed_factor)


func _tick_talking(delta: float) -> void:
	set_tangent_velocity(Vector3.ZERO)
	_speed_factor = 0.0
	if _has_face_target:
		face_direction(_face_target - global_position, FACE_TURN_SPEED, delta)
		return
	var p := _player()
	if p != null:
		face_direction(p.global_position - global_position, FACE_TURN_SPEED, delta)


func _tick_idle(delta: float) -> void:
	set_tangent_velocity(get_tangent_velocity().move_toward(Vector3.ZERO, walk_speed * 6.0 * delta))
	_speed_factor = get_tangent_velocity().length() / walk_speed
	var p := _player()
	if p != null and global_position.distance_to(p.global_position) < LOOK_AT_PLAYER_M:
		face_direction(p.global_position - global_position, TURN_SPEED * 0.6, delta)
	_state_timer -= delta
	if _state_timer <= 0.0 and _wander_on and _emote == "":
		_target_dir = _pick_wander_target()
		_state = State.WANDER
		_state_timer = WANDER_TIMEOUT


func _tick_wander(delta: float) -> void:
	_state_timer -= delta
	var target := planet.surface_point(_target_dir)
	var to := target - global_position
	var tangent := to - up * to.dot(up)
	if tangent.length() < ARRIVE_M or _state_timer <= 0.0:
		_state = State.IDLE
		_state_timer = _rng.randf_range(IDLE_MIN, IDLE_MAX)
		set_tangent_velocity(Vector3.ZERO)
		_speed_factor = 0.0
		return
	var dir := tangent.normalized()
	set_tangent_velocity(dir * walk_speed)
	face_direction(dir, TURN_SPEED, delta)
	_speed_factor = 1.0


# ============================================================================= placement & wander
func _place_home() -> void:
	_placed = true
	home_dir = _resolve_home_dir()
	var forward := planet.data.spawn_dir.normalized() if planet.data != null else Vector3.FORWARD
	place_on_planet(home_dir, forward - home_dir * forward.dot(home_dir), 0.06)
	_target_dir = home_dir
	_footstep_surface = _surface_for_biome()
	_refresh_marker()


## Home spot: the NPC's own `home_dir`, or — for hub shopkeepers — a point a few metres in front of
## their building, stepped toward the plaza spawn and nudged sideways so twins don't overlap.
func _resolve_home_dir() -> Vector3:
	var d := NpcData.get_data(npc_id)
	var hd: Variant = d.get("home_dir", Vector3.UP)
	var v: Vector3 = hd if hd is Vector3 else Vector3.UP
	v = v.normalized()
	var building := str(d.get("building", ""))
	if building != "" and planet.has_method("building_dir"):
		var bd: Vector3 = planet.building_dir(building)
		if bd != Vector3.ZERO:
			var spawn := planet.data.spawn_dir.normalized() if planet.data != null else bd
			v = planet.step_dir(bd, spawn, float(d.get("home_offset_m", 3.0)))
			var side := float(d.get("home_side_m", 0.0))
			if absf(side) > 0.01:
				var xf := planet.surface_transform(v, spawn - v * spawn.dot(v))
				v = (v + xf.basis.x * (side / planet.radius)).normalized()
	return v


func _pick_wander_target() -> Vector3:
	var from_dir := current_dir()
	var xf := planet.surface_transform(home_dir)
	for attempt in 24:
		var ang := _rng.randf_range(0.0, TAU)
		var dist := _rng.randf_range(1.4, maxf(wander_radius_m, 1.6))
		var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
		var d := (home_dir + tangent * (dist / planet.radius)).normalized()
		if _spot_blocked(d):
			continue
		if _path_blocked(from_dir, d):
			continue
		return d
	return home_dir


## Samples along the great circle so an NPC never sets off straight across a river or a building.
func _path_blocked(from_dir: Vector3, to_dir: Vector3) -> bool:
	for i in PATH_SAMPLES:
		var t := float(i + 1) / float(PATH_SAMPLES + 1)
		if _spot_blocked(from_dir.slerp(to_dir, t).normalized()):
			return true
	return false


func _spot_blocked(d: Vector3) -> bool:
	if planet.is_underwater(d):
		return true
	var wr := planet.water_radius()
	if wr > 0.0 and planet.height_at(d) < wr + 0.25:
		return true
	if planet.nearest_prop_distance(d) < AVOID_PROP_M:
		return true
	for r: Vector3 in planet.get_reserved_dirs():
		if planet.surface_distance(r, home_dir) < OWN_ZONE_M:
			continue                                  # that reserved circle is this NPC's own spot
		if planet.surface_distance(d, r) < AVOID_RESERVED_M:
			return true
	return false


func _surface_for_biome() -> String:
	if planet == null or planet.data == null:
		return "grass"
	match planet.data.biome:
		"chrome":
			return "metal"
		# AudioManager.FOOTSTEP_SURFACES is only ["grass", "stone", "metal"] and anything else is
		# silently coerced to grass, so there is no "sand" set to reach for: Fen's salt crust and
		# Grig's cut chalk both take stone, which is the closer of the three.
		"plaza", "flats", "chalk":
			return "stone"
		_:
			return "grass"


func _on_footstep(_foot: int) -> void:
	if not is_on_floor():
		return
	if AudioManager.has_method("play_footstep"):
		AudioManager.play_footstep(_footstep_surface, global_position, -12.0)
	else:
		AudioManager.play_sfx_at("footstep_%s_0" % _footstep_surface, global_position, -12.0)


func _on_emote_finished(_emote_name: String) -> void:
	_emote = ""
	_emote_timer = 0.0


## `Interactable.interacted` is declared with a loose `Node3D` (src/core/interactable.gd:7), while the
## ARCHITECTURE §6 contract types `start_conversation(player: Player)`. Narrow it here.
func _on_interacted(player: Node3D) -> void:
	var p := player as Player
	if p == null:
		push_warning("NPC %s: interacted by a non-Player node (%s)" % [npc_id, player])
		return
	start_conversation(p)


## Cached so the wander/idle/talk ticks stop running a group query every physics frame.
func _player() -> Node3D:
	if _player_cache != null and is_instance_valid(_player_cache):
		return _player_cache
	_player_cache = get_tree().get_first_node_in_group("player") as Node3D
	return _player_cache


## Cached so `_refresh_marker` stops walking the scene tree five times a second per NPC.
func _favor_system() -> FavorSystem:
	if _favors != null and is_instance_valid(_favors):
		return _favors
	_favors = FavorSystem.get_or_create()
	return _favors


# ============================================================================= "!" marker
## A flat "!" that always faces the camera. The first pass spun it and left only a 1 cm gap between
## the stem and the dot, which bloom closed into one glowing bar — a lollipop. It is now a plain
## unlit-ish toon yellow with a dark outline (no emission to bloom), a 6.3 cm gap, and it is
## billboarded around the NPC's up axis so it never presents edge-on on the curved planet.
func _build_marker() -> void:
	_marker = Node3D.new()
	_marker.name = "FavorMarker"
	_marker.visible = false
	var mat := MaterialLib.toon(Color("#ffcc33"), {"shade": 0.14, "rim": 0.0, "spec": 0.0})
	var outline := MaterialLib.toon(Color("#6b5232"), {"shade": 0.05, "rim": 0.0, "spec": 0.0})
	var parts: Array = [
		["Stem", Vector3(0.085, 0.170, 0.060), 0.030, MARKER_STEM_Y],
		["Dot", Vector3(0.085, 0.085, 0.060), 0.030, MARKER_DOT_Y],
	]
	for part: Array in parts:
		var n: String = part[0]
		var size3: Vector3 = part[1]
		var r: float = part[2]
		var y: float = part[3]
		var back := MeshInstance3D.new()
		back.name = n + "Outline"
		back.mesh = ChibiModel.rounded_box(size3 + Vector3(0.026, 0.026, 0.0), r + 0.010, 12)
		back.material_override = outline
		back.position = Vector3(0.0, y, -0.012)   # the billboard turns +Z to the camera, so this is BEHIND
		back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_marker.add_child(back)
		var mi := MeshInstance3D.new()
		mi.name = n
		mi.mesh = ChibiModel.rounded_box(size3, r, 12)
		mi.material_override = mat
		mi.position = Vector3(0.0, y, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_marker.add_child(mi)
	_marker.scale = Vector3.ONE * _body_scale
	_marker.position = Vector3(0.0, _marker_h * _body_scale, 0.0)
	add_child(_marker)


func _update_marker(delta: float) -> void:
	if _marker == null:
		return
	_marker_timer -= delta
	if _marker_timer <= 0.0:
		_marker_timer = MARKER_POLL
		_refresh_marker()
	if not _marker.visible:
		return
	_marker_t += delta
	_marker.position.y = (_marker_h + sin(TAU * _marker_t * 1.4) * 0.06) * _body_scale
	_face_marker_to_camera()


## Yaw-only billboard around the NPC's own up axis: the flat "!" always faces the camera, and the
## planet's curvature can never tilt it edge-on.
func _face_marker_to_camera() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var cam := vp.get_camera_3d()
	if cam == null:
		return
	var local := global_transform.basis.inverse() * (cam.global_position - _marker.global_position)
	if absf(local.x) < 0.0001 and absf(local.z) < 0.0001:
		return
	_marker.rotation.y = atan2(local.x, local.z)


## Shows the "!" when this neighbour has a favour to offer, one ready to hand in, or a gift to receive.
func _refresh_marker() -> void:
	if _marker == null:
		return
	var favors := _favor_system()
	if favors == null or _talking:
		_marker.visible = false
		return
	_marker.visible = favors.has_marker(npc_id)
