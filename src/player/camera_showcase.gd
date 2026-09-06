extends Node3D
## showcase/player_camera.tscn — the R2.10 camera framing, side by side with the things it has to
## keep legible.
##
## WHY THIS SCENE EXISTS. R2.10 moved the follow camera back ("*We should zoom out the camera a bit
## more but not so much that we cant appreciate the decor and details*") and gave mobile its own,
## further set of numbers. Both halves of that sentence are judged by LOOKING, and both need the same
## frame to be judged in: pull-back is only worth having if a decoration is still a thing with a
## shape at the new distance. So this scene stages six real decorations and two tall poles around the
## astronaut on a real planet under the real sky, then walks the camera through every framing the
## game can be in — desktop and mobile, default and both zoom stops — with the numbers on screen.
##
## The two poles are not decoration. They are the OCCLUSION case from the mobile decision mockup
## (~/.astro_captures/cmp/mobile_orientation.png), where a lamp post and a bunting pole covered the
## astronaut: one stands directly behind the player where the camera must look through it, the other
## just off the centre line, which is the near miss the old thin-ray probe used to sail past. Run with
## `--fade-debug` and the fade set prints as it engages.
##
## LIGHTING AND GEOMETRY are the real ones: src/planet/planet.tscn and src/world/environment.tscn,
## same as the game (docs/AGENT_WORKFLOW.md — "a showcase whose lighting differs from the game is
## worse than no showcase"). Root is named "World" so Director paths match the real game.
##
## Flags (after "--"):
##   --preset=<name>   pin one framing: desktop / desktop_in / desktop_out / mobile / mobile_in /
##                     mobile_out. Otherwise it cycles every PRESET_SECONDS.
##   --bare            no decorations and no poles (an empty-framing read)
##   --fade-debug      CameraRig prints the near-geometry fade set (see camera_rig.gd)

const PLANET_RADIUS := 16.0
const PRESET_SECONDS := 2.6

## The six decorations, at (right, forward) metres from the spawn on the tangent plane. Deliberately
## a spread of sizes: the legibility limit is set by the SMALL ones (a moon lamp's crescent, a robot
## dog's face), not by a fountain.
const DECOS := [
	{"id": "deco_moon_lamp", "right": 2.1, "fwd": 0.2},
	{"id": "deco_picnic_table", "right": -2.4, "fwd": 0.3},
	{"id": "deco_gear_fountain", "right": 3.7, "fwd": 2.6},
	{"id": "deco_alien_plant_pot", "right": 0.0, "fwd": 2.5},
	{"id": "deco_robot_dog", "right": 1.4, "fwd": 1.6},
	{"id": "deco_star_flag", "right": -1.4, "fwd": 1.6},
]
## The occlusion case. Negative `fwd` is BEHIND the astronaut, i.e. between them and the camera.
## Both poles are offset sideways by LESS than the astronaut's half-width (helmet 0.37 m): that is
## the near miss the old thin centre-line rays used to sail past while the pole covered half the
## visor on screen - see SIGHT_RADIUS in camera_rig.gd, and the before/after in the report.
const POLES := [
	{"id": "deco_string_lights", "right": 0.30, "fwd": -2.1},
	{"id": "deco_beacon_tower", "right": -0.30, "fwd": -3.6},
]

## Every framing the game can put the player in. `mobile` flips Platform, so the rig is exercised
## through the real `Platform.mode_changed` path rather than by setting numbers behind its back.
const PRESETS := [
	{"name": "desktop", "mobile": false, "zoom": "default"},
	{"name": "desktop_in", "mobile": false, "zoom": "min"},
	{"name": "desktop_out", "mobile": false, "zoom": "max"},
	{"name": "mobile", "mobile": true, "zoom": "default"},
	{"name": "mobile_in", "mobile": true, "zoom": "min"},
	{"name": "mobile_out", "mobile": true, "zoom": "max"},
]

var planet: Planet
var player: Player
var camera_rig: CameraRig

var _label: Label
var _preset := 0
var _timer := 0.0
var _frozen := false


func _ready() -> void:
	name = "World"
	var args := OS.get_cmdline_user_args()
	var data := PlanetData.new()
	data.id = "showcase"
	data.radius = PLANET_RADIUS
	planet = load("res://src/planet/planet.tscn").instantiate() as Planet
	planet.name = "Planet"
	planet.data = data
	add_child(planet)
	if not planet.is_in_group("planet"):
		planet.add_to_group("planet")

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

	if not args.has("--bare"):
		var props := Node3D.new()
		props.name = "Props"
		add_child(props)
		for d: Dictionary in DECOS:
			_place(props, str(d["id"]), float(d["right"]), float(d["fwd"]))
		for p: Dictionary in POLES:
			_place(props, str(p["id"]), float(p["right"]), float(p["fwd"]))

	_build_label()
	for a: String in args:
		if a.begins_with("--preset="):
			var want := a.substr(9)
			for i in PRESETS.size():
				if str(PRESETS[i]["name"]) == want:
					_preset = i
			_frozen = true
	_apply_preset()


## Drops one catalog decoration on the surface at a tangent offset from the spawn, using the same
## surface fit DecorationManager uses (radial position, ground-normal tilt) but WITHOUT going through
## the manager: a showcase must not write into the player's saved decorations.
func _place(parent: Node3D, item_id: String, right_m: float, fwd_m: float) -> void:
	var def := Catalog.get_item(item_id)
	var path := str(def.get("scene", ""))
	if path == "" or not ResourceLoader.exists(path):
		push_warning("CameraShowcase: no scene for '%s'" % item_id)
		return
	# The spawn is at +Y, the astronaut faces -Z (place_on_planet above), so "forward" is -Z and
	# "right" is +X. Offsets are metres of arc, converted to an angle on the sphere.
	var dir := (Vector3.UP + Vector3(right_m, 0.0, -fwd_m) / PLANET_RADIUS).normalized()
	var xf := planet.surface_transform(dir, Vector3.FORWARD)
	var n := planet.ground_normal(dir, 0.6)
	var axis := xf.basis.y.cross(n)
	if axis.length_squared() > 0.000001:
		var ang := acos(clampf(xf.basis.y.dot(n), -1.0, 1.0))
		xf.basis = Basis(axis.normalized(), minf(ang, deg_to_rad(22.0))) * xf.basis
	var node: Node3D = load(path).instantiate()
	node.name = item_id
	parent.add_child(node)
	node.global_transform = Transform3D(xf.basis.orthonormalized(), xf.origin)


func _build_label() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Overlay"
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color("#3d2f22"))
	_label.add_theme_color_override("font_outline_color", Color("#fdf6e3"))
	_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_label)


func _process(delta: float) -> void:
	if _frozen:
		return
	_timer += delta
	if _timer >= PRESET_SECONDS:
		_timer = 0.0
		_preset = (_preset + 1) % PRESETS.size()
		_apply_preset()


func _apply_preset() -> void:
	var p: Dictionary = PRESETS[_preset]
	Platform.set_mobile(bool(p["mobile"]), false)
	var r := camera_rig.get_zoom_range()
	match str(p["zoom"]):
		"min":
			camera_rig.set_zoom_distance(r.x)
		"max":
			camera_rig.set_zoom_distance(r.y)
		_:
			camera_rig.set_zoom_distance(camera_rig.dist_default())
	_update_label()


func _update_label() -> void:
	if _label == null:
		return
	var p: Dictionary = PRESETS[_preset]
	var r := camera_rig.get_zoom_range()
	_label.text = "%s   %.1f m  ·  %.0f deg  ·  fov 45\nzoom range %.1f - %.1f m" % [
		str(p["name"]).to_upper().replace("_", " "),
		camera_rig.get_zoom_distance(), camera_rig.pitch_default_deg(), r.x, r.y]
