extends Node3D
## showcase/astronaut_turntable.tscn — the astronaut on a turntable cycling through every animation
## state (label shows the state), with hat / backpack / colour variants lined up behind.
##
## LIGHTING: this scene instantiates the REAL src/world/environment.tscn, not a showcase sky.
## docs/AGENT_WORKFLOW.md: "A showcase whose lighting differs from the game is worse than no
## showcase — you will tune your art against a lie." The old built-in sky lit the character in a
## bright white void, which is precisely how a near-white suit gets tuned into a marshmallow.
## Pass --flat-env to fall back to PlayerShowcaseEnv (only useful for isolating a shading bug).
##
## Flags (after "--"):
##   --closeup           head-to-boots portrait framing
##   --convo             CONVERSATION range: exactly 2.0 m, 10 deg pitch (where R2.9 detail is judged)
##   --dist=<m>          the --convo framing at an arbitrary distance (for an R2.9 fade ramp)
##   --gameplay          the REAL gameplay camera (CameraRig.DIST_DEFAULT / PITCH_DEFAULT_DEG, FOV 45), character facing away
##   --back / --three-quarter    fixed viewing angle instead of the turntable's front
##   --freeze            stop the turntable
##   --state=<name>      pin one of the 14 states
##   --solo              hide the four variants (a clean silhouette read)
##   --seed=N            pin the global RNG (idle phase) so two captures can be diffed pixel to pixel
##   --no-surface        R2.9 CONTROL: the same frame with all surface detail zeroed (A/B baseline)
##   --tris              print the per-mesh triangle budget of one astronaut

## The 15 AstronautModel states. "boost" is the jetpack cruise (docs/STYLE_GUIDE.md R2.8) and sits
## next to "jump" and "fall" here on purpose: the three airborne silhouettes have to be tellable
## apart at a glance, and this showcase is where that is checked.
const STATES := ["idle", "walk", "run", "jump", "boost", "fall", "land", "talk", "wave", "happy", "think", "dance", "surprised", "carry_idle", "carry_walk"]
const STATE_SECONDS := 2.0
const TURN_SPEED := 0.45
## The gameplay camera. REFERENCED, not copied: R2.10 moved the desktop default from 6.5 m to 7.4 m,
## and a showcase holding the old number would judge the astronaut at a distance the game no longer
## uses - which is the "showcase whose lighting differs from the game" trap in one axis over.
const GAMEPLAY_DIST := CameraRig.DIST_DEFAULT
const GAMEPLAY_PITCH_DEG := CameraRig.PITCH_DEFAULT_DEG
## Conversation range (--convo): the distance the player stands at to talk, shop or emote, and the
## range R2.9's surface detail is judged at. Kept as a const so a before/after pair is framed
## identically down to the pixel.
const CONVO_DIST := 2.0
const CONVO_PITCH_DEG := 10.0
var TURN_SPEED_OVERRIDE: float = -1.0

const VARIANTS := [
	{"label": "Cap + Rocket pack", "style": {"hat_id": "hat_cap", "backpack_id": "pack_rocket", "accent_color": "#4c6fff"}},
	{"label": "Antenna + Jet pack", "style": {"hat_id": "hat_antenna", "backpack_id": "pack_jet", "suit_color": "#ffd1dc", "accent_color": "#7a3fe0", "visor_tint": "#b28dff"}},
	{"label": "Crown + Basic pack", "style": {"hat_id": "hat_crown", "backpack_id": "pack_basic", "suit_color": "#b9f2ff", "accent_color": "#ffb347", "trouser_color": "#3a5f8a"}},
	{"label": "Dark suit, pink visor", "style": {"hat_id": "", "backpack_id": "pack_basic", "suit_color": "#2b2f5e", "accent_color": "#ffcc33", "visor_tint": "#ff9ac9", "trouser_color": "#22254a", "panel_color": "#4a5090"}},
]

var _main: AstronautModel
var _main_pivot: Node3D
var _label: Label3D
var _variants: Array[AstronautModel] = []
var _state_index := 0
var _state_timer := 0.0
## >= 0 pins the showcase to one state (--state=<name>) instead of cycling every STATE_SECONDS.
var _pinned := -1
var _carry_mesh: Mesh


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	# `--seed=N` pins the global RNG before anything is built. AstronautModel seeds its idle clock
	# and its look-around timer with randf_range, so two otherwise identical captures land on
	# different animation phases and cannot be diffed pixel to pixel. With a seed (and capture.sh's
	# --fixed-fps) frame N is byte-identical between runs, which is what makes an A/B against
	# `--no-surface` a measurement instead of an eyeball.
	for a: String in args:
		if a.begins_with("--seed="):
			seed(a.substr(7).to_int())
	_build_env(args.has("--flat-env"))
	_carry_mesh = AstronautModel.make_item_placeholder(Color("#ffe27a"))

	var floor_mi := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 7.0
	floor_mesh.bottom_radius = 7.4
	floor_mesh.height = 0.3
	floor_mesh.radial_segments = 64
	floor_mi.mesh = floor_mesh
	# Chosen by MEASURING the render, not by copying the style guide swatch. The real game's grass
	# renders as #4a9d5a (S 0.53 V 0.62) at noon; MaterialLib.toon pushes chroma hard, so feeding it
	# the nominal #5cc44a produced a stage measuring S 0.71 V 0.78 - brighter and louder than the
	# game, which is the direction that makes a builder tune the character too dark. #6fa860 renders
	# as S 0.65 V 0.67, matching the game on value and much closer on saturation.
	# (Feeding it #4a9d5a directly renders NEON, S 0.94 - the toon ramp is not linear in albedo, so
	# this number has to be checked with tools/palette.py rather than reasoned about.)
	floor_mi.material_override = MaterialLib.toon(Color("#6fa860"), {"shade": 0.5, "spec": 0.05})
	floor_mi.position.y = -0.27
	add_child(floor_mi)

	_main_pivot = Node3D.new()
	_main_pivot.position = Vector3(0.0, 0.0, 0.9)
	_main_pivot.rotation.y = PI
	add_child(_main_pivot)
	_add_disc(_main_pivot, 0.8)
	_main = AstronautModel.new()
	_main.follow_game_state = true
	_main_pivot.add_child(_main)
	_label = _make_label("idle", Vector3(0.0, 1.78, 0.9))
	add_child(_label)

	var xs := [-3.0, -1.0, 1.0, 3.0]
	for i in (0 if args.has("--solo") else VARIANTS.size()):
		var v: Dictionary = VARIANTS[i]
		var holder := Node3D.new()
		holder.position = Vector3(xs[i], 0.0, -1.3)
		holder.rotation.y = PI
		add_child(holder)
		_add_disc(holder, 0.75)
		var m := AstronautModel.new()
		m.follow_game_state = false
		m.style_override = v["style"]
		holder.add_child(m)
		_variants.append(m)
		add_child(_make_label(str(v["label"]), holder.position + Vector3(0.0, 2.05, 0.0), 30))

	var cam := Camera3D.new()
	cam.fov = 45.0
	cam.current = true
	add_child(cam)
	if args.has("--gameplay"):
		# EXACTLY the gameplay camera (GAMEPLAY_DIST out, GAMEPLAY_PITCH_DEG above), aimed at the chest, with the
		# character facing away from it. A critic measured the old walk's on-screen bob at ~1.5 px
		# from here and called it gliding; nothing about this character may be judged anywhere else.
		var pitch := deg_to_rad(GAMEPLAY_PITCH_DEG)
		var pivot := Vector3(0.0, 0.75, 0.9)
		cam.look_at_from_position(pivot + Vector3(0.0, sin(pitch), cos(pitch)) * GAMEPLAY_DIST, pivot, Vector3.UP)
		_main_pivot.rotation.y = 0.0
		TURN_SPEED_OVERRIDE = 0.0
	elif args.has("--convo") or _dist_arg(args) > 0.0:
		# CONVERSATION distance, exactly CONVO_DIST metres from the chest at CONVO_PITCH_DEG. This
		# is the range R2.9's surface detail has to earn its keep at: talking to a neighbour, the
		# clothes shop mirror, an emote. It is a measured distance rather than a hand-placed camera
		# so a before/after pair is framed identically and the weave can be compared pixel to pixel.
		var cpitch := deg_to_rad(CONVO_PITCH_DEG)
		var cpivot := Vector3(0.0, 0.78, 0.9)
		var cdist := _dist_arg(args)
		if cdist <= 0.0:
			cdist = CONVO_DIST
		cam.look_at_from_position(cpivot + Vector3(0.0, sin(cpitch), cos(cpitch)) * cdist, cpivot, Vector3.UP)
		_main_pivot.rotation.y = 0.0
		TURN_SPEED_OVERRIDE = 0.0
	elif args.has("--closeup"):
		# whole plush silhouette, head to boots
		cam.look_at_from_position(Vector3(0.0, 1.05, 3.1), Vector3(0.0, 0.70, 0.9), Vector3.UP)
	elif args.has("--face"):
		# helmet framing, for judging the visor pane and the rim hardware
		cam.look_at_from_position(Vector3(0.0, 1.12, 2.0), Vector3(0.0, 1.02, 0.9), Vector3.UP)
	else:
		cam.look_at_from_position(Vector3(0.0, 2.05, 5.4), Vector3(0.0, 0.72, -0.3), Vector3.UP)
	# Fixed viewing angles for the comparison sheets: front (default), 3/4 and back.
	if args.has("--back"):
		_main_pivot.rotation.y = 0.0
	elif args.has("--three-quarter"):
		_main_pivot.rotation.y = PI - 0.72
	if args.has("--freeze"):
		TURN_SPEED_OVERRIDE = 0.0
	# --yaw=<deg> is an arbitrary fixed viewing angle (0 = back of the head, 180 = facing camera),
	# for judging a pose whose silhouette only reads from the side (the run, above all).
	for a: String in args:
		if a.begins_with("--yaw="):
			_main_pivot.rotation.y = deg_to_rad(a.substr(6).to_float())
			TURN_SPEED_OVERRIDE = 0.0
	# --state=<name> pins one animation state instead of cycling, so a single snap can frame any of
	# the 14 states (the carry poses are 24 s into the cycle otherwise).
	for a: String in args:
		if a.begins_with("--state="):
			var want := a.substr(8)
			if STATES.has(want):
				_pinned = STATES.find(want)
	_apply_state(_pinned if _pinned >= 0 else 0)
	if args.has("--no-surface"):
		_strip_surface_detail(_main)
	if args.has("--tris"):
		_dump_tris()


## `--no-surface`: the R2.9 CONTROL. Duplicates every material on the main astronaut and zeroes its
## `surface_kind` / `seam_strength`, giving the pre-R2.9 character under otherwise identical
## lighting, pose and framing. That is what makes the distance ramp a measurement rather than an
## assertion: capture the same frame with and without, and the difference IS the surface detail, so
## "the fine pattern fades with distance instead of moireing" can be shown as a number per distance.
func _strip_surface_detail(model: Node) -> void:
	for mi: MeshInstance3D in _collect_meshes(model):
		if mi.material_override is ShaderMaterial:
			mi.material_override = _flatten(mi.material_override as ShaderMaterial)
		for s in mi.get_surface_override_material_count():
			var sm := mi.get_surface_override_material(s) as ShaderMaterial
			if sm:
				mi.set_surface_override_material(s, _flatten(sm))


static func _flatten(src: ShaderMaterial) -> ShaderMaterial:
	var m := src.duplicate() as ShaderMaterial
	m.set_shader_parameter("surface_kind", 0)
	m.set_shader_parameter("surface_strength", 0.0)
	m.set_shader_parameter("sheen_strength", 0.0)
	m.set_shader_parameter("seam_strength", 0.0)
	return m


## `--dist=<metres>`: the --convo framing at an arbitrary distance, so a distance RAMP can be
## captured with everything else held identical. That is how R2.9's "the fine pattern must fade with
## distance rather than moire" is proved — one sheet at 2 / 3 / 4 / 5 / 6.5 m. Returns 0 if absent.
static func _dist_arg(args: PackedStringArray) -> float:
	for a: String in args:
		if a.begins_with("--dist="):
			return maxf(a.substr(7).to_float(), 0.0)
	return 0.0


## Instantiates the real game environment so the suit is tuned under the light it will ship in.
## The environment needs a PlanetData; `data_override` is the supported way to give it one without
## a Planet in the scene (src/world/environment.gd `_ready`).
func _build_env(flat: bool) -> void:
	if flat or not ResourceLoader.exists("res://src/world/environment.tscn"):
		PlayerShowcaseEnv.add_to(self)
		return
	var env: Node = load("res://src/world/environment.tscn").instantiate()
	env.name = "Environment"
	var data := PlanetData.new()
	data.id = "home"
	data.radius = 16.0
	env.set("data_override", data)
	# Frozen clock: the showcase must render the same hour every run, or two captures of the same
	# state are not comparable. --time=<hour> (Director) still sets which hour that is.
	env.set("time_scale", 0.0)
	add_child(env)


## `--tris` prints the per-mesh triangle budget of ONE astronaut (docs/OPEN_ISSUES.md issue 4:
## Stella inherits this count and the character budget is 6,000).
func _dump_tris() -> void:
	var rows: Array[Array] = []
	var total := 0
	for mi: MeshInstance3D in _collect_meshes(_main):
		var n := mi.mesh.get_faces().size() / 3
		total += n
		rows.append([n, str(_main.get_path_to(mi))])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	print("TRIS total=%d meshes=%d" % [total, rows.size()])
	for r: Array in rows:
		print("TRIS   %6d  %s" % [r[0], r[1]])


func _collect_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out.append(n as MeshInstance3D)
	for c: Node in n.get_children():
		out.append_array(_collect_meshes(c))
	return out


func _add_disc(parent: Node3D, r: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r + 0.06
	cm.height = 0.12
	cm.radial_segments = 40
	mi.mesh = cm
	mi.material_override = MaterialLib.toon(Color("#6fa860"), {"spec": 0.05})
	mi.position.y = -0.06
	parent.add_child(mi)


func _make_label(text: String, pos: Vector3, size: int = 44) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = int(size * 0.28)
	l.pixel_size = 0.0055
	l.modulate = Color("#fff8e1")
	l.outline_modulate = Color("#6b5232")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	return l


func _apply_state(i: int) -> void:
	_state_index = i % STATES.size()
	var st: String = STATES[_state_index]
	_label.text = st
	var carry := st.begins_with("carry")
	_main.set_carry_item(_carry_mesh if carry else null, Vector3(0.0, AstronautModel.PLACEHOLDER_ITEM_HEIGHT * 0.5, 0.0))
	_main.set_state(st)
	for k in _variants.size():
		var vs: String = STATES[(_state_index + 3 * (k + 1)) % STATES.size()]
		var vm := _variants[k]
		vm.set_carry_item(_carry_mesh if vs.begins_with("carry") else null, Vector3(0.0, AstronautModel.PLACEHOLDER_ITEM_HEIGHT * 0.5, 0.0))
		vm.set_state(vs)


static func _speed_for(st: String) -> float:
	match st:
		"walk", "carry_walk":
			return 1.0
		"run":
			return 1.67
		_:
			return 0.0


func _process(delta: float) -> void:
	_state_timer += delta
	if _pinned < 0 and _state_timer >= STATE_SECONDS:
		_state_timer -= STATE_SECONDS
		_apply_state(_state_index + 1)
	_main_pivot.rotation.y += (TURN_SPEED if TURN_SPEED_OVERRIDE < 0.0 else TURN_SPEED_OVERRIDE) * delta
	_main.tick(delta, _speed_for(_main.get_state()))
	for vm in _variants:
		vm.tick(delta, _speed_for(vm.get_state()))
