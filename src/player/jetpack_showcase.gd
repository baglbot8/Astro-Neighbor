extends Node3D
## showcase/player_jetpack.tscn — the jetpack boost (docs/STYLE_GUIDE.md R2.8) shown doing the thing
## the user asked for: *"may also help with hopping over tall decor or something"*.
##
## A 16 m planet with the player, the real gameplay camera rig, and a row of the THREE TALLEST
## decorations (beacon_tower 2.62 m, antenna_tree 2.62 m, dome_tent 1.76 m) laid out along the flight
## path, each with a height post beside it so a still frame shows how much clearance there was.
##
## It uses the REAL src/world/environment.tscn (docs/AGENT_WORKFLOW.md: a showcase whose lighting
## differs from the game is worse than no showcase) and the REAL player scene, so the numbers it
## prints are the numbers the game has.
##
## Drive it with tests/director/player_jetpack.json. Every 0.1 s of flight it prints one TELEMETRY
## line (height above ground, horizontal speed, fuel, thrust, state) and at the end a FLIGHT SUMMARY
## with peak height, mean cruise speed, air time and clearance over each prop — which is how the
## constants in player.gd were tuned, and the evidence that the boost clears the tall props.
##
## Flags (after "--"): --chase for a wider rear camera that frames the whole exhaust plume,
## --flat-env for the standalone sky, --quiet to suppress the per-tick telemetry.

## Distance out from the spawn along the flight path, in metres of arc.
const PROP_ARC := [6.8, 10.4, 14.0]
const PROP_IDS := ["beacon_tower", "antenna_tree", "dome_tent"]
## Visual top of each prop (metres above its own base), measured off src/decorations/items/*.gd.
const PROP_TOPS := [2.62, 2.62, 1.76]
const TELEMETRY_HZ := 10.0
## --chase camera: metres behind and metres above the astronaut (the gameplay rig is CameraRig.DIST_DEFAULT / PITCH_DEFAULT_DEG; 8.6 m / 34 deg on mobile).
const SIDE_CAM_DIST := 9.5
const SIDE_CAM_LIFT := 1.4

var planet: Planet
var player: Player
var camera_rig: CameraRig
var _props: Array[Node3D] = []
var _quiet := false
var _t := 0.0
var _tick := 0.0
var _peak_h := 0.0
var _air_time := 0.0
var _cruise_sum := 0.0
var _cruise_n := 0
var _clearance: PackedFloat32Array = PackedFloat32Array()
var _was_boosting := false
var _burn_start := -1.0
var _burn_total := 0.0
var _side_cam: Camera3D


func _ready() -> void:
	name = "World"
	var args := OS.get_cmdline_user_args()
	_quiet = args.has("--quiet")
	_clearance.resize(PROP_IDS.size())
	for i in PROP_IDS.size():
		_clearance[i] = -99.0

	var data := PlanetData.new()
	data.id = "showcase"
	data.radius = 16.0
	if ResourceLoader.exists("res://src/planet/planet.tscn"):
		planet = load("res://src/planet/planet.tscn").instantiate() as Planet
	else:
		planet = Planet.new()
	planet.name = "Planet"
	planet.data = data
	add_child(planet)
	if not planet.is_in_group("planet"):
		planet.add_to_group("planet")

	if args.has("--flat-env") or not ResourceLoader.exists("res://src/world/environment.tscn"):
		PlayerShowcaseEnv.add_to(self)
	else:
		var env: Node = load("res://src/world/environment.tscn").instantiate()
		env.name = "Environment"
		add_child(env)

	player = load("res://src/player/player.tscn").instantiate() as Player
	player.name = "Player"
	add_child(player)
	player.planet = planet
	player.place_on_planet(Vector3.UP, Vector3.FORWARD)
	EventBus.player_spawned.emit(player)

	camera_rig = load("res://src/player/camera_rig.tscn").instantiate() as CameraRig
	camera_rig.name = "CameraRig"
	add_child(camera_rig)

	_place_props()
	# --chase is a wider, further-back rear view than the gameplay rig, so the whole exhaust plume
	# is in frame instead of being cropped at the bottom edge.
	#
	# It is deliberately NOT a profile camera. Player movement is camera-relative
	# (`Player._camera_planar_forward`), so a camera parked at 90 degrees to the flight path turns
	# "move_forward" into "fly sideways" and the astronaut spirals off the prop line. Keeping the
	# chase camera behind the astronaut keeps the flight straight AND matches the angle the game is
	# actually played from; the profile read comes from the turntable showcase's --state=boost.
	if args.has("--chase") or args.has("--side"):
		_side_cam = Camera3D.new()
		_side_cam.name = "SideCam"
		_side_cam.fov = 46.0
		_side_cam.current = true
		add_child(_side_cam)
		_update_side_cam()


## The three tallest decorations in a line straight ahead of the spawn, each with a slim marker post
## exactly as tall as the prop so a capture frame shows the clearance without measuring pixels.
func _place_props() -> void:
	for i in PROP_IDS.size():
		var path := "res://src/decorations/items/%s.tscn" % PROP_IDS[i]
		var holder := Node3D.new()
		holder.name = "Prop_%s" % PROP_IDS[i]
		# The player spawns at +Y facing -Z, so the flight path runs along -Z: rotate about +X.
		var ang: float = float(PROP_ARC[i]) / planet.radius
		var dir := Vector3(0.0, cos(ang), -sin(ang)).normalized()
		holder.transform = planet.surface_transform(dir, Vector3.FORWARD)
		add_child(holder)
		if ResourceLoader.exists(path):
			var deco: Node = load(path).instantiate()
			holder.add_child(deco)
		else:
			push_warning("JetpackShowcase: missing %s" % path)
		_props.append(holder)
		# Height post: a thin pole exactly PROP_TOPS[i] tall with a bright cap, 1 m to the side.
		var post := MeshInstance3D.new()
		post.name = "HeightPost"
		var cm := CylinderMesh.new()
		cm.top_radius = 0.035
		cm.bottom_radius = 0.035
		cm.height = float(PROP_TOPS[i])
		cm.radial_segments = 8
		post.mesh = cm
		post.position = Vector3(1.15, float(PROP_TOPS[i]) * 0.5, 0.0)
		post.material_override = MaterialLib.toon(Color("#e8d9a8"), {"spec": 0.05})
		holder.add_child(post)
		var cap := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.075
		sm.height = 0.15
		sm.radial_segments = 10
		sm.rings = 5
		cap.mesh = sm
		cap.position = Vector3(1.15, float(PROP_TOPS[i]), 0.0)
		cap.material_override = MaterialLib.glow(Color("#ff9f43"), 1.4)
		holder.add_child(cap)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	var h := player.get_ground_height()
	var speed := player.get_tangent_velocity().length()
	var boosting := player.is_boosting()

	if boosting and not _was_boosting:
		_burn_start = _t
	elif _was_boosting and not boosting and _burn_start >= 0.0:
		_burn_total += _t - _burn_start
		_burn_start = -1.0
	_was_boosting = boosting

	if not player.is_on_floor():
		_air_time += delta
		_peak_h = maxf(_peak_h, h)
	if boosting and h > 0.6:
		_cruise_sum += speed
		_cruise_n += 1

	# Clearance over each prop: the smallest gap between the astronaut's BOOTS and the prop's top
	# recorded while passing within 1.2 m of it horizontally.
	for i in _props.size():
		var to := player.global_position - _props[i].global_position
		var n := planet.up_at(_props[i].global_position)
		var lateral := (to - n * to.dot(n)).length()
		if lateral < 1.2:
			var gap := to.dot(n) - float(PROP_TOPS[i])
			if _clearance[i] < -50.0 or gap < _clearance[i]:
				_clearance[i] = gap

	_update_side_cam()
	_tick += delta
	if not _quiet and _tick >= 1.0 / TELEMETRY_HZ:
		_tick = 0.0
		print("TELEMETRY t=%5.2f h=%5.2f spd=%5.2f fuel=%4.2f thrust=%4.2f floor=%s state=%s"
				% [_t, h, speed, player.get_boost_fuel(), player.get_model().get_boost_thrust(),
				"1" if player.is_on_floor() else "0", player.get_model().get_state()])


func _exit_tree() -> void:
	if _burn_start >= 0.0:
		_burn_total += _t - _burn_start
	var cruise := (_cruise_sum / float(_cruise_n)) if _cruise_n > 0 else 0.0
	print("FLIGHT SUMMARY peak_height=%.2f m  air_time=%.2f s  burn=%.2f s  cruise_speed=%.2f m/s  fuel_left=%.2f"
			% [_peak_h, _air_time, _burn_total, cruise, player.get_boost_fuel() if player else 0.0])
	for i in PROP_IDS.size():
		if _clearance[i] < -50.0:
			print("FLIGHT   %-14s NOT PASSED" % PROP_IDS[i])
		else:
			print("FLIGHT   %-14s top=%.2f m  boot clearance=%+.2f m  %s"
					% [PROP_IDS[i], float(PROP_TOPS[i]), _clearance[i], "CLEARED" if _clearance[i] > 0.0 else "HIT"])


## Follows the astronaut from further back and lower than the gameplay rig, so the whole exhaust
## plume is in frame. See the note in `_ready` for why this is not a profile camera.
func _update_side_cam() -> void:
	if _side_cam == null or player == null:
		return
	var n := planet.up_at(player.global_position)
	var back := player.global_transform.basis.z
	back = (back - n * back.dot(n)).normalized()
	var focus := player.global_position + n * 0.55
	_side_cam.look_at_from_position(focus + back * SIDE_CAM_DIST + n * SIDE_CAM_LIFT, focus, n)
