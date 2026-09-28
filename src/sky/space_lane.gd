class_name SpaceLane
extends Node3D
## SPIKE (2026-09-21, scratch only). EVERYTHING OUTSIDE THE WINDOW, AND WHY IT IS THERE.
##
## The user looked at the first safari frames and said the thing that matters most:
##
##     "There's no real clear sense of direction as you're moving through space and looking around.
##      We need some point of reference e.g. the target planet in the distance getting closer? ...
##      in games like pokemon snap, the background help remind you where you're looking and the
##      movement direction also help you figure out where you're facing."
##
## and, about the tone of the same frames: the black outside "seems too serious in tone / empty".
##
## THE DIAGNOSIS. The old lane had two spheres in it and nothing else, and both were 500 m or more
## away. At 35 m/s a body 500 m away moves 4 degrees a second - so the whole picture was, for
## practical purposes, STILL, and a still picture cannot tell you your heading or your speed. It was
## not dark that made it feel unmoored; it was that nothing had a near distance.
##
## THE FIX IS A PARALLAX LADDER. Five tiers, each with a job, and they are all driven by ONE number
## (`LANE_SPEED` metres per second) so nothing can disagree with anything else:
##
##   TIER          distance     what it does over a 62 s run          what it tells you
##   nebula/stars  infinite     nothing moves, ever                   which way is which, absolutely
##   ring world    3.2 km       real parallax; 1.9 deg while visible  a landmark, off the port bow
##   destination   2.98 -> 0.81 grows 5.5 deg -> 20.0 deg, 3.7x      FORWARD, and how far is left
##   home          0.35 -> 2.2  44 deg -> 7.5 deg, swinging astern    BACK, and that you left
##   lanterns      1.3 km -> 0  a gate every 2.3 s, converging        the lane, and the vanishing pt
##   motes          3 - 90 m    whip past, fast at the edges          speed, and your heading
##
## ROUND 3: EVERY BODY IS A FIXED POINT AND THE SHIP FLIES A STRAIGHT LINE. There is now exactly one
## rule for where a body is, with no exceptions and no gains:
##
##     body_relative_to_ship(t) = where_it_was_at_lane_zero + Vector3(0, 0, LANE_SPEED * t')
##
## because the ship flies along -Z at LANE_SPEED. That is the whole of it. The review took the old
## home apart and it deserved it: home was a slerp between two hand-picked directions driven by
## `clampf(u * 2.6)` - a fitted constant with nothing behind it - so its bearing was IDENTICAL at
## t=20, 30, 40 and 50 (az 170, el -33) while its distance grew 232 m to 839 m during 1715 m of
## flight, which is not a distance a body you are flying away from can have. Now home is a place:
## you are LANE_SPEED x pad_seconds over the pad when the clock starts, the pad is off to port, and
## everything else - 44 deg across and abeam at the pad, 7.5 deg and astern at touchdown, every
## bearing in between - falls out of Pythagoras. `--report` prints the table.
##
## THE DESTINATION IS ON THE LANE AXIS, dead ahead, because that is what a lane IS: the lantern
## gates converge on the vanishing point and the vanishing point is the world you are flying to. It
## used to sit 6 deg off the axis at a bearing that never changed, which is a body being carried
## along beside you rather than one you are approaching. It is also bigger and it starts further
## out: the review measured 40 of the 56 seconds under 5.3 degrees with all the growth in the last
## ten, because a 46 m rock at 2.6 km is a 2 degree speck for most of the way. A 143 m world sized
## so that it is 20 degrees across at touchdown starts at 5.5 degrees and is never under it.
##
## The two ends of that ladder are the user's request word for word: the target planet in the
## distance getting closer, and your own planet behind you shrinking. The middle of it is the part
## that makes swinging the scope feel like turning your head in a real place rather than scrubbing
## a texture: near things slide, far things do not.
##
## WHY LANTERNS. safari_cast.gd has called this route "Home to Zorp, the Lantern Lane" since it was
## written and nothing in the scene was ever a lantern. A corridor of paired warm lights receding to
## a point is the single clearest picture of "this is the way I am going" available, and it is also
## the cosy half of the note - amber every couple of seconds instead of empty black.
##
## HOW MUCH OF THIS IS REAL. All of it is real geometry at a real depth; none of it is a screen
## overlay, so it parallaxes correctly under any camera swing without a line of code saying so.
## SYNTHETIC: the numbers in the table above come from the autopilot run, and no part of this has
## been on a phone.

const GLOBE_SHADER := preload("res://src/sky/lane_globe.gdshader")
const HALO_SHADER := preload("res://src/sky/lane_halo.gdshader")
const MOTE_SHADER := preload("res://src/sky/lane_mote.gdshader")
const FLARE_SHADER := preload("res://src/sky/lane_flare.gdshader")
const RING_SHADER := preload("res://src/sky/lane_ring.gdshader")

# ---------------------------------------------------------------- the one speed everything obeys
## Metres per second, and the only speed in the file. A run is 62 s including the pad drop, so the
## ship covers 2170 m, and the lanterns, the motes, the approach and home falling behind are all
## THE SAME MOTION and cannot drift apart. Every distance below is derived from it.
const LANE_SPEED := 35.0

## BOTH WORLDS ARE THE SAME SIZE, because they are the same kind of thing: this lane is at model
## scale and a world in it has a 143 m radius. Everything else about the two of them is where they
## are, not how big they are.
const WORLD_RADIUS := 143.0
const DEST_RADIUS := WORLD_RADIUS
const HOME_RADIUS := WORLD_RADIUS

## THE ONE THING CHOSEN ABOUT THE DESTINATION: how big it is when you get there.
##
## WAVE 3 (G5, spec R7). The user: the planet is "way too big, distracting". It used to arrive
## 20.0 degrees across (811 m out), which in today's 56-degree lowered window is a disc of radius
## 10.0 deg against the window's 28: (10/28)^2 = 12.8% of the porthole - over R7's 12% ceiling at
## touchdown. It now arrives 12.0 degrees across: (6/28)^2 = 4.6% of the porthole at its biggest,
## the ceiling a factor 2.6 away. The start is not chosen - it falls out of how long the route is -
## and the per-second table (`--route-report`) is where R7 is read off, not this comment.
const DEST_END_DEG := 12.0
const DEST_END := WORLD_RADIUS / tan(DEST_END_DEG * 0.5 * PI / 180.0)   # 1360.6 m

## THE FAR PLANE IS NOT RAISED; THE BODIES ARE SCALED. At 156-234 s the destination starts 5-8 km
## out and SafariRun's camera `far` is 4000 m (safari_run.gd is not this group's file). A body past
## PROXY_MAX is drawn at PROXY_MAX with its radius scaled by the same factor - similar triangles, so
## its angular size and direction are EXACT, and no depth-range change is needed. Only the 6 s pad
## beat shows 3D at all (landmine T2); the glass gets the true distance from lane_report().
const PROXY_MAX := 3500.0

# ================================================================== R8: THE ROUTE HAS A SHAPE
## The user, 2026-09-21: "no straight line routes. Use winding paths, maybe some elevation etc."
## Until this round the ship flew `at + Vector3(0, 0, lane_z)` - a straight line at LANE_SPEED.
##
## HOW A ROUTE IS MADE. Each lane has ONE lateral shape and ONE vertical shape, both functions of
## how far along the chord you are (u 0..1), and two numbers that scale them: `yaw`, the steepest
## the heading ever gets off the chord, and `pitch`, the steepest climb or dive. Every shape has
## zero slope at both ends - the ship leaves the pad level and pointing down the lane (so the 6 s
## pad beat is unchanged) and arrives pointing at the destination. The chord is then solved so the
## curve's ARC LENGTH is exactly LANE_SPEED x run: winding does not make a run longer or shorter,
## and PHOTO_TRIP_HOURS does not move.
##
## S11: every lane has ONE full-length vertical arc ("hill" = climb then dive, "valley" = dive then
## climb) and at most two small bumps on top of it. The lateral shapes turn all the way through.
##
## THE SIGHTS RIDE WITH THE SHIP. safari_lanes.gd places every sight at an az/el in the SHIP's frame
## (az 0 is the bow), and safari_run.gd aims the scope in that frame too, so a turn cannot sweep a
## sight out of reach - what turns is the world outside: the stars, the aurora's plane, the two
## planets and the track. That is exactly what a turn looks like from inside a vehicle.
##
## NO BANKING. The ship yaws and pitches; it never rolls. The aurora band (R2) is the world's level
## plane, so the only way it can lean in the window is the pitch seen from the side, and it can
## lean no further than the steepest pitch: PITCH_CAP. `route_report()` measures it per lane.
const PITCH_CAP := 12.0
const PATH_N := 1400
## The sway laid over a slow shape (see _build_route): this much heading either way.
const MEANDER_DEG := 6.0
const ROUTES := {
	# lateral shape          yaw deg   vertical   pitch deg   small bumps [start u, width u, height]
	"lantern": {"name": "the lazy S over one low hill",
		"x": "s", "sway": 34.0, "yaw": 16.0, "y": "hill", "pitch": 7.0, "bumps": []},
	"commons": {"name": "the zig-zag through a shallow dip",
		"x": "zigzag", "yaw": 17.0, "y": "valley", "pitch": 6.0, "bumps": [[0.42, 0.16, 0.30]]},
	"ringgap": {"name": "one wide bow, diving under and climbing out",
		"x": "bow", "sway": 30.0, "yaw": 18.0, "y": "valley", "pitch": 11.0, "bumps": []},
	"chalk": {"name": "the staircase, up two terraces and over",
		"x": "stairs", "sway": 28.0, "yaw": 18.0, "y": "hill", "pitch": 10.0,
		"bumps": [[0.10, 0.18, 0.22], [0.28, 0.18, 0.22]]},
	"dusk": {"name": "the question mark, over a long low rise",
		"x": "hook", "sway": 32.0, "yaw": 19.0, "y": "hill", "pitch": 6.5, "bumps": [[0.70, 0.18, -0.25]]},
	"frost": {"name": "the snake, down into the cold",
		"x": "snake", "yaw": 14.0, "y": "valley", "pitch": 9.0, "bumps": []},
	"longhome": {"name": "the double bow over the big hill",
		"x": "double", "sway": 38.0, "yaw": 17.0, "y": "hill", "pitch": 12.0,
		"bumps": [[0.20, 0.16, -0.18], [0.64, 0.16, -0.18]]},
	"outerdark": {"name": "the dog-leg, down into the dark",
		"x": "dogleg", "sway": 30.0, "yaw": 19.0, "y": "valley", "pitch": 12.0, "bumps": [[0.60, 0.20, 0.25]]},
}

# ================================================================== R10: THE TRACK UNDER THE HULL
## The user: "Can you make the light trail leading the planet seemingly more directly underneath the
## ship? It's so far below it feels like it's leading to something below me vs a railway I'm riding
## on." The old rail was ONE line hung WORLD_RADIUS = 143 m under the lane axis: in the window it
## was a single vertical stroke from the rim up to the planet's lower limb - the picture of a beam
## pointing DOWN, not of a road you are on.
##
## A railway reads as a railway because of three things, and all three are here:
##   * TWO rails, TRACK_W either side of the ship's centreline, so they make a V that opens toward
##     you and closes on the vanishing point;
##   * close under the hull - TRACK_H below the eye - so the V's mouth fills the bottom of the
##     porthole and the rails come out from underneath you;
##   * sleepers across them every TRACK_GAP metres, streaming under you at LANE_SPEED.
## And it FOLLOWS THE ROUTE: the rails are the R8 path itself, offset down and sideways in the
## path's own frame, so a bend ahead is a bend in the track and a climb ahead is the track rising.
## The rails run into the destination because the route ends there.
##
## TRACK_H and TRACK_W are the ship's size, not tuning: a 4 m eye height over the floor and a 5 m
## gauge. With the default crosshair at el +4 the porthole's bottom rim is 24 deg below level, which
## rails 4 m down cross 9 m ahead at +-15.5 deg - a V a little over half the porthole wide.
const TRACK_H := 4.0
const TRACK_W := 2.5
const TRACK_GAP := 10.0
## The rail's half-width in metres. safari_eyepiece.gdshader holds the other copy (TRK_RAIL_M).
const TRACK_RAIL_M := 0.09
## How many points of the route go across to the glass (see feed_track for the spacing), the last
## one on the destination itself.
const TRACK_K := 24
const TRACK_D0 := 3.0
## Sleepers are drawn on the first this-many pieces. G5b's curve spends up to TRACK_ARC_PIECES of the
## points on the bend, so they now reach 92-322 m (p5-max, median 130 m, 16,026 frames) where they
## used to reach 330-412 m; past ~130 m a 10 m sleeper period is under 3 px on the phone porthole
## and the shader has already faded them to the bed (trk_sleepers' `res`).
const TRACK_SLEEPER_PIECES := 11
## R10 ROUND 3 (G5b): the track is the TRUE route for TRACK_JOIN metres, then one curve of radius
## TRACK_CURVE (tighter when the planet sits low), then straight into the planet (see _track_points).
## TRACK_JOIN is geometry: the point 20 deg under the default crosshair (el -16) is 14 m ahead of a
## 4 m eye height, so 15 m keeps everything you see steeply below you on the true route. TRACK_CURVE
## was picked from three measured radii - 60, 80 and 105 m all gave, over all 42 directed trips every
## 0.1 s at the default heading, 0 tangles, the centre line 20 deg under the crosshair within 1.78 deg
## of straight below in 100% of 79,962 samples, and no frame-to-frame jump above 0.77 deg - as the
## middle one, by the picture. It is a choice, not a fitted gain.
const TRACK_JOIN := 15.0
const TRACK_CURVE := 80.0
## On the curve no drawn piece turns through more than this, so the bend reads as a curve - unless
## that would spend more than TRACK_ARC_PIECES of the TRACK_K points on it, which would leave too few
## for the sleepers (they are drawn on the first TRACK_SLEEPER_PIECES pieces only).
const TRACK_PIECE_TURN := 3.0
const TRACK_ARC_PIECES := 5
## Measurement hooks only (the G5b probe and `--rail-join=` / `--rail-curve=` captures set them to
## compare shapes at the same moment); the game never changes them.
var track_bend_m := TRACK_JOIN
var track_turn_m := TRACK_CURVE

## HOME IS A PLACE YOU LEFT. Two facts fix it, and both are lengths rather than gains:
##   * the lane's clock starts at the TOP OF THE CLIMB, LANE_SPEED x pad_seconds = 210 m over the
##     pad, so home's centre is WORLD_RADIUS + 210 = 353 m away at lane zero;
##   * the pad is off to port and below, 33 degrees round from straight down, and the ship has
##     levelled off - its course is perpendicular to the line to home, so lane zero is also the
##     closest approach.
## After that home just falls behind at 35 m/s and everything about it is Pythagoras.
const HOME_OFF := Vector3(-0.55, -0.835, 0.0)

## The ringed chrome world, off the port bow. It is a fixed point like everything else; at 3.2 km it
## has REAL parallax, which is 1.9 deg over the 6 s of pad drop when the naked eye can see it (once
## the scope comes up the glass covers the window). It cannot be pushed out to the 30 km that would
## make it a fixed landmark for the whole run - SafariRun's camera far plane is 4000 m - so what it
## is, is a near-ish landmark honestly drawn, not a far one faked with a slide gain.
const FAR_DIST := 3200.0
const FAR_AZ := -58.0
const FAR_EL := 21.0

## The sun is one distant star off the port quarter. Everything in the lane - the globes, their air
## shells, the eyepiece's own subjects - is lit from here, and it never moves, so it is a second
## absolute reference behind the nebula.
const SUN_DIR := Vector3(-0.62, 0.30, 0.72)

## Lantern gates: a PAIR of lights every GATE_GAP metres, out to GATE_N gates. 80 m at 35 m/s is a
## gate every 2.3 s - slow enough to be cosy, often enough to be a metronome you can feel.
const GATE_N := 17
const GATE_GAP := 80.0
const GATE_BEHIND := 50.0        # recycle a gate once it is this far astern

const MOTE_N := 180
const MOTE_BACK := 95.0          # motes live from here ahead of you...
const MOTE_AHEAD := 12.0         # ...to here astern, then they are recycled
const MOTE_RAD_MIN := 2.5
const MOTE_RAD_MAX := 42.0

## Per-world palette for lane_globe.gdshader. Rocky worlds get band_gain 0; the two gas-ish ones
## get banding instead of coastlines. These follow the shipped planet colours so the world you fly
## to looks like the world you land on.
const WORLDS := {
	"home": {
		"low": "#2f5e7e", "high": "#4a7a58", "air": "#79b6e2", "night": "#16304a",
		"ember": "#ffc27a", "freq": 2.6, "bias": 0.02, "band": 0.0, "halo": "#69a8e0",
	},
	"zorp": {
		"low": "#4a2f78", "high": "#8a5ec2", "air": "#c79cf0", "night": "#2a1a4a",
		"ember": "#ffb0e0", "freq": 2.1, "bias": 0.06, "band": 0.35, "halo": "#a276e4",
	},
	"bolt": {
		"low": "#5a5f70", "high": "#9aa0ae", "air": "#bcc6d8", "night": "#232838",
		"ember": "#ffd98a", "freq": 3.0, "bias": -0.02, "band": 0.15, "halo": "#9fb0c8",
	},
	"fen": {
		"low": "#2c5a52", "high": "#6f9a6a", "air": "#8fd2c0", "night": "#153028",
		"ember": "#ffd07a", "freq": 2.4, "bias": 0.04, "band": 0.0, "halo": "#74c4ac",
	},
	"grig": {
		"low": "#6a3a2e", "high": "#a8724a", "air": "#e0a276", "night": "#341c16",
		"ember": "#ffbe72", "freq": 2.8, "bias": 0.0, "band": 0.20, "halo": "#d09068",
	},
	"vela": {
		"low": "#2a3a6a", "high": "#5a6aa8", "air": "#8ea6e8", "night": "#141c38",
		"ember": "#cfe0ff", "freq": 2.2, "bias": 0.03, "band": 0.30, "halo": "#7e94d8",
	},
	"hub": {
		"low": "#4a4438", "high": "#8a7c60", "air": "#d8c79a", "night": "#2a241a",
		"ember": "#ffd27a", "freq": 3.2, "bias": -0.04, "band": 0.0, "halo": "#c0ac80",
	},
}

var _run_seconds := 56.0
var _pad_sec := 6.0
var _from_id := "home"
var _to_id := "zorp"

var _home: Node3D
var _home_globe: MeshInstance3D
var _dest: Node3D
var _dest_globe: MeshInstance3D
var _dest_moon: Node3D
var _pad: Node3D
var _far: Node3D
var _gates: Array[Node3D] = []
var _gate_z: PackedFloat32Array = PackedFloat32Array()
var _motes: MultiMeshInstance3D
var _mm: MultiMesh
var _mote_p: PackedVector3Array = PackedVector3Array()
var _mote_s: PackedVector2Array = PackedVector2Array()   # (width, length)
var _rng := RandomNumberGenerator.new()

# what advance() last worked out, for the eyepiece and for the report
var _dest_start := 2981.0
var _dest_dist := 2981.0
var _home_dist := 353.0
var _dest_dir := Vector3(0.0, 0.0, -1.0)
var _home_dir := HOME_OFF.normalized()
## Metres flown along the ROUTE since lane zero (it was a Z coordinate while the route was straight;
## the gates and motes, which live in the ship's own frame, still stream by it).
var _lane_z := 0.0

# R8: the route, in lane-zero coordinates (the ship at lane zero is at the origin facing -Z)
var _route_id := "lantern"
var _reverse := false
var _px := PackedVector3Array()      # route points
var _ps := PackedFloat32Array()      # arc length at each point
var _path_len := 0.0
var _ship_p := Vector3.ZERO          # where the ship is now
var _ship_b := Basis.IDENTITY        # which way it is pointing (columns: right, up, back)
var _dest_w := Vector3(0.0, 0.0, -3000.0)
var _home_w := Vector3.ZERO
var _far_w := Vector3.ZERO


# ================================================================== build
## WIRE round (2026-09-21): the two world ids come in directly. They used to be looked up in
## safari_cast.gd's two-entry ROUTES table, which could only ever name home->zorp or bolt->fen -
## every other one of the 42 directed trips silently drew home's ball and Zorp's.
func setup(from_world: String, to_world: String, run_seconds: float, pad_sec: float) -> void:
	_run_seconds = run_seconds
	_pad_sec = pad_sec
	_from_id = from_world
	_to_id = to_world
	_rng.seed = hash("%s->%s" % [_from_id, _to_id])

	# MEASUREMENT HOOKS ONLY (G5b): capture the rail with another join or turn length, to compare
	# pictures at the same moment. The game never passes them.
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--rail-join="):
			track_bend_m = float(a.substr(12))
		elif a.begins_with("--rail-curve="):
			track_turn_m = float(a.substr(13))
	_build_route()
	# the fixed bodies, in lane-zero coordinates
	var end_s: Array = _sample(_path_len)
	_dest_w = (end_s[0] as Vector3) + (end_s[1] as Vector3) * DEST_END
	_dest_start = _dest_w.length()
	_home_w = HOME_OFF.normalized() * (WORLD_RADIUS + LANE_SPEED * _pad_sec)
	_far_w = _dir_of(FAR_AZ, FAR_EL) * FAR_DIST
	_build_env()
	_build_far()
	_build_dest()
	_build_home()
	_build_gates()
	_build_motes()
	advance(-_pad_sec, 0.0)
	# The lane prints its own geometry when the run is asked for a report, so the table a critic
	# checks is the one advance() actually produced rather than one re-derived beside it.
	if OS.get_cmdline_user_args().has("--report"):
		print("--- LANE %s -> %s, %.0f s run + %.0f s pad, %.0f m/s, %.0f m flown ---" % [
			_from_id, _to_id, _run_seconds, _pad_sec, LANE_SPEED,
			LANE_SPEED * (_run_seconds + _pad_sec)])
		print(lane_table([-_pad_sec, 1.0, _run_seconds * 0.25, _run_seconds * 0.5,
			_run_seconds * 0.75, _run_seconds - 5.0, _run_seconds]))
	if OS.get_cmdline_user_args().has("--route-report"):
		print(route_report())
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--route-csv="):
			_write_route_csv(a.substr(12))


# ================================================================== R8: build the route
## Which way round the lane is flown. SafariLanes lists each lane's pairs once; flying a pair in the
## listed order is the route as drawn, flying it the other way is THE SAME ROAD BACKWARDS - the
## same shape, turns in the opposite order and mirrored (a left bend flown backwards is a right
## bend), a hill still a hill. So a lane keeps one recognisable shape whichever way you fly it.
func _pair_listed(lid: String) -> bool:
	var ln: Dictionary = SafariLanes.LANES.get(lid, {})
	for pr in ln.get("pairs", []):
		if str(pr[0]) == _from_id and str(pr[1]) == _to_id:
			return true
	return false


## The lateral shape, as a function of how far along the chord (0..1). Each one has zero slope at
## both ends so the ship leaves the pad and reaches the destination pointing straight down the lane.
static func _shape_x(kind: String, u: float) -> float:
	match kind:
		"s":        # one S: out to one side, back across, home to the chord
			return sin(TAU * u) * sin(PI * u)
		"zigzag":   # six legs with rounded corners: a softened triangle wave, so no leg is straight
			return asin(0.97 * sin(3.0 * TAU * u)) * sin(PI * u)
		"bow":      # one wide bow off to one side and back
			return pow(sin(PI * u), 2.0)
		"stairs":   # three steps sideways: the heading swings out and back three times, one way
			return u - sin(3.0 * TAU * u) / (3.0 * TAU)
		"hook":     # a big bow, then a small hook the other way: a question mark
			if u < 0.68:
				return pow(sin(PI * u / 0.68), 2.0)
			return -0.30 * pow(sin(PI * (u - 0.68) / 0.32), 2.0)
		"snake":    # six quick even wiggles
			return sin(6.0 * TAU * u) * sin(PI * u)
		"double":   # two bows on the same side, touching the chord in the middle
			return pow(sin(TAU * u), 2.0)
		"dogleg":   # a long sideways step with a kink in it
			return (1.0 - cos(PI * u)) * 0.5 + 0.10 * sin(2.0 * TAU * u) * sin(PI * u)
	return 0.0


## The vertical shape: ONE full-length arc, plus at most two small bumps (S11).
static func _shape_y(r: Dictionary, u: float) -> float:
	var y: float = pow(sin(PI * u), 2.0)
	if str(r.get("y", "hill")) == "valley":
		y = -y
	for b in r.get("bumps", []):
		var c: float = float(b[0])
		var w: float = float(b[1])
		if u > c and u < c + w:
			y += float(b[2]) * pow(sin(PI * (u - c) / w), 2.0)
	return y


func _build_route() -> void:
	_route_id = str(SafariLanes.lane_for(_from_id, _to_id).get("id", "lantern"))
	var r: Dictionary = ROUTES.get(_route_id, ROUTES["lantern"])
	_reverse = not _pair_listed(_route_id)
	var n := PATH_N
	var fx := PackedFloat32Array()
	var fy := PackedFloat32Array()
	fx.resize(n + 1)
	fy.resize(n + 1)
	for i in n + 1:
		var u: float = float(i) / float(n)
		fx[i] = _shape_x(str(r["x"]), u)
		fy[i] = _shape_y(r, u)
	if _reverse:
		var gx := PackedFloat32Array(fx)
		var gy := PackedFloat32Array(fy)
		for i in n + 1:
			fx[i] = -(gx[n - i] - gx[n])
			fy[i] = gy[n - i] - gy[n]
	# scale each shape so its steepest slope is exactly the lane's yaw / pitch
	var mx := 0.0
	var my := 0.0
	for i in n:
		mx = maxf(mx, absf(fx[i + 1] - fx[i]) * float(n))
		my = maxf(my, absf(fy[i + 1] - fy[i]) * float(n))
	var ax: float = tan(deg_to_rad(float(r["yaw"]))) / maxf(mx, 0.0001)
	var ay: float = tan(deg_to_rad(minf(float(r["pitch"]), PITCH_CAP))) / maxf(my, 0.0001)
	# arc length per metre of chord, measured on the polyline itself
	var arc1 := 0.0
	for i in n:
		arc1 += Vector3(ax * (fx[i + 1] - fx[i]), ay * (fy[i + 1] - fy[i]),
			1.0 / float(n)).length()
	var chord: float = LANE_SPEED * _run_seconds / maxf(arc1, 0.0001)
	# THE MEANDER. Measured, not guessed: with the big shape alone the Lantern Lane's one S turned
	# so slowly that 46% of its run-seconds were within 5 deg of straight (R8 allows 25%) - a single
	# bend 168 s long is a straight line to anyone flying it. So every lane whose big shape is slow
	# also sways: MEANDER_DEG of heading either way, one sway every `sway` seconds. In metres that
	# is a few percent of the big shape's width, so the plot keeps its silhouette and the ship keeps
	# turning. The zig-zag and the snake already turn fast enough and do not sway.
	var sway: float = float(r.get("sway", 0.0))
	if sway > 0.0:
		var lam: float = LANE_SPEED * sway          # metres of chord per sway (close enough: the
		var amp: float = tan(deg_to_rad(MEANDER_DEG)) * lam / TAU   # route is within 5% of it)
		for i in n + 1:
			var u: float = float(i) / float(n)
			var env: float = smoothstep(0.0, 0.05, u) * (1.0 - smoothstep(0.95, 1.0, u))
			fx[i] += amp / (ax * chord) * sin(TAU * u * chord / lam) * env
		# the sway made the route a little longer; solve the chord again on the swayed shape
		arc1 = 0.0
		for i in n:
			arc1 += Vector3(ax * (fx[i + 1] - fx[i]), ay * (fy[i + 1] - fy[i]),
				1.0 / float(n)).length()
		chord = LANE_SPEED * _run_seconds / maxf(arc1, 0.0001)
	var pad_len: float = LANE_SPEED * _pad_sec
	_px = PackedVector3Array()
	_ps = PackedFloat32Array()
	# the pad leg: straight and level, so the 6 s the naked eye sees are exactly as before
	var pad_n := 12
	for i in pad_n:
		_px.append(Vector3(0.0, 0.0, -pad_len * float(i) / float(pad_n)))
	for i in n + 1:
		var u: float = float(i) / float(n)
		_px.append(Vector3(ax * chord * fx[i], ay * chord * fy[i], -pad_len - chord * u))
	_ps.resize(_px.size())
	_ps[0] = 0.0
	for i in range(1, _px.size()):
		_ps[i] = _ps[i - 1] + _px[i].distance_to(_px[i - 1])
	_path_len = _ps[_ps.size() - 1]


## Where the ship is and which way it points, `s` metres along the route. Past the end it carries on
## straight, which is only used for the last leg of the track into the destination.
func _sample(s: float) -> Array:
	var last: int = _px.size() - 1
	if s >= _path_len:
		var fe: Vector3 = (_px[last] - _px[last - 1]).normalized()
		return [_px[last] + fe * (s - _path_len), fe]
	s = maxf(s, 0.0)
	var lo := 0
	var hi := last
	while hi - lo > 1:
		var mid: int = (lo + hi) >> 1
		if _ps[mid] <= s:
			lo = mid
		else:
			hi = mid
	var seg: float = maxf(_ps[hi] - _ps[lo], 0.0001)
	var k: float = clampf((s - _ps[lo]) / seg, 0.0, 1.0)
	var p: Vector3 = _px[lo].lerp(_px[hi], k)
	# the heading, blended with the neighbouring segment so a turn has no facets
	var f0: Vector3 = (_px[hi] - _px[lo]).normalized()
	if k < 0.5 and lo > 0:
		var fa: Vector3 = (_px[lo] - _px[lo - 1]).normalized()
		return [p, fa.lerp(f0, 0.5 + k).normalized()]
	if k >= 0.5 and hi < last:
		var fb: Vector3 = (_px[hi + 1] - _px[hi]).normalized()
		return [p, f0.lerp(fb, k - 0.5).normalized()]
	return [p, f0]


## The ship's frame for a heading. No roll, ever: right is always level.
static func _basis_of(fwd: Vector3) -> Basis:
	var f: Vector3 = fwd.normalized()
	var rt: Vector3 = f.cross(Vector3.UP)
	if rt.length() < 0.0001:
		rt = Vector3.RIGHT
	rt = rt.normalized()
	var up: Vector3 = rt.cross(f).normalized()
	return Basis(rt, up, -f)


func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://src/sky/safari_space.gdshader")
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#2b3350")
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# One distant sun. The globes light themselves per-pixel against SUN_DIR (a 48-segment sphere's
	# engine terminator is a faceted stair at 12 deg across), but the canopy and the pad are ordinary
	# lit meshes and still need it, and it has to point the SAME way or the scene contradicts itself.
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#ffe9c6")
	sun.light_energy = 1.15
	sun.rotation = Basis.looking_at(-SUN_DIR.normalized(), Vector3.UP).get_euler()
	add_child(sun)


func _globe(id: String, radius: float) -> Node3D:
	var w: Dictionary = WORLDS.get(id, WORLDS["zorp"])
	var holder := Node3D.new()
	holder.name = "World_" + id

	var g := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = 56
	sph.rings = 28
	g.mesh = sph
	var m := ShaderMaterial.new()
	m.shader = GLOBE_SHADER
	m.set_shader_parameter("sun_dir", SUN_DIR.normalized())
	m.set_shader_parameter("c_low", Color(str(w["low"])))
	m.set_shader_parameter("c_high", Color(str(w["high"])))
	m.set_shader_parameter("c_air", Color(str(w["air"])))
	m.set_shader_parameter("c_night", Color(str(w["night"])))
	m.set_shader_parameter("c_ember", Color(str(w["ember"])))
	m.set_shader_parameter("land_freq", float(w["freq"]))
	m.set_shader_parameter("land_bias", float(w["bias"]))
	m.set_shader_parameter("band_gain", float(w["band"]))
	m.set_shader_parameter("seed", float(hash(id) % 997) * 0.01 + 1.0)
	g.material_override = m
	g.extra_cull_margin = radius
	holder.add_child(g)
	holder.set_meta("globe", g)

	# the air shell, at 1.09x. This is what makes a 2-degree dot read as a world.
	var h := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = radius * 1.09
	hs.height = radius * 2.18
	hs.radial_segments = 40
	hs.rings = 20
	h.mesh = hs
	var hm := ShaderMaterial.new()
	hm.shader = HALO_SHADER
	hm.set_shader_parameter("sun_dir", SUN_DIR.normalized())
	hm.set_shader_parameter("tint", Color(str(w["halo"])))
	hm.set_shader_parameter("gain", 0.65)
	h.material_override = hm
	h.extra_cull_margin = radius
	holder.add_child(h)
	return holder


func _build_dest() -> void:
	_dest = _globe(_to_id, DEST_RADIUS)
	add_child(_dest)
	# A moon, so the destination has SCALE. One body has no size; two bodies with a gap between them
	# do, and the gap opening up as you close is a second reading of "getting nearer".
	_dest_moon = _globe("bolt", DEST_RADIUS * 0.21)
	_dest.add_child(_dest_moon)


func _build_home() -> void:
	_home = _globe(_from_id, HOME_RADIUS)
	add_child(_home)

	# The pad you are leaving, standing on home's near surface. It is only readable for the first
	# second or two, and that is the point: it is the last thing at a human scale you see.
	_pad = Node3D.new()
	add_child(_pad)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color("#9c8e78")
	dm.roughness = 0.75
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.4
	cm.bottom_radius = 5.0
	cm.height = 0.8
	disc.mesh = cm
	disc.material_override = dm
	_pad.add_child(disc)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color("#ffd27a")
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.4
		var post := MeshInstance3D.new()
		var qm := BoxMesh.new()
		qm.size = Vector3(0.26, 2.6, 0.26)
		post.mesh = qm
		post.position = Vector3(cos(a) * 3.8, 1.7, sin(a) * 3.8)
		post.material_override = dm
		_pad.add_child(post)
		var bulb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.30
		sm.height = 0.60
		bulb.mesh = sm
		bulb.material_override = lm
		bulb.position = Vector3(cos(a) * 3.8, 3.1, sin(a) * 3.8)
		_pad.add_child(bulb)
		var pl := OmniLight3D.new()
		pl.light_color = Color("#ffd27a")
		pl.light_energy = 1.5
		pl.omni_range = 7.0
		pl.position = Vector3(cos(a) * 3.8, 3.1, sin(a) * 3.8)
		_pad.add_child(pl)


func _build_far() -> void:
	# The ringed chrome world, 3.2 km off the port bow: the one thing that is neither infinitely far
	# (the stars) nor near enough to whip past. See FAR_DIST for what its parallax really is.
	_far = Node3D.new()
	add_child(_far)
	var body := _globe("bolt", 150.0)
	_far.add_child(body)
	var ring := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(760.0, 760.0)
	ring.mesh = pm
	var rm := ShaderMaterial.new()
	rm.shader = RING_SHADER
	rm.set_shader_parameter("tint", Color("#b9b2a4"))
	rm.set_shader_parameter("gain", 0.62)
	ring.material_override = rm
	ring.rotation_degrees = Vector3(72.0, 0.0, 18.0)
	_far.add_child(ring)


func _build_gates() -> void:
	# The Lantern Lane, made literal: pairs of warm buoys marking a corridor. They converge on the
	# vanishing point, which is the picture that answers "which way am I going".
	_gate_z.resize(GATE_N)
	for i in GATE_N:
		var gate := Node3D.new()
		# A GATE IS A PAIR AT THE SAME LATERAL DISTANCE. The first capture staggered them (15/22/29
		# m) and the corridor stopped reading as a corridor - it was just scattered lights. Two
		# widths, alternating, keeps the perspective lines clean and still gives the lane a rhythm.
		var lat: float = 16.0 if (i % 2) == 0 else 23.0
		var lift: float = -3.0 + 2.0 * float(i % 3)
		# every fourth gate is a pale mint marker instead of amber, so a gate is countable and the
		# lane has a rhythm rather than one endless repeat
		var warm: bool = (i % 4) != 2
		for s in [-1.0, 1.0]:
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(4.8, 4.8)
			q.mesh = qm
			var fm := ShaderMaterial.new()
			fm.shader = FLARE_SHADER
			fm.set_shader_parameter("tint", Color("#f0a64a") if warm else Color("#9be8d0"))
			fm.set_shader_parameter("gain", 1.25 if warm else 0.90)
			q.material_override = fm
			q.extra_cull_margin = 5.0
			q.position = Vector3(lat * s, lift, 0.0)
			gate.add_child(q)
			# A small buoy so the light is an OBJECT and not a bare glow. It sits ASTERN of its own
			# lamp, not under it: the first capture put a 0.55 m box in front of the flare and at
			# 40 m it read as a black brick stuck on the light. It is faintly self-lit for the same
			# reason - out here the only sun is 3 km off the port bow, so an unlit face is pure
			# black and pure black reads as a hole in the picture.
			var post := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.34, 0.34, 1.7)
			post.mesh = bm
			var pmat := StandardMaterial3D.new()
			pmat.albedo_color = Color("#2a3048")
			pmat.roughness = 0.62
			pmat.emission_enabled = true
			pmat.emission = Color("#5a4a34")
			pmat.emission_energy_multiplier = 0.35
			post.material_override = pmat
			post.position = Vector3(lat * s, lift, 1.35)
			gate.add_child(post)
		add_child(gate)
		_gates.append(gate)
		_gate_z[i] = -float(i) * GATE_GAP


func _build_motes() -> void:
	_motes = MultiMeshInstance3D.new()
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var qm := QuadMesh.new()
	qm.size = Vector2(1.0, 1.0)
	_mm.mesh = qm
	_mm.instance_count = MOTE_N
	_motes.multimesh = _mm
	var mat := ShaderMaterial.new()
	mat.shader = MOTE_SHADER
	mat.set_shader_parameter("gain", 0.85)
	_motes.material_override = mat
	# the motes live in a 90 m box around the eye; without this the whole MultiMesh pops out of
	# frame the moment its AABB origin leaves the frustum
	_motes.extra_cull_margin = 140.0
	add_child(_motes)

	_mote_p.resize(MOTE_N)
	_mote_s.resize(MOTE_N)
	for i in MOTE_N:
		_spawn_mote(i, _rng.randf_range(-MOTE_BACK, MOTE_AHEAD))
	_write_motes()


func _spawn_mote(i: int, z: float) -> void:
	var a := _rng.randf() * TAU
	var rad: float = sqrt(_rng.randf()) * (MOTE_RAD_MAX - MOTE_RAD_MIN) + MOTE_RAD_MIN
	_mote_p[i] = Vector3(cos(a) * rad, sin(a) * rad * 0.78, z)
	_mote_s[i] = Vector2(_rng.randf_range(0.055, 0.115), _rng.randf_range(0.9, 2.6))
	# ice flecks are cold, dust is warm; about a third warm, so the field is not one blue haze
	var warm := _rng.randf() < 0.34
	var c := Color("#cfe4ff").lerp(Color("#ffd3a0"), 1.0 if warm else 0.0)
	c = c.lerp(Color.WHITE, _rng.randf() * 0.25)
	c.a = _rng.randf_range(0.35, 1.0)
	_mm.set_instance_color(i, c)


func _write_motes() -> void:
	for i in MOTE_N:
		var s: Vector2 = _mote_s[i]
		var b := Basis(Vector3(s.x, 0.0, 0.0), Vector3(0.0, s.y, 0.0), Vector3(0.0, 0.0, 1.0))
		_mm.set_instance_transform(i, Transform3D(b, _mote_p[i]))


# ================================================================== drive
## `t` is SafariRun's clock: -PAD_SEC at the pad, 0 when the scope comes up, _run_seconds at the end.
func advance(t: float, delta: float) -> void:
	var total: float = _run_seconds + _pad_sec
	_lane_z = LANE_SPEED * clampf(t + _pad_sec, 0.0, total)
	# R8: where the ship is on its route, and which way it is pointing
	var sp: Array = _sample(_lane_z)
	_ship_p = sp[0]
	_ship_b = _basis_of(sp[1])

	# --- THE DESTINATION, at the end of the route, getting nearer. It is a fixed place: the route
	# arrives pointing at it, so it is dead ahead at touchdown and wherever the bends put it before.
	var dp: Vector3 = _rel(_dest_w)
	_dest_dist = maxf(dp.length(), WORLD_RADIUS * 2.0)
	_dest_dir = dp / _dest_dist
	_place(_dest, dp)
	if _dest_moon != null:
		var ma: float = 0.35 + t * 0.045
		_dest_moon.position = Vector3(cos(ma), 0.22, sin(ma)) * DEST_RADIUS * 2.9

	# --- HOME, a fixed place you are flying away from: where it was when the clock started, seen
	# from wherever the route has taken the ship since.
	var hp: Vector3 = _rel(_home_w)
	_home_dist = maxf(hp.length(), WORLD_RADIUS * 1.2)
	_home_dir = hp / _home_dist
	_place(_home, hp)
	_pad.position = _home_dir * maxf(_home_dist - HOME_RADIUS, 1.5)
	_pad.transform.basis = Basis(Quaternion(Vector3.UP, -_home_dir))
	_pad.visible = t < 1.0

	# --- the far ring world: 3 km out, creeping
	_place(_far, _rel(_far_w))

	# --- the lantern gates, streaming and recycling
	for i in _gates.size():
		var z: float = _gate_z[i] + _lane_z
		var span: float = float(GATE_N) * GATE_GAP
		while z > GATE_BEHIND:
			z -= span
			_gate_z[i] -= span
		_gates[i].position.z = z

	# --- the motes
	for i in MOTE_N:
		var p: Vector3 = _mote_p[i]
		p.z += LANE_SPEED * delta
		if p.z > MOTE_AHEAD:
			_spawn_mote(i, p.z - (MOTE_BACK + MOTE_AHEAD))
		else:
			_mote_p[i] = p
	_write_motes()


## WHERE A FIXED POINT IS RIGHT NOW, in the ship's own frame. `at` is where it was relative to the
## ship at lane zero; the ship is now at _ship_p pointing along _ship_b. While the route was straight
## this was `at + (0, 0, lane_z)`, and on the pad leg (straight, level, identity basis) it still is,
## to the last bit. This is the only positioning rule in the file.
func _rel(at: Vector3) -> Vector3:
	return _ship_b.transposed() * (at - _ship_p)


## A fixed body placed at ship-relative `rel`. Past PROXY_MAX it is pulled in and shrunk by the same
## factor, so its angular size and bearing are exact while it stays inside the camera's far plane.
## The node is also turned by the ship's inverse heading, so its surface and its moon stay put in
## the world while the ship turns underneath them.
func _place(node: Node3D, rel: Vector3) -> void:
	var d: float = rel.length()
	var k: float = minf(1.0, PROXY_MAX / maxf(d, 0.001))
	node.transform = Transform3D(_ship_b.transposed().scaled(Vector3.ONE * k), rel * k)


static func _dir_of(az_deg: float, el_deg: float) -> Vector3:
	var a := deg_to_rad(az_deg)
	var b := deg_to_rad(el_deg)
	return Vector3(sin(a) * cos(b), sin(b), -cos(a) * cos(b))


# ================================================================== what the glass is told
## The spyglass draws its own picture, so without this it would show an empty sky while the naked
## eye showed a world filling a sixth of the window. Two things go across:
##
##   * WHERE THE TWO PLANETS ARE IN THE FIELD, and how big - so raising the glass at the destination
##     shows the destination, magnified, which is the strongest version of the user's "point of
##     reference" there is;
##   * WHERE YOU ARE FLYING, as a point in field coordinates. The glass streams its motes radially
##     AWAY from that point, so looking down the lane makes them bloom out of the centre and looking
##     abeam makes them all run one way across the field. That is the "movement direction helps you
##     figure out where you're facing" note, inside the glass where the player spends the run.
##
## `az`/`el` are the scope heading in degrees; the maths is the same as SafariRun.field_of().
func feed_eyepiece(mat: ShaderMaterial, az: float, el: float) -> void:
	if mat == null:
		return
	mat.set_shader_parameter("flow_from", _field_of_dir(_dir_of(0.0, 0.0), az, el))
	mat.set_shader_parameter("dest_pos", _field_of_dir(_dest_dir, az, el))
	mat.set_shader_parameter("dest_r", _field_radius(DEST_RADIUS, _dest_dist))
	mat.set_shader_parameter("dest_col", Color(str(WORLDS.get(_to_id, WORLDS["zorp"])["high"])))
	mat.set_shader_parameter("dest_air", Color(str(WORLDS.get(_to_id, WORLDS["zorp"])["halo"])))
	mat.set_shader_parameter("home_pos", _field_of_dir(_home_dir, az, el))
	mat.set_shader_parameter("home_r", _field_radius(HOME_RADIUS, _home_dist))
	mat.set_shader_parameter("home_col", Color(str(WORLDS.get(_from_id, WORLDS["home"])["high"])))
	mat.set_shader_parameter("home_air", Color(str(WORLDS.get(_from_id, WORLDS["home"])["halo"])))
	mat.set_shader_parameter("sun_at", _field_of_dir(_ship_b.transposed() * SUN_DIR.normalized(),
		az, el))
	# R8: the ship's heading, so the glass can turn the stars, the nebula and the aurora's plane -
	# the WORLD - while the ship-frame sights, the far marks and the reticle stay where they are.
	mat.set_shader_parameter("ship_basis", _ship_b)
	feed_track(mat)


## R10: THE TRACK, as TRACK_K points, in metres, in the ship's frame. `trk_l` and `trk_r` are the
## two rails, `trk_s` is each point's distance along the track from lane zero (the sleepers are laid
## on it, so they stream past at exactly LANE_SPEED). The last point is the destination's centre:
## the rails run into the planet, and the planet's disc covers where they end.
func feed_track(mat: ShaderMaterial) -> void:
	var pts: Array = _track_points()
	_feed_track_pts(mat, pts[0], pts[1], pts[2])


## WHERE THE TRACK GOES. ROUND 1 laid the rails on the whole route, all the way to the planet, and
## the far half drew as a tangle in 9 of the critic's 10 start and mid frames: kilometres of winding,
## climbing route squeezed into the last few degrees above the horizon, seen from 4 m above it, with
## no ground to hide the far side of a crest. ROUND 2 replaced it with ONE quadratic Bezier from under
## the hull to the destination's centre, pulled by the route 105 m ahead. That fixed the far tangle,
## but a quadratic whose end point is kilometres away is dominated by that end point within 10-20 m,
## so the rails UNDER THE HULL swung toward the planet instead of running along the ship's line: its
## critic measured the centre line 20 deg below the crosshair 10-18 deg to one side for 10.5% of
## run-time (up to 25% on the Long Way Home), and the pull point, taken from a local minimum that
## appeared and vanished, popped the near track sideways by up to 4.6 deg in one frame.
##
## ROUND 3 (G5b) builds the track the way a railway is laid - straight, then a curve, then straight:
##   1. THE TRUE ROUTE for the first TRACK_JOIN metres, TRACK_H under it in its own frame. That is
##      all of the track the eye sees steeply from above (the porthole's rim is 9 m ahead; 20 deg
##      under the crosshair is 14 m ahead), so the rails leave from straight under the crosshair.
##   2. ONE CIRCULAR CURVE of radius TRACK_CURVE, leaving the route along its own heading at the
##      join and turning, in the plane of that heading and the planet, until it points at the planet.
##   3. A STRAIGHT LINE into the planet's centre; the disc covers the end.
## Why not the true route for ~100 m, which is what the round-2 critic proposed: measured on all 42
## trips every 0.1 s (G5b probe), a 105 m true reach followed by any bend puts the bend where the
## track is seen edge-on - 4 m under the eye and 50-100 m out, a planet 6 deg below the horizon sits
## on the track's own line of sight - and 27,424 of 79,962 frames failed the round-2 critic's tangle
## rules checked every frame (rails crossing, the track hooking up past the planet and back). The
## bend has to happen where the track is still seen from above, which is the first few tens of metres.
## Why this has no search in it, and so cannot pop: the join is a fixed distance down a smooth route,
## the curve's size is a constant, and where it turns is the one tangent from a circle to a point -
## all smooth functions of the ship's position. Measured: no frame-to-frame jump above 1 deg.
## Why it cannot tangle: an arc and its tangent line lie in one plane and turn one way only, so the
## centre line cannot cross itself or double back, and a straight line seen from anywhere closes on
## its end point monotonically. The rails are the centre line offset level either side, so they can
## only cross where a bend is seen edge-on - which is why the curve tightens when the planet sits low
## (below). Without that, 381-968 frames (radius 60-105 m) had the far rail cross the near one; with
## it, 0. (Banking the far rails to face the eye instead was tried and drawn: it reads as a twisted
## ribbon standing on edge, so it is not used.)
## What it gives up, said plainly: the drawn track does not trace the route's later bends and hills;
## past its first metres it shows the way to the planet. The route itself is still flown (R8), and
## its turns are still seen in the planets, the stars and this track swinging as the ship turns.
func _track_points() -> Array:
	var tl := PackedVector3Array()
	var tr := PackedVector3Array()
	var ts := PackedFloat32Array()
	var dc: Vector3 = _rel(_dest_w)
	var jd: float = track_bend_m
	var rho: float = track_turn_m
	# the centre line, finely, in lane-zero coordinates, with its running length (bl) and heading (bh)
	var bp := PackedVector3Array()
	var bl := PackedFloat32Array()
	var bh := PackedVector3Array()
	# 1. the true route, every metre or so
	var nn: int = maxi(int(ceil(jd)), 1)
	for i in nn + 1:
		var d: float = jd * float(i) / float(nn)
		var smp: Array = _sample(_lane_z + d)
		var hd: Vector3 = smp[1]
		bp.append((smp[0] as Vector3) - _basis_of(hd).y * TRACK_H)
		bl.append(d)
		bh.append(hd)
	# 2. the curve: in the plane of the heading T at the join J and the planet P2, the circle of
	# radius rho tangent to T at J; it turns through th, where its tangent passes through P2
	var pj: Vector3 = bp[nn]
	var tj: Vector3 = (bh[nn] as Vector3).normalized()
	var p2: Vector3 = _dest_w
	var c2: Vector3 = p2 - pj
	var px: float = c2.dot(tj)
	var nv: Vector3 = c2 - tj * px
	var py: float = nv.length()
	var qprev: Vector3 = pj
	var qrun: float = jd
	var arc_end: float = jd
	var arc_th := 0.0
	if py > 0.001:
		nv /= py
		var th: float = _curve_turn(px, py, rho)
		# FINISH THE CURVE WHILE IT IS SEEN FROM ABOVE. A level track TRACK_H under the eye reaches the
		# planet's height on the glass at d_e = TRACK_H / tan(planet's depression); past d_e the track
		# runs along the line of sight, and a bend there is seen edge-on - its two rails drawn on top
		# of each other, the far one crossing the near one. So when the planet sits low, the curve
		# tightens until it ends by d_e. Never tighter than twice the gauge: the inner rail's own
		# radius, rho - TRACK_W, stays at least the gauge's half. Smooth in the planet's position, so
		# it cannot pop.
		var dep: float = -asin(clampf(dc.normalized().y, -1.0, 1.0))
		if dep > 0.0001 and th > 0.0001:
			var room: float = TRACK_H / tan(dep) - jd
			var fit: float = clampf(room / th, 2.0 * TRACK_W, rho)
			if fit < rho:
				rho = fit
				th = _curve_turn(px, py, rho)
		var narc: int = maxi(int(ceil(rho * th)), 1)
		for i in range(1, narc + 1):
			var a: float = th * float(i) / float(narc)
			var q: Vector3 = pj + (tj * sin(a) + nv * (1.0 - cos(a))) * rho
			qrun += q.distance_to(qprev)
			qprev = q
			bp.append(q)
			bl.append(qrun)
			bh.append(tj * cos(a) + nv * sin(a))
		arc_end = qrun
		arc_th = th
	# 3. the straight line into the planet: where it crosses the planet's surface is `reach`
	var q0: Vector3 = qprev
	var hl: Vector3 = (p2 - q0).normalized()
	var ll: float = q0.distance_to(p2)
	bp.append(p2)
	bl.append(qrun + ll)
	bh.append(hl)
	var nb: int = bp.size() - 1
	var run: float = bl[nb]
	var reach: float = maxf(run - DEST_RADIUS, arc_end) if ll > DEST_RADIUS else run
	# SPACING: geometric under the hull (each step 60% of the distance so far, as rounds 1 and 2),
	# where the rails are wide on screen - but on the curve no piece turns more than TRACK_PIECE_TURN,
	# so the bend draws as a curve and not as corners; then even steps out to where the track enters
	# the planet (past the curve the track is straight, and a straight piece is drawn exactly).
	var arc_step: float = rho * maxf(deg_to_rad(TRACK_PIECE_TURN), arc_th / float(TRACK_ARC_PIECES))
	var nr: int = TRACK_K - 1
	var ds := PackedFloat32Array()
	var dd := 0.0
	for k in nr:
		ds.append(minf(dd, reach))
		var left: int = nr - 1 - k
		if left <= 0:
			break
		var even: float = (reach - dd) / float(left)
		var stp: float = maxf(dd * 0.6, TRACK_D0)
		if dd < arc_end and dd + stp > jd:
			stp = minf(stp, maxf(arc_step, jd - dd))
		dd += minf(stp, even)
	ds[nr - 1] = reach
	var j := 0
	for k in nr:
		var d: float = ds[k]
		while j < nb - 1 and bl[j + 1] < d:
			j += 1
		var seg: float = maxf(bl[j + 1] - bl[j], 0.0001)
		var f: float = clampf((d - bl[j]) / seg, 0.0, 1.0)
		var c: Vector3 = _rel((bp[j] as Vector3).lerp(bp[j + 1], f))
		# the rails sit TRACK_W either side, level, square to the track's heading there
		var o: Vector3 = _ship_b.transposed() * _basis_of((bh[j] as Vector3).lerp(bh[j + 1], f)).x
		tl.append(c - o * TRACK_W)
		tr.append(c + o * TRACK_W)
		ts.append(_lane_z + d)
	tl.append(dc)
	tr.append(dc)
	ts.append(_lane_z + run)
	return [tl, tr, ts]


## How far a circle of radius `rho`, tangent to the heading at the join, turns before its tangent
## passes through the planet at (px ahead, py across) in the curve's own plane.
static func _curve_turn(px: float, py: float, rho: float) -> float:
	var th: float = atan2(py - rho, px) + asin(clampf(rho / Vector2(px, py - rho).length(), -1.0, 1.0))
	return clampf(th, 0.0, PI)


## The track's centre line under the TRUE route, `d` metres ahead, in lane-zero coordinates.
func _track_centre(d: float) -> Vector3:
	var smp: Array = _sample(_lane_z + d)
	var b: Basis = _basis_of(smp[1])
	return (smp[0] as Vector3) - b.y * TRACK_H


func _feed_track_pts(mat: ShaderMaterial, tl: PackedVector3Array, tr: PackedVector3Array,
		ts: PackedFloat32Array) -> void:
	# Each piece's plane and each sleeper quad's plane and bounding cone, worked out once here
	# instead of once per pixel (see the uniforms in safari_eyepiece.gdshader for the measurement).
	var nl := PackedVector4Array()
	var nrr := PackedVector4Array()
	for k in TRACK_K:
		var k1: int = mini(k + 1, TRACK_K - 1)
		nl.append(_piece(tl[k], tl[k1]))
		nrr.append(_piece(tr[k], tr[k1]))
	# one cone per piece that holds both rails, their glow and the sleepers between them
	var pc := PackedVector4Array()
	for k in TRACK_K:
		var k1: int = mini(k + 1, TRACK_K - 1)
		var corners: Array = [tl[k], tr[k], tl[k1], tr[k1]]
		var ax := Vector3.ZERO
		for c in corners:
			ax += (c as Vector3).normalized()
		if ax.length() < 0.0001:
			pc.append(Vector4(0.0, 0.0, -1.0, 2.0))        # cos > 1: the cone holds nothing
			continue
		ax = ax.normalized()
		var cmin := 1.0
		for c in corners:
			cmin = minf(cmin, ax.dot((c as Vector3).normalized()))
		# slack: the rails' glow (3.5 x their angular half-width at the nearer end, as the shader's
		# own early-out), the sleepers' 22% overhang past the rails, and one degree for the pixel
		var near: float = maxf(minf((tl[k] as Vector3).length(), (tl[k1] as Vector3).length()), 0.05)
		var half: float = acos(clampf(cmin, -1.0, 1.0)) + 3.5 * TRACK_RAIL_M / near \
			+ 0.22 * TRACK_W / near + deg_to_rad(1.0)
		pc.append(Vector4(ax.x, ax.y, ax.z, cos(minf(half, PI))))
	var qq := PackedVector4Array()
	for k in TRACK_SLEEPER_PIECES:
		var n: Vector3 = (tr[k] - tl[k]).cross(tl[k + 1] - tl[k])
		if n.length() < 0.000001:
			qq.append(Vector4(0.0, 0.0, 0.0, 0.0))
			continue
		n = n.normalized()
		qq.append(Vector4(n.x, n.y, n.z, n.dot(tl[k])))
	mat.set_shader_parameter("trk_l", tl)
	mat.set_shader_parameter("trk_r", tr)
	mat.set_shader_parameter("trk_nl", nl)
	mat.set_shader_parameter("trk_nr", nrr)
	mat.set_shader_parameter("trk_pc", pc)
	mat.set_shader_parameter("trk_q", qq)
	mat.set_shader_parameter("trk_s", ts)
	mat.set_shader_parameter("trk_gap", TRACK_GAP)
	mat.set_shader_parameter("trk_w", TRACK_W)


## A world direction, in field radii from the middle of the glass. x right, y DOWN (screen order),
## matching SafariRun.field_of() exactly so a planet and a subject cannot disagree about where the
## middle is.
static func _field_of_dir(d: Vector3, az: float, el: float) -> Vector2:
	var daz := wrapf(rad_to_deg(atan2(d.x, -d.z)) - az, -180.0, 180.0)
	var del := rad_to_deg(asin(clampf(d.normalized().y, -1.0, 1.0))) - el
	return Vector2(daz, -del) / SafariCast.FIELD_HALF_DEG


static func _field_radius(radius: float, dist: float) -> float:
	return rad_to_deg(atan(radius / maxf(dist, 0.001))) / SafariCast.FIELD_HALF_DEG


## Where a lane body is, as (az, el) in degrees. The capture rig aims at these so a sheet column is
## the SAME subject at three times, not three headings.
func bearing(which: String) -> Vector2:
	var d: Vector3 = _home_dir if which == "home" else _dest_dir
	if which == "far":
		d = _rel(_far_w)
	d = d.normalized()
	return Vector2(rad_to_deg(atan2(d.x, -d.z)), rad_to_deg(asin(clampf(d.y, -1.0, 1.0))))


# ================================================================== measurement hooks
## Everything a critic would otherwise have to eyeball. Same data the frame is drawn from.
func lane_report(t: float) -> Dictionary:
	return {
		"t": t,
		"lane_z": _lane_z,
		"dest_dist": _dest_dist,
		"dest_deg": 2.0 * rad_to_deg(atan(DEST_RADIUS / _dest_dist)),
		"dest_el": rad_to_deg(asin(clampf(_dest_dir.normalized().y, -1.0, 1.0))),
		"home_dist": _home_dist,
		"home_deg": 2.0 * rad_to_deg(atan(HOME_RADIUS / _home_dist)),
		"dest_az": rad_to_deg(atan2(_dest_dir.x, -_dest_dir.z)),
		"home_az": rad_to_deg(atan2(_home_dir.x, -_home_dir.z)),
		"home_el": rad_to_deg(asin(clampf(_home_dir.normalized().y, -1.0, 1.0))),
		"gates_ahead": _gates_ahead(),
	}


## THE TABLE A CRITIC WOULD OTHERWISE HAVE TO CAPTURE. Bearing and angular size of both worlds at a
## list of run seconds, straight out of advance() - the same maths the frame is drawn from, run for
## real rather than predicted. It leaves the lane where it found it.
func lane_table(times: Array) -> String:
	var keep: float = _lane_z
	var keep_gz := PackedFloat32Array(_gate_z)
	var out := "  t      dest_deg dest_az dest_el  dest_m   home_deg home_az home_el  home_m  flown_m\n"
	for tt in times:
		advance(float(tt), 0.0)
		var r: Dictionary = lane_report(float(tt))
		out += "  %6.1f %7.2f %7.1f %7.1f %8.0f %9.2f %7.1f %7.1f %8.0f %8.0f\n" % [
			float(tt), float(r["dest_deg"]), float(r["dest_az"]), float(r["dest_el"]),
			float(r["dest_dist"]), float(r["home_deg"]), float(r["home_az"]),
			float(r["home_el"]), float(r["home_dist"]), float(r["lane_z"])]
	advance((keep / LANE_SPEED) - _pad_sec, 0.0)
	_gate_z = keep_gz
	return out


## R7 and R8, MEASURED BY RUNNING advance() at every run second - the same maths the frame is drawn
## from, not a prediction beside it. Leaves the lane where it found it.
##   straight  a run-second is "within 5 deg of straight" when every heading in the 20 s around it
##             (t-10..t+10, 1 s steps) is within 5 deg of that window's chord. A constant gentle
##             turn is NOT straight by this test; a straight leg is, whatever it is between.
##   roll      how far the world's level plane (the aurora band) leans in the window, taken at every
##             azimuth round the ship: the steepest screen slope of the band, as an angle.
##   R7        the destination's angular radius, and its disc as a share of the LOWERED porthole
##             (radius FIELD_LOW = 28 deg, safari_run.gd): (r / 28)^2.
func route_report() -> String:
	var keep: float = _lane_z
	var keep_gz := PackedFloat32Array(_gate_z)
	var r: Dictionary = ROUTES.get(_route_id, ROUTES["lantern"])
	var n: int = int(floor(_run_seconds))
	var pos: Array = []
	var fwd: Array = []
	var pitch := PackedFloat32Array()
	var out := "--- ROUTE %s (%s)%s: %s -> %s, run %.0f s, route %.0f m, chord %.0f m ---\n" % [
		_route_id, str(r["name"]), " FLOWN BACKWARDS" if _reverse else "", _from_id, _to_id,
		_run_seconds, _path_len, _dest_w.length() - DEST_END]
	out += "  t     yaw_w  pitch  dest_az dest_el  dest_r  area%  in_default_window  roll\n"
	var roll_max := 0.0
	var world_max := 0.0
	var area_max := 0.0
	var r_at := {}
	var inwin := 0
	for i in n + 1:
		var tt: float = float(i)
		advance(tt, 0.0)
		var f: Vector3 = -_ship_b.z
		pos.append(_ship_p)
		fwd.append(f)
		var pt: float = rad_to_deg(asin(clampf(f.y, -1.0, 1.0)))
		pitch.append(pt)
		var rep: Dictionary = lane_report(tt)
		var rr: float = rad_to_deg(atan(DEST_RADIUS / _dest_dist))
		var area: float = 100.0 * pow(rr / 28.0, 2.0)
		area_max = maxf(area_max, area)
		# the default crosshair is az 0, el +4 (safari_run.gd's start); is the disc inside the window?
		var off: float = Vector2(wrapf(float(rep["dest_az"]), -180.0, 180.0),
			float(rep["dest_el"]) - 4.0).length()
		var seen: bool = off + rr < 28.0
		if seen:
			inwin += 1
		var roll: float = band_roll_deg()
		roll_max = maxf(roll_max, roll)
		world_max = maxf(world_max, world_lean_deg())
		if i == 0 or i == n / 2 or i == n:
			r_at[i] = rr
		if i == 2 or i == n / 2 or i == n - 2:
			out += "  TRACK t=%d (crosshair az 0 el +4): %s\n" % [i, track_probe(0.0, 4.0)]
		if i % 10 == 0 or i == n:
			out += "  %5.0f %6.1f %6.1f %7.1f %7.1f %7.2f %6.2f  %-5s              %5.1f\n" % [
				tt, rad_to_deg(atan2(f.x, -f.z)), pt, float(rep["dest_az"]), float(rep["dest_el"]),
				rr, area, str(seen), roll]
	# straightness
	var straight := 0
	for i in n + 1:
		var a: int = maxi(i - 10, 0)
		var b: int = mini(i + 10, n)
		var ch: Vector3 = (pos[b] as Vector3) - (pos[a] as Vector3)
		if ch.length() < 1.0:
			continue
		ch = ch.normalized()
		var worst := 0.0
		for j in range(a, b + 1):
			worst = maxf(worst, rad_to_deg(acos(clampf((fwd[j] as Vector3).dot(ch), -1.0, 1.0))))
		if worst < 5.0:
			straight += 1
	# climb and dive
	var up_max := 0.0
	var dn_max := 0.0
	var travel := 0.0
	var biggest := 0.0
	var run_start: float = pitch[0]
	var dir := 0
	for i in range(1, pitch.size()):
		up_max = maxf(up_max, pitch[i])
		dn_max = minf(dn_max, pitch[i])
		var dd: float = pitch[i] - pitch[i - 1]
		travel += absf(dd)
		var sgn: int = 1 if dd > 0.0005 else (-1 if dd < -0.0005 else dir)
		if sgn != dir:
			biggest = maxf(biggest, absf(pitch[i - 1] - run_start))
			run_start = pitch[i - 1]
			dir = sgn
	biggest = maxf(biggest, absf(pitch[pitch.size() - 1] - run_start))
	var ys: Array = pos.map(func(p): return (p as Vector3).y)
	var y_hi: float = ys.max()
	var y_lo: float = ys.min()
	out += "  SUMMARY %s: straight(5 deg, 20 s window) %d of %d run-seconds = %.1f%% | pitch up %.1f deg, down %.1f deg, total pitch travel %.1f deg, largest single change %.1f deg | height %.0f..%.0f m | band roll max %.1f deg (world level leans up to %.1f) | R7 dest radius start %.2f mid %.2f end %.2f deg, max %.2f%% of the lowered porthole | dest inside the default window %d of %d s\n" % [
		_route_id, straight, n + 1, 100.0 * float(straight) / float(n + 1), up_max, dn_max,
		travel, biggest, y_lo, y_hi, roll_max, world_max, float(r_at.get(0, 0.0)),
		float(r_at.get(n / 2, 0.0)), float(r_at.get(n, 0.0)), area_max, inwin, n + 1]
	advance((keep / LANE_SPEED) - _pad_sec, 0.0)
	_gate_z = keep_gz
	return out


## R10's numbers for the CURRENT frame, with the crosshair at (az, el) in the ship's frame. All in
## degrees relative to the crosshair, straight from the same route the glass is sent:
##   rim     where each rail crosses the porthole's bottom rim (FIELD_LOW = 28 deg below the
##           crosshair): how far out to each side, and how far ahead of the hull that is;
##   under   the track's centre 50 m and 300 m ahead - the part you "ride on" - as an angle below
##           the crosshair;
##   far     the destination's centre and radius; the rails' last point IS that centre, so the
##           gap between the track and the planet is zero by construction and the disc covers the
##           join.
func track_probe(az: float, el: float) -> String:
	# ROUND 2: measured on the track AS DRAWN (the same points the glass is sent), not on the route.
	var rim_el: float = el - 28.0
	var out := ""
	var pts: Array = _track_points()
	var ts: PackedFloat32Array = pts[2]
	for side in [0, 1]:
		var rail: PackedVector3Array = pts[side]
		var prev_el := INF
		var hit := ""
		for k in rail.size() - 1:
			for q in 8:
				var f: float = float(q) / 8.0
				var p: Vector3 = (rail[k] as Vector3).lerp(rail[k + 1], f)
				var pa: float = rad_to_deg(atan2(p.x, -p.z))
				var pe: float = rad_to_deg(atan2(p.y, Vector2(p.x, p.z).length()))
				if prev_el != INF and prev_el <= rim_el and pe > rim_el:
					hit = "%+.1f deg across at %.1f m ahead" % [wrapf(pa - az, -180.0, 180.0),
						lerpf(ts[k], ts[k + 1], f) - _lane_z]
					break
				prev_el = pe
			if hit != "":
				break
		out += "rail%s crosses the rim %s; " % ["L" if side == 0 else "R",
			hit if hit != "" else "(does not reach the rim)"]
	for dd in [50.0, 300.0]:
		var k := 0
		while k < ts.size() - 2 and ts[k + 1] - _lane_z < dd:
			k += 1
		var f: float = clampf((dd - (ts[k] - _lane_z)) / maxf(ts[k + 1] - ts[k], 0.001), 0.0, 1.0)
		var c: Vector3 = ((pts[0][k] as Vector3).lerp(pts[0][k + 1], f)
			+ (pts[1][k] as Vector3).lerp(pts[1][k + 1], f)) * 0.5
		var ca: float = rad_to_deg(atan2(c.x, -c.z))
		var ce: float = rad_to_deg(atan2(c.y, Vector2(c.x, c.z).length()))
		out += "track centre %.0f m ahead at %+.2f across, %.2f deg below the crosshair; " % [
			dd, wrapf(ca - az, -180.0, 180.0), el - ce]
	var dz: float = rad_to_deg(atan2(_dest_dir.x, -_dest_dir.z))
	var de: float = rad_to_deg(asin(clampf(_dest_dir.y, -1.0, 1.0)))
	out += "destination centre %+.2f across, %+.2f up from the crosshair, radius %.2f deg (the rails end at its centre)" % [
		wrapf(dz - az, -180.0, 180.0), de - el, rad_to_deg(atan(DEST_RADIUS / _dest_dist))]
	return out


## How far the R2 band leans on screen right now, in degrees, at the worst azimuth. ROUND 2: the
## band is the lane's plane (safari_eyepiece.gdshader, the aurora block), whose normal in the ship's
## frame is the ship's own up - so this is 0 by construction, and it is measured rather than
## asserted so a later change to either file shows up here.
func band_roll_deg() -> float:
	return _plane_lean_deg(Vector3.UP)


## How far the WORLD's level plane leans on screen right now - what round 1's band did. Reported
## beside the band so the climb the band no longer shows is still a number.
func world_lean_deg() -> float:
	return _plane_lean_deg(_ship_b.transposed() * Vector3.UP)


## A plane through the eye with normal `nu` (ship frame): at azimuth phi its elevation is
## atan(-(n.x sin phi - n.z cos phi) / n.y). The lean is the steepest slope of that curve (degrees
## of elevation per degree of azimuth, as an angle), which is what the eye reads as the horizon
## tilting. No bank means the world's can never exceed the pitch.
func _plane_lean_deg(nu: Vector3) -> float:
	var worst := 0.0
	var prev := 0.0
	for i in 73:
		var phi: float = deg_to_rad(-180.0 + 5.0 * float(i))
		var e: float = atan(-(nu.x * sin(phi) - nu.z * cos(phi)) / maxf(nu.y, 0.0001))
		if i > 0:
			worst = maxf(worst, rad_to_deg(atan(absf(e - prev) / deg_to_rad(5.0))))
		prev = e
	return worst


## A rail piece's plane for the glass: xyz its unit normal, w the rail's angular half-width at the
## piece's nearer end. w = -1 marks a degenerate piece (zero length, or pointing straight at the eye).
static func _piece(a: Vector3, b: Vector3) -> Vector4:
	var n: Vector3 = a.normalized().cross(b.normalized())
	if n.length() < 0.000002 or a.length() < 0.05 or b.length() < 0.05:
		return Vector4(0.0, 0.0, 1.0, -1.0)
	n = n.normalized()
	return Vector4(n.x, n.y, n.z, TRACK_RAIL_M / minf(a.length(), b.length()))


## One CSV row per run second, for the R8 plots: t, x, y, z of the ship, then its yaw and pitch.
func _write_route_csv(path: String) -> void:
	var keep: float = _lane_z
	var keep_gz := PackedFloat32Array(_gate_z)
	var fa := FileAccess.open(path, FileAccess.WRITE)
	if fa == null:
		push_warning("route csv: cannot write %s" % path)
		return
	fa.store_line("lane,name,reverse,t,x,y,z,yaw,pitch,dest_x,dest_y,dest_z")
	var nm: String = str(ROUTES.get(_route_id, ROUTES["lantern"])["name"])
	for i in int(floor(_run_seconds)) + 1:
		advance(float(i), 0.0)
		var f: Vector3 = -_ship_b.z
		fa.store_line("%s,\"%s\",%s,%d,%.2f,%.2f,%.2f,%.3f,%.3f,%.1f,%.1f,%.1f" % [
			_route_id, nm, str(_reverse), i, _ship_p.x, _ship_p.y, _ship_p.z,
			rad_to_deg(atan2(f.x, -f.z)), rad_to_deg(asin(clampf(f.y, -1.0, 1.0))),
			_dest_w.x, _dest_w.y, _dest_w.z])
	fa.close()
	advance((keep / LANE_SPEED) - _pad_sec, 0.0)
	_gate_z = keep_gz


func _gates_ahead() -> int:
	var n := 0
	for i in _gates.size():
		if _gates[i].position.z < 0.0:
			n += 1
	return n
