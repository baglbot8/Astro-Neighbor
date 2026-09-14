extends Node3D
## CATCH THE RUNAWAYS - the first mini-game (docs/CORE_LOOP.md "Mini-games instead of fetch trips",
## decided 2026-09-12; docs/BUILD_PLAN.md Phase 3).
##
## N things belonging to a neighbour have come loose and are drifting round their world at glide
## height - Bolt's bolts off his machines, Zorp's river lights, Grig's seed pods off the terraces,
## Fen's glow moths, Vela's warm sparks. You jump, light the jetpack and fly through them. Touching
## one catches it. They drift along great circles, so every one of them goes over the horizon and
## comes back to where it started; there is no timer, nothing is ever lost, and there is no way to
## fail. Catching the last one finishes the game. Started and owned by MinigameSystem - read that
## file's header first.
##
## THIS FILE'S FLAVOURS TABLE IS THE ONE SOURCE OF TRUTH for both mini-games (added 2026-09-13, the
## Phase 3 brief: a new look was being added twice, once here and once as ring_game.gd's own copy of
## the same three keys, and the two could drift). `ring_game.gd` reads `FLAVOURS` from THIS script
## via `preload(...).FLAVOURS` rather than keeping its own dictionary - see that file's own comment.
## Add a new look ONCE, here, and both games pick it up.
##
## ============================================================================== CONFIG (all optional)
##   "count": 5                 how many runaways. 3-8 is the useful range.
##   "done": 2                  how many are ALREADY caught (resuming a half-played game).
##   "flavour": "bolt"          which art: "bolt" (Bolt), "light" (Zorp), "pod" (Grig), "moth" (Fen),
##                              "spark" (Vela). Unknown flavours fall back to "bolt" with a warning.
##   "label": "bolt"            noun for the toasts, singular. Default: the flavour's own.
##   "label_plural": "bolts"    ...and plural.
##   "title": "Bolt's bolts"    the line on the progress pill. Default "Catch the <plural>".
##   "near": [x, y, z]          planet-local direction they START clustered around (the neighbour's
##                              yard, say). Left out, they start spread over the whole planet.
##   "near_radius_m": 10.0      how far from "near" they may start.
##   "speed": 1.5               drift speed in m/s along the ground. Clamped to DRIFT_SPEED_RANGE;
##                              0 parks them (a test affordance, not a real step - see that const).
##   "height": 3.2              metres above the ground under them. Clamped to HEIGHT_RANGE.
##   "seed": 12345              fixes the layout. Default: hashed from the owner and the planet, so
##                              the same save always gets the same start and two captures match.
##
## ============================================================================== WHY THESE NUMBERS
## Everything here is set by the jetpack, which is NOT changed (docs/STYLE_GUIDE.md R2.8, and the
## brief: its numbers are tuned and the ceiling is load-bearing). Measured from src/player/player.gd:
##   jump apex          JUMP_VELOCITY^2 / 2g = 8.5^2 / 60   = 1.20 m
##   climb              BOOST_RISE_SPEED 5.6 m/s up to BOOST_CLIMB_HEIGHT 3.8 m, then it latches
##   float              BOOST_FALL_SPEED 0.75 m/s down, air control 0.92, horizontal speed 7.0 m/s
##   hard ceiling       BOOST_MAX_HEIGHT 4.6 m (no thrust above it at all)
##   fuel               BOOST_BURN_TIME 2.8 s, refilled by landing
## A full tank is therefore about 0.7 s of climb to 3.8 m and 2.1 s of float down to about 2.2 m,
## covering ~19 m of ground. GLIDE_HEIGHT_M 3.2 with BOB_M 0.3 puts the runaways at 2.9-3.5 m: right
## through the middle of that glide, above the tallest decoration (2.62 m, beacon_tower), below the
## climb latch and well under the ceiling. They are never at a height that needs the ceiling.
##
## "REACHABLE ONLY BY GLIDING, NEVER BY WALKING" IS A RULE, NOT A HEIGHT, and that is deliberate.
## Height alone cannot promise it on a sphere with terrain: a player standing on a plateau (+0.72 m)
## beside a runaway drifting over a crater floor (-0.5 m) is already 1.2 m closer to it than the flat
## case, and a 1.20 m jump plus the catch radius would reach. So the catch also asks the jetpack:
## `Player.is_boosting()`, or within CATCH_GRACE_S of the thruster going out. Walking and jumping
## never light it, on any terrain, with no fitted constant anywhere. The grace exists so that a tank
## running dry a fifth of a second before you reach one does not eat the catch; it is 2 / the
## jetpack's own BOOST_SPOOL_DOWN, i.e. about as long as the plume takes to die.

## Metres above the ground under it, and how far it bobs either side.
const GLIDE_HEIGHT_M := 3.2
const BOB_M := 0.30
## A content writer's "height" is clamped to this. The ceiling keeps them under the jetpack's climb
## latch (3.8 m), so a catch never needs the hard ceiling. The floor was 2.8 - above the tallest
## decoration (2.62 m) - and was MEASURED too thin: at 2.8 with the bob at its lowest, a full jump
## (feet 1.25 m, measured over 18 apex samples) closed to 1.33 m against a 1.15 m catch radius, a
## margin of 0.18 m. At 3.0 the same worst case is 1.45 m, a margin of 0.30 m.
const HEIGHT_RANGE := Vector2(3.0, 3.6)
const BOB_HZ := 0.30
## How close the astronaut's feet have to get. Generous on purpose: at the glide's 7 m/s this is a
## ~0.33 s window, which is what makes it catchable with a thumb on a phone.
const CATCH_RADIUS_M := 1.15
## Seconds after the thruster goes out that a touch still counts. 2 / Player.BOOST_SPOOL_DOWN.
const CATCH_GRACE_S := 2.0 / 5.0

const DRIFT_SPEED_MS := 1.5
## 0 parks them where they start. That is a TEST affordance (it makes "can a jump reach one?" a
## fixed-geometry question instead of a chase), not a shape for a real step - a parked runaway is a
## floating collectible, and the drift is the game.
const DRIFT_SPEED_RANGE := Vector2(0.0, 3.0)
## Per-runaway variation on the drift speed, so the set never moves as one block.
const DRIFT_VARY := 0.18
const SPIN_RAD_S := 0.55
const COUNT_RANGE := Vector2i(1, 12)
const DEFAULT_COUNT := 5
const DEFAULT_NEAR_RADIUS_M := 10.0
## Start spots: this many random candidates, then farthest-point sampling for the spread.
const SPOT_CANDIDATES := 40
## Ground distance the FIRST runaway starts from the astronaut. Well outside the catch radius, and
## inside the horizon on every world (the smallest is grig, radius 9.5), so the game opens with one
## of them on screen - see `_pick_start_dirs`.
const FIRST_SPOT_M := 7.0

## Art. One mesh and one material per flavour, shared by every runaway of that flavour, so a runaway
## is TWO draw calls: its body and a soft billboarded halo.
##
## A third piece - a soft additive pool on the ground under each one, as the "fly to here" cue - was
## built and then cut. At the alpha the palette gates leave room for (0.10) it was invisible in the
## capture over Bolt's chrome and Grig's chalk, so it was a node and a draw call each for nothing.
## The pill's chevron does that job instead, for one triangle on the whole screen.
const BODY_SIZE_M := 0.52
const HALO_SIZE_M := 1.45
const HALO_ALPHA := 0.15

## docs/STYLE_GUIDE.md: no dominant swatch above S 0.60, saturation p90 <= 0.68. Every colour here is
## measured under both: the strongest is Vela's signature amber glow (spark) at S 0.574 - itself
## reused verbatim, not invented (see "spark" below), and still comfortably under the 0.60 cap. Spark's
## "body"/"accent" were SWAPPED 2026-09-13 (see that entry's own comment) - same two hexes, same
## measured saturations, now assigned to the roles that render correctly under Vela's cool light.
const FLAVOURS := {
	"bolt": {
		"body": "#b3acc0", "accent": "#cf9a5f", "glow": "#dcb887",
		"label": "bolt", "plural": "bolts",
	},
	"light": {
		"body": "#8f79c9", "accent": "#c3b0f0", "glow": "#b9a6ee",
		"label": "river light", "plural": "river lights",
	},
	# Grig is a dry CHALK world, so the first pod - pale ochre body, green tuft - measured as a lemon
	# against a wall the same colour. Body and tuft are swapped: a sage-green pod with a pale down
	# tuft separates from the chalk instead of blending into it.
	"pod": {
		"body": "#93a877", "accent": "#e6ddbd", "glow": "#dcd3b4",
		"label": "seed pod", "plural": "seed pods",
	},
	# Fen's Long Dusk (docs/NEXT_WORLDS.md). REVISED 2026-09-13 after the critic's round-2 measurement
	# ON FEN ITSELF: the first body tone (#b7a58c, S 0.235 V 0.718 raw) sat too close in both value
	# and saturation to Fen's own PALEST ground tone (ground_color_low = S 0.167 V 0.847, measured off
	# fen.tres) to read as pale against it, and rendered rust-brown under Fen's warm sun_color
	# (1.0, 0.745, 0.526). Seen from above - the real gameplay camera angle, not "seen from below
	# against the sky" as this comment used to assume; that assumption was never checked against the
	# ground and was wrong - it had the lowest contrast of any flavour on its own world. Fix: the
	# whole palette moved one step paler - "body" is now the old "accent" tone (already proven pale
	# enough for its old job as the wing's small bright mark), and a new "accent" sits between it and
	# "glow", which is unchanged. See _build_moth()'s own header for why "body" still carries the wing
	# rather than switching to the palest colour outright.
	"moth": {
		"body": "#e6d4a8", "accent": "#ecddb4", "glow": "#f2e6bf",
		"label": "glow moth", "plural": "glow moths",
	},
	# Vela's Still Frost: the one warm thing on a cold blue world. REVISED 2026-09-13 after the
	# critic's round-2 measurement: the first cut put the warm colour ("accent") on a thin waist band
	# around a body built from the dark ember tone, so the object read as MOSTLY dark - and Vela's own
	# light (sun_color (0.91,0.93,0.98), ambient_color (0.49,0.55,0.71), both measured off vela.tres
	# and both cool, with no warm bounce anywhere to lift a dark warm-brown) rendered that dark
	# majority near-black. Fix: "body" and "accent" are SWAPPED - same two hexes, now putting the
	# amber on the MAJORITY surface and the dark ember on a minority trim; see _build_spark()'s own
	# header for the shape change that went with it. "glow" (her signature amber #d8a25c, verbatim -
	# the SAME hex as vela_model.gd's AMBER and the relay masts' lamp glow in planet_props.gd's
	# _vela(), reused rather than reinvented so the spark reads as HER light) is unchanged.
	"spark": {
		"body": "#e0a868", "accent": "#7a5a3e", "glow": "#d8a25c",
		"label": "warm spark", "plural": "warm sparks",
	},
}
const DEFAULT_FLAVOUR := "bolt"

## Per-world DEFAULT flavour for both mini-games - which look a planet suggests when nothing more
## specific picks one. ADDED 2026-09-13 (critic round 2, BLOCKING): `src/ui/pause/dev_menu.gd` kept
## its OWN small "planet id -> flavour" map for its "Play: catch the runaways" / "Play: ring run"
## dev-menu rows, and it had drifted - "fen" and "vela" were both missing, so neither new look could
## be previewed on its own world from the phone's dev menu. That is exactly the two-copies-can-drift
## risk this file's FLAVOURS table exists to prevent (see this file's header comment), one level up,
## so the fix belongs in the same place: ONE table, here.
##
## FIXED 2026-09-13 (Phase 3a polish): `_play_minigame()`'s own lookup in `dev_menu.gd` now reads
## this table live instead of a hand-copied literal - `ResourceLoader.exists(path)` guarded, then
## `load(path).get_script_constant_map()`, NEVER `preload(...)`, because that file must still parse
## in a build with `src/minigames/**` removed (its own PHASE 2/3 GUARD rule, which a static preload
## would break outright). See `dev_menu.gd::_minigame_flavour_for`.
##
## `dev_menu.gd`'s own `MINIGAME_FLAVOURS` const is GONE now too (critic round 2, BLOCKING: round 1
## left it in place, reasoning that `replay_board.gd`'s dev stand-in board entries read that exact
## const NAME via `get_script_constant_map()` reflection, which can only see a CONST, and that a
## guarded runtime load could not populate one to replace it with - true, but beside the point: that
## stand-in lookup only runs for a mini-game kind with no real project step yet, and every kind
## already has one (`src/projects/data/bolt.gd`, `zorp.gd`, `grig.gd`, `fen.gd`, `vela.gd` - one
## each), so the lookup is never reached and its fallback to "bolt" when the const is simply absent
## costs nothing observable. A planet not listed here has no mini-game content yet; callers fall
## back to "bolt" for an unknown id, the same way `FLAVOURS.get(id, FLAVOURS["bolt"])` already does
## elsewhere in this file.
const PLANET_DEFAULT_FLAVOUR := {
	"bolt": "bolt",
	"zorp": "light",
	"grig": "pod",
	"fen": "moth",
	"vela": "spark",
}

var _system: MinigameSystem
var _planet: Planet
var _player: Node3D
var _flavour: String = DEFAULT_FLAVOUR
var _label: String = "bolt"
var _plural: String = "bolts"
var _title: String = ""
var _total: int = 0
var _done: int = 0
var _height: float = GLIDE_HEIGHT_M
var _catch_r2: float = CATCH_RADIUS_M * CATCH_RADIUS_M
var _grace: float = 0.0
var _t: float = 0.0
## One entry per LIVE runaway. Freed entries are removed, so `_items.size()` is what is left.
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
		push_warning("catch_game: unknown flavour '%s', using '%s'" % [_flavour, DEFAULT_FLAVOUR])
		_flavour = DEFAULT_FLAVOUR
	var f: Dictionary = FLAVOURS[_flavour]
	_label = str(config.get("label", f["label"]))
	_plural = str(config.get("label_plural", f["plural"]))
	_title = str(config.get("title", ""))
	if _title == "":
		_title = "Catch the %s" % _plural

	_total = clampi(int(config.get("count", DEFAULT_COUNT)), COUNT_RANGE.x, COUNT_RANGE.y)
	_done = clampi(int(config.get("done", 0)), 0, _total)
	_height = clampf(float(config.get("height", GLIDE_HEIGHT_M)), HEIGHT_RANGE.x, HEIGHT_RANGE.y)
	var speed := clampf(float(config.get("speed", DRIFT_SPEED_MS)), DRIFT_SPEED_RANGE.x, DRIFT_SPEED_RANGE.y)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(config["seed"]) if config.has("seed") \
		else hash([str(config.get("owner", "")), _planet.data.id, _planet.data.seed, _total])

	# A resumed game spawns only what is LEFT. Which particular ones were caught is not saved and
	# does not matter - they are interchangeable, and the host only ever persists the count.
	var left := _total - _done
	if left > 0:
		var dirs := _pick_start_dirs(rng, left, config)
		var body := _body_mesh(_flavour)
		var body_mat := _body_material(_flavour)
		var halo := _halo_material(Color(str(f["glow"])))
		for i in left:
			_items.append(_spawn(dirs[i], rng, speed, body, body_mat, halo))
	# The system needs the REAL total (its caller's "count" has been clamped here) before the pill is
	# drawn, and the host gets one progress_changed with the numbers it is about to see.
	_system.report_progress(_done, _total)
	if left <= 0:
		# Nothing to do: the host handed us a finished game. Report it and let the system tidy up.
		_finish.call_deferred()
	return ""


func title() -> String:
	return _title


## World position of the nearest one still out there, for the progress pill's chevron.
func hint_direction() -> Vector3:
	if _items.is_empty() or _player == null or not is_instance_valid(_player):
		return Vector3.INF
	var best := Vector3.INF
	var best_d := INF
	var from: Vector3 = _player.global_position
	for it: Dictionary in _items:
		var node: Node3D = it["node"]
		if not is_instance_valid(node):
			continue
		var d := node.global_position.distance_squared_to(from)
		if d < best_d:
			best_d = d
			best = node.global_position
	return best


## Called by the system just before this node is freed. Nothing to unwind: every node, mesh and
## material this game made is a child of it, and it never touched the player, a modal or the tree.
func outro() -> void:
	pass


# ============================================================================= per-frame
func _process(delta: float) -> void:
	# `is_instance_valid`, not `!= null`: on a planet change the whole World is freed and the order
	# within that frame is not ours to choose, so the planet can already be gone while this node has
	# one more `_process` to run.
	if _items.is_empty() or not is_instance_valid(_planet):
		return
	_t += delta
	var boosting := false
	var alive := is_instance_valid(_player)
	if alive and _player.has_method("is_boosting") and bool(_player.call("is_boosting")):
		boosting = true
	_grace = CATCH_GRACE_S if boosting else maxf(_grace - delta, 0.0)
	var can_catch := alive and _grace > 0.0
	var player_pos: Vector3 = _player.global_position if alive else Vector3.ZERO
	var centre := _planet.global_position
	var caught := -1
	for i in _items.size():
		var it: Dictionary = _items[i]
		var node: Node3D = it["node"]
		if not is_instance_valid(node):
			continue
		var theta: float = float(it["phase"]) + float(it["omega"]) * _t
		var u: Vector3 = it["u"]
		var v: Vector3 = it["v"]
		var c := cos(theta)
		var s := sin(theta)
		var dir := u * c + v * s
		# NOT `* signf(omega)`: signf(0) is 0, and a parked runaway (speed 0, the test affordance)
		# then handed Basis.looking_at a zero vector - 480 engine errors in one run before this was
		# measured. The tangent is never zero, so the sign is applied as a branch instead.
		var drift := (v * c - u * s) if float(it["omega"]) >= 0.0 else (u * s - v * c)
		# The terrain under it, exactly, every frame - NOT cached or eased. Round-robin sampling was
		# tried first and measured wrong: over Bolt's plateau banks the stale ground put a runaway
		# 2.61 m over the hill it was crossing instead of the 2.90 m floor this game promises, which
		# is under the tallest decoration. `Planet.height_at` is two noise lookups; five of them a
		# frame did not move the frame time (see the builder report's cost table).
		var ground := _planet.height_at(dir)
		var bob: float = sin(_t * TAU * BOB_HZ + float(it["bob_phase"])) * BOB_M
		var pos := centre + dir * (ground + _height + bob)
		node.global_position = pos
		node.global_basis = Basis.looking_at(drift, dir) * Basis(Vector3.UP, _t * SPIN_RAD_S + float(it["bob_phase"]))
		if caught < 0 and can_catch and pos.distance_squared_to(player_pos) <= _catch_r2:
			caught = i

	if caught >= 0:
		_catch(caught)


## Planet-local direction of one runaway at time `t`.
static func _dir_of(it: Dictionary, t: float) -> Vector3:
	var theta: float = float(it["phase"]) + float(it["omega"]) * t
	return (it["u"] as Vector3) * cos(theta) + (it["v"] as Vector3) * sin(theta)


# ============================================================================= catching
func _catch(index: int) -> void:
	var it: Dictionary = _items[index]
	_items.remove_at(index)
	_done += 1
	# Persist FIRST, celebrate second: the system's header explains why completion must never depend
	# on the finish signal arriving.
	if is_instance_valid(_system):
		_system.report_progress(_done, _total)
	AudioManager.play_sfx("pickup")
	var last := _items.is_empty()
	if not last:
		EventBus.toast_requested.emit("Caught %s %s (%d/%d)" % [_article(_label), _label, _done, _total], "")
	var node: Node3D = it["node"]
	if is_instance_valid(node):
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3.ONE * 1.45, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector3.ONE * 0.01, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
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


# ============================================================================= spawning
## One runaway: its great circle (u, v and an angular speed), its bob, and its nodes.
func _spawn(start_dir: Vector3, rng: RandomNumberGenerator, speed: float, body: Mesh,
		body_mat: Material, halo_mat: Material) -> Dictionary:
	# The great circle through `start_dir` heading toward a random tangent `v`. Keeping (u, v) as an
	# orthonormal pair means the position is two multiply-adds a frame, with no drift and no
	# accumulated error from rotating a vector over and over.
	var u := start_dir.normalized()
	var t := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	t -= u * t.dot(u)
	if t.length_squared() < 0.0001:
		t = u.cross(Vector3.UP)
		if t.length_squared() < 0.0001:
			t = u.cross(Vector3.RIGHT)
	var v := t.normalized()
	var vary := 1.0 + rng.randf_range(-DRIFT_VARY, DRIFT_VARY)
	var omega := speed * vary / maxf(_planet.radius, 1.0) * (1.0 if rng.randf() < 0.5 else -1.0)

	var node := Node3D.new()
	node.name = "Runaway"
	add_child(node)
	var mi := MeshInstance3D.new()
	mi.mesh = body
	# NOT optional. `DecoKit.commit()` returns a vertex-coloured ArrayMesh with NO material, and a
	# MeshInstance3D without one draws Godot's default white - which is exactly what the first
	# capture showed: a bleached bolt with its brass nut invisible. Every decoration in the game gets
	# this material from `DecoItem`; so does this.
	mi.material_override = body_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)
	var halo := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(HALO_SIZE_M, HALO_SIZE_M)
	halo.mesh = hq
	halo.material_override = halo_mat
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(halo)

	return {
		"node": node, "u": u, "v": v, "omega": omega,
		"phase": 0.0, "bob_phase": rng.randf() * TAU,
	}


## Start directions: spread over the whole planet, or clustered around "near". Farthest-point
## sampling from each other, so "catch them all" means flying the planet rather than turning on the
## spot - the same idea as ProjectSystem's find markers, without the free-ground test (these never
## touch the ground).
##
## THE FIRST ONE IS DELIBERATELY NOT FAR AWAY. The first version seeded the sampling from the spawn
## and the pad, which pushed every runaway to the far side: the capture of the opening frame on Bolt
## had FIVE runaways and none of them on screen, 13-23 m off, so the game began with nothing to look
## at. The first pick is now the candidate whose distance from the astronaut is closest to
## FIRST_SPOT_M, and the rest are spread from it, so there is always one in sight when the game
## starts and the others are still a flight away.
func _pick_start_dirs(rng: RandomNumberGenerator, count: int, config: Dictionary) -> Array[Vector3]:
	var near := Vector3.ZERO
	if config.has("near"):
		var raw: Variant = config["near"]
		if raw is Vector3:
			near = (raw as Vector3).normalized()
		elif raw is Array and (raw as Array).size() == 3:
			var a: Array = raw
			near = Vector3(float(a[0]), float(a[1]), float(a[2])).normalized()
	var near_r := float(config.get("near_radius_m", DEFAULT_NEAR_RADIUS_M))

	var candidates: Array[Vector3] = []
	for _i in SPOT_CANDIDATES:
		var c := Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		if c.length_squared() < 0.0001:
			continue
		c = c.normalized()
		if near != Vector3.ZERO:
			if _planet.surface_distance(c, near) > near_r:
				continue
		candidates.append(c)
	if candidates.size() < count:
		# A tight "near" radius on a big planet can starve the sample. Fill the rest around `near`
		# itself rather than leave the step unfinishable.
		var base := near if near != Vector3.ZERO else Vector3.UP
		while candidates.size() < count:
			candidates.append(_planet.random_surface_dir(rng, [], 8.0) if near == Vector3.ZERO
				else _jitter(base, rng, near_r))

	var chosen: Array[Vector3] = []
	# First pick: the one that will be on screen. `near` still wins - it only ever chooses among the
	# candidates that survived the "near" filter, so a clustered game stays clustered.
	var here := _planet.dir_of(_player.global_position) if is_instance_valid(_player) else Vector3.UP
	var first := Vector3.ZERO
	var first_err := INF
	for c: Vector3 in candidates:
		var err := absf(_planet.surface_distance(c, here) - FIRST_SPOT_M)
		if err < first_err:
			first_err = err
			first = c
	if first != Vector3.ZERO:
		chosen.append(first)
	var seeds: Array[Vector3] = []
	while chosen.size() < count:
		var best := Vector3.ZERO
		var best_d := -1.0
		for c: Vector3 in candidates:
			if chosen.has(c):
				continue
			var dmin := INF
			for s: Vector3 in seeds + chosen:
				dmin = minf(dmin, _planet.surface_distance(c, s))
			if dmin > best_d:
				best_d = dmin
				best = c
		if best == Vector3.ZERO:
			best = _planet.random_surface_dir(rng, chosen, 10.0)
		chosen.append(best)
	return chosen


func _jitter(base: Vector3, rng: RandomNumberGenerator, radius_m: float) -> Vector3:
	var ang := rng.randf() * radius_m / maxf(_planet.radius, 1.0)
	var t := Vector3(rng.randfn(), rng.randfn(), rng.randfn())
	t -= base * t.dot(base)
	if t.length_squared() < 0.0001:
		t = base.cross(Vector3.UP)
	return (base * cos(ang) + t.normalized() * sin(ang)).normalized()


# ============================================================================= art
## One vertex-coloured mesh per flavour, cached on the script so five runaways build it once.
## Static, so a set of five builds one mesh and one material each, and a second visit to the same
## world reuses them. A handful of small resources for the session; nothing per-runaway is cached.
static var _meshes: Dictionary = {}
static var _body_mats: Dictionary = {}
static var _halo_mats: Dictionary = {}


static func _body_mesh(flavour: String) -> Mesh:
	if _meshes.has(flavour):
		return _meshes[flavour]
	var f: Dictionary = FLAVOURS.get(flavour, FLAVOURS[DEFAULT_FLAVOUR])
	var body := Color(str(f["body"]))
	var accent := Color(str(f["accent"]))
	var kit := DecoKit.new()
	match flavour:
		"light":
			_build_light(kit, body, accent)
		"pod":
			_build_pod(kit, body, accent)
		"moth":
			_build_moth(kit, body, accent)
		"spark":
			_build_spark(kit, body, accent)
		_:
			_build_bolt(kit, body, accent)
	var mesh := kit.commit()
	_meshes[flavour] = mesh
	return mesh


## Bolt's: a chunky hex-head bolt, shank down, with a loose nut halfway along it. Six-sided so the
## silhouette reads as hardware and not as a pebble at gameplay distance.
static func _build_bolt(kit: DecoKit, body: Color, accent: Color) -> void:
	var s := BODY_SIZE_M
	kit.cone(Vector3(0.0, 0.10 * s, 0.0), 0.34 * s, 0.34 * s, 0.22 * s, body, Basis.IDENTITY, 6)
	kit.disc(Vector3(0.0, 0.32 * s, 0.0), 0.34 * s, body.lightened(0.10), Basis.IDENTITY, 6)
	kit.cone(Vector3(0.0, -0.62 * s, 0.0), 0.13 * s, 0.13 * s, 0.72 * s, body.darkened(0.06))
	kit.cone(Vector3(0.0, -0.40 * s, 0.0), 0.22 * s, 0.22 * s, 0.16 * s, accent, Basis.IDENTITY, 6)
	kit.disc(Vector3(0.0, -0.62 * s, 0.0), 0.13 * s, body.darkened(0.12), Basis(Vector3.RIGHT, PI))


## Zorp's: a little river light - a soft squashed lantern in a thin band, with a carry loop on top.
static func _build_light(kit: DecoKit, body: Color, accent: Color) -> void:
	var s := BODY_SIZE_M
	kit.sphere(Vector3(0.0, 0.0, 0.0), 0.40 * s, accent, Vector3(1.0, 0.86, 1.0), 14)
	kit.torus(Vector3(0.0, 0.0, 0.0), 0.40 * s, 0.06 * s, body, Basis.IDENTITY, 14, 5)
	kit.cone(Vector3(0.0, 0.30 * s, 0.0), 0.13 * s, 0.09 * s, 0.14 * s, body)
	kit.torus(Vector3(0.0, 0.52 * s, 0.0), 0.11 * s, 0.035 * s, body, Basis(Vector3.RIGHT, PI * 0.5), 12, 4)


## Grig's: a ribbed seed pod with a tuft of down on top, the way a dry terrace plant throws seed.
static func _build_pod(kit: DecoKit, body: Color, accent: Color) -> void:
	var s := BODY_SIZE_M
	kit.sphere(Vector3(0.0, 0.0, 0.0), 0.34 * s, body, Vector3(1.0, 1.30, 1.0), 12)
	kit.cone(Vector3(0.0, -0.56 * s, 0.0), 0.0, 0.16 * s, 0.14 * s, body.darkened(0.10), Basis.IDENTITY, 8)
	for i in 3:
		var a := TAU * float(i) / 3.0
		var tip := Vector3(cos(a) * 0.26 * s, 0.74 * s, sin(a) * 0.26 * s)
		kit.bar(Vector3(0.0, 0.40 * s, 0.0), tip, 0.022 * s, accent, 6)
		kit.sphere(tip, 0.075 * s, accent.lightened(0.18), Vector3(1.0, 0.7, 1.0), 8)


## Fen's: a glow moth - the light the pools lost, carried off on wings. A wide, chunky thorax between
## a tiny head and two pairs of wings held OPEN WIDE (a moth spreads flat rather than folding like a
## butterfly at rest).
##
## MEASURED THREE TIMES, all three in this file's own builder report - each round flown to a real
## catch distance (~1.5-2 m, not just "spawned nearby") and shot through several spin phases before
## judging it, because a spinning silhouette can look fine in one frame and wrong in the next:
## 1. Narrow `accent`-coloured wings measured as a firefly dot - too small to read as anything.
## 2. Widened wings, still `accent`, measured as a pale blob fusing into the halo's own glow (both
##    near-white and additive). Zorp's river light avoids this with an equally pale `accent` dome
##    only because a dome is a curved VOLUME that shades itself light-to-dark under the sun; a flat
##    wing panel has no such gradient. Fix: `body` (the darker of the pair) carries the wing, the way
##    bolt and pod already put their darker colour on the majority surface and save `accent` for a
##    small trim.
## 3. Wide `body`-toned wings ROOTED NEAR THE CENTRELINE still measured as ONE fused kite/leaf rather
##    than two wings, because the left and right roots sat only ~0.08 s apart with a thin body between
##    them - there was nothing to visually separate them. Fix, and what shipped: the thorax is wide
##    (`body` sphere at X-scale 1.0, not 0.62) and each wing roots OUTSIDE the thorax's own edge, so a
##    solid body mass sits between the wing bases in every spin phase, not just some of them.
## 4. [2026-09-13, critic round 2] All three rounds above judged the SHAPE against a neutral or sky
##    background. Measured on Fen itself, from above (the real gameplay camera angle): the shipped
##    `body` sat too close to Fen's own palest ground tone to read as pale under Fen's warm sun, and
##    rendered rust-brown instead - see the FLAVOURS entry's own comment for the numbers. That fix is
##    COLOUR-ONLY, in FLAVOURS; nothing below this point (the shape this docstring documents) moved.
## Built from explicit double-sided triangle() fans (same primitive planet_props.gd's Fen scrub
## blades use) rather than a lathed/extruded panel, so there is no basis or winding to get wrong.
static func _build_moth(kit: DecoKit, body: Color, accent: Color) -> void:
	var s := BODY_SIZE_M
	var wing := body.darkened(0.04)
	var wing_dark := body.darkened(0.26)
	# THORAX - wide on purpose (X-scale 1.0): this is the mass that keeps the two wings visually
	# separate instead of fusing into one shape, in every spin phase, not just face-on.
	kit.sphere(Vector3(0.0, -0.02 * s, 0.0), 0.155 * s, body, Vector3(1.0, 1.05, 0.72), 10)
	kit.sphere(Vector3(0.0, 0.24 * s, 0.0), 0.085 * s, body.lightened(0.06), Vector3(1.0, 0.90, 1.0), 8)
	kit.bar(Vector3(0.0, 0.29 * s, 0.02 * s), Vector3(0.09 * s, 0.46 * s, 0.08 * s), 0.010 * s, accent, 5)
	kit.bar(Vector3(0.0, 0.29 * s, 0.02 * s), Vector3(-0.09 * s, 0.46 * s, 0.08 * s), 0.010 * s, accent, 5)
	for side: float in [1.0, -1.0]:
		# FOREWING - rooted OUTSIDE the thorax (0.16 s clears the 0.155 s-radius body), so there is
		# always a visible gap of body-coloured mass between the two wing roots.
		var root_hi := Vector3(side * 0.16 * s, 0.20 * s, 0.0)
		var root_lo := Vector3(side * 0.15 * s, -0.04 * s, 0.0)
		var tip := Vector3(side * 0.70 * s, 0.16 * s, -0.14 * s)
		var tip_hi := Vector3(side * 0.50 * s, 0.42 * s, -0.20 * s)
		var tip_lo := Vector3(side * 0.40 * s, -0.14 * s, -0.20 * s)
		kit.triangle(root_hi, tip_hi, tip, wing)
		kit.triangle(root_hi, tip, root_lo, wing)
		kit.triangle(root_lo, tip, tip_lo, wing)
		# A darker notch bitten out of the tip - a real moth's forewing tip or eyespot - so the wing is
		# never one single flat swatch even before the halo touches it.
		var notch_a := tip_hi.lerp(tip, 0.45)
		var notch_b := tip_lo.lerp(tip, 0.45)
		kit.triangle(notch_a, tip, notch_b, wing_dark)
		# The one small BRIGHT mark on the wing - `accent`, used sparingly, the way bolt's nut and
		# pod's tuft are the small light note on an otherwise darker shape.
		var spot := root_hi.lerp(tip_hi, 0.42)
		var spot2 := root_hi.lerp(tip, 0.30)
		kit.triangle(root_hi, spot, spot2, accent)
		# HINDWING - smaller, lower, tucked under the forewing rather than matching it - also rooted
		# outside the thorax.
		var hroot := Vector3(side * 0.15 * s, -0.02 * s, 0.01 * s)
		var hroot_lo := Vector3(side * 0.14 * s, -0.16 * s, 0.01 * s)
		var htip := Vector3(side * 0.44 * s, -0.06 * s, -0.08 * s)
		kit.triangle(hroot, htip, hroot_lo, wing_dark)


## Vela's: a warm spark - a small faceted ember, hex-cut like Bolt's hardware because Vela's own
## world language is hard edges and flat panels, never soft blobs (planet_props.gd's _vela() header:
## "SOFT IS FOR WEATHER, HARD IS FOR MACHINERY").
##
## REBUILT 2026-09-13 (critic round 2, BLOCKING; see the FLAVOURS entry's own comment for the colour
## half of this fix). Two independent problems, one shape change each:
## 1. SIZE. The radius was a third smaller than bolt's disc (0.34 s) or light's dome (0.40 s) -
##    measured at 90 rendered body pixels at 22 m against 199-263 for the other four flavours. Both
##    cones' `r_bottom` is now 0.44 s (was 0.24 s) and the total height 0.64 s (was 0.52 s) - big
##    enough to read at the same weight as its siblings without stopping being "small". The two cones
##    MUST keep an identical `r_bottom` - they meet at y=0, and mismatched radii show a lip there.
## 2. COLOUR. `body` and `accent` were swapped in FLAVOURS (same two hexes, new roles), so what was a
##    thin amber band on a dark majority is now an amber majority with a dark trim. The waist band
##    (`accent`, now the dark ember) stays a THIN ring on purpose, the same 0.06 s it always was - a
##    trim, not competing for area with the amber it sits on. The three motes now come off
##    `body.lightened()` (amber, brightened) instead of `accent.lightened()`, which would now brighten
##    the DARK ember into a dull brown - backwards for "three short motes thrown off it": they should
##    be the single brightest thing on the object, hotter than the amber body itself.
static func _build_spark(kit: DecoKit, body: Color, accent: Color) -> void:
	var s := BODY_SIZE_M
	kit.cone(Vector3(0.0, 0.0, 0.0), 0.44 * s, 0.0, 0.36 * s, body, Basis.IDENTITY, 6)
	kit.cone(Vector3(0.0, 0.0, 0.0), 0.44 * s, 0.0, 0.28 * s, body.darkened(0.12), Basis(Vector3.RIGHT, PI), 6)
	kit.cylinder(Vector3(0.0, -0.035 * s, 0.0), 0.48 * s, 0.48 * s, 0.070 * s, accent, Basis.IDENTITY, 6)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.35
		var dir := Vector3(cos(a), 0.30, sin(a)).normalized()
		kit.bar(dir * 0.50 * s, dir * 0.80 * s, 0.032 * s, body.lightened(0.22), 5)


## The surface every runaway is drawn with - the game's own decoration material, one shared instance
## per flavour.
##
## `DecoItem.metal_material()` was tried first for Bolt's hardware and measured worse: its rim 0.42
## and spec 0.45 are tuned for a big prop standing in the light, and on a 0.5 m object seen from
## BELOW against the sky (which is where a runaway lives) it painted the head almost black with a
## hard bright edge. The matte body material keeps the shape readable from underneath, which is the
## angle that matters here.
static func _body_material(flavour: String) -> Material:
	if _body_mats.has(flavour):
		return _body_mats[flavour]
	var m: Material = DecoItem.body_material()
	_body_mats[flavour] = m
	return m


## Soft additive halo, billboarded. Low alpha on purpose: the palette gates cap blown highlights
## under 5%, and an additive white sprite is the fastest way to break them.
static func _halo_material(glow: Color) -> Material:
	var key := glow.to_html(false)
	if _halo_mats.has(key):
		return _halo_mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(glow.r, glow.g, glow.b, HALO_ALPHA)
	m.albedo_texture = DecoItem.soft_dot_texture()
	m.disable_receive_shadows = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	_halo_mats[key] = m
	return m


static func _article(word: String) -> String:
	return "an" if word != "" and "aeiou".contains(word.substr(0, 1).to_lower()) else "a"


# ============================================================================= QA
## Prints one line per live runaway: where it is, how high above the ground under it, and how far the
## astronaut is from it. This is the measurement behind "reachable only by gliding".
func debug_report(tag: String = "") -> void:
	var ph := 0.0
	var boosting := false
	if is_instance_valid(_player):
		if _player.has_method("get_ground_height"):
			ph = float(_player.call("get_ground_height"))
		if _player.has_method("is_boosting"):
			boosting = bool(_player.call("is_boosting"))
	print("CATCH %s flavour=%s done=%d/%d left=%d height=%.2f player_air=%.2f boosting=%s grace=%.2f" % [
		tag, _flavour, _done, _total, _items.size(), _height, ph, str(boosting), _grace])
	for i in _items.size():
		var it: Dictionary = _items[i]
		var node: Node3D = it["node"]
		if not is_instance_valid(node):
			continue
		var dir := _dir_of(it, _t)
		var above := (node.global_position - _planet.global_position).length() - _planet.height_at(dir)
		var d := node.global_position.distance_to(_player.global_position) if is_instance_valid(_player) else -1.0
		print("  runaway %d above_ground=%.2f dist_to_player=%.2f omega=%.4f dir=[%.4f,%.4f,%.4f]" % [
			i, above, d, float(it["omega"]), dir.x, dir.y, dir.z])
