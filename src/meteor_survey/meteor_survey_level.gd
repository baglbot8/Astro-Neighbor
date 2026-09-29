class_name MeteorSurveyLevel
extends PlanetSafari
## THE METEOR SURVEY LEVEL (docs/STORY_HOME_SPEC.md 9.2; builder METEOR, 2026-09-28). Made and awaited by
## `MeteorSurvey.run` (meteor_survey.gd); never started any other way.
##
## It IS a planet safari underneath - it extends PlanetSafari for the first-person walk, the camera-up
## mode, the zoom, the focus, the shutter, SafariLayer's buttons and SafariPhotoScorer's grades, all
## unchanged - but it replaces the safari's life cycle: no day flag, no tips, no review, no pay, no journal
## or scrapbook, no End button. `_ready`, `_process`, `request_end`, `_offer_film_out` and `_restore` are
## overridden; everything else is PlanetSafari's own code.
##
## ------------------------------------------------------------------------------------------ FLOW
##   Fade to black. Behind it: every Node3D child of /root/World except the Player, the CameraRig and the
##   Environment is hidden and its processing disabled (so the hub's colliders leave the physics world);
##   the clock is held at SURVEY_HOUR; the rock (MeteorRock, radius ROCK_RADIUS) is built at the world
##   origin and becomes the player's planet; the player stands at the start in first person. Warm-up
##   (PlanetSafari._warm_up), fade in.
##   AN ATTEMPT: TIME_LIMIT seconds (the clock top right), FILM plates. A photo of an unmarked weak point
##   at Fair or better (SafariScoring's planet grade, grade_idx >= 1) marks it: its plume goes out and a
##   beacon stands on it. A Smudge says the one thing to fix (`_smudge_reason`). A photo of only marked
##   ones gives the plate back. Five marked = done.
##   OUT OF TIME, or OUT OF FILM with cracks left: the retry card (the Professor, one button, "Try
##   again") -> a fresh attempt from the start: all five unmarked, the clock and the film full. As often
##   as it takes; there is no other way out.
##   DONE: the Professor's line, a beat, fade to black, everything put back exactly (`_restore`), fade in,
##   `survey_done`, and the node frees itself.

signal survey_done

const SURVEY_ID := "meteor"
## Spec 9.2: five weak points, film for five plus misses. The clock was two minutes; spec 9.5.2 (the user's play,
## 2026-09-28: "We may need to add on an extra 15 seconds ... just barely made it in time") makes it 2:15.
const TIME_LIMIT := 135.0
const FILM := 12
const CRACK_COUNT := 5
## The rock. A stated pick, measured: at the safari walk (1.5 m/s) the bot's straight-line tour of all
## five takes most of the clock (see the builder report).
const ROCK_RADIUS := 22.0
## Where the weak points are: (degrees round the rock from the start, bearing from the start heading,
## + = right). Spread so no two are in one view and the tour crosses the whole rock.
const CRACK_SPOTS: Array[Vector2] = [Vector2(36, 12), Vector2(72, 100), Vector2(118, 162), Vector2(100, -100),
	Vector2(152, -32)]
## Each weak point as a photo subject: a sphere round the split, and its best size in the frame.
const CRACK_RADIUS := 1.3
const CRACK_BAND := Vector2(0.26, 0.8)
## Fair or better marks it (SafariScoring.GRADES: Smudge 0, Fair 1, Fine 2, Gallery 3).
const MARK_GRADE_IDX := 1
## The clock is held here during the survey (a low warm sun) and put back after.
const SURVEY_HOUR := 16.5
const SHARD_COUNT := 26
## THE LANDMARKS (builder METEOR2, spec 9.5.2): five big, different things (MeteorProps.LM_NAMES) in the gaps
## between the weak points, so a player always knows where they have been. Same (around, bearing) degrees as
## CRACK_SPOTS; picked by a farthest-point search over the rock (each is 52-67 deg of arc, 20-26 m, from every
## weak point, the start and the other landmarks), so none stands in a crack's photo.
const LANDMARK_SPOTS: Array[Vector2] = [Vector2(88, -36), Vector2(104, 36), Vector2(64, -162), Vector2(140, 90),
	Vector2(52, -78)]
## Shards keep this far (m of surface) from a landmark's centre.
const LANDMARK_CLEAR_M := 7.0
## THE LOOKOUTS (builder METEOR3, spec 9.6.4; the user: "looking for the last beacon feels a bit like pick a direction
## and hope you see it ... at least 2 higher up things you can climb on ... the higher up vantage point should let
## you see further for the red lights"). Two lookouts (MeteorVantage), each placed by a search over the rock (the
## builder's report): >= 45 deg (17 m) from every weak point, >= 30 deg from every landmark, and with weak points
## 50-60 deg away that the ground cannot show but the top can. Since builder RISE (2026-09-29; the user on the stair
## towers: "make it more natural and not stairs. Find another way to guide players to it that isnt so obvious")
## each is a low rocky rise of the crust itself - a gentle walkable back up to a crest 3 m over the ground, a crystal
## vein up the back and one small glowing crystal on the crest - at the same spot, crest and height as builder
## LOOKOUT's small rock, so the sight lines are unchanged (ray casts to the glow column, 0-13.8 m over a crack): the
## far rise's crest shows cracks 3, 4, 5 from 1.5, 1.5, 1.25 m up; the near one's crack 2 from 2.0 m and crack 3
## from 2.75 m; from the foot the same cracks show only from 2.25-7.5 m up, or not at all. [around, bearing] as
## CRACK_SPOTS, then the cracks it looks out on (0-based; the walkable back faces the start, inside the widest gap
## between them, `_build_lookouts`).
const VANTAGE_SPOTS: Array = [[Vector2(144, -138), [2, 3, 4]], [Vector2(60, 162), [1, 2]]]
## Shards keep this far (m of surface) from a rise's centre: its walkable back runs out ~8.5 m, and from the crest
## a shard just past its foot stood as a big dark block in the foreground of the look toward crack 5 (builder RISE).
const VANTAGE_CLEAR_M := 10.5
const RETRY_MODAL := "meteor_retry"
const START_LINES := ["Find the five glowing cracks. Snap each one!", "A good photo plants a beacon. Beat the clock!"]
const LINE_FIRST := "Splendid! The ships can see that one."
const LINE_LAST_ONE := "One more! Now where did I put my pencil..."
const LINE_HURRY := "Thirty seconds! You're doing fine."
const LINE_DONE := "All five! The ships will fly to your beacons."
const TIMEOUT_TITLE := "Out of time!"
const TIMEOUT_LINE := "No harm done. The rock's still here. Again!"
const FILMOUT_TITLE := "Out of film!"
const FILMOUT_LINE := "Here's a fresh roll. Let's start again!"
const ALREADY_LINE := "Already marked! Find one that still glows."
## After a failed try (spec 9.6.4: "The professor can give a hint too to climb up on them if you fail once"). Names
## the rises in words (builder RISE: no flags or glowing steps any more; both rises stand by a lava flow).
const LINE_CLIMB_HINT := "Tip: climb a rocky rise by the lava to spot the red glows!"
## THE STEAM HAZE (spec 9.6.6): the Environment's depth fog, steam-coloured and thicker, written every frame after
## environment.gd's own write (this node's process_priority is later) and put back by `_restore`. Clear near the
## eye, ~13% at 7 m (the horizon from a standing eye; the eye is 1.1 m up), ~28% at 15 m, at its thickest past HAZE_END_M; the cracks' light is fog-free and reads through it.
const HAZE_COLOR := Color(0.70, 0.62, 0.64)   # = MeteorSteam.STEAM, so the ground haze meets the sky band
const HAZE_DENSITY := 0.45
const HAZE_BEGIN_M := 1.5
const HAZE_END_M := 24.0
const HAZE_CURVE := 0.9

var cracks: Array = []   # {key, root, plume, beacon, marked, dir}
var landmarks: Array = []   # {name, root, dir, look_y}
var lookouts: Array = []    # {root, dir, sees}
var steam: MeteorSteam
var _fog_env: Environment
var _fog_saved: Dictionary = {}
var _blobs: Array = []      # the lava fountain's molten blobs: {node, phase, angle, reach}
var marked := 0
var survey_t := 0.0
var attempt := 1
var hud: MeteorHud
var _hub_planet: Planet
var _env: Node
var _env_saved: Dictionary = {}
var _hub_hidden: Array = []
var _input_saved := true
var _move_locked_saved := false
var _sky_root: Node3D
var _done := false
var _hurry_said := false
var _retrying := false
## For the test report: every attempt's outcome and every photo's verdict.
var attempts_log: Array = []
var photo_log: Array = []


func _ready() -> void:
	current = self
	# Late in the frame, after the CameraRig has moved, so the sky planets ride this frame's lens (`_process`).
	process_priority = 100
	_debug = OS.get_cmdline_user_args().has("--safari-debug")
	world = get_parent()
	_hub_planet = world.get_node_or_null("Planet") as Planet
	player = world.get_node_or_null("Player") as Player
	rig = world.get_node_or_null("CameraRig") as CameraRig
	_env = world.get_node_or_null("Environment")
	planet_id = SURVEY_ID
	layer = _NoEndLayer.new()
	layer.safari = self
	add_child(layer)
	hud = MeteorHud.new()
	hud.level = self
	add_child(hud)
	photo_taken.connect(_on_photo)
	_start()


func _start() -> void:
	if player == null or rig == null:
		push_warning("MeteorSurvey: no Player or CameraRig under %s; the survey is skipped." % str(world.get_path()))
		_restored = true
		_finish.call_deferred()
		return
	_saved_xform = player.global_transform
	_input_saved = player.input_enabled
	_move_locked_saved = player.is_move_locked()
	player.set_move_locked(true)
	phase = Phase.FADE_IN
	await layer.fade_to(1.0, FADE_SEC)
	if not is_instance_valid(player):
		return
	_enter_rock()
	await _warm_up()
	layer.show_awake_ui(true)
	hud.show_play(true)
	await layer.fade_to(0.0, FADE_SEC)
	for l: String in START_LINES:
		hud.say(l)
	_begin_attempt()


# ======================================================================================== THE ROCK
func _enter_rock() -> void:
	PhotoMode.begin(SURVEY_ID)
	for c: Node in world.get_children():
		if c == self or c == player or c == rig or c == _env or not (c is Node3D):
			continue
		_hub_hidden.append({"node": c, "visible": (c as Node3D).visible, "pm": c.process_mode})
		(c as Node3D).visible = false
		c.process_mode = Node.PROCESS_MODE_DISABLED
		# A CanvasLayer under a hidden Node3D still draws (the rocket pad's compass pip froze on screen).
		for cl: Node in c.find_children("*", "CanvasLayer", true, false):
			_hub_hidden.append({"node": cl, "visible": (cl as CanvasLayer).visible, "pm": cl.process_mode})
			(cl as CanvasLayer).visible = false
	# 3D things the hub hangs under a PLAIN Node stood on the rock (spec 9.5.3, the user: "There was a random
	# Play board on the meteor"): the Commons' game board is /root/World/ReplayBoard/Board, and ReplayBoard is a
	# Node, so the loop above skipped it and the board stood at its hub spot, 21.2 m from the centre - on the
	# 22 m rock's surface. ProjectSystem holds one too. Every top 3D node under such a host is hidden and taken
	# out of the physics world the same way; the host itself keeps running (it is not drawn).
	for c: Node in world.get_children():
		if c == self or c is Node3D or c is CanvasLayer:
			continue
		for n3: Node in c.find_children("*", "Node3D", true, false):
			if n3.get_parent() is Node3D:
				continue
			_hub_hidden.append({"node": n3, "visible": (n3 as Node3D).visible, "pm": n3.process_mode})
			(n3 as Node3D).visible = false
			n3.process_mode = Node.PROCESS_MODE_DISABLED
	if _env != null:
		_env_saved = {"time_scale": _env.get("time_scale"), "radius": _env.get("planet_radius"),
			"hour": _env.call("get_hour") if _env.has_method("get_hour") else GameState.time_of_day}
		_env.set("time_scale", 0.0)
		if _env.has_method("set_time"):
			_env.call("set_time", SURVEY_HOUR)
		_env.set("planet_radius", ROCK_RADIUS)
		# The hub's own sky - its small neighbour worlds, the meteor streak and a ring if it has one - rides the
		# eye, so it would hang in the survey's sky over the rock's own planets. Hidden for the survey; the
		# nodes' own visibility is never written by environment.gd (it updates their children), so this holds
		# until `_restore` puts it back from `_hub_hidden`.
		for sky_name: String in ["SkyBodies", "MeteorStreak", "Ring"]:
			var sky := _env.get_node_or_null(sky_name) as Node3D
			if sky != null:
				_hub_hidden.append({"node": sky, "visible": sky.visible, "pm": sky.process_mode})
				sky.visible = false
	_content = SafariWorld.new()
	_content.name = "Content"
	_content.safari = self
	add_child(_content)
	start_dir = Vector3.UP
	start_fwd = Vector3.FORWARD
	var rng := RandomNumberGenerator.new()
	rng.seed = 92809
	var crater_dirs: Array = []
	for i in range(5):
		crater_dirs.append(dir_from_start(rng.randf_range(50.0, 170.0), rng.randf_range(-180.0, 180.0)))
	var rock := MeteorRock.new()
	rock.name = "Rock"
	_content.add_child(rock)
	rock.build(ROCK_RADIUS, crater_dirs)
	planet = rock
	player.planet = rock
	player.input_enabled = true
	_build_cracks(rng)
	_build_landmarks(rng)
	_build_lookouts()
	_build_shards(rng)
	steam = MeteorSteam.new()
	steam.rock = rock
	steam.level = self
	_content.add_child(steam)
	_save_haze()
	_build_sky()
	_place_player()
	rig.reseat_behind_player()
	rig.set_first_person(true)
	_set_start_pitch()
	rig.set_fov_deg(PHOTO_MODE_OFF_FOV)
	player.set_safari_walk(true)
	_make_puff_material()


func _build_cracks(rng: RandomNumberGenerator) -> void:
	for i in range(CRACK_COUNT):
		var spot: Vector2 = CRACK_SPOTS[i]
		var dir := dir_from_start(spot.x, spot.y)
		var root := MeteorProps.outcrop(rng)
		root.name = "Crack%d" % (i + 1)
		_content.add_child(root)
		# Upright on the ground, turned so the split faces back toward the start (it reads from the path).
		var xf := planet.surface_transform(dir, start_dir - dir * start_dir.dot(dir))
		xf.basis = xf.basis.rotated(xf.basis.y.normalized(), rng.randf_range(-0.5, 0.5))
		root.global_transform = xf
		var plume := MeteorProps.plume()
		root.add_child(plume)
		var beacon := MeteorProps.beacon()
		beacon.visible = false
		root.add_child(beacon)
		var key := add_subject({
			"id": "crack_%d" % (i + 1),
			"name": "Weak point",
			"category": "sight",
			"node": root,
			"offset": Vector3(0.0, MeteorProps.SPLIT_Y, 0.0),
			"radius": CRACK_RADIUS,
			"band": CRACK_BAND,
			"awake": func() -> bool: return true,
		})
		cracks.append({"key": key, "root": root, "plume": plume, "beacon": beacon, "marked": false, "dir": dir})


func _build_shards(rng: RandomNumberGenerator) -> void:
	var holder := Node3D.new()
	holder.name = "Shards"
	_content.add_child(holder)
	var mat := MeteorProps.rock_material()
	var meshes: Array = []
	for i in range(5):
		meshes.append(MeteorProps.shard_mesh(rng, 1.0, 0.38, 5 + i % 3, 0.3))
	var avoid: Array = [start_dir]
	for c: Dictionary in cracks:
		avoid.append(c["dir"])
	var placed := 0
	var lm_dirs: Array = []
	for l: Dictionary in landmarks:
		lm_dirs.append(l["dir"])
	var tries := 0
	while placed < SHARD_COUNT and tries < 400:
		tries += 1
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if dir.length_squared() < 0.01:
			continue
		dir = dir.normalized()
		var ok := true
		for a: Vector3 in avoid:
			# Clear of the start and each weak point (and each other) by ~5 m of surface.
			if acos(clampf(dir.dot(a), -1.0, 1.0)) * ROCK_RADIUS < 5.0:
				ok = false
				break
		for a: Vector3 in lm_dirs:
			if acos(clampf(dir.dot(a), -1.0, 1.0)) * ROCK_RADIUS < LANDMARK_CLEAR_M:
				ok = false
				break
		for l: Dictionary in lookouts:
			if acos(clampf(dir.dot(l["dir"] as Vector3), -1.0, 1.0)) * ROCK_RADIUS < VANTAGE_CLEAR_M:
				ok = false
				break
		if not ok:
			continue
		avoid.append(dir)
		var h := rng.randf_range(0.6, 2.6)
		var mi := MeshInstance3D.new()
		mi.mesh = meshes[placed % meshes.size()]
		mi.material_override = mat
		var n := Node3D.new()
		n.name = "Shard%d" % placed
		holder.add_child(n)
		var xf := planet.surface_transform(dir, start_fwd)
		xf.basis = xf.basis.rotated(xf.basis.y.normalized(), rng.randf_range(0.0, TAU))
		n.global_transform = xf
		mi.scale = Vector3(h * rng.randf_range(0.8, 1.2), h, h * rng.randf_range(0.8, 1.2))
		n.add_child(mi)
		if h > 1.1:
			n.add_child(MeteorProps.collider(0.3 * h, h))
		placed += 1


func _build_landmarks(rng: RandomNumberGenerator) -> void:
	for i in range(LANDMARK_SPOTS.size()):
		var spot: Vector2 = LANDMARK_SPOTS[i]
		var dir := dir_from_start(spot.x, spot.y)
		var kind: String = MeteorProps.LM_NAMES[i % MeteorProps.LM_NAMES.size()]
		var root := MeteorProps.landmark(kind, rng)
		_content.add_child(root)
		# Turned to show its broad side to the start (the arch's opening faces the way most players come).
		var xf := planet.surface_transform(dir, start_dir - dir * start_dir.dot(dir))
		root.global_transform = xf
		if root.has_meta("blobs"):
			_blobs.append_array(root.get_meta("blobs"))
		landmarks.append({"name": kind, "root": root, "dir": dir, "look_y": float(root.get_meta("look_y", 2.5))})


## The lookouts: each rise stands at its spot with its walkable back turned toward the start (inside the widest gap between
## the cracks it looks out on). Own seeded stream, so adding them leaves every other thing on the rock where it was.
func _build_lookouts() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 60928
	for v: Array in VANTAGE_SPOTS:
		var spot: Vector2 = v[0]
		var dir := dir_from_start(spot.x, spot.y)
		# The walkable back runs out toward where players come from (the start), kept inside the widest gap between
		# the cracks the lookout is for, so nobody climbs with their back to them and the slope never sits under the
		# look toward one (builder LOOKOUT, 2026-09-29; kept by builder RISE).
		var xf := planet.surface_transform(dir, start_dir)
		var angles: Array = []
		for ci: int in v[1]:
			var cl: Vector3 = xf.basis.inverse() * (cracks[ci]["dir"] as Vector3)
			angles.append(atan2(cl.z, cl.x))
		angles.sort()
		var gap_a0 := 0.0
		var gap_w := -1.0
		for i in range(angles.size()):
			var a0: float = angles[i]
			var a1: float = angles[(i + 1) % angles.size()] + (TAU if i == angles.size() - 1 else 0.0)
			if a1 - a0 > gap_w:
				gap_w = a1 - a0
				gap_a0 = a0
		var sl: Vector3 = xf.basis.inverse() * start_dir
		var start_a := gap_a0 + fposmod(atan2(sl.z, sl.x) - gap_a0, TAU)
		var margin := minf(deg_to_rad(40.0), gap_w * 0.35)
		var steps_a := clampf(start_a, gap_a0 + margin, gap_a0 + gap_w - margin)
		if start_a > gap_a0 + gap_w and start_a - (gap_a0 + gap_w) > TAU - start_a + gap_a0:
			steps_a = gap_a0 + margin   # nearer the gap's first edge the other way round
		# MeteorVantage runs its walkable back out along local -Z (atan2 angle -PI/2); this turns it to `steps_a`.
		xf.basis = xf.basis * Basis(Vector3.UP, -PI * 0.5 - steps_a)
		var looks: Array = []
		for ci: int in v[1]:
			looks.append((cracks[ci]["root"] as Node3D).global_position)
		var crag := MeteorVantage.build(planet, xf, rng, looks)
		_content.add_child(crag)
		crag.global_transform = xf
		var seen: Array = []
		for c: Dictionary in cracks:
			seen.append(snappedf(rad_to_deg(acos(clampf(dir.dot(c["dir"] as Vector3), -1.0, 1.0))), 0.1))
		lookouts.append({"root": crag, "dir": dir, "sees": v[1]})
		_log("lookout at %s: degrees to cracks 1-5 %s, looks out on %s; back %.0f deg off the way to the start, in a %.0f deg gap; crystal %.0f deg off the nearest look" % [
			str(spot), str(seen), str(v[1]), rad_to_deg(absf(angle_difference(steps_a, atan2(sl.z, sl.x)))), rad_to_deg(gap_w),
			float(crag.get_meta("crystal_off_look_deg", 0.0))])


## The fountain's blobs, every frame (a dozen transforms; runs in every phase so it never freezes on a fade).
func _animate_landmarks() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for b: Dictionary in _blobs:
		var node := b["node"] as Node3D
		var k := fposmod(t * 0.55 + float(b["phase"]), 1.0)
		node.position = MeteorProps.fountain_blob_pos(b, k)
		node.scale = Vector3.ONE * (1.0 - 0.6 * k)


## The system's planets, huge in the sky (spec 9.2). They ride with the lens (`_process`), so they sit at
## infinity like the sky itself; the rock hides them as the player walks round.
func _build_sky() -> void:
	_sky_root = Node3D.new()
	_sky_root.name = "SkyPlanets"
	_content.add_child(_sky_root)
	# [around deg from straight up (90 = the start's level), bearing, distance, radius, colours, bands, ring].
	# Near the start's level so they hang just over the rock's horizon (it dips ~18 deg on a 22 m rock).
	var specs := [
		[80.0, -22.0, 230.0, 80.0, Color("#6fa77a"), Color("#4f8a8f"), Color("#bfe6ff"), 6.0, Color.TRANSPARENT],
		[76.0, 62.0, 240.0, 44.0, Color("#8a6fc4"), Color("#6c56a8"), Color("#d8c8ff"), 9.0, Color.TRANSPARENT],
		[74.0, -140.0, 235.0, 40.0, Color("#8fa3bf"), Color("#6f819c"), Color("#dfe8f5"), 12.0, Color("#c9d3e6")],
		[70.0, 150.0, 250.0, 30.0, Color("#e9dcc3"), Color("#cdb993"), Color("#fff4d6"), 4.0, Color.TRANSPARENT],
	]
	for s: Array in specs:
		var dir := dir_from_start(float(s[0]), float(s[1]))
		# Lit mostly from the rock's side, a little across, so each shows a wide lit face and a terminator.
		var side := dir.cross(start_dir).normalized()
		var light := (-dir + side * 0.8 + start_dir * 0.3).normalized()
		var body := MeteorProps.sky_planet(float(s[3]), s[4], s[5], s[6], light, float(s[7]), s[8])
		_sky_root.add_child(body)
		body.position = dir * float(s[2])


func _place_player() -> void:
	player.dev_teleport(planet.surface_point(start_dir))
	player.place_on_planet(start_dir, start_fwd)
	player.velocity = Vector3.ZERO


# ======================================================================================== AN ATTEMPT
func _begin_attempt() -> void:
	survey_t = 0.0
	elapsed = 0.0
	film_start = FILM
	film_left = FILM
	_film_out_offered = false
	_hurry_said = false
	marked = 0
	for c: Dictionary in cracks:
		c["marked"] = false
		(c["plume"] as Node3D).visible = true
		(c["beacon"] as Node3D).visible = false
	hud.set_marks(0, CRACK_COUNT)
	hud.set_clock(TIME_LIMIT)
	player.set_move_locked(false)
	phase = Phase.AWAKE
	_log("attempt %d: go (film %d, %.0f s)" % [attempt, film_left, TIME_LIMIT])


func _process(delta: float) -> void:
	if _sky_root != null and is_instance_valid(_sky_root) and rig != null and is_instance_valid(rig):
		var cam := rig.get_view_camera()
		if cam != null:
			_sky_root.global_position = cam.global_position
	if not _blobs.is_empty():
		_animate_landmarks()
	_apply_haze()
	if steam != null and is_instance_valid(steam) and rig != null and is_instance_valid(rig):
		steam.step(rig.get_view_camera(), delta)
	if phase != Phase.AWAKE:
		return
	_max_frame_ms = maxf(_max_frame_ms, delta * 1000.0)
	survey_t += delta
	# The safari's sun-dial reads elapsed / DURATION: scaled so it runs the whole arc in TIME_LIMIT.
	elapsed = minf(survey_t, TIME_LIMIT) / TIME_LIMIT * DURATION
	_update_camera_mode(delta)
	hud.set_clock(TIME_LIMIT - survey_t)
	if not _hurry_said and TIME_LIMIT - survey_t <= 30.0:
		_hurry_said = true
		hud.say(LINE_HURRY)
	if survey_t >= TIME_LIMIT:
		_retry(TIMEOUT_TITLE, TIMEOUT_LINE, "time")


## The survey has no End button (it can only be finished). This is SafariLayer unchanged except that its own
## `_layout` places the button off screen, so it is never drawn or hit - no per-frame fix-up from the level and
## no process order to rely on. Nothing to restore: the layer is the survey's own and goes with it. (A
## `show_end` switch in safari_layer.gd would let the layout skip the button outright; not this builder's file.)
class _NoEndLayer:
	extends SafariLayer

	func _layout() -> void:
		super._layout()
		end_rect = Rect2(Vector2(-10000.0, -10000.0), Vector2.ZERO)


func request_end() -> void:
	pass


# ======================================================================================== PHOTOS
func _on_photo(photo: Dictionary) -> void:
	var entries: Array = []
	if not (photo.get("raw", {}) as Dictionary).is_empty():
		entries.append(photo["raw"])
	entries.append_array(photo.get("others", []))
	var verdict := ""
	var crack_key := ""
	for e: Dictionary in entries:
		var c := _crack(str(e.get("key", "")))
		if not c.is_empty() and not bool(c["marked"]) and int(e.get("grade_idx", 0)) >= MARK_GRADE_IDX:
			crack_key = str(c["key"])
			verdict = "marked"
			_mark(c)
			break
	if verdict == "":
		for e: Dictionary in entries:
			var c := _crack(str(e.get("key", "")))
			if not c.is_empty() and not bool(c["marked"]):
				crack_key = str(c["key"])
				verdict = "smudge"
				var why := _smudge_reason(e)
				layer.banner(why, 3.2)
				AudioManager.play_sfx("blocked", -8.0)
				break
	if verdict == "":
		verdict = "already"
		film_left += 1
		layer.banner(ALREADY_LINE, 2.6)
	var raw: Dictionary = photo.get("raw", {})
	var row := {"attempt": attempt, "t": snappedf(survey_t, 0.01), "verdict": verdict, "crack": crack_key,
		"grade": str(photo.get("grade", "")), "scores": photo.get("scores", {}),
		"dist": snappedf(float(raw.get("dist", 0.0)), 0.01), "size_frac": snappedf(float(raw.get("size_frac", 0.0)), 0.001),
		"film_left": film_left}
	photo_log.append(row)
	_log("photo %s" % str(row))


func _crack(key: String) -> Dictionary:
	for c: Dictionary in cracks:
		if str(c["key"]) == key:
			return c
	return {}


## The ONE thing to fix, from the scorer's own numbers for that crack: whichever craft factor is lowest.
static func _smudge_reason(e: Dictionary) -> String:
	var inside := float(e.get("inside_frac", 1.0))
	var seen := float(e.get("seen_frac", 1.0))
	var size_frac := float(e.get("size_frac", 0.0))
	var options := {
		"focus": float(e.get("focus", 10.0)),
		"centred": float(e.get("centred", 10.0)),
		"size": SafariPhotoScorer.band_score(size_frac, CRACK_BAND),
		"cut": inside * 10.0,
		"hidden": seen * 10.0,
	}
	var worst := "focus"
	for k: String in options:
		if float(options[k]) < float(options[worst]):
			worst = k
	match worst:
		"focus":
			return "Smudge: blurry. Hold the shutter to focus."
		"centred":
			return "Smudge: off-centre. Put the crack in the ring."
		"cut":
			return "Smudge: cut off. Get all of the crack in view."
		"hidden":
			return "Smudge: something's in the way. Find a clear view."
		_:
			if size_frac > CRACK_BAND.y:
				return "Smudge: too close. Step back a little."
			return "Smudge: too small. Zoom in or walk closer."


func _mark(c: Dictionary) -> void:
	c["marked"] = true
	marked += 1
	(c["plume"] as Node3D).visible = false
	var beacon := c["beacon"] as Node3D
	beacon.visible = true
	beacon.scale = Vector3.ONE * 0.2
	create_tween().tween_property(beacon, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var root := c["root"] as Node3D
	puff_at(root.global_position + root.global_transform.basis.y.normalized() * 0.6, 22, MeteorProps.BEACON)
	AudioManager.play_sfx("part_fitted", -3.0)
	hud.set_marks(marked, CRACK_COUNT)
	var left := CRACK_COUNT - marked
	_log("marked %s at t=%.2f (%d left)" % [c["key"], survey_t, left])
	if left <= 0:
		layer.banner("Beacon placed! All five marked!", 3.0)
		_complete.call_deferred()
		return
	layer.banner("Beacon placed! %d to go." % left, 2.6)
	if marked == 1:
		hud.say(LINE_FIRST)
	elif left == 1:
		hud.say(LINE_LAST_ONE)


## Called (deferred) by PlanetSafari._take_photo when the last plate is used. With cracks still to mark,
## the survey cannot be finished on this roll: the retry card, straight away.
func _offer_film_out() -> void:
	if _film_out_offered or _done or phase != Phase.AWAKE or film_left > 0:
		return
	_film_out_offered = true
	while phase == Phase.AWAKE and capturing:
		await get_tree().process_frame
	# Let the last photo's flash and its verdict show first.
	await get_tree().create_timer(1.2).timeout
	if _done or phase != Phase.AWAKE or film_left > 0:
		return
	_retry(FILMOUT_TITLE, FILMOUT_LINE, "film")


# ======================================================================================== RETRY
func _retry(title: String, line: String, why: String) -> void:
	if _retrying or _done:
		return
	_retrying = true
	holding = false
	if camera_up:
		set_camera_up(false)   # before the phase changes: set_camera_up only acts while AWAKE
	phase = Phase.SLEEPING
	player.set_move_locked(true)
	layer.cancel_pointers()
	attempts_log.append({"attempt": attempt, "result": why, "marked": marked, "t": snappedf(survey_t, 0.01),
		"film_left": film_left})
	_log("attempt %d over: %s, %d marked, t=%.2f" % [attempt, why, marked, survey_t])
	EventBus.ui_modal_opened.emit(RETRY_MODAL)
	await hud.show_retry_card(title, line)
	EventBus.ui_modal_closed.emit(RETRY_MODAL)
	await layer.fade_to(1.0, FADE_SEC)
	attempt += 1
	_place_player()
	rig.reseat_behind_player()
	_set_start_pitch()
	camera_fov = PHOTO_MODE_OFF_FOV
	rig.set_fov_deg(PHOTO_MODE_OFF_FOV)
	_begin_attempt()
	phase = Phase.FADE_IN
	player.set_move_locked(true)
	await layer.fade_to(0.0, FADE_SEC)
	hud.say("Attempt %d. You've got this!" % attempt)
	hud.say(LINE_CLIMB_HINT)
	player.set_move_locked(false)
	phase = Phase.AWAKE
	_retrying = false


# ======================================================================================== DONE
func _complete() -> void:
	if _done:
		return
	_done = true
	holding = false
	if camera_up:
		set_camera_up(false)
	phase = Phase.SLEEPING
	player.set_move_locked(true)
	attempts_log.append({"attempt": attempt, "result": "done", "marked": marked, "t": snappedf(survey_t, 0.01),
		"film_left": film_left})
	_log("survey done: attempt %d, t=%.2f, film_left=%d, max_frame_ms=%.1f" % [attempt, survey_t, film_left, _max_frame_ms])
	hud.say(LINE_DONE)
	AudioManager.play_sfx("quest_complete", -2.0)
	await get_tree().create_timer(3.2).timeout
	phase = Phase.FADE_OUT
	await layer.fade_to(1.0, FADE_SEC)
	hud.show_play(false)
	layer.show_awake_ui(false)
	_restore(true)
	await get_tree().process_frame
	await layer.fade_to(0.0, FADE_SEC)
	_finish()


func _finish() -> void:
	phase = Phase.DONE
	survey_done.emit()
	queue_free()


## Everything back as it was before the survey (PlanetSafari._restore does the camera, the walk, the lock
## and the player's place; this puts back what the survey itself changed first: the planet under the
## player, the hub's nodes, the clock and the input switch). `teleport` false = the scene is going away.
func _restore(teleport: bool) -> void:
	if _restored:
		return
	_blobs.clear()  # the landmarks are freed below; stop _animate_landmarks touching them in the fade-out
	steam = null
	_restore_haze()
	if planet is MeteorRock and is_instance_valid(planet):
		# Out of the physics world now, not at the end of the frame, before the player is put back.
		planet.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(player):
		if _hub_planet != null and is_instance_valid(_hub_planet):
			player.planet = _hub_planet
		player.input_enabled = _input_saved
	for h: Dictionary in _hub_hidden:
		var n: Variant = h["node"]
		if n is Node3D and is_instance_valid(n):
			(n as Node3D).visible = bool(h["visible"])
			(n as Node).process_mode = int(h["pm"])
		elif n is CanvasLayer and is_instance_valid(n):
			(n as CanvasLayer).visible = bool(h["visible"])
	_hub_hidden.clear()
	if _env != null and is_instance_valid(_env) and not _env_saved.is_empty():
		_env.set("planet_radius", _env_saved["radius"])
		if _env.has_method("set_time"):
			_env.call("set_time", float(_env_saved["hour"]))
		_env.set("time_scale", _env_saved["time_scale"])
	if _hub_planet != null and is_instance_valid(_hub_planet):
		planet = _hub_planet
	super._restore(teleport)
	if teleport and is_instance_valid(player):
		player.set_move_locked(_move_locked_saved)


# ======================================================================================== HAZE
func _save_haze() -> void:
	_fog_env = _env.get("_env") as Environment if _env != null else null
	if _fog_env == null:
		return
	_fog_saved = {"begin": _fog_env.fog_depth_begin, "end": _fog_env.fog_depth_end, "curve": _fog_env.fog_depth_curve,
		"aerial": _fog_env.fog_aerial_perspective, "density": _fog_env.fog_density, "color": _fog_env.fog_light_color,
		"enabled": _fog_env.fog_enabled}
	_apply_haze()


## Every frame while on the rock: environment.gd writes the hub's fog colour and density each frame, so this
## writes the steam over them after it (process_priority 100).
func _apply_haze() -> void:
	if _fog_env == null or _fog_saved.is_empty():
		return
	_fog_env.fog_enabled = true
	_fog_env.fog_depth_begin = HAZE_BEGIN_M
	_fog_env.fog_depth_end = HAZE_END_M
	_fog_env.fog_depth_curve = HAZE_CURVE
	_fog_env.fog_aerial_perspective = 0.0
	_fog_env.fog_light_color = HAZE_COLOR
	_fog_env.fog_density = HAZE_DENSITY


func _restore_haze() -> void:
	if _fog_env == null or _fog_saved.is_empty():
		return
	_fog_env.fog_depth_begin = float(_fog_saved["begin"])
	_fog_env.fog_depth_end = float(_fog_saved["end"])
	_fog_env.fog_depth_curve = float(_fog_saved["curve"])
	_fog_env.fog_aerial_perspective = float(_fog_saved["aerial"])
	_fog_env.fog_density = float(_fog_saved["density"])
	_fog_env.fog_light_color = _fog_saved["color"]
	_fog_env.fog_enabled = bool(_fog_saved["enabled"])
	_fog_saved = {}


func _log(msg: String) -> void:
	print("[MeteorSurvey] " + msg)


## Everything a test needs, in plain values.
func survey_state() -> Dictionary:
	return {"phase": phase, "attempt": attempt, "survey_t": survey_t, "marked": marked, "film_left": film_left,
		"camera_up": camera_up, "retry_card": hud != null and hud.card_showing(), "done": _done,
		"line": hud.current_line() if hud != null else ""}
