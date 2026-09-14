extends Node3D
## THE GAME BOARD itself: the procedural prop that stands on the Commons beside the stepping stones.
## Built and placed by replay_board.gd (read that header first); this file is only the object.
##
## ============================================================================== WHERE IT STANDS
## Chosen on purpose, and MEASURED on the Commons (hub, R 21 m). Round 2, 2026-09-13.
##   * A rocket landing puts the astronaut 3.2 m off the pad centre (world.gd `_spawn_player`), facing
##     away from the pad, and the camera reseats behind them: a view over the rocket's nose with the
##     FLY gate on the right and the clothes store on the left.
##   * ANCHOR is 2.4 m along the pad->spawn great circle (the line the stones are laid on,
##     rocket_pad.gd `_build_trail`) and 4.2 m off it on the landing spot's side: on the grass strip
##     at the edge of the pad's paving, between the pad and the clothes store, 4.8 m from the pad
##     centre and nowhere near the stones. From the landing it stands left of the astronaut with the
##     FLY gate on the right - a PLAY board and a FLY board either side of you.
##   * THE FIRST ANCHOR (6.2 m along, 2.4 m off) passed every ground rule but was seen THROUGH the FLY
##     gate's left post and a plaza lamp. Its rendered cover at the settled landing (board drawn flat
##     magenta, counted with the world as it is and with everything else hidden): phone 24.4% of the
##     board and 29.3% of its PLAY plate hidden, desktop 20.6% and 18.1%. That is why the search now
##     has the sight rule below. Here: phone 0.6% and 2.4%, desktop 0.3% and 1.0%, and a pixel diff
##     shows the rest is only the one-pixel rim where the edge blends into a different background.
##   * WHY HERE. With the sight rule run over the whole view (every 0.4 m from 1 m behind the pad to
##     13 m out, 8 m either side), the framed spots every line reaches are: left of the landing spot,
##     between the pad and the clothes store (1.0-4.2 m along, 3.2-5.6 m off); a corner past the
##     store's topiary (6.2-7.0 along, 7.2-8.0 off); and two on the stones inside the FLY gate.
##     Everywhere else in the frame the lamp just in front of the landing spot, the store's topiary,
##     the FLY gate or the rocket cuts some lines. The gate and the corner fail the ground rules (the
##     pad, the store's plaza props). In the band, a 0.1 m survey of 2.0-3.2 along by 3.7-4.9 off
##     leaves one strip, 2.1-2.8 m along and 4.1-4.3 m off: nearer the pad the pad's clearance or the
##     Fly prompt fails, further out the clothes store's clearance. The 0.4 m survey found no other.
##   * THE RULE AGREES WITH THE RENDER, measured by moving the built board (a test-only move) after a
##     real landing, on the phone and the desktop: at 6 spots the rule clears (0 of 64 lines), 0.1-1.1%
##     of the board rendered hidden - the rim; at 6 it rejects, 5.5-60.2%, and where it counted lines
##     the blocked share tracked the render (5 of 64 lines: 5.5% and 6.4%; 37 of 64: 41.9%).
##   * Nothing else is hand-placed. `_pick_spot` runs up to three passes and prints which one won:
##       1. "framed": every rule in `_spot_problem`, SEARCH_STEP_M steps out from the anchor (8 rings),
##          then the mirror side. On the Commons as it is, the anchor itself wins.
##       2. "wide": only if nothing in pass 1 passed. The ground rules alone (`_ground_problem`), the
##          nearest legal spot to the anchor on a SEARCH_STEP_M lattice, out to as far as the spawn is
##          from the pad (12.7 m on the Commons).
##       3. "anywhere": the ground rules on a FOOTPRINT_M lattice over the rest of the world.
##     It never stands on ground that broke a rule: with no legal spot at all it is not built, and says
##     so. WHY PASS 2 EXISTS (fix round 1): a save made before the board existed may hold a
##     decoration on the strip pass 1 needs (the pre-board placement rules allowed all six of its
##     cells), and the board then stood on the raw anchor, clipping the bench. MEASURED with a
##     decoration on each of those six cells, and with the round-2 critic's one bench: pass 1 finds
##     nothing, and pass 2 stands the board on the grass beside the pad (along -0.27, lat -4.79),
##     2.67 m from the anchor, the whole search 20-26 ms. There its collider is 1.05 m clear of the
##     bench's and 1.45 m clear of the clothes store's, with 2.85 m of ground to the nearest plaza
##     prop, 5.98 m to the nearest stepping stone's centre and 5.86 m to the nearest home (Stella's);
##     it shows at the left of the phone's landing frame. Pass 3 and "not built" were only forced with
##     a stand-in decoration list (SYNTHETIC): 200-217 ms and 462-498 ms for the search on this Mac.
##   * CLEAR OF THE NEIGHBOURS' HOMES (fix round 1, `_ground_problem` "home"). On that save the ground
##     rules alone also passed cells past the strip (along 5.4-6.0, lat -5.0 to -5.6) standing only
##     1.5-2.0 m from Stella's home, where she stands most of the day. A spot must now be at least
##     FOOTPRINT_M + DecorationManager.NPC_CLEARANCE from every home: the board may not stand where a
##     decoration its size could not be put down beside a neighbour. The homes come from the
##     neighbours themselves (see `_neighbour_homes`). The measured best spot is 3.99 m from Stella's.
##     For the same reason the later passes keep DecorationManager.RESERVED_CLEARANCE from the spawn
##     point, where a loaded save stands the player (`_ground_problem` "spawn").
##   * It faces the pad centre: 25 degrees off the phone's landing camera, 19 off the desktop's.
## `Planet.register_prop` then keeps decorations (DecorationManager `spot_block_reason` "prop"), find
## markers and neighbours' wander picks (npc.gd `_spot_blocked`) off it, and a StaticBody3D on the
## decoration layer (1 << 3, the bench's and every placed item's) stops the astronaut and neighbours
## walking through it. That layer is also the camera rig's OCCLUDER_MASK, so it ghosts rather than
## hides the player, like every other prop.
##
## ============================================================================== SEEN FROM THE LANDING
## `_view_problem`, the last rule of the search. A spot passes only when, from BOTH landing cameras:
##   * THE CAMERAS are the game's own, rebuilt from its numbers: the landing spot (world.gd), the
##     facing (rocket_pad.gd `_pop_out`) and camera_rig.gd `_snap_to_target` at its desktop and its
##     mobile default distance and pitch, 45 degree lens. Checked against a real landing: the rebuilt
##     eye was 0.025 m from the real one, 0.00 degrees apart, on both screens.
##   * IN FRAME: the whole board lands inside that screen's VIEW_SAFE (clear of its HUD) and off the
##     phone's prompt pill (VIEW_KEEP_OUT), turned at most MAX_FACE_TURN_DEG from the camera.
##   * CLEAR: 64 sight lines, a SIGHT_GRID_M grid over the panel and the plate plus the star, each a
##     capsule SIGHT_MARGIN_M round, touch nothing: the real triangles of every mesh near the view
##     (plaza props, placed decorations, buildings, the pad with its FLY gate and mast), the rocket at
##     rest on the deck and the astronaut at the landing spot (see `_open_sight_space`).
## And one rule for the landing itself (`_ground_problem` "landing"): the board's use point stays
## LANDING_REACH_GAP_M beyond its reach from the landing spot, so a player who lands is still offered
## Fly. A first try at 2.6 m along / 4.0 m off put "Play a game" on the landing prompt instead.
## COST, Compatibility on this Mac: the whole search 14.0-14.2 ms when a real landing builds the
## Commons (the sight space 11.5-11.8 ms of it, 142 bodies, 128 sight lines), once per load.
##
## ============================================================================== THE LOOK
## A sibling of the Commons' own signs, not a new style: the Town Hall bulletin board's sawn timber
## (Building.WOOD / WOOD_DARK / WOOD_DEEP on Building.wood_material) and the rocket pad FLY sign's
## cream plate, tan rim and brown lettering (rocket_pad.gd SIGN_CREAM / SIGN_EDGE / SIGN_TEXT), so
## it reads as part of the plaza's signage. Structured, not bubbly (STYLE_GUIDE "Shape language"):
## a flat footing per post, two straight posts with capped tops, crisp rails, a recessed slate panel.
## The panel carries five round tokens, one per neighbour's game: a game the board lists has its
## neighbour's colour in the middle (catch_game.gd FLAVOURS "glow", the colour that game itself glows);
## a locked one is an empty dark socket. No emblems, so nothing is spoiled.
## Every colour is an existing Commons or mini-game swatch except three: the panel paint (#74767c,
## S 0.06, V 0.49), an empty socket (#50555f) and the muted gold star (#d2b064, S 0.52). The panel is
## near-neutral ON PURPOSE: facing the pad it is mostly in shade, and the Commons' shade and navy
## ambient pushed a slate-blue albedo (#65778f, S 0.30) to a rendered S 0.69 (tools/palette.py on
## the close-up, Compatibility); this albedo renders S 0.36-0.38 on the shipped wood material.
## Two lit meshes and two unshaded labels; its measured frame cost is in `_build`.

signal used(player: Node3D)

## See "WHERE IT STANDS".
const ANCHOR := Vector2(2.4, -4.2)
## See "SEEN FROM THE LANDING". world.gd `_spawn_player`: a rocket landing puts the astronaut this far
## off the pad centre along pad_dir x UP. MIRRORED, not read from the player: the board must stand in
## the same place however this load arrived (a landing, a loaded save, a walk-in).
const LANDING_SIDE_M := 3.2
const CAMERA_RIG_PATH := "res://src/player/camera_rig.gd"
## camera_rig.gd sets its lens in code (`_camera.fov = 45.0`), not as a constant.
const LANDING_FOV_DEG := 45.0
## The screens the landing frame is judged on: the desktop window and the phone's logical viewport.
const VIEW_ASPECTS := {"mobile": 1560.0 / 720.0, "desktop": 1280.0 / 720.0}
## Where the whole board must fall in each landing frame, in screen units (-1..1, +y up), clear of
## that screen's HUD as captured at the landing on 2026-09-13: on the phone the bag / journal / pause
## buttons end at x -0.62, the stick starts at y -0.36 and the Emote / Fly buttons at x 0.65; on the
## desktop the stardust and clock pills sit above y 0.82 and the prompt pill below y -0.61.
const VIEW_SAFE := {"mobile": Rect2(-0.6, -0.5, 1.2, 1.3), "desktop": Rect2(-0.85, -0.55, 1.7, 1.35)}
## Per screen, a patch the board must not touch: on the phone the interact prompt pill sits at the
## top centre (hud.gd `_layout`, measured 1560x720: x 740-806, y 90-128 px for "Fly").
const VIEW_KEEP_OUT := {"mobile": Rect2(-0.14, 0.6, 0.28, 0.4)}
## Sight lines run to a grid this fine over the panel and the plate, and each is a capsule of half
## the grid's width, so nothing thinner than the grid can slip between two lines.
const SIGHT_GRID_M := 0.19
const SIGHT_MARGIN_M := 0.1
## A mesh whose top is this low over the ground (the deck, inlays, paving, contact shadows) cannot
## hide any of the board, whose lowest sight line is 0.82 m up.
const LOW_MESH_M := 0.5
## The face may be turned from a landing camera by at most this much.
const MAX_FACE_TURN_DEG := 60.0
## The astronaut standing at the landing spot, and rocket_pad.gd DECK_Y (the rocket's rest height).
const ASTRONAUT_RADIUS_M := 0.45
const ASTRONAUT_HEIGHT_M := 1.6
const PAD_DECK_Y := 0.10
## Kept in hand past the furthest point a sight line can reach (see `_sight_range`).
const SIGHT_RANGE_SLACK_M := 0.5
## Where the board is used from: hand height just in front of the face, with a reach like the house
## mailbox's (player_home.gd, 2.05 m, shrunk there so it never took the door's prompt).
const USE_POINT := Vector3(0.0, 0.9, -0.35)
const USE_REACH_M := 2.0
## A landing must still offer the rocket ("Fly"), never the board: from the landing spot the use point
## stays this far beyond its reach (Player `_update_interact_target` picks the nearest in reach).
const LANDING_REACH_GAP_M := 0.35
const SEARCH_STEP_M := 0.2
const SEARCH_RINGS := 8
## Radius the board claims on the ground (its widest part is the 1.72 m rail, half 0.86).
const FOOTPRINT_M := 0.95
## From a neighbour's home: the board's footprint plus the room DecorationManager keeps between any
## decoration and a neighbour (see "CLEAR OF THE NEIGHBOURS' HOMES").
const HOME_CLEAR_M := FOOTPRINT_M + DecorationManager.NPC_CLEARANCE
## Extra daylight kept from any registered prop, on top of both footprints' worth of radius.
const PROP_GAP_M := 0.35
## From the stones' centre line: 0.5 m stone radius + FOOTPRINT_M + 0.6 m to walk past.
const TRAIL_CLEAR_M := 2.05
## From the pad centre: rocket_pad.gd PAD_R 2.55 + the FLY sign's 1.55 m + 0.5 m.
const PAD_CLEAR_M := 4.6
## From a Commons building's centre: its footprint reaches about 4.1 m (planet.gd
## HUB_BUILDING_FLAT_RADIUS note) + FOOTPRINT_M + a little.
const BUILDING_CLEAR_M := 5.2
## The posts are sunk POST_SINK_M, so this much ground-height difference under the footprint stays
## hidden.
const MAX_RIM_DH_M := 0.2
const MAX_SLOPE_DEG := 12.0
const POST_SINK_M := 0.25

const POST_X := 0.80
const RAIL_TOP_Y := 1.655
const RAIL_LOW_Y := 0.745
const PANEL_Y := 1.20
const PLATE_Y := 1.95
const POST_TOP_Y := 2.12
const TOKEN_R := 0.14
## Token slots as the viewer sees them (the front faces -Z, so +X is on the VIEWER'S LEFT).
const TOKEN_SLOTS: Array[Vector2] = [
	Vector2(0.48, 1.36), Vector2(0.0, 1.36), Vector2(-0.48, 1.36),
	Vector2(0.24, 1.00), Vector2(-0.24, 1.00),
]

const WOOD := Color("#c08b52")         # Building.WOOD
const WOOD_DARK := Color("#8a5f37")    # Building.WOOD_DARK
const WOOD_DEEP := Color("#6a4726")    # Building.WOOD_DEEP
const STONE_DEEP := Color("#9c9179")   # Building.STONE_DEEP
const METAL_DARK := Color("#5d6678")   # Building.METAL_DARK
const SIGN_CREAM := Color("#e6d8ae")   # rocket_pad.gd SIGN_CREAM
const SIGN_EDGE := Color("#c9ad74")    # rocket_pad.gd SIGN_EDGE
const SIGN_TEXT := Color("#6b5232")    # rocket_pad.gd SIGN_TEXT
const PANEL := Color("#74767c")
const TOKEN_OFF := Color("#50555f")
const STAR := Color("#d2b064")
## A game's colour when its flavour is not in catch_game.gd's table (a game with its own look).
const GAME_COLORS := {
	"catch": Color("#dcb887"), "rings": Color("#b9a6ee"), "guide": Color("#f2e6bf"),
	"hunt": Color("#9cc4d4"), "call": Color("#d8a25c"),
}
const CATCH_GAME_PATH := "res://src/minigames/catch_game.gd"

var planet: Planet
var interactable: Interactable
var spot_dir := Vector3.ZERO
var spot_note := ""
## Which pass of `_pick_spot` placed the board: "framed", "wide", "anywhere" or "" (not built).
var spot_pass := ""
## How long the spot search took on this load (QA).
var search_usec := 0
## QA: sight bodies built and sight lines tested by that search, and the build's share of its time.
var sight_body_count := 0
var sight_lines := 0
var sight_build_usec := 0

## The two landing cameras, {name, eye, basis, tan_x, tan_y} (see `_build_views`).
var _views: Array[Dictionary] = []
var _sight_points: Array[Vector3] = []
var _astronaut_xf := Transform3D.IDENTITY
## Every neighbour's home on this world while a spot is searched (see `_neighbour_homes`).
var _homes: Array[Vector3] = []
## The private physics space the sight lines are tested in while a spot is searched (RIDs), and the
## shapes its bodies use (kept alive while they exist).
var _space := RID()
var _sweep := RID()
var _sight_bodies: Array[RID] = []
var _sight_shapes: Array = []


## Places the board, builds it and reserves its ground. `tokens` is one {game, flavour} per game the
## board lists, in order. Builds nothing when no ground on this world passes (`is_built` is false).
func setup(p: Planet, deco: Node, tokens: Array[Dictionary]) -> void:
	planet = p
	if planet == null:
		return
	var t0 := Time.get_ticks_usec()
	_build_views()
	_homes = _neighbour_homes()
	spot_dir = _pick_spot(deco)
	_close_sight_space()
	search_usec = Time.get_ticks_usec() - t0
	if spot_dir == Vector3.ZERO:
		return
	global_transform = _board_xf(spot_dir)
	planet.register_prop(spot_dir, FOOTPRINT_M)
	_build(tokens)
	_build_collider()
	_build_interactable()


func is_built() -> bool:
	return spot_dir != Vector3.ZERO


# ============================================================================= placement
## The three passes of "WHERE IT STANDS". Returns Vector3.ZERO when none finds legal ground.
func _pick_spot(deco: Node) -> Vector3:
	var offsets: Array[Vector2] = []
	for ix in range(-SEARCH_RINGS, SEARCH_RINGS + 1):
		for iy in range(-SEARCH_RINGS, SEARCH_RINGS + 1):
			offsets.append(Vector2(ix, iy) * SEARCH_STEP_M)
	offsets.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.length_squared() < b.length_squared() or (is_equal_approx(a.length_squared(), b.length_squared()) and (a.x < b.x or (is_equal_approx(a.x, b.x) and a.y < b.y))))
	var first_problem := ""
	for side_sign: float in [1.0, -1.0]:
		for off: Vector2 in offsets:
			var along := ANCHOR.x + off.x
			var lat := (ANCHOR.y + off.y) * side_sign
			var d := dir_at(along, lat)
			var why := _spot_problem(d, deco)
			if why == "":
				return _chosen("framed", d, Vector2(along, lat), "")
			if first_problem == "":
				first_problem = why
	# Nothing near the anchor passed every rule. From here on the ground rules alone decide, and the
	# board never stands on ground that broke one.
	var wide_m := planet.surface_distance(planet.data.pad_dir.normalized(), planet.data.spawn_dir.normalized())
	var d := _nearest_legal(SEARCH_STEP_M, 0.0, wide_m, deco)
	if d != Vector3.ZERO:
		return _chosen("wide", d, along_lat_of(d), first_problem)
	d = _nearest_legal(FOOTPRINT_M, wide_m, PI * planet.radius, deco)
	if d != Vector3.ZERO:
		return _chosen("anywhere", d, along_lat_of(d), first_problem)
	spot_pass = ""
	spot_note = "not built: no legal ground (near the anchor: %s)" % first_problem
	push_warning("ReplayBoard: no ground on '%s' passes the board's rules; it is not built" % planet.data.id)
	return Vector3.ZERO


## Records and prints which pass placed the board (a print, not a warning: every pass is a valid
## outcome). The "framed" note keeps its round-2 form, "along=2.40 lat=-4.20".
func _chosen(pass_name: String, d: Vector3, at: Vector2, nearer_problem: String) -> Vector3:
	spot_pass = pass_name
	spot_note = "along=%.2f lat=%.2f" % [at.x, at.y]
	if pass_name != "framed":
		spot_note += " (%s pass, %.2f m from the anchor; the framed pass met: %s)" % [pass_name,
			planet.surface_distance(d, dir_at(ANCHOR.x, ANCHOR.y)), nearer_problem]
	print("ReplayBoard: placed by the '%s' pass, %s" % [pass_name, spot_note])
	return d


## The spot nearest the anchor that passes the ground rules, on a `step` lattice laid on the ground
## around the anchor from `r_min` to `r_max` metres out; Vector3.ZERO when there is none. Distances
## are true surface distances (each lattice point is walked out from the anchor along its own great
## circle, see `_lattice_dir`). It goes out one square ring at a time and stops as soon as no further
## ring can hold a nearer spot, so a spot 3 m away costs about 3 m of search, not the whole area.
func _nearest_legal(step: float, r_min: float, r_max: float, deco: Node) -> Vector3:
	var a := dir_at(ANCHOR.x, ANCHOR.y)
	# The lattice's axes are the anchor's own "along" and "lat" directions, so near the anchor a
	# lattice point sits by the `dir_at` grid point with the same offsets (measured 0.02 m apart at
	# 1 m out, 0.26 m at 2.7 m: `dir_at` itself stretches with distance, the lattice does not).
	var t1 := dir_at(ANCHOR.x + SEARCH_STEP_M, ANCHOR.y) - a
	t1 = (t1 - a * t1.dot(a)).normalized()
	var t2 := dir_at(ANCHOR.x, ANCHOR.y + SEARCH_STEP_M) - a
	t2 = (t2 - a * t2.dot(a) - t1 * t2.dot(t1)).normalized()
	var lo2 := r_min * r_min / (step * step)
	var hi2 := r_max * r_max / (step * step)
	var best := Vector3.ZERO
	var best_n2 := -1
	for k in int(ceil(r_max / step)) + 1:
		# Ring k holds no point nearer than k steps.
		if best_n2 >= 0 and k * k >= best_n2:
			break
		for ix in range(-k, k + 1):
			var iys: Array = range(-k, k + 1) if absi(ix) == k else [-k, k]
			for iy: int in iys:
				var n2 := ix * ix + iy * iy
				if (best_n2 >= 0 and n2 >= best_n2) or float(n2) > hi2 or float(n2) < lo2:
					continue
				var d := _lattice_dir(a, t1, t2, float(ix) * step, float(iy) * step)
				if _ground_problem(d, deco) == "":
					best = d
					best_n2 = n2
	return best


## The point `x` metres along `t1` and `y` metres along `t2` from `a`, walked on the ground: exactly
## sqrt(x^2 + y^2) metres from `a` along the great circle in that heading.
func _lattice_dir(a: Vector3, t1: Vector3, t2: Vector3, x: float, y: float) -> Vector3:
	var r := sqrt(x * x + y * y)
	if r < 1e-6:
		return a
	var ang := r / planet.radius
	return (a * cos(ang) + (t1 * x + t2 * y) / r * sin(ang)).normalized()


## The inverse of `dir_at`, for notes: (along, lat) of a direction.
func along_lat_of(d: Vector3) -> Vector2:
	var pad := planet.data.pad_dir.normalized()
	var n := pad.cross(planet.data.spawn_dir.normalized())
	if n.length_squared() < 1e-8:
		return Vector2.ZERO
	n = n.normalized()
	var v := d.normalized()
	# `dir_at`'s lat axis is -n (t x a, with t the heading toward the spawn), and it adds lat / R of it.
	var s := clampf(-v.dot(n), -0.999999, 0.999999)
	var on := (v + n * s).normalized()
	var along := atan2(pad.cross(on).dot(n), pad.dot(on)) * planet.radius
	return Vector2(along, planet.radius * s / sqrt(1.0 - s * s))


## Where each neighbour on this world stands at home. A neighbour works its home out on its own first
## physics frame (npc.gd `_place_home`), which comes after the world - and so this board - is built,
## so the board asks the neighbour's own resolver now, through the public `resolve_home_dir()`
## (npc.gd's thin wrapper over its private `_resolve_home_dir`), and never a copy of its rules that
## could drift. The resolver only computes; it also caches the neighbour's building node and wander
## bearing, the very values its first frame sets. A neighbour already placed is read as it is. One
## with no resolver and no building (a plain NpcData home) uses NpcData's home_dir. MEASURED: the
## homes found here are the ones all five Commons neighbours then stand on, to 0.0000 m.
func _neighbour_homes() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if not is_inside_tree():
		return out
	for n: Node in get_tree().get_nodes_in_group("npc"):
		var home: Variant = null
		if n.get("_placed") == true:
			home = n.get("home_dir")
		elif n.has_method("resolve_home_dir") and n.get("planet") != null:
			home = n.call("resolve_home_dir")
		else:
			var data := NpcData.get_data(str(n.get("npc_id")))
			if not data.has("building"):
				home = data.get("home_dir")
		if home is Vector3 and (home as Vector3).length_squared() > 0.01:
			out.append((home as Vector3).normalized())
	return out


## Unit direction `along` metres from the pad toward the spawn on their great circle, then `lat`
## metres off it (on the Commons, - is the side the landing spot is on).
func dir_at(along: float, lat: float) -> Vector3:
	var pad := planet.data.pad_dir.normalized()
	var spawn := planet.data.spawn_dir.normalized()
	var a := planet.step_dir(pad, spawn, along)
	var t := spawn - a * spawn.dot(a)
	if t.length_squared() < 1e-8:
		t = Vector3.RIGHT - a * Vector3.RIGHT.dot(a)
	t = t.normalized()
	var b := t.cross(a).normalized()
	return (a + b * (lat / planet.radius)).normalized()


## "" when the board may stand at `d`, otherwise the first rule it breaks.
func _spot_problem(d: Vector3, deco: Node) -> String:
	var why := _ground_problem(d, deco)
	return why if why != "" else _view_problem(d)


## The ground rules alone: water, the pad, the spawn point, the landing prompt, the stones, props,
## buildings, neighbours' homes, decorations, collectibles and the lie of the land.
func _ground_problem(d: Vector3, deco: Node) -> String:
	var pad := planet.data.pad_dir.normalized()
	var spawn := planet.data.spawn_dir.normalized()
	if planet.is_underwater(d):
		return "water"
	if planet.surface_distance(d, pad) < PAD_CLEAR_M:
		return "pad"
	# Where a loaded save puts the player (world.gd `_spawn_player`), with the room every decoration
	# keeps from it. Only the later passes can reach it: the anchor is 11.1 m away.
	if planet.surface_distance(d, spawn) < DecorationManager.RESERVED_CLEARANCE:
		return "spawn"
	if not _views.is_empty() and (_board_xf(d) * USE_POINT).distance_to(_astronaut_xf.origin) < USE_REACH_M + LANDING_REACH_GAP_M:
		return "landing"
	var n := pad.cross(spawn)
	if n.length_squared() > 1e-8:
		var off_line := absf(asin(clampf(d.dot(n.normalized()), -1.0, 1.0))) * planet.radius
		# Only the stretch the stones actually cover counts as "the trail".
		if off_line < TRAIL_CLEAR_M and planet.surface_distance(d, spawn) < planet.surface_distance(pad, spawn):
			return "trail"
	if planet.nearest_prop_distance(d) < FOOTPRINT_M + PROP_GAP_M:
		return "prop"
	for bid: String in planet.data.buildings:
		var bd := planet.building_dir(bid)
		if bd != Vector3.ZERO and planet.surface_distance(d, bd) < BUILDING_CLEAR_M:
			return "building:" + bid
	# A home sits 3-5 m in front of its building, inside what BUILDING_CLEAR_M alone would allow (see
	# "CLEAR OF THE NEIGHBOURS' HOMES"). A neighbour's later wander picks avoid the registered prop.
	for h: Vector3 in _homes:
		if planet.surface_distance(d, h) < HOME_CLEAR_M:
			return "home"
	if deco != null and deco.has_method("get_instances"):
		for rec: Dictionary in deco.call("get_instances"):
			if planet.surface_distance(d, rec["dir"] as Vector3) < FOOTPRINT_M + float(rec["footprint"]) + 0.2:
				return "decoration"
	if planet.collectibles_root != null:
		for c: Node in planet.collectibles_root.get_children():
			if c is Node3D and planet.surface_distance(d, planet.dir_of((c as Node3D).global_position)) < FOOTPRINT_M + 0.5:
				return "collectible"
	var ground := planet.ground_normal(d, FOOTPRINT_M)
	if rad_to_deg(acos(clampf(ground.dot(d), -1.0, 1.0))) > MAX_SLOPE_DEG:
		return "slope"
	var h0 := planet.height_at(d)
	var xf := planet.surface_transform(d)
	for k in 8:
		var ang := TAU * float(k) / 8.0
		var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
		var hh := planet.height_at((d + tangent * (FOOTPRINT_M / planet.radius)).normalized())
		if absf(hh - h0) > MAX_RIM_DH_M:
			return "uneven"
	return ""


# ============================================================================= seen from the landing
## The transform the board gets at `d`: standing on the ground, its face turned to the pad centre.
func _board_xf(d: Vector3) -> Transform3D:
	var pad := planet.data.pad_dir.normalized()
	return planet.surface_transform(d, planet.surface_point(pad) - planet.surface_point(d))


## Rebuilds the two cameras a rocket landing on this world hands the player, the way the game builds
## them (see "SEEN FROM THE LANDING").
func _build_views() -> void:
	_views.clear()
	var pad := planet.data.pad_dir.normalized()
	var side := pad.cross(Vector3.UP)
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	var land := (pad + side.normalized() * (LANDING_SIDE_M / planet.data.radius)).normalized()
	var feet := planet.surface_point(land)
	var up := planet.up_at(feet)
	var away := feet - planet.pad_transform().origin
	away -= up * away.dot(up)
	if away.length_squared() < 1e-6:
		return
	away = away.normalized()
	var rig := {}
	if ResourceLoader.exists(CAMERA_RIG_PATH):
		var script := load(CAMERA_RIG_PATH) as GDScript
		if script != null:
			rig = script.get_script_constant_map()
	var pivot := feet + up * float(rig.get("PIVOT_HEIGHT", 1.0))
	var tan_y := tan(deg_to_rad(LANDING_FOV_DEG) * 0.5)
	for mode: String in VIEW_ASPECTS:
		var mobile := mode == "mobile"
		var dist := float(rig.get("MOBILE_DIST_DEFAULT" if mobile else "DIST_DEFAULT", 8.6 if mobile else 7.4))
		var pitch := deg_to_rad(float(rig.get("MOBILE_PITCH_DEFAULT_DEG" if mobile else "PITCH_DEFAULT_DEG",
			34.0 if mobile else 28.0)))
		# camera_rig.gd `_snap_to_target`, line for line.
		var eye := pivot - away * cos(pitch) * dist + up * sin(pitch) * dist
		_views.append({"name": mode, "eye": eye, "basis": Basis.looking_at((pivot - eye).normalized(), up),
			"tan_x": tan_y * float(VIEW_ASPECTS[mode]), "tan_y": tan_y})
	_astronaut_xf = Transform3D(planet.surface_transform(land, away).basis, feet)
	_sight_points = _face_points()


## Board-local points the sight lines run to: a SIGHT_GRID_M grid over the painted panel and over the
## PLAY plate, and the star, all just in front of the face (which looks down -Z).
func _face_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for iy in 5:
		for ix in 9:
			out.append(Vector3(-0.76 + SIGHT_GRID_M * ix, PANEL_Y - 0.38 + SIGHT_GRID_M * iy, -0.08))
	for iy in 3:
		for ix in 6:
			out.append(Vector3(-0.475 + SIGHT_GRID_M * ix, PLATE_Y - SIGHT_GRID_M + SIGHT_GRID_M * iy, -0.08))
	out.append(Vector3(0.0, PLATE_Y + 0.36, -0.06))
	return out


## THE OCCLUDERS, as their real triangles in a private physics space that lives only while the spot
## is searched (`_close_sight_space`). Every mesh near the landing view that stands higher than
## LOW_MESH_M: the plaza's props, placed decorations, the buildings, the rocket pad (the FLY gate, the
## mast, the console), the rocket AT REST on the deck, and the astronaut at the landing spot. The
## rocket's meshes are used from where they rest, not where they are: while a landing plays it is
## still up in the sky, and the board must stand where it stands on every load. Meshes hidden when the
## world is built are left out (the pad's waypoint gem shows only to a player who has not found the
## pad, never at a landing). MEASURED 2026-09-13: a body added to a PRIVATE PhysicsServer3D space
## answers a query in the same frame under Jolt; one added to the world's own space does not until the
## next physics step, which is why the world's space is not used.
func _open_sight_space() -> void:
	if _space.is_valid():
		return
	var t0 := Time.get_ticks_usec()
	_space = PhysicsServer3D.space_create()
	PhysicsServer3D.space_set_active(_space, true)
	_sweep = PhysicsServer3D.capsule_shape_create()
	var root := get_tree().root if is_inside_tree() else null
	var roots: Array[Node] = []
	if planet.props_root != null:
		roots.append(planet.props_root)
	var pad_node: Node = null
	if root != null:
		for path: String in ["World/Decorations", "World/Buildings"]:
			var n := root.get_node_or_null(path)
			if n != null:
				roots.append(n)
		pad_node = root.get_node_or_null("World/Rocket")
		if pad_node != null:
			roots.append(pad_node)
	var rocket: Node3D = pad_node.get("rocket") as Node3D if pad_node != null else null
	var pad_point := planet.pad_transform().origin
	var reach := _sight_range(pad_point)
	var shapes := {}
	var stack: Array[Node] = roots.duplicate()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n == self or n == rocket:
			continue
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null and mi.is_visible_in_tree() and _near_view(mi.global_transform, mi.get_aabb(), pad_point, reach) \
				and _stands_up(mi.global_transform, mi.get_aabb()):
			_add_sight_body(mi.global_transform, _trimesh(mi.mesh, shapes))
		for c: Node in n.get_children():
			stack.append(c)
	if rocket != null:
		var pad_root := pad_node.get_node_or_null("Pad") as Node3D
		var rest: Variant = pad_node.get("_rest_xf")
		var rest_local: Transform3D = rest if rest is Transform3D else Transform3D(Basis.IDENTITY, Vector3(0.0, PAD_DECK_Y, 0.0))
		var rest_root := (pad_root.global_transform if pad_root != null else planet.pad_transform()) * rest_local
		var to_rocket := rocket.global_transform.affine_inverse()
		for m: Node in rocket.find_children("*", "MeshInstance3D", true, false):
			var rm := m as MeshInstance3D
			if rm.mesh != null and rm.visible:
				_add_sight_body(rest_root * (to_rocket * rm.global_transform), _trimesh(rm.mesh, shapes))
	var body := CapsuleShape3D.new()
	body.radius = ASTRONAUT_RADIUS_M
	body.height = ASTRONAUT_HEIGHT_M
	shapes["astronaut"] = body
	_add_sight_body(_astronaut_xf * Transform3D(Basis.IDENTITY, Vector3(0.0, ASTRONAUT_HEIGHT_M * 0.5, 0.0)), body)
	_sight_shapes = shapes.values()
	sight_body_count = _sight_bodies.size()
	sight_build_usec = Time.get_ticks_usec() - t0


func _exit_tree() -> void:
	_close_sight_space()


func _close_sight_space() -> void:
	for b: RID in _sight_bodies:
		PhysicsServer3D.free_rid(b)
	_sight_bodies.clear()
	if _sweep.is_valid():
		PhysicsServer3D.free_rid(_sweep)
	_sweep = RID()
	if _space.is_valid():
		PhysicsServer3D.free_rid(_space)
	_space = RID()
	_sight_shapes.clear()


## How far from the pad centre a sight line can ever pass: every line runs from a landing camera to a
## point on a board the search may try, and all of those lie inside this ball (a segment stays inside
## any ball that holds both its ends). Nothing wholly outside it can hide the board.
func _sight_range(pad_point: Vector3) -> float:
	var far := 0.0
	for v: Dictionary in _views:
		far = maxf(far, (v["eye"] as Vector3).distance_to(pad_point))
	var out := ANCHOR.length() + SEARCH_RINGS * SEARCH_STEP_M * sqrt(2.0) + 0.91
	return maxf(far, Vector2(out, 2.42).length()) + SIGHT_MARGIN_M + SIGHT_RANGE_SLACK_M


## True when any part of a mesh's box comes within `reach` of the pad centre.
func _near_view(xf: Transform3D, box: AABB, pad_point: Vector3, reach: float) -> bool:
	var world := AABB(xf * box.position, Vector3.ZERO)
	for i in 8:
		world = world.expand(xf * box.get_endpoint(i))
	return pad_point.clamp(world.position, world.end).distance_to(pad_point) < reach


## True when a mesh's top stands LOW_MESH_M or more over the ground under it.
func _stands_up(xf: Transform3D, box: AABB) -> bool:
	var centre := xf * box.get_center()
	var ground := planet.surface_point(planet.dir_of(centre))
	var up := planet.up_at(centre)
	for i in 8:
		if (xf * box.get_endpoint(i) - ground).dot(up) >= LOW_MESH_M:
			return true
	return false


## The mesh's triangles as a shape, or null when it has none with any area (Jolt refuses to build a
## shape from only degenerate triangles, and says so in the log). Cached per mesh for one search.
static func _trimesh(mesh: Mesh, cache: Dictionary) -> Shape3D:
	var key := mesh.get_instance_id()
	if cache.has(key):
		return cache[key]
	var shape: Shape3D = null
	var faces := mesh.get_faces()
	for i in range(0, faces.size() - 2, 3):
		if (faces[i + 1] - faces[i]).cross(faces[i + 2] - faces[i]).length_squared() > 1e-10:
			var concave := ConcavePolygonShape3D.new()
			concave.set_faces(faces)
			shape = concave
			break
	cache[key] = shape
	return shape


func _add_sight_body(xf: Transform3D, shape: Shape3D) -> void:
	if shape == null:
		return
	var b := PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(b, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_space(b, _space)
	PhysicsServer3D.body_add_shape(b, shape.get_rid())
	PhysicsServer3D.body_set_state(b, PhysicsServer3D.BODY_STATE_TRANSFORM, xf)
	PhysicsServer3D.body_set_collision_layer(b, 1)
	PhysicsServer3D.body_set_collision_mask(b, 0)
	_sight_bodies.append(b)


## True when anything in the sight space comes within SIGHT_MARGIN_M of the line from a to b.
func _line_blocked(a: Vector3, b: Vector3) -> bool:
	var along := b - a
	var length := along.length()
	if length < 0.01:
		return false
	var y := along / length
	var x := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
	PhysicsServer3D.shape_set_data(_sweep, {"radius": SIGHT_MARGIN_M, "height": length + 2.0 * SIGHT_MARGIN_M})
	var state := PhysicsServer3D.space_get_direct_state(_space)
	if state == null:
		return false   # cannot be judged here (physics on its own thread): the ground rules decide
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape_rid = _sweep
	q.transform = Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5)
	q.collision_mask = 1
	sight_lines += 1
	return not state.intersect_shape(q, 1).is_empty()


## "" when both landing cameras see the whole board, in the safe part of the frame, past everything;
## otherwise which rule failed and for which camera ("offscreen:mobile", "hidden:desktop").
func _view_problem(d: Vector3) -> String:
	return str(_view_report(d, true)["problem"])


## The sight rule's numbers for the board at `d`: {problem, views: [{name, rect (the board's screen
## rectangle, -1..1 +y up), face_deg, blocked, lines}]}. With `first_only` it stops at the first
## failure (the spot search); without it every line is counted (QA).
func _view_report(d: Vector3, first_only: bool) -> Dictionary:
	var out := {"problem": "", "views": []}
	if _views.is_empty():
		return out   # no pad data to judge by (a world without one): the ground rules alone
	var xf := _board_xf(d)
	var centre := xf * Vector3(0.0, 1.4, 0.0)
	var face_n := -xf.basis.z.normalized()
	var corners: Array[Vector3] = [xf * Vector3(-0.91, 0.0, 0.0), xf * Vector3(0.91, 0.0, 0.0),
		xf * Vector3(-0.91, 2.42, 0.0), xf * Vector3(0.91, 2.42, 0.0)]
	for v: Dictionary in _views:
		var name_v := str(v["name"])
		var eye: Vector3 = v["eye"]
		var basis: Basis = v["basis"]
		var rep := {"name": name_v, "rect": Rect2(), "face_deg": 0.0, "blocked": 0, "lines": _sight_points.size()}
		(out["views"] as Array).append(rep)
		var rect := Rect2()
		var behind := false
		for i in corners.size():
			var rel := corners[i] - eye
			var depth := -basis.z.dot(rel)
			if depth < 0.5:
				behind = true
				break
			var sp := Vector2(basis.x.dot(rel) / depth / float(v["tan_x"]), basis.y.dot(rel) / depth / float(v["tan_y"]))
			rect = Rect2(sp, Vector2.ZERO) if i == 0 else rect.expand(sp)
		rep["rect"] = rect
		if behind or not (VIEW_SAFE[name_v] as Rect2).encloses(rect) or (VIEW_KEEP_OUT.has(name_v) and (VIEW_KEEP_OUT[name_v] as Rect2).intersects(rect)):
			if out["problem"] == "":
				out["problem"] = "offscreen:" + name_v
			if first_only:
				return out
			continue
		rep["face_deg"] = rad_to_deg(face_n.angle_to(eye - centre))
		if float(rep["face_deg"]) > MAX_FACE_TURN_DEG:
			if out["problem"] == "":
				out["problem"] = "edge-on:" + name_v
			if first_only:
				return out
		_open_sight_space()
		for s: Vector3 in _sight_points:
			if _line_blocked(eye, xf * s):
				rep["blocked"] = int(rep["blocked"]) + 1
				if out["problem"] == "":
					out["problem"] = "hidden:" + name_v
				if first_only:
					return out
	return out


## QA: the sight rule's numbers for where the board stands (see `_view_report`). Opens and closes its
## own sight space, so call it rarely.
func debug_view() -> Dictionary:
	if planet == null:
		return {}
	var rep := _view_report(spot_dir, false)
	_close_sight_space()
	return rep


# ============================================================================= the object
## Local height of the ground under a point of the board's own footprint (0 at the centre).
func _ground_y(local_x: float, local_z: float) -> float:
	var wp := global_transform * Vector3(local_x, 0.0, local_z)
	var g := planet.surface_point(planet.dir_of(wp))
	return (global_transform.affine_inverse() * g).y


func _build(tokens: Array[Dictionary]) -> void:
	# TWO lit meshes: the timber (the painted panel shares its matte wood material) and one
	# vertex-coloured body for everything else - plate, tokens, footings, the tiny hardware. The Commons
	# already draws 710-790 calls a frame at the landing view on Compatibility, so the board stays cheap:
	# MEASURED with its visibility toggled in 90-frame windows at that camera (same run, 8 alternations,
	# twice), +5.3 and +6.0 draw calls, and render CPU inside the noise (2.58-2.60 ms shown against
	# 2.74 ms hidden). A first cut used five materials (a separate slate, metal and glow mesh); it was
	# only ever compared across two runs, whose spread (711-760 calls with no board at all) is too wide
	# to say what it cost, so no number is claimed for it.
	var wood := DecoKit.new()
	var body := DecoKit.new()
	var coin := Basis(Vector3.RIGHT, -PI * 0.5)   # a disc's axis pointing out of the front (-Z)

	for s: float in [-1.0, 1.0]:
		var x := POST_X * s
		var gy := _ground_y(x, 0.0)
		# footing: a flat stone collar the post stands in, so the contact reads on a slope
		body.cone(Vector3(x, gy - 0.08, 0.0), 0.17, 0.14, 0.16, STONE_DEEP, Basis.IDENTITY, 12)
		wood.cone(Vector3(x, gy - POST_SINK_M, 0.0), 0.085, 0.075, POST_TOP_Y - (gy - POST_SINK_M), WOOD_DARK, Basis.IDENTITY, 10)
		wood.cone(Vector3(x, POST_TOP_Y, 0.0), 0.105, 0.03, 0.15, WOOD_DEEP, Basis.IDENTITY, 10)

	# The frame: two crisp rails between the posts, a plank back, a recessed slate panel. Every flat
	# face is an EXTRUDED rounded rectangle, not an rbox: a level-0 rbox has 12 vertices, so its big
	# front face interpolates the corners' diagonal normals and shades like a pillow (the first
	# close-ups showed pale cloudy patches across the panel on every material tried).
	_slab(wood, Vector2(1.72, 0.12), 0.15, 0.03, Vector3(0.0, RAIL_TOP_Y, 0.0), WOOD)
	_slab(wood, Vector2(1.72, 0.12), 0.15, 0.03, Vector3(0.0, RAIL_LOW_Y, 0.0), WOOD)
	_slab(wood, Vector2(1.56, 0.80), 0.04, 0.02, Vector3(0.0, PANEL_Y, 0.035), WOOD_DARK)
	# the panel: painted planks on the same timber material, so a big flat face stays matte
	_slab(wood, Vector2(1.54, 0.80), 0.05, 0.02, Vector3(0.0, PANEL_Y, -0.02), PANEL)
	# a little drip lip under the low rail, for a darker underside line
	_slab(wood, Vector2(1.60, 0.05), 0.10, 0.015, Vector3(0.0, RAIL_LOW_Y - 0.085, 0.0), WOOD_DEEP)

	# five tokens, one per neighbour's game
	for i in TOKEN_SLOTS.size():
		var slot := TOKEN_SLOTS[i]
		var base := Vector3(slot.x, slot.y, -0.045)
		body.cone(base, TOKEN_R, TOKEN_R - 0.012, 0.03, SIGN_CREAM, coin, 18)
		body.torus(base + Vector3(0.0, 0.0, -0.03), TOKEN_R - 0.018, 0.012, SIGN_EDGE, coin, 18, 4)
		var core := base + Vector3(0.0, 0.0, -0.03)
		if i < tokens.size():
			body.cone(core, 0.085, 0.078, 0.014, _token_color(tokens[i]), coin, 16)
		else:
			body.cone(core, 0.07, 0.065, 0.01, TOKEN_OFF, coin, 14)
		body.sphere(base + Vector3(0.0, TOKEN_R - 0.03, -0.035), 0.013, METAL_DARK, Vector3.ONE, 6)

	# the header plate, the FLY sign's own recipe: tan rim, cream face, brown word
	for s: float in [-1.0, 1.0]:
		body.bar(Vector3(0.34 * s, RAIL_TOP_Y + 0.05, 0.0), Vector3(0.34 * s, PLATE_Y - 0.12, 0.0), 0.022, METAL_DARK, 6)
	wood.extrude(DecoKit.round_rect_poly(1.02, 0.42, 0.13, 4), 0.07, SIGN_EDGE,
		Transform3D(Basis.IDENTITY, Vector3(0.0, PLATE_Y, 0.0)))
	body.extrude(DecoKit.round_rect_poly(0.90, 0.31, 0.10, 4), 0.10, SIGN_CREAM,
		Transform3D(Basis.IDENTITY, Vector3(0.0, PLATE_Y, 0.0)))
	for s: float in [-1.0, 1.0]:
		body.sphere(Vector3(0.40 * s, PLATE_Y, -0.052), 0.018, METAL_DARK, Vector3.ONE, 6)
	# a small star on top: the one playful note, in a muted gold that stays under the S 0.60 cap
	body.bar(Vector3(0.0, PLATE_Y + 0.2, 0.0), Vector3(0.0, PLATE_Y + 0.27, 0.0), 0.018, METAL_DARK, 6)
	body.extrude(DecoKit.star_poly(0.105, 0.048, 5), 0.045, STAR,
		Transform3D(Basis.IDENTITY, Vector3(0.0, PLATE_Y + 0.36, 0.0)))

	_add_mesh(wood.commit(), Building.wood_material(Vector3.UP), "Timber")
	_add_mesh(body.commit(), Building.body_material(), "Body")
	for face in 2:
		var label := Label3D.new()
		label.name = "Word%d" % face
		label.text = "PLAY"
		label.font = UIStyle.font()
		label.font_size = 96
		label.pixel_size = 0.0030
		label.modulate = SIGN_TEXT
		label.outline_size = 0
		label.shaded = false
		label.double_sided = false
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector3(0.0, PLATE_Y - 0.005, -0.056 if face == 0 else 0.056)
		label.rotation.y = PI if face == 0 else 0.0
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(label)


## A flat rounded board `size` (x, y) and `depth` thick, centred on `at`, facing -Z and +Z.
func _slab(kit: DecoKit, size: Vector2, depth: float, corner: float, at: Vector3, color: Color) -> void:
	kit.extrude(DecoKit.round_rect_poly(size.x, size.y, corner, 2), depth, color, Transform3D(Basis.IDENTITY, at))


func _token_color(t: Dictionary) -> Color:
	var flavour := str(t.get("flavour", ""))
	if flavour != "" and ResourceLoader.exists(CATCH_GAME_PATH):
		var script := load(CATCH_GAME_PATH) as GDScript
		var table: Variant = script.get_script_constant_map().get("FLAVOURS", {}) if script != null else {}
		if table is Dictionary and (table as Dictionary).has(flavour):
			var hex := str(((table as Dictionary)[flavour] as Dictionary).get("glow", ""))
			if Color.html_is_valid(hex):
				return Color(hex)
	return GAME_COLORS.get(str(t.get("game", "")), SIGN_EDGE)


func _add_mesh(mesh: Mesh, mat: Material, part_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	return mi


func _build_collider() -> void:
	var body := StaticBody3D.new()
	body.name = "Blocker"
	body.collision_layer = 1 << 3
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.86, 2.3, 0.34)
	cs.shape = box
	cs.position = Vector3(0.0, 1.15, 0.0)
	body.add_child(cs)
	add_child(body)


func _build_interactable() -> void:
	interactable = Interactable.new()
	interactable.name = "Interactable"
	interactable.prompt_text = "Play a game"
	interactable.reach = USE_REACH_M
	# In front of the panel at hand height, so the front is the side that finds it first.
	interactable.position = USE_POINT
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	cs.shape = sphere
	interactable.add_child(cs)
	add_child(interactable)
	interactable.interacted.connect(func(who: Node3D) -> void: used.emit(who))


## "along=5.00 lat=3.00 pad=5.83 m" - where it stands and how it got there.
func debug_spot() -> String:
	if planet == null:
		return "no planet"
	if not is_built():
		return spot_note
	return "%s pad=%.2fm spawn=%.2fm prop_after=%.2f search=%.1fms (sight space %.1fms, %d bodies, %d lines)" % [spot_note,
		planet.surface_distance(spot_dir, planet.data.pad_dir.normalized()),
		planet.surface_distance(spot_dir, planet.data.spawn_dir.normalized()),
		planet.nearest_prop_distance(spot_dir), float(search_usec) / 1000.0, float(sight_build_usec) / 1000.0,
		sight_body_count, sight_lines]
