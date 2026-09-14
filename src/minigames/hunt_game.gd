extends Node3D
## SIGNAL HUNT - the third mini-game (docs/CORE_LOOP.md "More mini-games, one per neighbour", decided
## 2026-09-13). Companion to catch_game.gd / ring_game.gd on the same contract - read
## minigame_system.gd's header first.
##
## `count` spots are hidden on free, flat ground. Nothing marks where one is: hint_direction() is
## always Vector3.INF, because a chevron pointing at a hidden spot would end the hunt. Instead a pulse
## rings out from the astronaut's feet - a ring expands over the ground each beat, and the beats come
## quicker, and a little brighter, the closer the NEXT spot is. A soft tick plays with each beat for
## players with sound, but nothing depends on it (a phone may be on silent). Walk or fly onto the spot
## and it is found: a spring wells up out of the ground, a sound plays, and the next spot goes live.
## No timer, no failure. After the last find the springs stay for a moment, then drain away together
## and the hunt reports done.
##
## First use: Grig's dry chalk world, "dowse for water under the chalk". Ships one look, "spring".
##
## ============================================================================== CONFIG (all optional)
##   "count": 3                 how many spots. Clamped to COUNT_RANGE.
##   "done": 1                  how many are ALREADY found (resuming). Like catch and rings only the
##                              count is saved, so a resume reveals the FIRST `done` spots of this
##                              file's own deterministic list and hunts list[done] next (see "WHY ONLY
##                              THE NEXT SPOT IS LIVE").
##   "look": "spring"           which reveal, keyed into LOOKS. Unknown looks fall back to "spring"
##                              with a warning. A new look is ONE LOOKS entry; a new SHAPE is that
##                              entry plus one `_build_<shape>()` in the art section.
##   "dirs": [[x,y,z], ...]     explicit planet-local unit directions, in order. Skips the automatic
##                              layout (and its keep-offs) entirely; its length IS the count.
##   "found_radius_m": 1.1      how close (straight line, feet to ground point) counts as found.
##                              Clamped to FOUND_RADIUS_RANGE.
##   "label" / "label_plural"   noun for the toasts. Default: the look's own ("spring" / "springs").
##   "title"                    the line on the progress pill. Default: the look's own ("Dowse for
##                              water").
##   "seed": 12345              fixes the layout. Default: hashed from the owner, the npc, the planet
##                              and the count, so the same save always gets the same spots.
##   "npc": "grig"              whose hunt this is. Seeds the default layout, and when that neighbour
##                              lives on THIS world the layout starts from their home and keeps clear
##                              of everywhere a talk with them can happen (see "WHERE THE SPOTS GO").
##                              The hosts pass it; pass the id the story talk used.
##   "near": [x,y,z]            an explicit planet-local anchor, same shape as ring_game.gd's. Wins
##                              over "npc" as the layout's start; both keep their own clearance. Pass
##                              a FIXED point (never a live player position - see rule 1 below).
## The dev menu's {"owner", "count", "flavour"} is a valid config: "flavour" is ignored and the hunt
## starts from the world's spawn with the default look.
##
## ============================================================================== WHY ONLY THE NEXT SPOT IS LIVE
## Only `done` is persisted, so the spot at index `done` is the ONLY one that is ever live - the only
## one the pulse measures and the only one `found_radius_m` can trigger. Found spots are therefore
## always exactly `dirs[0 .. done-1]`, however the hunt was played, and a reload with "done": 1 shows
## the spring the player really found. (Round 1 hunted a shrinking pool in any order, and a resume then
## revealed a spot nobody had visited.)
##
## ============================================================================== WHERE THE SPOTS GO
## RULE 1 of the brief: free, flat, reachable ground, at least SPOT_MIN_GAP_M apart, at least
## START_CLEAR_M (along the surface, and in a straight line too) from where the astronaut stands when
## the game starts - and the same spots after a save and a reload. The start position cannot seed a
## layout that must survive a reload, so every place a HOST starts the game from is kept clear instead:
##   * spawn_dir                  a fresh world load, and the dev menu right after one.
##   * the ARRIVAL point          world.gd `_spawn_player` puts a rocket arrival ARRIVAL_STEP_OFF_M
##                                beside the pad centre; a replay from the Commons starts right there.
##                                Round 2 kept clear of the pad CENTRE only, and a spot sat 3.15 m from
##                                the real landing point. The pad centre is kept clear as well.
##   * the neighbour's talk ring  a story step starts mid-conversation, wherever their wander left
##                                them: START_CLEAR_M + wander_radius_m + NPC.TALK_REACH from their
##                                home. Round 2 left out the talk reach and measured 4.97 m.
##   * "near", when given.
## A dev-menu start after walking away from spawn is NOT covered.
##
## The spots are a CHAIN. The first sits in a band CHAIN_MAX_M - CHAIN_MIN_M wide just outside the start
## anchor's own keep-off, as near the ARRIVAL point as the band allows: a replay lands with the first
## spot inside the pulse's steep range wherever the world has good ground there, and a story start
## loses nothing (the band is the same distance from the neighbour's home all round). Every next spot is
## CHAIN_MIN_M-CHAIN_MAX_M from the one before, along the surface and in a straight line, so after each
## find the next is in the steep range too. `_pick_chain_link` tries SPOT_TRIES seeded points first,
## because they keep layouts varied. When every try misses, the band is searched POINT BY POINT, nearest
## first (`_scan_nearest`: rings and points SCAN_STEP_M apart, each distance rule skipping exactly the
## points it rules out), and only a band with no good ground at all widens - to the NEAREST good ground
## past it, by the same scan. Only a fall back to rough ground warns. Fix round 1 widened after its 60
## tries: 22 of 1008 links on the seven worlds ran past 8 m (up to 11.9 m; 9 of 80 story and replay
## links on Grig), and for every one a dense scan with its own `_spot_ok` found good ground inside the
## band. Its first spot was only the nearest of those tries, too: 93 of 160 story and replay starts on
## Bolt, Zorp, Grig and Fen had it past 8 m from the landing while good band ground lay inside 8 m.
## MEASURED, 469 layouts on all seven worlds (dev, bare, 20 story, 40 replay, 3 seeded and 2 eight-spot
## configs each; 205 identical to fix round 1's): 0 warnings; 0 of 1008 links past 8 m along the surface
## or in a line (longest 7.99 m); a first spot past 8 m from the landing with good band ground inside
## 8 m (a 0.2 m by 2 degree scan): 0 of 200 starts - Vela's 40 all are past 8 m, its band has no ground
## nearer the landing than 8.2 m. Nearest two spots 4.07 m; nearest spot to the arrival point 5.00 m
## along the surface and in a line, to spawn 5.05 / 5.01 m, to the pad 6.00 / 5.93 m, to the edge of a
## neighbour's talk ring 5.25 m; nothing solid on any spot; the ground within 0.75 m of every spring
## within 6 cm of its centre (48 samples; the rule's 8 hold it to 5 cm). On Grig a replay's first spot
## is 5.0-6.8 m from the landing (median 5.5), a story's 15.5-16.6 m from Grig's home. Every spot of 20
## story and 20 replay layouts per world (840) was reached on foot from 5 m out, 9 with a jump round an
## obstacle. `_spot_ok` agrees with an independent copy of the rules on 224,000 random points, and
## `_scan_nearest` with a brute-force walk of the same grid on 1218 scans; layouts are identical across
## processes.
##
## WHY THE LAYOUT IGNORES PROPS ADDED LATER. `Planet.register_prop` is append-only, and a find step's
## markers (project_markers.gd) are registered at runtime and stay registered after the step ends,
## until the next landing. Round 2 read every registered prop, so the same hunt measured a different
## layout once markers existed (1 of 3 spots moved) - and a reload, which rebuilds the planet without
## them, would move a found spring. The layout reads only the props the planet was BUILT with (its
## seeded scatter, collectibles included, counted by `_read_baked_props()`), identical on every load.
## What IS physically standing on a spot when the game starts - home's build bench, a placed decoration,
## a live marker post - moves only THAT spot to the nearest clear ground (`_clear_solid_blockers`, a
## physics query, so a leftover registration with nothing standing there moves nothing).
## MEASURED on Grig: 12 runtime props registered on and around the three spots moved 0 of them; a solid
## body standing on spot 1 moved spot 1 by 1.13 m and the others by 0.000 m, its links staying 6.33 and
## 7.92 m long, and removing it put all three back exactly. Something solid covered a spot in 3 of 67
## home layouts; each was moved clear with its links inside 8 m.
##
## ============================================================================== WHY THIS BEAT CURVE
## interval(d) = PULSE_MIN_S * (PULSE_MID_S / PULSE_MIN_S) ^ clamp(d / PULSE_NEAR_M, 0, 1)
##             * (PULSE_MAX_S / PULSE_MID_S) ^ clamp((d - PULSE_NEAR_M) / (PULSE_TAIL_M - PULSE_NEAR_M), 0, 1)
## One continuous, monotonic curve - nothing switches between two rates, so nothing can flicker. The
## beat is a phase that advances every frame by delta / interval(d now), so the tempo follows the
## distance continuously: a slow far beat already on its way arrives sooner if you run in. `d` is the
## larger of the straight-line and the surface distance to the live spot (the straight line alone
## flattens out on the far side of a small world, where walking barely changes it; the surface distance
## changes at walking speed everywhere; the straight line still counts height while flying over a spot).
##   * NEAR (0-8 m): 0.26 s -> 1.15 s. interval(2) / interval(8) = (0.26 / 1.15) ^ 0.75 = 0.33, under the
##     brief's 0.40. Walking in from 8 m the next beat is about twice as fast.
##   * TAIL (8-28 m): 1.15 s -> 2.0 s, 2.8% per metre. Round 2 held the beat flat past 8 m, and Grig's
##     story starts begin 15-18 m from the first spot, so the first beats said nothing. 28 m covers
##     all of Grig but its last 1.8 m (29.8 m to the far side); only the far side of Vela and the Commons
##     is flat, and only for a dev start.
## MEASURED on Grig, standing (5 beats each): 1.3 m 0.337 s, 2 m 0.380, 4 m 0.550, 6 m 0.793, 8 m 1.150,
## 12 m 1.283, 18 m 1.517, 22 m 1.693, 26 m 1.893, 29 m 2.000 - the formula to one frame. From a story
## start beside Grig (17 m out), walking at the spot: 1.40, 1.22, 0.87, 0.55, 0.40 s; walking away:
## 1.58, 1.70, 1.72 s. Round 2 from its own story start (12-18 m out): 1.15 s beat after beat walking
## away or sideways, and walking at the spot nothing changed until the astronaut was inside 8 m.
## The ring's alpha follows the near range only: PULSE_ALPHA_FAR at 8 m and beyond.
##
## ============================================================================== WHY THE RING BENDS OVER THE GROUND
## Round 2 shrank a flat ring until it fitted the flat ground, which on Grig's terraces meant 0.14 m -
## under the astronaut's boots - at 14-22% of standing spots (274 of 1356 walking beats showed nothing),
## and a flat ring on the ground under a flying astronaut fell off the bottom of the screen above ~3.3 m.
## Now the ring always opens to its full size and follows the ground instead: while it is visible, the
## ground is sampled at RING_SAMPLES points on the ring's CURRENT circle, and the ring's shader lifts
## each vertex to that height. Two rules keep the terrain from hiding it:
##   * a vertex never sits more than RING_DROP_MAX_M below the FEET. Over a terrace edge that falls
##     away, the ring stays at foot level instead of ducking behind the edge; in flight the whole ring
##     flies with the feet, and it settles back onto the ground as they land.
##   * between two samples that straddle a step (more than RING_STEP_SNAP_M apart) the ring takes the
##     HIGHER one, so a riser can never cut a segment out of it.
## MEASURED, the ring as the phone camera sees it six frames into each beat (48 points, a ray from the
## camera to each): 1004 walking beats on Grig (story and replay starts, 90-120 s of wandering each),
## Zorp and home - 0 beats without a ring, radius already 0.84 m, 0 points below the ground, 1 point of
## 48,192 hidden by terrain; the points that do hide are behind a monolith, the rocket or Grig himself.
## Flying at 1.4-3.6 m on Grig and Vela the whole ring stayed on screen (6 of 6 airborne beats, 48 of 48
## points). The mesh is one shared unit torus; radius, height and alpha are material uniforms, and the
## six vec4 height uniforms are values, not arrays, so nothing is allocated per frame.
##
## ============================================================================== WHY THE SPRING LOOKS LIKE THIS
## Round 2's spring rendered as a brown clay bowl holding a near-white disc: its rim's warm grey went
## through the toon material's albedo squaring (a warm grey squared is brown), and its water was an
## unshaded pale blue that ACES flattened to S 0.02. Now, two meshes:
##   * STONES: a low faceted collar cut round the pool and a few loose chips, in a cool chalk grey
##     through the same rock material as Grig's monoliths (`PlanetPropMeshes.rock_material`).
##   * WATER: the pool and the damp ring of wet ground around the collar, one small LIT shader in the
##     house recipe (pc_in / pc_out, the shared toon ramp, pc_light_term so the albedo lands once), so it
##     takes the world's light and time of day like the ground. Its colours were picked by measuring
##     them AS RENDERED under Grig's own light (the table at LOOKS). Thin ripple crests run outward on
##     TIME, on the GPU.
##   * the REVEAL wells up: the collar rises out of the ground, a mound of water pushes up through it and
##     spreads into the pool, the damp ring surfaces as it settles, and the mound keeps breathing. All of
##     it is node transforms on the two meshes - no per-spring material.
## MEASURED on Grig at 9:50 AM, region medians, Compatibility (Forward+ within 0.01): water #80afc8
## S 0.36 V 0.78; collar #d2c5b4 S 0.14; damp ring #a8a090 S 0.14 V 0.66. The ripple moves the pool's
## pixels by 35 codes on average between frames 0.6 s apart close up, and by 28 in a gameplay view from
## behind the astronaut 3 m away (round 2's moved fewer than 2).
##
## ============================================================================== WHY THE FINALE HOLDS
## When the system hears `report_finished` it frees this node, springs and all, in one frame. So the
## last find plays its completion sound at once but holds up to FINISH_HOLD_MAX_S (or until the player
## steps clearly off the spot), then every spring drains down along its own local down over SINK_S, and
## only then does the hunt report finished. Progress was persisted at the find, before any of this.
##
## ============================================================================== PHONE AND HEAT
## docs/OPEN_ISSUES.md 44/47: single-digit nodes, at most two draw calls per object, one shared material
## per look, no particles. Steady state is this node and the ring: two nodes, one draw call. A found
## spring is three nodes (root, stones, water) and two draw calls; its ripple and bubble run in its
## shader. The tick is AudioManager's pooled one-shot, silenced while a modal is open.
## MEASURED on this Mac, Compatibility 1560x720 on Grig: render CPU +0.01 to +0.08 ms with the ring
## pulsing at 1.6 m (four reps, other agents' Godot runs sharing the machine), draw calls +2 per spring;
## a frame of this script with the ring showing (24 `height_at` calls, 9 uniform writes) 20 us, between
## beats 0.9 us; 20 s of beats every 0.34 s left nodes and resources unchanged.
## Building a layout, once per start, 67 starts per world run one after another: median 1.0-3.8 ms by
## world (fix round 1: 0.9-1.7), at most 5.0 ms (Zorp, whose landing's steep range is searched on most
## starts); 3.0 ms on the Commons, whose spawn plaza is proven empty point by point; 11.2 ms once, on
## home, where a solid body forced the nudge search. A process's first start takes 32-39 ms in both
## versions (one-time mesh, material and shader builds).

# ============================================================================= config ranges
const COUNT_RANGE := Vector2i(1, 8)
const DEFAULT_COUNT := 3
const FOUND_RADIUS_RANGE := Vector2(0.6, 2.2)
const DEFAULT_FOUND_RADIUS_M := 1.1

# ============================================================================= placement
## Along the surface, between any two spots.
const SPOT_MIN_GAP_M := 4.0
## Along the surface AND in a straight line, from every place a host starts the game from.
const START_CLEAR_M := 5.0
## world.gd `_spawn_player`: a rocket arrival stands this far beside the pad centre.
const ARRIVAL_STEP_OFF_M := 3.2
## npc.gd's exported `wander_radius_m` default, for a neighbour whose NpcData entry leaves it out.
const NPC_WANDER_DEFAULT_M := 9.0
## One chain link, along the surface. CHAIN_MAX_M == PULSE_NEAR_M on purpose.
const CHAIN_MIN_M := 5.0
const CHAIN_MAX_M := 8.0
## Seeded candidates tried in the intended band first (they keep the layouts varied).
const SPOT_TRIES := 60
## The point-by-point search behind them (`_scan_nearest`): rings this far apart, and points this far
## apart along every ring - finer at every radius than a 0.1 m by 2 degree grid.
const SCAN_STEP_M := 0.1
## Slack kept when a broken distance rule skips the points it is guaranteed to break (`_scan_nearest`).
const SCAN_SKIP_SLACK_M := 0.001
## The coarser grid of the one search that is about a better START rather than the chain rule: ground
## inside the pulse's steep range of the landing (`_pick_chain_link` rung 2). At SCAN_STEP_M it cost
## 8-14 ms per story start on Bolt and Zorp; at this grid 2.5 ms on Zorp.
const PREFER_STEP_M := 0.25
## A spring's footprint: clearance from props and reserved zones while a spot is chosen, and the extra
## gap from every reserved centre that decorations also keep (DecorationManager.RESERVED_CLEARANCE).
const SPOT_CLEARANCE_M := 1.0
const SPOT_RESERVED_GAP_M := 1.0
## How far the ground under the stain may stray from its centre height.
const SEAT_TOLERANCE_M := 0.05
## "Something solid stands here now": the decoration and building layers (project.godot layer_names 4
## and 7) - every blocking decoration, the bench, the game board, a live find marker, a building. A
## blocked spot moves to the nearest clear point within NUDGE_REACH_M (`_clear_solid_blockers`).
const SOLID_MASK := (1 << 3) | (1 << 6)
const NUDGE_REACH_M := 2.5

# ============================================================================= the pulse
## See "WHY THIS BEAT CURVE".
const PULSE_MIN_S := 0.26
const PULSE_MID_S := 1.15
const PULSE_MAX_S := 2.0
const PULSE_NEAR_M := 8.0
const PULSE_TAIL_M := 28.0
## Additive alpha peak at touching distance and at PULSE_NEAR_M - "a little brighter" the closer.
const PULSE_ALPHA_NEAR := 0.24
const PULSE_ALPHA_FAR := 0.11
## One ring's expand-and-fade, the same length whatever the beat interval.
const RING_ANIM_S := 0.42
## The ring opens at RING_START_M (just outside the boots) and ends at RING_PEAK_M.
const RING_START_M := 0.45
const RING_PEAK_M := 1.55
const RING_TUBE_R := 0.06
## Fraction of the animation the alpha takes to come up, so a new ring never pops on at full strength.
const RING_FADE_IN := 0.08
## See "WHY THE RING BENDS OVER THE GROUND". RING_SAMPLES must stay 24: the shader reads six vec4s.
const RING_SAMPLES := 24
const RING_LIFT_M := 0.07
const RING_DROP_MAX_M := 0.15
const RING_STEP_SNAP_M := 0.2
## Measured off the shipped WAVs in round 2: ui_tick and pickup render at almost the same RMS (-14.41
## vs -14.27 dBFS) and the same peak at 0 dB, so the tick plays 6 dB down - a real half-amplitude cut
## under the pickup sound, not a trust in the shorter clip sounding quieter.
const TICK_DB := -6.0

# ============================================================================= the finale
const FINISH_HOLD_MAX_S := 2.5
const FINISH_STEP_OFF_MULT := 1.6
const SINK_S := 0.5
const SINK_DEPTH_M := 0.35

# ============================================================================= the spring
## Pool, collar and damp-ring radii and heights, in metres. The collar clears the astronaut's boots on
## every side (round 2 measured a smaller spring hiding behind the astronaut standing on it).
const POOL_R_M := 0.36
const COLLAR_R_M := 0.54
const COLLAR_H_M := 0.075
const STAIN_R_M := 0.70
const STAIN_Y_M := 0.012
## The damp ring is a very shallow cone, its rim this far below its centre: a flat disc tangent at the
## spot floats above a round world at its edge by r^2 / 2R, 0.026 m on Grig (R 9.5, the smallest).
const STAIN_EDGE_DROP_M := 0.026
const WATER_Y_M := 0.036
## The breathing bubble's height at the pool's centre. The water mesh is built around the POOL'S plane
## (local y 0, the node sitting at WATER_Y_M), so the reveal's Y scale of SURGE_SCALE stretches only the
## mound upward - and pushes the damp ring, which lies below that plane, down out of sight until the
## surge settles and it surfaces.
const MOUND_M := 0.012
const SURGE_SCALE := 11.0
const REVEAL_S := 0.75

## One entry per look. "shape" picks the mesh builder (`_build_<shape>`); the rest are sRGB colours.
## "stone" is the collar, through the rock material Grig's monoliths use. The rest are the water
## shader's, which lights them ONCE (pc_light_term), so what they render as is what was measured:
## MEASURED 2026-09-13 under Grig's own 9:50 AM light, a uniform pool from a still camera 2.6 m away,
## Compatibility and Forward+ within 0.01 S of each other. The warm sun and ACES turn a blue towards
## cyan and flatten it: authored #8cc3db (home's shallow water, S 0.36) renders #d3dbd4, S 0.04 -
## round 2's white disc. Authored -> rendered: #5282b8 -> S 0.24, #4a76b8 -> #83b0c9 S 0.35,
## #4876ae -> S 0.36, #4270b0 -> S 0.44, #3f6fa8 -> #65a9c2 S 0.48, #2c6a9c -> S 0.73.
## So "shallow" is #4a76b8 and "deep" (the centre) #3f6fa8, for a pool that renders around S 0.36.
## The damp ring the same way: a warm or neutral grey renders brown under this sun (#6f6c64 -> S 0.30,
## #5e5b54 -> S 0.41, clay again), and a cool slate renders as wet grey chalk (#566068 -> #918d84
## S 0.09 V 0.57, #646c70 -> #aca694 S 0.14 V 0.67), so "damp" is #566068 fading to "damp_edge" #646c70.
const LOOKS := {
	"spring": {
		"label": "spring", "plural": "springs", "title": "Dowse for water", "shape": "spring",
		"stone": "#bdbcb4",
		"shallow": "#4a76b8", "deep": "#3f6fa8", "ripple": "#a8cce8",
		"damp": "#566068", "damp_edge": "#646c70",
		"pulse": "#eef8f8",
	},
}
const DEFAULT_LOOK := "spring"

# Shader parameter names, as StringName constants so the per-frame writes build nothing.
const _P_RADIUS := &"ring_radius"
const _P_ALPHA := &"ring_alpha"
const _P_CURVE := &"curvature"
const _P_H := [&"h0", &"h1", &"h2", &"h3", &"h4", &"h5"]

var _system: MinigameSystem
var _planet: Planet
var _player: Node3D
var _look: String = DEFAULT_LOOK
var _label: String = "spring"
var _plural: String = "springs"
var _title: String = ""
var _total: int = 0
var _done: int = 0
var _found_r2: float = DEFAULT_FOUND_RADIUS_M * DEFAULT_FOUND_RADIUS_M

## Every spot, fixed for the life of this instance, in the order "done" resumes against.
## `_positions[i]` is `_dirs[i]`'s ground point (the terrain is static). `_found_nodes[i]` is null until
## spot i is revealed, then the node that reveal built.
var _dirs: Array[Vector3] = []
var _positions: PackedVector3Array = PackedVector3Array()
var _found_nodes: Array[Node3D] = []
var _reveal_tweens: Array[Tween] = []

## Progress to the next beat, 0..1. It advances by delta / interval_at(the distance NOW) every frame,
## so a beat that is already on its way comes sooner when you close in - see "WHY THIS BEAT CURVE".
var _beat_phase: float = 1.0
var _ring: MeshInstance3D
var _ring_mat: ShaderMaterial
var _ring_t: float = 1.0          # >= 1.0: idle and hidden between beats
var _ring_peak_alpha: float = 0.0
var _ring_h: PackedFloat32Array = PackedFloat32Array()

## Finale: `_finishing` is the hold after the last find, `_sinking` the drain before report_finished.
var _finishing: bool = false
var _sinking: bool = false
var _finish_t: float = 0.0
var _last_found_pos: Vector3 = Vector3.ZERO

## Placement scratch, filled by `_resolve_dirs` and only read while the layout is being built.
var _keep_off: Array[Dictionary] = []
var _reserved: Array[Vector3] = []
## Planet's reserved-zone radii, index for index with `_reserved`; empty when unreadable (see `_spot_reject`).
var _zone_radii: PackedFloat32Array = PackedFloat32Array()
var _baked_props: int = 0
var _prop_dirs: PackedVector3Array = PackedVector3Array()
var _prop_radii: PackedFloat32Array = PackedFloat32Array()
var _deco: DecorationManager
var _nudged: int = 0


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

	_look = str(config.get("look", DEFAULT_LOOK))
	if not LOOKS.has(_look):
		push_warning("hunt_game: unknown look '%s', using '%s'" % [_look, DEFAULT_LOOK])
		_look = DEFAULT_LOOK
	var f: Dictionary = LOOKS[_look]
	_label = str(config.get("label", f["label"]))
	_plural = str(config.get("label_plural", f["plural"]))
	_title = str(config.get("title", ""))
	if _title == "":
		_title = str(f.get("title", "Signal hunt"))
	var found_r := clampf(float(config.get("found_radius_m", DEFAULT_FOUND_RADIUS_M)), FOUND_RADIUS_RANGE.x, FOUND_RADIUS_RANGE.y)
	_found_r2 = found_r * found_r

	_dirs = _resolve_dirs(config)
	_total = _dirs.size()
	_positions.resize(_total)
	for i in _total:
		_positions[i] = _planet.surface_point(_dirs[i])
	_found_nodes.resize(_total)
	_done = clampi(int(config.get("done", 0)), 0, _total)
	# A resume shows the first `done` springs already settled - no reveal, nothing to celebrate.
	for i in _done:
		_found_nodes[i] = _build_found_node(_dirs[i])

	_build_ring(Color(str(f["pulse"])))
	_beat_phase = 1.0   # the first beat lands at once, not after a far-away wait
	_system.report_progress(_done, _total)
	if _done >= _total:
		_finish.call_deferred()
	return ""


func title() -> String:
	return _title


## ALWAYS Vector3.INF - a chevron at a hidden spot would end the hunt.
func hint_direction() -> Vector3:
	return Vector3.INF


## Nothing to unwind: every node, mesh and material is a child of this node or a script-cached shared
## resource, and the tick is AudioManager's own one-shot.
func outro() -> void:
	pass


# ============================================================================= per-frame
func _process(delta: float) -> void:
	# `is_instance_valid`, not `!= null`: on a planet change the World is freed and this node can have
	# one more `_process` first (catch_game.gd's comment).
	if not is_instance_valid(_planet) or not is_instance_valid(_player):
		return
	_advance_ring(delta)
	if _sinking:
		_finish_t += delta
		if _finish_t >= SINK_S:
			_sinking = false
			_finish()
		return
	if _finishing:
		_finish_t += delta
		var stepped_off := _player.global_position.distance_to(_last_found_pos) > sqrt(_found_r2) * FINISH_STEP_OFF_MULT
		if _finish_t >= FINISH_HOLD_MAX_S or stepped_off:
			_start_sink()
		return
	if _done >= _total:
		return
	var player_pos := _player.global_position
	if _positions[_done].distance_squared_to(player_pos) <= _found_r2:
		_find_current()
		return
	var dist := _pulse_distance(player_pos)
	_beat_phase += delta / interval_at(dist)
	if _beat_phase >= 1.0:
		# Carry the overshoot so the average rate is exact; a long hitch never queues a second beat.
		_beat_phase = minf(_beat_phase - 1.0, 0.5)
		_fire_beat(dist)


## The distance the pulse reads: the larger of the straight line and the surface distance to the live
## spot - see "WHY THIS BEAT CURVE".
func _pulse_distance(player_pos: Vector3) -> float:
	var line := _positions[_done].distance_to(player_pos)
	var arc := _planet.surface_distance(_planet.dir_of(player_pos), _dirs[_done])
	return maxf(line, arc)


static func interval_at(dist_m: float) -> float:
	var near_t := clampf(dist_m / PULSE_NEAR_M, 0.0, 1.0)
	var tail_t := clampf((dist_m - PULSE_NEAR_M) / (PULSE_TAIL_M - PULSE_NEAR_M), 0.0, 1.0)
	return PULSE_MIN_S * pow(PULSE_MID_S / PULSE_MIN_S, near_t) * pow(PULSE_MAX_S / PULSE_MID_S, tail_t)


## One beat: restarts the ring at a brightness for the current distance, ticks unless a modal (a talk,
## the bag, the pause menu) is covering the game.
func _fire_beat(dist_m: float) -> void:
	_ring_peak_alpha = lerpf(PULSE_ALPHA_NEAR, PULSE_ALPHA_FAR, clampf(dist_m / PULSE_NEAR_M, 0.0, 1.0))
	_ring_t = 0.0
	if not EventBus.is_modal_open():
		AudioManager.play_sfx("ui_tick", TICK_DB, 0.03)


## Opens the ring over RING_ANIM_S around the astronaut's feet and bends it over the ground under its
## current circle - see "WHY THE RING BENDS OVER THE GROUND".
func _advance_ring(delta: float) -> void:
	if _ring_t >= 1.0 or _ring == null:
		return
	_ring_t = minf(_ring_t + delta / RING_ANIM_S, 1.0)
	if _ring_t >= 1.0:
		_ring.visible = false
		return
	var eo := 1.0 - (1.0 - _ring_t) * (1.0 - _ring_t)          # ease-out: quick start, settling later
	var radius := lerpf(RING_START_M, RING_PEAK_M, eo)
	var alpha := _ring_peak_alpha * (1.0 - _ring_t) * smoothstep(0.0, RING_FADE_IN, _ring_t)
	var feet := _player.global_position
	var centre := _planet.global_position
	var up := (feet - centre).normalized()
	var feet_r := feet.distance_to(centre)
	var side := up.cross(Vector3.UP if absf(up.y) < 0.9 else Vector3.RIGHT).normalized()
	var fwd := side.cross(up)
	_ring.global_transform = Transform3D(Basis(side, up, fwd), feet)
	var e := radius / maxf(feet_r, 1.0)
	for i in RING_SAMPLES:
		var ang := TAU * float(i) / float(RING_SAMPLES)
		var ground := _planet.height_at(up + (side * cos(ang) + fwd * sin(ang)) * e)
		_ring_h[i] = maxf(ground - feet_r, -RING_DROP_MAX_M)
	for b in 6:
		_ring_mat.set_shader_parameter(_P_H[b], Vector4(_ring_h[b * 4], _ring_h[b * 4 + 1], _ring_h[b * 4 + 2], _ring_h[b * 4 + 3]))
	_ring_mat.set_shader_parameter(_P_RADIUS, radius)
	_ring_mat.set_shader_parameter(_P_ALPHA, alpha)
	_ring_mat.set_shader_parameter(_P_CURVE, 0.5 / maxf(feet_r, 1.0))
	_ring.visible = true


# ============================================================================= finding
## The live spot was reached. Persist FIRST (the system's header: completion never depends on the
## finish signal), then celebrate. The LAST find holds instead of reporting finished - see "WHY THE
## FINALE HOLDS".
func _find_current() -> void:
	var idx := _done
	_done += 1
	if is_instance_valid(_system):
		_system.report_progress(_done, _total)
	AudioManager.play_sfx("pickup")
	var node := _build_found_node(_dirs[idx])
	_found_nodes[idx] = node
	_reveal_tweens.append(_play_reveal(node))
	if _done >= _total:
		_last_found_pos = _positions[idx]
		_finishing = true
		_finish_t = 0.0
		AudioManager.play_sfx("quest_complete", -3.0)
	else:
		EventBus.toast_requested.emit("Found %s %s (%d/%d)" % [_article(_label), _label, _done, _total], "")


## The spring wells up: the collar rises out of the ground, the water pushes up through its middle as
## a tall mound and spreads into the pool, and the mound settles into the breathing bubble.
func _play_reveal(node: Node3D) -> Tween:
	var stones := node.get_node("Stones") as Node3D
	var water := node.get_node("Water") as Node3D
	stones.scale = Vector3(0.5, 0.15, 0.5)
	stones.position = Vector3(0.0, -COLLAR_H_M, 0.0)
	water.scale = Vector3(0.2, SURGE_SCALE, 0.2)
	water.position = Vector3(0.0, -MOUND_M * SURGE_SCALE - WATER_Y_M, 0.0)
	var tw := node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(stones, "scale", Vector3.ONE, REVEAL_S * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(stones, "position", Vector3.ZERO, REVEAL_S * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(water, "position", Vector3(0.0, WATER_Y_M, 0.0), REVEAL_S * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(water, "scale:x", 1.0, REVEAL_S).set_delay(REVEAL_S * 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(water, "scale:z", 1.0, REVEAL_S).set_delay(REVEAL_S * 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(water, "scale:y", 1.0, REVEAL_S * 1.6).set_delay(REVEAL_S * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


## Every found spring drains along its OWN local down (they sit all over a sphere).
func _start_sink() -> void:
	_finishing = false
	_sinking = true
	_finish_t = 0.0
	for tw in _reveal_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_reveal_tweens.clear()
	for n in _found_nodes:
		if n == null or not is_instance_valid(n):
			continue
		var target := n.global_position - n.global_transform.basis.y.normalized() * SINK_DEPTH_M
		var tw := n.create_tween()
		tw.set_parallel(true)
		tw.tween_property(n, "global_position", target, SINK_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(n, "scale", Vector3.ONE * 0.08, SINK_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _finish() -> void:
	if _system == null or not is_instance_valid(_system):
		return
	_system.report_finished(true)


## Stones + water, seated at `dir`, in their settled state.
func _build_found_node(dir: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "Found"
	add_child(node)
	node.global_transform = _planet.surface_transform(dir)
	var stones := MeshInstance3D.new()
	stones.name = "Stones"
	stones.mesh = _stones_mesh(_look)
	stones.material_override = PlanetPropMeshes.rock_material()
	stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(stones)
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = _water_mesh()
	water.material_override = _water_material(_look)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.position = Vector3(0.0, WATER_Y_M, 0.0)
	node.add_child(water)
	return node


static func _article(word: String) -> String:
	return "an" if word != "" and "aeiou".contains(word.substr(0, 1).to_lower()) else "a"


# ============================================================================= placement
## Every spot's planet-local direction, in order: `dirs` verbatim when usable, otherwise the seeded
## chain. Index order is what resume relies on.
func _resolve_dirs(config: Dictionary) -> Array[Vector3]:
	if config.has("dirs"):
		var raw: Variant = config["dirs"]
		if raw is Array:
			var out: Array[Vector3] = []
			for v: Variant in (raw as Array):
				var d := _read_dir(v)
				if d != Vector3.ZERO:
					out.append(d)
			if not out.is_empty():
				return out
		push_warning("hunt_game: 'dirs' had no usable entries, generating spots instead")
	var count := clampi(int(config.get("count", DEFAULT_COUNT)), COUNT_RANGE.x, COUNT_RANGE.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config["seed"]) if config.has("seed") \
		else hash([str(config.get("owner", "")), str(config.get("npc", "")), _planet.data.id, _planet.data.seed, count])
	_reserved = _planet.get_reserved_dirs()
	var radii: Variant = _planet.get("_reserved_radii")
	_zone_radii = radii if radii is PackedFloat32Array and (radii as PackedFloat32Array).size() == _reserved.size() else PackedFloat32Array()
	_deco = get_tree().root.get_node_or_null("World/Decorations") as DecorationManager
	_read_baked_props()
	var start := _resolve_anchors(config)
	var chosen: Array[Vector3] = []
	var anchor: Vector3 = start["dir"]
	var link_min := maxf(CHAIN_MIN_M, float(start["clear"]))
	var prefer: Vector3 = start["prefer"]
	for _i in count:
		var picked := _pick_chain_link(rng, anchor, link_min, chosen, prefer)
		chosen.append(picked)
		anchor = picked
		link_min = CHAIN_MIN_M
		prefer = Vector3.ZERO
	_clear_solid_blockers(chosen)
	_keep_off.clear()
	_prop_dirs = PackedVector3Array()
	_prop_radii = PackedFloat32Array()
	return chosen


## Parses a Vector3 or [x,y,z] into a normalized direction, or Vector3.ZERO when absent/unusable.
static func _read_dir(raw: Variant) -> Vector3:
	var v := Vector3.ZERO
	if raw is Vector3:
		v = raw
	elif raw is Array and (raw as Array).size() == 3:
		var a: Array = raw
		v = Vector3(float(a[0]), float(a[1]), float(a[2]))
	return v.normalized() if v.length_squared() > 0.0001 else Vector3.ZERO


## Fills `_keep_off` with every host start - see "WHERE THE SPOTS GO" - and returns the chain's start
## as {"dir", "clear", "prefer"}: "near" if given, else the neighbour's home when they live here, else
## the spawn. "clear" is that anchor's own keep-off, where the first link's band begins. "prefer" is
## the ARRIVAL point unless the host named "near": of the good ground in the first band, the spot
## nearest the landing wins, so a replay (which starts where the rocket lands) opens with the pulse
## already in its steep range, and a story start near the neighbour loses nothing - the band is the
## same distance from their home in every direction.
func _resolve_anchors(config: Dictionary) -> Dictionary:
	_keep_off.clear()
	var spawn := _planet.data.spawn_dir.normalized()
	var pad := _planet.data.pad_dir.normalized()
	var arrival := _arrival_dir()
	_add_keep_off(spawn, START_CLEAR_M)
	_add_keep_off(pad, START_CLEAR_M)
	_add_keep_off(arrival, START_CLEAR_M)
	var start := {"dir": spawn, "clear": START_CLEAR_M, "prefer": arrival}
	var npc_id := str(config.get("npc", ""))
	if npc_id != "":
		var nd := NpcData.get_data(npc_id)
		if nd.has("home_dir") and str(nd.get("planet", "")) == _planet.data.id:
			var home: Vector3 = (nd["home_dir"] as Vector3).normalized()
			var r := START_CLEAR_M + float(nd.get("wander_radius_m", NPC_WANDER_DEFAULT_M)) + NPC.TALK_REACH
			_add_keep_off(home, r)
			start = {"dir": home, "clear": r, "prefer": arrival}
	var near := _read_dir(config.get("near"))
	if near != Vector3.ZERO:
		_add_keep_off(near, START_CLEAR_M)
		start = {"dir": near, "clear": START_CLEAR_M, "prefer": Vector3.ZERO}
	return start


func _add_keep_off(dir: Vector3, r: float) -> void:
	_keep_off.append({"dir": dir, "point": _planet.surface_point(dir), "r": r})


## Exactly world.gd `_spawn_player`'s arrival spot: ARRIVAL_STEP_OFF_M beside the pad centre.
func _arrival_dir() -> Vector3:
	var pd := _planet.data.pad_dir.normalized()
	var side := pd.cross(Vector3.UP)
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	return (pd + side.normalized() * (ARRIVAL_STEP_OFF_M / _planet.data.radius)).normalized()


## The props the planet was BUILT with - see "WHY THE LAYOUT IGNORES PROPS ADDED LATER". Planet has no
## public count, so this reads its prop arrays and its ambient-occlusion index: `_build_ao_index()` runs
## once, right after the seeded scatter, and `register_prop()` never adds to it. A runtime prop is
## appended after every baked one and is missing from its own AO cell, so scanning back from the end
## finds the last baked prop. If Planet's internals ever change shape, every prop counts (round 2's
## behaviour) rather than none.
func _read_baked_props() -> void:
	var dirs: Variant = _planet.get("_prop_dirs")
	var radii: Variant = _planet.get("_prop_radii")
	var cells: Variant = _planet.get("_ao_cells")
	if not (dirs is PackedVector3Array) or not (radii is PackedFloat32Array):
		_prop_dirs = PackedVector3Array()
		_prop_radii = PackedFloat32Array()
		_baked_props = -1
		return
	_prop_dirs = dirs
	_prop_radii = radii
	_baked_props = _prop_dirs.size()
	if not (cells is Dictionary):
		return
	var cd: Dictionary = cells
	for i in range(_prop_dirs.size() - 1, -1, -1):
		var arr: Variant = cd.get(Planet._cell_key(_prop_dirs[i]))
		if arr is PackedInt32Array and (arr as PackedInt32Array).has(i):
			_baked_props = i + 1
			return
	_baked_props = 0


## One chain link from `anchor`, rung by rung - see "WHERE THE SPOTS GO":
##   1. SPOT_TRIES seeded tries in the band [link_min, link_max]: the first good one, or with `prefer`
##      the good one nearest `prefer`.
##   2. With `prefer`, when that best try is further than PULSE_NEAR_M from it (or there is none): the
##      band on a PREFER_STEP_M grid (`_scan_nearest`) on rings round `prefer`, out to PULSE_NEAR_M -
##      the good ground nearest `prefer` inside the pulse's steep range, if any. Else the best try.
##   3. No good try at all: the whole band point by point, nearest the anchor first.
##   4. No good ground anywhere in the band: the same scan past it, so the link takes the NEAREST good
##      ground beyond, out to the far side of the world.
##   5. Rough ground anywhere - the only rung that warns.
## Every rung keeps the straight line inside the band too (terrain can make it longer than the surface
## distance), except the widening rung, whose whole point is to leave the band.
func _pick_chain_link(rng: RandomNumberGenerator, anchor: Vector3, link_min: float, chosen: Array[Vector3], prefer: Vector3) -> Vector3:
	var link_max := link_min + CHAIN_MAX_M - CHAIN_MIN_M
	var far_side := PI * _planet.radius
	var best := Vector3.ZERO
	var best_d := INF
	var anchor_point := _planet.surface_point(anchor)
	for _attempt in SPOT_TRIES:
		var v := _annulus_dir(rng, anchor, link_min, link_max)
		if not _spot_ok(v, chosen, false) or _planet.surface_point(v).distance_to(anchor_point) > link_max:
			continue
		if prefer == Vector3.ZERO:
			return v
		var d := _planet.surface_distance(v, prefer)
		if d < best_d:
			best_d = d
			best = v
	if prefer != Vector3.ZERO and best_d > PULSE_NEAR_M:
		# Rings round `prefer` from the band's nearest edge out to the pulse's steep range only: ground
		# further than PULSE_NEAR_M from `prefer` is no better a start than the seeded best.
		var d_pa := _planet.surface_distance(prefer, anchor)
		var near := _scan_nearest(rng, prefer, maxf(0.0, maxf(link_min - d_pa, d_pa - link_max)),
			minf(PULSE_NEAR_M, d_pa + link_max), anchor, link_min, link_max, true, chosen, PREFER_STEP_M)
		if near != Vector3.ZERO:
			return near
	if best != Vector3.ZERO:
		return best
	var scanned := _scan_nearest(rng, anchor, link_min, link_max, anchor, link_min, link_max, true, chosen)
	if scanned != Vector3.ZERO:
		return scanned
	scanned = _scan_nearest(rng, anchor, link_max + SCAN_STEP_M, far_side, anchor, link_max, far_side, false, chosen)
	if scanned != Vector3.ZERO:
		return scanned
	for _attempt in SPOT_TRIES * 2:
		var v := _annulus_dir(rng, anchor, 0.0, far_side)
		if _spot_ok(v, chosen, true):
			push_warning("hunt_game: spot %d is on rough ground (no flat ground left on this world)" % chosen.size())
			return v
	push_warning("hunt_game: spot %d fell back to any direction (no free ground left on this world)" % chosen.size())
	return _planet.random_surface_dir(rng, chosen, rad_to_deg(SPOT_MIN_GAP_M / maxf(_planet.radius, 1.0)))


## Moves each spot that something SOLID covers right now (see "WHY THE LAYOUT IGNORES PROPS ADDED
## LATER") to the nearest clear point within NUDGE_REACH_M that still passes every placement rule - on
## rings SCAN_STEP_M apart, points SCAN_STEP_M apart, nearest first - preferring one that also keeps both
## its links in the chain band (`_links_hold`); a spot with no clear point that near stays (found_radius_m
## still reaches past a post). Later links were already chained from the original spot, so nothing else
## moves.
func _clear_solid_blockers(chosen: Array[Vector3]) -> void:
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var shape := CylinderShape3D.new()
	shape.radius = COLLAR_R_M + 0.15
	shape.height = 1.2
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = SOLID_MASK
	var rad := _planet.radius
	for i in chosen.size():
		if not _solid_at(space, q, chosen[i]):
			continue
		var others: Array[Vector3] = []
		for j in chosen.size():
			if j != i:
				others.append(chosen[j])
		var c0 := chosen[i]
		var t1 := c0.cross(Vector3.UP if absf(c0.y) < 0.9 else Vector3.RIGHT).normalized()
		var t2 := c0.cross(t1)
		var moved := Vector3.ZERO
		for keep_links: bool in [true, false]:
			for ring in range(1, int(round(NUDGE_REACH_M / SCAN_STEP_M)) + 1):
				var rho := float(ring) * SCAN_STEP_M / rad
				var n := maxi(6, ceili(TAU * rad * sin(rho) / SCAN_STEP_M))
				for k in n:
					var ang := TAU * float(k) / float(n)
					var v := (c0 * cos(rho) + (t1 * cos(ang) + t2 * sin(ang)) * sin(rho)).normalized()
					if _spot_ok(v, others, false) and (not keep_links or _links_hold(chosen, i, v)) and not _solid_at(space, q, v):
						moved = v
						break
				if moved != Vector3.ZERO:
					break
			if moved != Vector3.ZERO:
				break
		if moved != Vector3.ZERO:
			chosen[i] = moved
			_nudged += 1


## Whether moving spot `i` to `v` keeps each of its links, to the spot before and the spot after, within
## CHAIN_MAX_M along the surface and in a straight line - or no longer than it already was, for a link
## the widening stretched. Without it a nudge on home left a link at 8.01 m.
func _links_hold(chosen: Array[Vector3], i: int, v: Vector3) -> bool:
	var p := _planet.surface_point(v)
	var here := _planet.surface_point(chosen[i])
	for j: int in [i - 1, i + 1]:
		if j < 0 or j >= chosen.size():
			continue
		var there := _planet.surface_point(chosen[j])
		var cap := maxf(CHAIN_MAX_M, maxf(_planet.surface_distance(chosen[i], chosen[j]), here.distance_to(there)))
		if _planet.surface_distance(v, chosen[j]) > cap or p.distance_to(there) > cap:
			return false
	return true


func _solid_at(space: PhysicsDirectSpaceState3D, q: PhysicsShapeQueryParameters3D, v: Vector3) -> bool:
	var xf := _planet.surface_transform(v)
	q.transform = Transform3D(xf.basis, xf.origin + xf.basis.y * 0.65)
	return not space.intersect_shape(q, 1).is_empty()


## A seeded direction whose surface distance from `anchor` is uniform in AREA over [r_min, r_max].
func _annulus_dir(rng: RandomNumberGenerator, anchor: Vector3, r_min: float, r_max: float) -> Vector3:
	var a := anchor.normalized()
	var t1 := a.cross(Vector3.UP if absf(a.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2 := a.cross(t1)
	var c_far := cos(clampf(r_max / _planet.radius, 0.0, PI))
	var c_near := cos(clampf(r_min / _planet.radius, 0.0, PI))
	var c := lerpf(c_far, c_near, rng.randf())
	var s := sqrt(maxf(0.0, 1.0 - c * c))
	var ang := rng.randf() * TAU
	return (a * c + (t1 * cos(ang) + t2 * sin(ang)) * s).normalized()


## The point-by-point search behind a chain link. Walks rings `step` apart round `centre`, from
## `r_from` out to `r_to` metres along the surface, each ring at points `step` apart from one seeded
## bearing, and returns the FIRST point that lies in the band [lo, hi] round `anchor` (along the surface,
## and when `line_cap` in a straight line too) and passes every placement rule - so the nearest `centre`
## to within a ring. Vector3.ZERO when no point does.
## What makes a whole band affordable: a point that breaks a DISTANCE rule (a gap, a keep-off, a reserved
## zone, a prop's clearance, the band itself) by m metres breaks it everywhere within m of itself - the
## triangle inequality - and neighbours on a ring are never further apart than the ring's own arc between
## them, so the scan steps over every point that rule is guaranteed to reject without testing it; a ring
## that lies wholly inside one of the big circles (a gap, a keep-off, a reserved zone) is skipped whole.
## Only terrain and straight-line rules are tested point by point. The result is the same as testing all.
func _scan_nearest(rng: RandomNumberGenerator, centre: Vector3, r_from: float, r_to: float, anchor: Vector3,
		lo: float, hi: float, line_cap: bool, chosen: Array[Vector3], step: float = SCAN_STEP_M) -> Vector3:
	var c0 := centre.normalized()
	var t1 := c0.cross(Vector3.UP if absf(c0.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2 := c0.cross(t1)
	var rad := _planet.radius
	var line_to := _planet.surface_point(anchor) if line_cap else Vector3.INF
	# Seeded, but read from the generator's state without advancing it: a scan that finds nothing leaves
	# every later seeded try - and so the rest of the layout - exactly as it was.
	var bearing0 := TAU * float(hash([rng.state, c0, r_from]) & 0xFFFF) / 65536.0
	var r_end := minf(r_to, PI * rad)
	if r_end < r_from:
		return Vector3.ZERO
	# The big circles, as (distance from `centre`, reach): a ring of radius r lies wholly inside one when
	# that distance + r is under its reach.
	var big_d := PackedFloat64Array()
	var big_r := PackedFloat64Array()
	for c: Vector3 in chosen:
		big_d.append(_planet.surface_distance(c0, c))
		big_r.append(SPOT_MIN_GAP_M)
	for k: Dictionary in _keep_off:
		big_d.append(_planet.surface_distance(c0, k["dir"]))
		big_r.append(float(k["r"]))
	for i in _reserved.size():
		big_d.append(_planet.surface_distance(c0, _reserved[i]))
		big_r.append(_reserved_reach(i))
	var d_ca := _planet.surface_distance(c0, anchor)
	var rings := int(floor((r_end - r_from) / step + 0.0001))
	for ring in rings + 1:
		var r := r_from + float(ring) * step
		# Wholly outside the band, or wholly inside one big circle: nothing on this ring can pass.
		if d_ca + r < lo - SCAN_SKIP_SLACK_M or r - d_ca > hi + SCAN_SKIP_SLACK_M:
			continue
		var inside := false
		for b in big_d.size():
			if big_d[b] + r < big_r[b] - SCAN_SKIP_SLACK_M:
				inside = true
				break
		if inside:
			continue
		var rho := r / rad
		var ring_len := TAU * rad * sin(rho)
		var n := maxi(1, ceili(ring_len / step))
		var pitch := maxf(ring_len / float(n), 0.0001)
		var cr := cos(rho)
		var sr := sin(rho)
		var j := 0
		while j < n:
			var ang := bearing0 + TAU * float(j) / float(n)
			var v := (c0 * cr + (t1 * cos(ang) + t2 * sin(ang)) * sr).normalized()
			var da := _planet.surface_distance(v, anchor)
			# Outside the band by `miss` metres; a micrometre of slack keeps a ring that lies ON an edge in.
			var miss := maxf((lo - 0.000001) - da, da - (hi + 0.000001))
			if miss <= 0.0:
				miss = _spot_reject(v, chosen, false, line_to, hi)
				if miss < 0.0:
					return v
			j += 1
			if miss > SCAN_SKIP_SLACK_M:
				j += int((miss - SCAN_SKIP_SLACK_M) / pitch)
	return Vector3.ZERO


## Every placement rule for one candidate. `rough` drops only the flatness rules.
func _spot_ok(v: Vector3, chosen: Array[Vector3], rough: bool) -> bool:
	return _spot_reject(v, chosen, rough) < 0.0


## `_spot_ok` with a reach, for `_scan_nearest`: -1.0 when `v` passes every rule; otherwise how far along
## the surface the rejection is GUARANTEED to reach - how deep `v` sits inside the first distance rule's
## circle it breaks, since every point that much closer is inside that circle too. 0.0 when the rule that
## failed says nothing about the neighbours (a straight line, water, terrain). Distance rules first, each
## returning at its first break (cheap, and most of a band fails them), terrain last. With `line_to` set,
## `v`'s ground point must also lie within `line_max` of it in a straight line.
func _spot_reject(v: Vector3, chosen: Array[Vector3], rough: bool, line_to: Vector3 = Vector3.INF, line_max: float = INF) -> float:
	for k: Dictionary in _keep_off:
		var m := float(k["r"]) - _planet.surface_distance(v, k["dir"])
		if m > 0.0:
			return m
	for c: Vector3 in chosen:
		var m := SPOT_MIN_GAP_M - _planet.surface_distance(v, c)
		if m > 0.0:
			return m
	for i in _reserved.size():
		var m := _reserved_reach(i) - _planet.surface_distance(v, _reserved[i])
		if m > 0.0:
			return m
	# The planet's BAKED props - see "WHY THE LAYOUT IGNORES PROPS ADDED LATER".
	if _baked_props < 0:
		var mp := SPOT_CLEARANCE_M - _planet.nearest_prop_distance(v)
		if mp > 0.0:
			return mp
	for i in _baked_props:
		var m := _prop_radii[i] + SPOT_CLEARANCE_M - _planet.surface_distance(v, _prop_dirs[i])
		if m > 0.0:
			return m
	var p := _planet.surface_point(v)
	if line_to.is_finite() and p.distance_to(line_to) > line_max:
		return 0.0
	for k: Dictionary in _keep_off:
		if p.distance_to(k["point"]) < float(k["r"]):
			return 0.0
	return -1.0 if _ground_ok(v, p, rough) else 0.0


## How close to reserved centre `i` a spring may not sit: DecorationManager's gap, or the zone itself
## grown by the spring's footprint when Planet's zone radii are readable - every point whose footprint
## overlaps the zone, which the earlier six samples round the footprint only approximated (they missed
## the slivers between samples, up to 13 cm deep). Unreadable radii fall back to those samples, in
## `_ground_ok`.
func _reserved_reach(i: int) -> float:
	var gap := DecorationManager.RESERVED_CLEARANCE + SPOT_RESERVED_GAP_M
	if _zone_radii.size() != _reserved.size():
		return gap
	return maxf(gap, _zone_radii[i] + SPOT_CLEARANCE_M)


## Free ground for a spring, the rules that are not plain distances: out of the water, and (unless
## `rough`) as flat as `Planet._find_free_dir` and DecorationManager's terrain rule ask. Deterministic: it
## reads nothing a player or another system can change. Only ever called by `_spot_reject`, after the
## distance rules passed.
func _ground_ok(v: Vector3, p: Vector3, rough: bool) -> bool:
	var h := p.distance_to(_planet.global_position)
	var wr := _planet.water_radius()
	if wr > 0.0 and h < wr + 0.18:
		return false
	var xf := _planet.surface_transform(v)
	var e := SPOT_CLEARANCE_M / _planet.radius
	if _zone_radii.size() != _reserved.size():
		if _planet.reserved_zone_at(v) != "":
			return false
		for k in 6:
			var ang := TAU * float(k) / 6.0
			if _planet.reserved_zone_at(v + (xf.basis.x * cos(ang) + xf.basis.z * sin(ang)) * e) != "":
				return false
	if rough:
		return true
	# The spring's own seat first (it rejects most terrace edges, at its first bad sample): the ground
	# under the whole stain within SEAT_TOLERANCE_M of its centre, so the flat stain neither floats nor
	# sinks at its edge (round 2 placed spots with 0.2 m of step under a 0.6 m stain on Grig).
	var e_seat := (STAIN_R_M + 0.05) / _planet.radius
	for k in 8:
		var ang := TAU * float(k) / 8.0
		if absf(_planet.height_at((v + (xf.basis.x * cos(ang) + xf.basis.z * sin(ang)) * e_seat).normalized()) - h) > SEAT_TOLERANCE_M:
			return false
	# Planet._find_free_dir's own flatness rule at this clearance.
	var e_near := 0.45 / _planet.radius
	var hmin := h
	var hmax := h
	var nmin := h
	var nmax := h
	for k in 6:
		var ang := float(k) * PI / 3.0
		var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
		var hh := _planet.height_at((v + tangent * e).normalized())
		hmin = minf(hmin, hh)
		hmax = maxf(hmax, hh)
		if wr > 0.0 and hh < wr + 0.1:
			return false
		var hn := _planet.height_at((v + tangent * e_near).normalized())
		nmin = minf(nmin, hn)
		nmax = maxf(nmax, hn)
	if hmax - hmin > 0.28 + SPOT_CLEARANCE_M * 0.12 or nmax - nmin > 0.13:
		return false
	if _deco != null and _deco.ground_block_reason(v, SPOT_CLEARANCE_M) != "":
		return false
	return true


# ============================================================================= the ring
func _build_ring(glow: Color) -> void:
	_ring = MeshInstance3D.new()
	_ring.name = "Pulse"
	_ring.mesh = _ring_shared_mesh()
	_ring_mat = ShaderMaterial.new()
	_ring_mat.shader = _shader(&"ring", RING_SHADER_CODE)
	_ring_mat.set_shader_parameter(&"glow", glow)
	_ring_mat.set_shader_parameter(&"lift", RING_LIFT_M)
	_ring_mat.set_shader_parameter(&"snap", RING_STEP_SNAP_M)
	_ring.material_override = _ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The shader moves every vertex out to the live radius and height, so the mesh's own unit bounds
	# would let the ring be culled while it is on screen.
	_ring.custom_aabb = AABB(Vector3(-RING_PEAK_M - 0.2, -2.0, -RING_PEAK_M - 0.2), Vector3(RING_PEAK_M * 2.0 + 0.4, 4.0, RING_PEAK_M * 2.0 + 0.4))
	_ring.visible = false
	_ring_h.resize(RING_SAMPLES)
	add_child(_ring)


# ============================================================================= art (cached, shared)
static var _stones_meshes: Dictionary = {}
static var _water_mats: Dictionary = {}
static var _shaders: Dictionary = {}
static var _water_mesh_cache: Mesh = null
static var _ring_mesh_cache: Mesh = null


static func _shader(key: StringName, code: String) -> Shader:
	if _shaders.has(key):
		return _shaders[key]
	var sh := Shader.new()
	sh.code = code
	_shaders[key] = sh
	return sh


static func _stones_mesh(look: String) -> Mesh:
	if _stones_meshes.has(look):
		return _stones_meshes[look]
	var f: Dictionary = LOOKS.get(look, LOOKS[DEFAULT_LOOK])
	var kit := PlanetMeshKit.new()
	match str(f.get("shape", "spring")):
		"spring":
			_build_spring(kit, f)
		var other:
			push_warning("hunt_game: look '%s' has no shape '%s', building a spring" % [look, other])
			_build_spring(kit, f)
	var mesh := kit.commit()
	_stones_meshes[look] = mesh
	return mesh


## A spring breaking through dry ground: a low faceted collar cut round the pool and a few loose chips
## on it - flat base, crisp edges, nothing taller than COLLAR_H_M. The damp ring around it and the pool
## inside it are the water mesh (`_water_mesh`), so both are lit once, in colours measured as rendered.
static func _build_spring(kit: PlanetMeshKit, f: Dictionary) -> void:
	var stone := Color(str(f["stone"]))
	# Outer foot -> top -> down the inner wall, so every band's normal faces out of the stone.
	kit.lathe(PackedVector2Array([
		Vector2(COLLAR_R_M + 0.03, 0.0),
		Vector2(COLLAR_R_M, COLLAR_H_M * 0.6),
		Vector2(COLLAR_R_M - 0.05, COLLAR_H_M),
		Vector2(POOL_R_M + 0.05, COLLAR_H_M),
		Vector2(POOL_R_M, COLLAR_H_M * 0.6),
		Vector2(POOL_R_M - 0.01, 0.0),
	]), 9, Transform3D.IDENTITY, stone, false)
	var mid := (POOL_R_M + COLLAR_R_M) * 0.5
	for i in 4:
		var ang := TAU * (float(i) + 0.17 * float(i * i % 3)) / 4.0 + 0.4
		kit.faceted_blob(Vector3(cos(ang) * mid, COLLAR_H_M + 0.012, sin(ang) * mid), 0.05 + 0.012 * float(i % 2),
			stone.lightened(0.05), Vector3(1.0, 0.5, 0.8), 0, 0.22, float(i) * 1.7, Basis(Vector3.UP, ang))


## The damp ring and the pool in one lathe, outside in, around the pool's own plane (y 0 here, the node
## sits at WATER_Y_M): the damp ring on the ground out to STAIN_R_M, a step up under the collar (hidden
## by it), and the pool with the breathing mound in its middle.
static func _water_mesh() -> Mesh:
	if _water_mesh_cache != null:
		return _water_mesh_cache
	var kit := PlanetMeshKit.new()
	var r := POOL_R_M + 0.012
	var damp_y := STAIN_Y_M - WATER_Y_M
	kit.lathe(PackedVector2Array([
		Vector2(STAIN_R_M, damp_y - STAIN_EDGE_DROP_M), Vector2(COLLAR_R_M - 0.03, damp_y),
		Vector2(r, 0.0), Vector2(r * 0.72, 0.0), Vector2(r * 0.45, MOUND_M * 0.3),
		Vector2(r * 0.22, MOUND_M * 0.8), Vector2(0.0, MOUND_M),
	]), 24, Transform3D.IDENTITY, Color.WHITE, true)
	_water_mesh_cache = kit.commit()
	return _water_mesh_cache


static func _water_material(look: String) -> ShaderMaterial:
	if _water_mats.has(look):
		return _water_mats[look]
	var f: Dictionary = LOOKS.get(look, LOOKS[DEFAULT_LOOK])
	var m := ShaderMaterial.new()
	m.shader = _shader(&"water", WATER_SHADER_CODE)
	m.set_shader_parameter(&"shallow_color", Color(str(f["shallow"])))
	m.set_shader_parameter(&"deep_color", Color(str(f["deep"])))
	m.set_shader_parameter(&"ripple_color", Color(str(f["ripple"])))
	m.set_shader_parameter(&"damp_color", Color(str(f["damp"])))
	m.set_shader_parameter(&"damp_edge_color", Color(str(f["damp_edge"])))
	m.set_shader_parameter(&"pool_radius", POOL_R_M)
	m.set_shader_parameter(&"collar_radius", COLLAR_R_M)
	m.set_shader_parameter(&"damp_radius", STAIN_R_M)
	_water_mats[look] = m
	return m


## One plain white unit torus (centre-line radius 1.0, tube RING_TUBE_R) shared by every hunt: the
## shader places each vertex at the live radius and height, and the colour is a uniform.
static func _ring_shared_mesh() -> Mesh:
	if _ring_mesh_cache != null:
		return _ring_mesh_cache
	var kit := PlanetMeshKit.new()
	var prof := PackedVector2Array()
	for i in 5:
		var a := TAU * float(i) / 4.0
		prof.append(Vector2(1.0 + cos(a) * RING_TUBE_R, sin(a) * RING_TUBE_R))
	kit.lathe(prof, 72, Transform3D.IDENTITY, Color.WHITE, true, true)
	_ring_mesh_cache = kit.commit()
	return _ring_mesh_cache


const RING_SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// hunt_game.gd "WHY THE RING BENDS OVER THE GROUND". The mesh is a unit torus in local XZ; each vertex
// is moved out to ring_radius (the tube keeps its own size) and up to the ground height sampled at its
// angle - 24 samples in six vec4s, h0.x at angle 0, counter-clockwise from +X towards +Z.
uniform vec4 glow : source_color = vec4(1.0);
uniform float ring_alpha = 0.0;
uniform float ring_radius = 1.0;
uniform float curvature = 0.0;
uniform float lift = 0.07;
uniform float snap = 0.2;
uniform vec4 h0;
uniform vec4 h1;
uniform vec4 h2;
uniform vec4 h3;
uniform vec4 h4;
uniform vec4 h5;

float sample_h(int i) {
	int k = i % 24;
	int b = k / 4;
	vec4 v = (b == 0) ? h0 : (b == 1) ? h1 : (b == 2) ? h2 : (b == 3) ? h3 : (b == 4) ? h4 : h5;
	return v[k - b * 4];
}

void vertex() {
	float len = length(VERTEX.xz);
	vec2 dir = len > 0.00001 ? VERTEX.xz / len : vec2(1.0, 0.0);
	float ang = atan(dir.y, dir.x);
	if (ang < 0.0) {
		ang += 6.28318530718;
	}
	float f = ang / 6.28318530718 * 24.0;
	int i0 = int(floor(f));
	float t = f - float(i0);
	float a = sample_h(i0);
	float b = sample_h(i0 + 1);
	// Across a step the HIGHER sample wins, so a riser can never cut a segment out of the ring.
	float h = mix(mix(a, b, t), max(a, b), clamp(abs(b - a) / snap, 0.0, 1.0));
	float r = ring_radius + (len - 1.0);
	VERTEX.xz = dir * r;
	// The ring's local plane is tangent at the feet; drop by the sphere's own curvature at this radius.
	VERTEX.y += h + lift - curvature * r * r;
}

void fragment() {
	// A source_color straight into ALBEDO with no maths: identical on both renderers
	// (planet_common.gdshaderinc, "the two therefore break even").
	ALBEDO = glow.rgb;
	ALPHA = ring_alpha;
}
"""


const WATER_SHADER_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"
global uniform float astro_compat;

// hunt_game.gd "WHY THE SPRING LOOKS LIKE THIS". Opaque and lit in the house recipe: pc_in on each
// source_color at first use, pc_out on the write, the shared toon ramp in light() with pc_light_term so
// the albedo lands once (planet_common.gdshaderinc). One mesh, two zones by radius: the pool inside
// pool_radius, the damp ground ring from collar_radius out to damp_radius (the collar covers the step).
uniform vec4 shallow_color : source_color;
uniform vec4 deep_color : source_color;
uniform vec4 ripple_color : source_color;
uniform vec4 damp_color : source_color;
uniform vec4 damp_edge_color : source_color;
uniform float pool_radius = 0.36;
uniform float collar_radius = 0.54;
uniform float damp_radius = 0.70;
// Thin ripple crests travel outward: one every ripple_spacing metres, at ripple_speed metres a second,
// brightest near the middle where the water wells up.
uniform float ripple_spacing = 0.14;
uniform float ripple_speed = 0.07;
uniform float ripple_strength = 0.6;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.4;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.3;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);
uniform float shade_floor = 0.6;
uniform float glint = 0.9;

varying float v_r;

void vertex() {
	v_r = length(VERTEX.xz);
	float u = clamp(v_r / pool_radius, 0.0, 1.0);
	// The bubble breathes: the mesh's own mound rises and falls a few millimetres.
	float mound = 1.0 - smoothstep(0.0, 0.5, u);
	VERTEX.y += mound * mound * 0.004 * sin(TIME * 2.3);
}

void fragment() {
	vec3 col;
	if (v_r > pool_radius + 0.02) {
		col = mix(pc_in(damp_color.rgb), pc_in(damp_edge_color.rgb), smoothstep(collar_radius, damp_radius, v_r));
	} else {
		float u = clamp(v_r / pool_radius, 0.0, 1.0);
		col = mix(pc_in(deep_color.rgb), pc_in(shallow_color.rgb), smoothstep(0.05, 0.95, u));
		float ph = fract(v_r / ripple_spacing - TIME * ripple_speed / ripple_spacing);
		float crest = exp(-pow((ph - 0.5) / 0.11, 2.0));
		float fade = smoothstep(0.08, 0.3, u) * (1.0 - smoothstep(0.75, 1.0, u)) * (1.0 - 0.45 * u);
		col = mix(col, pc_in(ripple_color.rgb), crest * fade * ripple_strength);
	}
	ALBEDO = pc_out(pc_albedo_floor(col));
	ROUGHNESS = 0.35;
	METALLIC = 0.0;
	SPECULAR = 0.4;
}

void light() {
	float lit;
	vec3 diffuse = pc_toon_diffuse(ALBEDO, dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, shade_strength, pc_in(shade_tint.rgb), shade_floor, LIGHT_IS_DIRECTIONAL, lit);
	DIFFUSE_LIGHT += pc_light_term(diffuse * LIGHT_COLOR / PI, ALBEDO);
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	SPECULAR_LIGHT += smoothstep(0.4, 0.55, pow(ndh, 160.0)) * glint * lit * LIGHT_COLOR / PI;
}
"""


# ============================================================================= QA
## QA only: world position of the live spot, or Vector3.INF when nothing is left. hint_direction()
## stays Vector3.INF for players; this exists so a test can steer to a known target.
func debug_nearest_pos() -> Vector3:
	if _done >= _total:
		return Vector3.INF
	return _positions[_done]


## QA only: the interval the pulse schedules at a distance (the exact formula `_fire_beat` uses).
func debug_interval_at(dist_m: float) -> float:
	return interval_at(dist_m)


## One line of pulse state, then every spot with its status and distances.
func debug_report(tag: String = "") -> void:
	var alive := is_instance_valid(_player)
	var pd := _pulse_distance(_player.global_position) if alive and _done < _total else -1.0
	print("HUNT %s look=%s done=%d/%d pulse_d=%.2f next_interval=%.3f beat_phase=%.3f ring_t=%.2f ring_peak_a=%.3f baked_props=%d nudged=%d finishing=%s sinking=%s" % [
		tag, _look, _done, _total, pd, interval_at(pd) if pd >= 0.0 else -1.0, _beat_phase, _ring_t,
		_ring_peak_alpha, _baked_props, _nudged, str(_finishing), str(_sinking)])
	for i in _total:
		var status := "FOUND" if i < _done else ("LIVE" if i == _done else "hidden")
		var d := _positions[i].distance_to(_player.global_position) if alive else -1.0
		var prev_d := _planet.surface_distance(_dirs[i], _dirs[i - 1]) if i > 0 else -1.0
		print("  spot %d [%s] dir=[%.4f,%.4f,%.4f] line_to_player=%.2f surface_to_prev=%.2f" % [
			i, status, _dirs[i].x, _dirs[i].y, _dirs[i].z, d, prev_d])
