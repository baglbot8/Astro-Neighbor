extends Node3D
## RING RUN - the second mini-game (docs/CORE_LOOP.md "Mini-games instead of fetch trips", decided
## 2026-09-12; docs/BUILD_PLAN.md Phase 3). Companion to catch_game.gd on the same contract - read
## minigame_system.gd's header first.
##
## A chain of hoops sits 1-3.6 m above the ground on a single great circle that loops the whole
## planet. Fly them IN ORDER, hop / glide / land / hop: the next hoop is always the only one ARMED
## (a bright glowing core in its opening; every other hoop is plain, undecorated ring). Fly through
## an armed hoop's opening to pass it. Fly past it without threading it and nothing happens at all
## - you just turn around and line up again; there is no miss timer, no penalty, no failure state.
## Passing the last hoop finishes the run.
##
## ============================================================================== CONFIG (all optional)
##   "count"    how many hoops. Default: the planet's own circumference / TARGET_SPACING_M,
##              clamped to COUNT_RANGE - a lap always resolves to a sensible number of hops without
##              a content writer having to know the planet's radius.
##   "done"     how many are ALREADY passed (resuming a half-run).
##   "flavour"  which palette: "bolt", "light", "pod", "moth" or "spark" - READ DIRECTLY from
##              catch_game.gd's own FLAVOURS table (one source of truth since 2026-09-13; see the
##              const below), so a neighbour's colour carries across both of their mini-games and a
##              new look is added in ONE place, just carried by a hoop instead of a bolt / lantern /
##              seed pod / moth / spark. Unknown flavours fall back to "bolt" with a warning.
##   "title"    the line on the progress pill. Default "Ring run".
##   "near"     planet-local direction ([x,y,z] or Vector3) the course starts near - a neighbour's
##              yard, say, or wherever the player is standing when a host starts the course for the
##              first time. LEFT OUT, the anchor is drawn from "seed" instead (see "WHY NO PLAYER
##              FALLBACK" below) - fine for a quick dev test, but a REAL host that wants a stable,
##              resumable course should pass the same "near" every time it calls `start`, the same
##              way it passes the same "seed".
##   "height"   metres above ground at the MIDDLE of the lap's gentle rise-and-dip. Clamped to
##              HEIGHT_RANGE.
##   "seed"     fixes the course layout (which great circle, which way the height wave breathes, and
##              the default anchor when "near" is not given). Default: hashed from the owner and the
##              planet, so the same save always gets the same course and two captures match.
##
## ============================================================================== WHY THESE NUMBERS
## The jetpack itself is not changed (docs/STYLE_GUIDE.md R2.8; the brief repeats it: the ceiling is
## load-bearing). MEASURED in this build, headless, real physics: boost held from a standing start
## on Bolt through `TouchControls.debug_widget("boost", true)` - the SAME `_pointer_*` routing and
## hit tests a real finger goes through (touch_controls.gd's own header), not `Input.action_press`
## (which "sets action state but emits no InputEvent" per that same file, and per CLAUDE.md). Player
## `get_ground_height()` rose 0.00 -> 1.36 -> 2.48 -> 3.60 -> 3.94 m over the first 1.5 s (the climb
## overshooting BOOST_CLIMB_HEIGHT's 3.8 m latch briefly before the float-down target takes over),
## then settled into the documented 0.75 m/s descent exactly: 3.94, 3.79, 3.64, 3.49 m at 0.2 s
## steps, a step of 0.15 m = 0.75 m/s every time. Full trace: this file's builder report.
##
## HEIGHT_RANGE is 1.0-3.6 m, not the full 1-4 m the brief sketched: the low end sits right at the
## jump apex (1.20 m, so an occasional low hoop is a quick jump-through rather than always needing
## the jetpack - fine for a cozy course with no fail state), and the high end keeps a 0.34 m margin
## under the MEASURED 3.94 m peak rather than asking every course to be threaded at the exact top of
## a transient overshoot that varies with frame timing. Horizontal cruise while boosting is ~7 m/s
## (player.gd's own R2.8 note), so TARGET_SPACING_M keeps one hop-to-hop gap inside a single
## boost-glide, with the "land, refuel" beat the brief asks for rather than a multi-tank slog.
##
## ============================================================================== WHY STATIC, NOT DRIFTING
## Unlike catch's runaways, a hoop never moves once placed - the course has to fly the same way
## every time you look at it, not chase a moving target. That makes the whole layout a ONE-TIME
## computation in `setup()`: ground height is sampled once per hoop with `Planet.height_at`, never
## per frame, and only the ONE currently-armed hoop does any per-frame work at all (a slow spin and
## the pass check). Cost is therefore flat regardless of hoop count - cheaper than catch's per-frame
## terrain sample on every live item - and only gets cheaper as the run goes on and hoops are freed.
##
## ============================================================================== WHY NO PLAYER FALLBACK
## MEASURED, not reasoned to: an early version defaulted a "near"-less anchor to
## `Planet.dir_of(_player.global_position)` - wherever the player is standing THE INSTANT `setup()`
## runs - so a fresh course opened right where the player stood. That is exactly wrong for a RESUME:
## a host calling `start` again with "done": 2 does so after the player has already flown two hoops
## away from where the course began, so the "no near given" branch rebuilt the whole great circle
## around the player's NEW position and every remaining hoop moved. Caught by running the same
## seed/count twice in this build - once straight through, once resumed at "done": 2 - and comparing
## the third hoop's position: (-1.06, -13.87, -1.53) fresh vs (0.01, 13.99, 0.04) resumed, nowhere
## close. The anchor now comes from `rng` (seeded exactly like everything else in this course) when
## "near" is absent, never from the player, so "done": N always rebuilds the same course a fresh
## "done": 0 run would eventually reach - proven the same way, this file's builder report. The
## trade is that a course with no "near" no longer opens guaranteed-in-view (it can be anywhere on
## the sphere) - a real host should pass "near" for that, the same way catch's does for a clustered
## start.
##
## ============================================================================== WHY NO JETPACK GATE
## catch_game gates a catch on `Player.is_boosting()` because height alone cannot promise
## "glide-only" on uneven terrain (a plateau player can be closer to a runaway than the flat-ground
## case). A hoop is a WAYPOINT, not a prize: the height band is the brief's own 1-3.6 m rather than
## catch's tighter 3.0-3.6 m glide band, and most of that band already sits above jump apex, so
## flying it is the natural way through even with no rule enforcing it. No anti-cheese check is
## added on top - a player who threads a low hoop with one well-timed jump has still flown the
## course, and this is a cozy game with no failure state to protect.
##
## ============================================================================== PHONE AND HEAT
## docs/OPEN_ISSUES.md 44: small node/draw budgets, one shared material per look, no GPUParticles3D
## - see `catch_game.gd`'s own header. This game's hoop is TWO draw calls (the gate body, one shared
## vertex-coloured mesh per flavour; the beacon quad, shown on only ONE hoop at a time) - the same
## shape of budget as a runaway, but with less per-frame cost (see "WHY STATIC" above).

## Metres above ground at the wave's midpoint, default. Clamped to HEIGHT_RANGE.
const HEIGHT_MID_DEFAULT := 2.3
## Half the sine swing around the midpoint - see "WHY THESE NUMBERS" above for how the band was set.
const HEIGHT_WAVE_M := 1.3
const HEIGHT_RANGE := Vector2(1.0, 3.6)
## How many rise-and-dip cycles the height wave completes over one full lap - picked once per
## course (2 or 3) from the seed, never per hoop, so different neighbours' courses feel different
## without any hoop-to-hoop randomness that would break resume determinism (see `setup()`).
const WAVE_CYCLES_RANGE := Vector2i(2, 3)

## Ground distance the FIRST hoop starts from wherever the course begins (the anchor - "near", or
## the player). Same idea as catch's FIRST_SPOT_M: comfortably inside the horizon on every world
## (grig, the smallest, is radius 9.5) so the course opens with something to fly at, and clear of
## the anchor itself so hoop 0 is never spawned on top of the player.
const START_SPOT_M := 8.0

const COUNT_RANGE := Vector2i(4, 10)
## A hop-to-hop gap this big keeps one boost-glide (~7 m/s cruise, player.gd R2.8) to roughly one
## hop between hoops, so the course reads as "hop, glide, land, hop" instead of one long fly.
const TARGET_SPACING_M := 11.0

## How close the astronaut has to fly to the hoop's own centre LINE - the axis through the hole,
## along the direction of travel - to count as threaded. Generous on purpose, the same reasoning as
## catch's CATCH_RADIUS_M: a static target flown past at ~7 m/s needs forgiveness for a phone thumb,
## not precision.
const GATE_RADIUS_M := 1.25
## How far either side of the hoop's own plane still counts, along the travel axis. At worst-case
## frame time (30 fps, 0.033 s) a 7 m/s flythrough covers 0.23 m per frame - a fraction of this, so
## the pass is never missed between two samples.
const GATE_HALF_THICK_M := 1.5

## Radians/second the ARMED hoop spins around its own hole (its local Y, the travel axis) - the one
## piece of per-frame motion this game has, and only on one hoop at a time.
const SPIN_RAD_S := 1.1

## Visual size. R is the tube's own centre radius, r the tube's thickness - the opening a player
## flies through is R - r.
const RING_R := 1.05
const RING_TUBE_R := 0.15
## The inner accent band sits INSIDE the main hoop; the four corner studs sit ON its rim.
const ACCENT_R_SCALE := 0.80
const ACCENT_TUBE_R := 0.05
const STUD_R := 0.19
## Soft glow disc filling the ARMED hoop's opening - the "next one is always marked" cue. Same
## additive / unshaded / billboarded recipe as catch's halo, same alpha: it already measured clean
## against three worlds' palette gates at this exact value.
const BEACON_SIZE_M := 1.5
const BEACON_ALPHA := 0.15

## ONE SOURCE OF TRUTH (2026-09-13): this used to be ring_game.gd's OWN copy of catch_game.gd's three
## flavours, and the Phase 3 brief called out exactly the risk that shape invites - a new look added
## here and forgotten there, or added there and forgotten here, with no error to catch the drift.
## Reading catch_game.gd's own `FLAVOURS` const through `preload(...)` instead means a look is
## authored in exactly one dictionary (that file's own palette-gate comment explains the numbers);
## this file just borrows it. `FLAVOURS` below still names the same Dictionary everywhere it is used
## in this file (`FLAVOURS.has(...)`, `FLAVOURS[...]`), so nothing past this line changed. The extra
## "label"/"plural" keys catch_game.gd's rows carry are simply unused here - only "body", "accent"
## and "glow" are ever read for a hoop. Only the SHAPE tells catch and rings apart.
const FLAVOURS := preload("res://src/minigames/catch_game.gd").FLAVOURS
const DEFAULT_FLAVOUR := "bolt"

var _system: MinigameSystem
var _planet: Planet
var _player: Node3D
var _flavour: String = DEFAULT_FLAVOUR
var _title: String = ""
var _total: int = 0
var _done: int = 0
var _t: float = 0.0
## One entry per hoop NOT YET PASSED, in course order. Index 0 is always the ARMED one; passing it
## removes it, so `_items.size()` is what is left of the lap.
var _items: Array[Dictionary] = []


# ============================================================================= setup
func setup(system: MinigameSystem, config: Dictionary) -> String:
	_system = system
	var tree := get_tree()
	if tree == null:
		return "not in a scene tree"
	_planet = tree.get_first_node_in_group("planet") as Planet
	if _planet == null:
		return "no planet here"
	_player = tree.get_first_node_in_group("player") as Node3D
	if _player == null:
		return "no player here"

	_flavour = str(config.get("flavour", DEFAULT_FLAVOUR))
	if not FLAVOURS.has(_flavour):
		push_warning("ring_game: unknown flavour '%s', using '%s'" % [_flavour, DEFAULT_FLAVOUR])
		_flavour = DEFAULT_FLAVOUR
	_title = str(config.get("title", ""))
	if _title == "":
		_title = "Ring run"

	var default_count := clampi(int(round(TAU * _planet.radius / TARGET_SPACING_M)), COUNT_RANGE.x, COUNT_RANGE.y)
	_total = clampi(int(config.get("count", default_count)), COUNT_RANGE.x, COUNT_RANGE.y)
	_done = clampi(int(config.get("done", 0)), 0, _total)
	var height_mid := clampf(float(config.get("height", HEIGHT_MID_DEFAULT)), HEIGHT_RANGE.x, HEIGHT_RANGE.y)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(config["seed"]) if config.has("seed") \
		else hash([str(config.get("owner", "")), _planet.data.id, _planet.data.seed, _total])

	var anchor := _anchor_dir(config, rng)
	var tangent := _pick_tangent(anchor, rng)
	# Drawn ONCE from the seed, before the per-hoop loop, so a resumed game (which only loops from
	# `_done`, never from 0) still reproduces every earlier hoop's exact position - see the header's
	# "WHY STATIC" note. Nothing below this line draws from `rng` again.
	var wave_cycles := float(rng.randi_range(WAVE_CYCLES_RANGE.x, WAVE_CYCLES_RANGE.y))
	var wave_phase := rng.randf() * TAU

	var first_offset := START_SPOT_M / maxf(_planet.radius, 1.0)
	var spacing := TAU / float(_total)

	var body := _body_mesh(_flavour)
	var body_mat := _body_material(_flavour)
	var beacon_mat := _beacon_material(Color(str(FLAVOURS[_flavour]["glow"])))

	# A resumed game spawns only what is LEFT, exactly like catch - but every angle below is a pure
	# function of `i`, so hoop 7 sits in the same place whether this run started at "done": 0 or is
	# resuming from "done": 7. Nothing here is interchangeable the way catch's runaways are: a hoop
	# IS the course, so its position must survive a save / reload / world-hop unchanged.
	for i in range(_done, _total):
		var angle := first_offset + float(i) * spacing
		var dir := (anchor * cos(angle) + tangent * sin(angle)).normalized()
		var fwd := (tangent * cos(angle) - anchor * sin(angle)).normalized()
		var ground := _planet.height_at(dir)
		var h := clampf(height_mid + HEIGHT_WAVE_M * sin(angle * wave_cycles + wave_phase), HEIGHT_RANGE.x, HEIGHT_RANGE.y)
		var pos := _planet.global_position + dir * (ground + h)
		_items.append(_spawn(pos, fwd, body, body_mat, beacon_mat))

	if not _items.is_empty():
		_set_beacon(_items[0], true)
	_system.report_progress(_done, _total)
	if _items.is_empty():
		# Nothing to do: the host handed us a finished course. Report it and let the system tidy up.
		_finish.call_deferred()
	return ""


## Planet-local direction the course starts near: "near" if the config gives one, else a point
## drawn from `rng` - NEVER the player's live position. See the header's "WHY NO PLAYER FALLBACK":
## the player moves between a fresh start and a resume, and the anchor must not.
func _anchor_dir(config: Dictionary, rng: RandomNumberGenerator) -> Vector3:
	if config.has("near"):
		var raw: Variant = config["near"]
		if raw is Vector3:
			var v3: Vector3 = raw
			if v3.length_squared() > 0.0001:
				return v3.normalized()
		elif raw is Array and (raw as Array).size() == 3:
			var a: Array = raw
			var v := Vector3(float(a[0]), float(a[1]), float(a[2]))
			if v.length_squared() > 0.0001:
				return v.normalized()
	var v := Vector3(rng.randfn(), rng.randfn(), rng.randfn())
	return v.normalized() if v.length_squared() > 0.0001 else Vector3.UP


## An orthonormal tangent to `anchor`, so (anchor, tangent) spans the course's great circle.
func _pick_tangent(anchor: Vector3, rng: RandomNumberGenerator) -> Vector3:
	var t := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	t -= anchor * t.dot(anchor)
	if t.length_squared() < 0.0001:
		t = anchor.cross(Vector3.UP)
		if t.length_squared() < 0.0001:
			t = anchor.cross(Vector3.RIGHT)
	return t.normalized()


func title() -> String:
	return _title


## WORLD position of the armed hoop, for the progress pill's chevron.
func hint_direction() -> Vector3:
	if _items.is_empty():
		return Vector3.INF
	var node: Node3D = _items[0]["node"]
	return node.global_position if is_instance_valid(node) else Vector3.INF


## Called by the system just before this node is freed. Nothing to unwind: every node and material
## this game made is a child of it (or a cached static shared with every other course), and it never
## touched the player, a modal or the tree.
func outro() -> void:
	pass


# ============================================================================= per-frame
func _process(delta: float) -> void:
	if _items.is_empty() or not is_instance_valid(_planet) or not is_instance_valid(_player):
		return
	_t += delta
	var active: Dictionary = _items[0]
	var node: Node3D = active["node"]
	if not is_instance_valid(node):
		# Should not happen (nothing outside this game frees a hoop), but a stray free must not wedge
		# the run - drop the dead entry and let the next frame arm whatever is left.
		_items.pop_front()
		if not _items.is_empty():
			_set_beacon(_items[0], true)
		return
	# The one piece of per-frame motion in this whole game (see the header's "WHY STATIC" note) -
	# spins around the hoop's OWN local Y, which `axis_basis` set to the through-direction at spawn,
	# so this always reads as the hoop spinning in its own hole rather than tumbling.
	node.rotate_object_local(Vector3.UP, SPIN_RAD_S * delta)

	var fwd: Vector3 = active["forward"]
	var pos: Vector3 = active["pos"]
	var rel: Vector3 = _player.global_position - pos
	var along := rel.dot(fwd)
	var perp := (rel - fwd * along).length()
	if absf(along) <= GATE_HALF_THICK_M and perp <= GATE_RADIUS_M:
		_pass_ring()


# ============================================================================= passing
func _pass_ring() -> void:
	var it: Dictionary = _items.pop_front()
	_done += 1
	# Persist FIRST, celebrate second - the system header's rule: completion must never depend on the
	# `finished` signal, which can be missed (the player reaches the rocket during the pop animation).
	if is_instance_valid(_system):
		_system.report_progress(_done, _total)
	AudioManager.play_sfx("pickup")
	var last := _items.is_empty()
	if not last:
		_set_beacon(_items[0], true)
	var node: Node3D = it["node"]
	if is_instance_valid(node):
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3.ONE * 1.3, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector3.ONE * 0.01, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(node.queue_free)
		if last:
			tw.tween_callback(_finish)
	elif last:
		_finish.call_deferred()


func _finish() -> void:
	if _system == null or not is_instance_valid(_system):
		return
	AudioManager.play_sfx("quest_complete", -3.0)
	_system.report_finished(true)


func _set_beacon(it: Dictionary, on: bool) -> void:
	var beacon: Variant = it.get("beacon")
	if beacon is MeshInstance3D:
		(beacon as MeshInstance3D).visible = on


# ============================================================================= spawning
## One hoop: its node, its gate body mesh and its (initially hidden) beacon quad.
func _spawn(pos: Vector3, fwd: Vector3, body: Mesh, body_mat: Material, beacon_mat: Material) -> Dictionary:
	var node := Node3D.new()
	node.name = "Hoop"
	add_child(node)
	node.global_position = pos
	# Y = the through-direction, so the hoop stands facing the way you fly it - see `DecoKit.axis_basis`.
	node.global_basis = DecoKit.axis_basis(fwd)

	var mi := MeshInstance3D.new()
	mi.mesh = body
	mi.material_override = body_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)

	var beacon := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(BEACON_SIZE_M, BEACON_SIZE_M)
	beacon.mesh = q
	beacon.material_override = beacon_mat
	beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.visible = false
	node.add_child(beacon)

	return {"node": node, "pos": pos, "forward": fwd, "beacon": beacon}


# ============================================================================= art
## One vertex-coloured mesh per flavour, cached on the script - every course of every neighbour of
## this flavour reuses the same Mesh/Material resources, same pattern as catch_game.gd.
static var _meshes: Dictionary = {}
static var _body_mats: Dictionary = {}
static var _beacon_mats: Dictionary = {}


static func _body_mesh(flavour: String) -> Mesh:
	if _meshes.has(flavour):
		return _meshes[flavour]
	var f: Dictionary = FLAVOURS.get(flavour, FLAVOURS[DEFAULT_FLAVOUR])
	var body := Color(str(f["body"]))
	var accent := Color(str(f["accent"]))
	var kit := DecoKit.new()
	_build_gate(kit, body, accent)
	var mesh := kit.commit()
	_meshes[flavour] = mesh
	return mesh


## A checkpoint gate, not a bolt / lantern / pod: the outer hoop, a smaller accent band nested
## inside it, and four studs around the rim. Reads as "fly through here" at gameplay distance, and
## nothing here is a shape catch_game.gd uses.
static func _build_gate(kit: DecoKit, body: Color, accent: Color) -> void:
	kit.torus(Vector3.ZERO, RING_R, RING_TUBE_R, body, Basis.IDENTITY, 22, 6)
	kit.torus(Vector3.ZERO, RING_R * ACCENT_R_SCALE, ACCENT_TUBE_R, accent, Basis.IDENTITY, 20, 4)
	for i in 4:
		var az := TAU * float(i) / 4.0 + TAU / 8.0
		var p := Vector3(cos(az), 0.0, sin(az)) * RING_R
		kit.sphere(p, STUD_R, accent.lightened(0.12), Vector3.ONE, 8)


## The same shared decoration surface every prop in the game uses (DecoItem.body_material()) - see
## catch_game.gd's own comment on why `material_override` is not optional here.
static func _body_material(flavour: String) -> Material:
	if _body_mats.has(flavour):
		return _body_mats[flavour]
	var m: Material = DecoItem.body_material()
	_body_mats[flavour] = m
	return m


## Soft additive glow disc, billboarded, filling the armed hoop's opening. Same recipe and the same
## alpha as catch's halo (`catch_game.gd._halo_material`) - already measured clean against the
## palette gates on three worlds at this value.
static func _beacon_material(glow: Color) -> Material:
	var key := glow.to_html(false)
	if _beacon_mats.has(key):
		return _beacon_mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(glow.r, glow.g, glow.b, BEACON_ALPHA)
	m.albedo_texture = DecoItem.soft_dot_texture()
	m.disable_receive_shadows = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	_beacon_mats[key] = m
	return m


# ============================================================================= QA
## Prints the armed hoop's position and the player's along/perp offsets against its gate - the
## measurement behind "fly through in order". `along` inside +-GATE_HALF_THICK_M and `perp` inside
## GATE_RADIUS_M means the NEXT frame would pass it.
func debug_report(tag: String = "") -> void:
	var active_pos := Vector3.INF
	var along := 0.0
	var perp := 0.0
	if not _items.is_empty():
		var it: Dictionary = _items[0]
		var node: Node3D = it["node"]
		if is_instance_valid(node):
			active_pos = node.global_position
			if is_instance_valid(_player):
				var fwd: Vector3 = it["forward"]
				var rel: Vector3 = _player.global_position - active_pos
				along = rel.dot(fwd)
				perp = (rel - fwd * along).length()
	print("RINGRUN %s flavour=%s done=%d/%d left=%d active=%s along=%.2f perp=%.2f gate_r=%.2f gate_half=%.2f" % [
		tag, _flavour, _done, _total, _items.size(), str(active_pos), along, perp, GATE_RADIUS_M, GATE_HALF_THICK_M])
