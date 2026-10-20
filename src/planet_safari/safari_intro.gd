class_name SafariIntro
extends Node3D
## THE SAFARI START CUTSCENE (prototype, builder SINTRO, 2026-10-19). The user: "a bit of a mini cutscene
## when you start a safari. Almost like how in Pokemon Snap at the start of the level you see the player
## moving then slowly zooming in and settling into a first person view" (OPTION A), or "3 scenes across the
## planet and a name of the planet fades in ... cut it down to 2 scenes and the start point" (OPTION B).
## Both are built so the user can compare them on the phone; ONE runner plays either, they differ only in
## the shot list. About TOTAL_SEC (4.5 s) from the black lifting to control.
##
## WHERE IT RUNS. PlanetSafari._run(), after the world is built and warmed behind the black, asks
## `kind_for` and, when it is "a" or "b", adds this node and awaits `done` INSTEAD of today's 0.45 s fade-in.
## Everything after (`phase = AWAKE`, `elapsed = 0.0`, the opening line) is unchanged, so THE TIMER STARTS
## WHEN CONTROL RETURNS, exactly as before. The schedule, the content's tick and every tip/hint run only in
## phase AWAKE, so nothing in the safari can start or arm during the intro: no creature is ticked, no event
## warned, no tip card or hover hint armed. The content is NOT ticked here (ticking it early would draw on
## its random numbers and change what a normal start does).
##
## THE DEV SWITCH. GameState.settings["safari_intro"] = "c" (both, the default) | "a" (the swoop) | "b" (the tour)
## | "off" (the dev menu's World tab, "Safari start intro"), read at each outing's start, for every outing that has
## intro data. "off", and any outing WITHOUT data, is today's start, line for line.
##
## ==================================================================================== FOR A PLANET BUILDER
## ENABLING AN OUTING takes DATA and, for an outing that is not a plain PlanetSafari, ONE hook line:
##   * A planet safari: its world script (worlds/<planet>.gd, a SafariWorld) adds `func intro_data() -> Dictionary`.
##     PlanetSafari._run already calls the hook. No data (no method, or {}) = today's start.
##   * Another outing that extends PlanetSafari (MeteorSurveyLevel, CaveVisit) replaces its own two "lift" lines
##         layer.show_awake_ui(true)
##         await layer.fade_to(0.0, FADE_SEC)
##     with the ONE line
##         if not await SafariIntro.lift(self, <its data Dictionary>): return
##     right after its world is built and warmed behind the black, before it gives control. `lift` plays the
##     cutscene when there is data and the switch allows, and otherwise runs exactly those two old lines. It returns
##     false only when the host is going away mid-intro (stop then: no control, no timer). What the host must have,
##     as PlanetSafari does: `player`, `rig`, `planet` (anything with Planet's `surface_point` / `up_at` /
##     `height_at` / `radius` / `global_position` - MeteorRock is one), `start_dir` / `start_fwd`, `layer` (a
##     SafariLayer: `fade_to`, `show_awake_ui`, a "Root" control), the player standing on the start in first person
##     (`rig.set_first_person(true)` done), and the black UP when `lift` is called.
## THE DATA (all optional except as marked; Zorp's `intro_data()` in worlds/zorp.gd is the worked example):
##   "title": "Zorp's Violet Hollow"   the name (default: the planet's display_name)
##   "title_lines": ["ZORP'S VIOLET", "HOLLOW"]   how it breaks (default: upper case, split in two near the middle
##                                     when longer than 12 letters)
##   "subtitle": "The Glowing Garden"  the small line under it (Baloo 2), "" for none
##   "title_style": {...}              TitleLettering's style (title_lettering.gd, THE PLANET INTERFACE); missing keys
##                                     come from TitleLettering.default_style()
##   "scene1": {...}  REQUIRED for "c": the ONE slow opening view, a shot as below. WITHOUT it "c" plays the OLD
##                    start (not scene 2 alone): a swoop with no name card would be a third variant nobody chose.
##                    Data that cannot play (wrong types, a path under 2 points, a swoop key list under 2 keys) is
##                    refused with ONE push_warning and also plays the old start (`data_problem`).
##   "total": 8.5     seconds from the black lifting to control, clamped to C_TOTAL_MIN..C_TOTAL_MAX (8..10)
##   "cut": 3.9       when scene 1 hands over to the swoop (the name is in and out inside scene 1)
##   "swoop": {...}   overrides for the astronaut swoop (scene 2), keys of SwoopPath: "walk_m", "walk_steady",
##                    "walk_stop", "freeze", and time keys "phi" / "r" / "h" / "look_y" / "lead" as arrays of
##                    Vector3(t, value, slope per second) over scene 2's own clock (default `_path_c`, scaled to fit)
##   "terrain_follow": true   false where the start is not on the planet's ground (the cave): the walk is a rigid arc
##   "double_light": {"color": Color, "energy": 1.0, "range": 4.0}   a light only the astronaut double sees (layer
##                    DOUBLE_LAYER): where the world's lighting is baked into vertex colours (the cave). Optional
##                    "fade_sec": 0.4 dims it to nothing over the last fade_sec before he vanishes (the push into
##                    the helmet), so a brightly lit dome never fills the frame at full light
##   "tour": [shot, ...]   option "b" only: the shots of the tour (secs adding up to TOTAL_SEC)
## A SHOT: "secs"; "ease" "linear" | "out" | "inout"; the lens path EITHER "path": [Vector2(degrees round the start,
## bearing from the start heading)] with "height": Vector2(first, last) metres above the ground, OR "local_path":
## [Vector3(x right, y up, z back)] metres in the START FRAME (the player's own transform at the start: use it for a
## rock or a cave); the aim "look_from" / "look_to": Vector3(round, bearing, metres up) or "fp" (the safari's
## first-person view), OR "local_look_from" / "local_look_to": Vector3 in the start frame; optional "cast":
## {"npc": id, "at": Vector2(round, bearing), "emote": "wave", "out_m": 0.9} (a stand-in neighbour, never the real
## one); optional "spores_at": Vector2(round, bearing) - or "local_spores_at": Vector3 metres in the start frame, for
## a cave or a rock - and "spore_cols": [Color] (scene 1's cosmetic spore drift, the intro's own particles).
## DO NOT TOUCH (planet builders): this file, title_lettering.gd, the planet_safari.gd hook, the dev row. A planet's
## shapes go in titles/<planet>_title.gd (title_lettering.gd's interface), its data in its own world script.
##
## WHAT IT TOUCHES, AND PUTS BACK (also from `_exit_tree`, so a quit or scene change mid-intro leaves
## nothing behind):
##   * its own Camera3D, current for the intro; the rig's camera is made current again at the end. The last
##     HANDBACK_SEC blend the intro's lens into the rig's live first-person lens (position, direction, FOV),
##     so the hand-back step is one frame of ordinary motion.
##   * the "safari_intro" modal, open for the whole intro: the player cannot walk, look, hop or talk, the
##     touch stick hides, and SafariLayer ignores every press (it only listens in phase AWAKE).
##   * SafariLayer's black: set to clear the instant this node's own (identical navy) black is up, so the
##     lift and the dips run on THIS node's clock - which freezes while the Skip pop-up is open.
##   * SafariLayer's "Root" (the shutter, film, sun-dial, End button): shown and faded in over the last
##     UI_FADE_SEC, fully opaque at control.
## It never touches the player, the real astronaut model, the real Zorp or the content. Option A's walking
## astronaut is a DOUBLE (an AstronautModel in the player's own style, on render layer DOUBLE_LAYER, which
## only the intro's camera draws); the real astronaut is already standing at the start, hidden by the rig's
## first-person layer, so the double walks INTO him and the lens goes through the double's helmet into the
## real first-person eye. The double vanishes by the same mechanism the rig uses (the camera stops drawing its
## layer), never `visible`. Option B's waving Zorp is a double too (NpcModels.make), so the real Zorp's
## place, emote and wander state are exactly what a normal start leaves.
##
## SKIP. The first time a save sees a prototype it plays in full (GameState.flags SEEN_FLAG_PREFIX + kind, set
## when it ends). Later ones show a small "Skip" pill bottom right (the cockpit's look, at least SKIP_MIN_PT
## tall on a phone, clear of the home bar): it, any key, or a pad button opens SkipConfirm ("Skip the
## intro?"); the clock is frozen while it is open; a tap anywhere else does nothing. A confirmed skip dips to
## navy, lands in the end state (rig lens current, first-person pose, UI shown) and lifts in SKIP_LIFT_SEC.

signal done(skipped: bool)

const SETTING := "safari_intro"
## "b" since the critic's round (2026-10-19): the user's first Zorp safari plays the version with no known pop.
const DEFAULT_KIND := "c"
const SEEN_FLAG_PREFIX := "safari_intro_seen_"
const MODAL := "safari_intro"

## Render layer of option A's double (1-based). 17 is the rig's first-person layer, 19 the rocket's ground
## light, 20 the crash's fill, 6 the water: 18 is free (grep `layers` / `cull_mask`, 2026-10-19).
const DOUBLE_LAYER := 18
const DOUBLE_BIT := 1 << (DOUBLE_LAYER - 1)
## Over SafariLayer (30), under SafariLayer's own black (99) and SkipConfirm (150).
const CARD_LAYER := 98

## From the black starting to lift to control.
const TOTAL_SEC := 4.5
const LIFT_SEC := 0.5
## The intro's lens blends into the rig's first-person lens over the last this-long.
const HANDBACK_SEC := 0.8
## SafariLayer's controls fade in over the last this-long (opaque at control).
const UI_FADE_SEC := 0.35
## Option B: the dip between shots (out and back in), and the name card's fade out at the end.
const DIP_SEC := 0.18
const CARD_OUT_SEC := 0.5
## OPTION B's TITLE, the planet's own lettering (TitleLettering, the user: "takes up a lot of the screen and is in the
## center middle. Then it becomes more transparent and fades out"). Its strength over the 4.5 s, in order:
## fades IN with the black's lift to full by TITLE_IN_END; HOLDS full to TITLE_HOLD_END; DRIFTS smoothly down to
## TITLE_DRIFT_ALPHA by TITLE_DRIFT_END (the middle of scene 2) so the scenes show through; LINGERS, still thinning,
## to TITLE_LINGER_ALPHA at TITLE_LINGER_END; then FADES OUT, gone (and no longer drawn) at TITLE_GONE, before
## control. It grows by TITLE_GROW (a few percent) from the end of the hold to gone.
const TITLE_IN_END := 0.5
const TITLE_HOLD_END := 1.5
const TITLE_DRIFT_END := 2.2
const TITLE_DRIFT_ALPHA := 0.33
const TITLE_LINGER_END := 3.6
const TITLE_LINGER_ALPHA := 0.22
const TITLE_GONE := 4.4
const TITLE_GROW := 0.06
## The subtitle comes in a little after the title (then follows its schedule).
const SUB_IN := Vector2(0.45, 1.0)
## The title block (lettering + subtitle) fits inside this share of the screen's height and of its width between
## the safe areas.
const TITLE_MAX_H := 0.40
const TITLE_MAX_W := 0.80
## The title and its planet backdrop, at their largest, stay this share of the screen HEIGHT inside every edge.
const TITLE_EDGE := 0.03
## The block's vertical centre, as a share of the screen height from the top (0.5 = the middle).
## 0.28: the two-line block ends above Zorp's head in scene 2 (three centred lines ran across his face).
const TITLE_CENTER_Y := 0.28
## The lettering atlas is baked at this share of the cap height the screen shows (0.75: about 56% of the texture
## memory of a full-resolution bake; compared side by side at phone size).
const TITLE_BAKE_SCALE := 0.75
## The intro's own lens (the rig's first person is 45).
const INTRO_FOV := 50.0
## The warm-up draws every pose with this much wider a lens (vertical degrees), so what ANY screen shape will see
## near the path - a 4:3 tablet, a 16:9 desktop, a 2.17:1 phone - is drawn, and its shaders compiled, behind the
## black. Measured without it (critic, then here, 1280x720 at 30 fps, 2 of 2 runs): a 138-140 ms frame at 5.54 s in
## "c", the very frame the rocket's hull glints (RocketModel `_build_sparkle`, a quad-glint shader) first entered a
## 16:9 view; the phone-shaped warm-up poses had happened to draw them, the 16:9 ones had not.
const WARM_FOV := 110.0
## The intro clock's largest step per frame (seconds; see `_process`).
const MAX_STEP_SEC := 0.05
const SKIP_ARM_SEC := 0.3
const SKIP_MIN_PT := 44.0
const SKIP_DIP_SEC := 0.2
const SKIP_LIFT_SEC := 0.3
## Director timelines tap these (Input.action_press sends no InputEvent): CockpitIntro's set.
const SKIP_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "cancel", "pause"]

# ------------------------------------------------------------------------------ option A, the swoop
## How far behind the start the double begins (metres along the start heading). The pad's centre is 3.2 m
## behind the start (PlanetSafari.PAD_STEP_M), its deck 2.55 m round (RocketPad.PAD_R) and the rocket's hull
## 0.62 m: the start is only 0.65 m off the deck, so a walk along the heading that ENDS on the start always begins
## on the deck. 1.6 m keeps him about 1 m clear of the hull and steps him off the deck early in the shot.
const A_WALK_M := 1.6
## THE SWOOP'S PATHS (`SwoopPath`, built by `_path_a` and `_path_c`): every lens quantity is TIME KEYS joined by
## cubic Hermite curves - a pure function of time, never of an animated bone. Two measured fixes (2026-10-19, the
## user: "the back of the astronaut's head is like weirdly sucking in and out"; mask-render measurement in the
## report): (1) he stops walking BEFORE the lens comes round behind him and his pose is then FROZEN - the walk's
## root squash (+-2.2% in height at the stride, not scaled down for a slow walk) and the neck's +-0.10 rad roll had
## the dome's silhouette pulsing +-4% at ~1 Hz; (2) the radius has a matching slope where the orbit hands over to the
## push - the old orbit eased to a halt at 2.6 s and the push eased off from it, so the lens hovered 0.4 s at
## 1.46 m while the head pumped, then lurched in.
## The opening (both paths) is from his LEFT side, aimed ahead of him (room in front of a walking subject): the
## rocket, 1.6 m behind him at the start, stays outside the frame's ~45 degree half-width.
## The look the push ends on, before the settle tilts it up to the safari's own START_PITCH_DEG (-10): lower, so
## the ground ahead and the start's crystal fill the view through the vanish (the critic: "70% empty sky").
const A_END_PITCH_DEG := -16.0
## THE VANISH is covered by a dip to the visor's navy (the intro's own black), up over A_DIP_IN to full on the frame
## he vanishes and back over A_DIP_OUT: going "into his head" rather than a shape disappearing in one frame.
const A_DIP_IN := 0.14
## During the push the lens aims at a point that slides this far ahead of his helmet (see `_swoop`).
const PUSH_AIM_AHEAD := 2.0
const A_DIP_OUT := 0.10
## THE VISOR DIM FOLLOWS THE HELMET'S SIZE ON SCREEN (2026-10-20, the critics: the distance-timed dip left 3-5 frames
## with the helmet filling a third to three quarters of the frame undimmed - in the cave, its `double_light`-lit
## dome made a white flash, mean frame brightness 50 -> 176). Every frame the lens measures the share of the frame
## the dome covers (`_dome_share`, rays through a HELMET_GRID grid) and the black is at least 1 - VISOR_SHARE /
## share: the helmet's UNDIMMED share of the frame (share x (1 - black)) never exceeds VISOR_SHARE. The A_DIP_IN
## ramp still ends at full black on the vanish frame (the dome covering the diagonal: share 1).
const VISOR_SHARE := 0.30
const HELMET_GRID := Vector2i(48, 24)
## The brass camera in his hands, this many times the cockpit's (so it reads from 3 m).
const A_CAM_SCALE := 1.5

# ------------------------------------------------------------------------------ "c", the combined start
## The user (2026-10-19, after the MP4s): "a combination of both ... It seems a bit too quick ... one interesting view
## on the planet but its like panning across or zooming out ... with the name appearing and disappearing, then it
## switches to the one where it pans out and flies behind the astronaut." SCENE 1 (0..C_CUT): one slow move over
## the world's `intro_scene_c()` view with the name in and out; a C_DIP_SEC navy dip; SCENE 2 (C_CUT..C_TOTAL):
## the swoop, `_path_c`. Control at C_TOTAL.
const C_CUT := 3.9
const C_TOTAL := 8.5
## A planet's "total" is held inside these (the user, 2026-10-19: "up to about 8-10 seconds").
const C_TOTAL_MIN := 8.0
const C_TOTAL_MAX := 10.0
const C_DIP_SEC := 0.28
## The name in scene 1: fades in over C_TITLE_IN0..C_TITLE_IN1, holds, fades out over C_TITLE_OUT0..C_TITLE_GONE -
## gone well before the cut.
const C_TITLE_IN0 := 0.35
const C_TITLE_IN1 := 0.95
const C_TITLE_OUT0 := 2.55
const C_TITLE_GONE := 3.25
## Scene 1 has no neighbour under the name, so it sits nearer the middle.
const C_TITLE_CENTER_Y := 0.34

var safari: PlanetSafari
var kind := ""
var skippable := false

var _cam: Camera3D
var _rig_cam: Camera3D
var _t := 0.0
var _running := false
var _done := false
var _confirming := false
var _skipping := false
var _modal_open := false
var _ui_shown := false
var _skip_primed := false
var _skip_held: Dictionary = {}
var _hide_dist := 0.5
var _double_hidden := false
var _helmet_share := 0.0         # the share of this frame the double's dome covers (0 when he is not drawn)
var _dl: OmniLight3D             # the double's own light ("double_light"), if any
var _dl_energy := 0.0
var _dl_fade := 0.0
## When option A's lens reaches _hide_dist (found once from the path, before the clock starts).
var _t_hide := -1.0
## True when `done` came from `_exit_tree` (this node, and probably the scene, going away): the caller must
## not start the safari.
var aborted := false
var _warming := false

var _card_layer: CanvasLayer
var _card_root: Control
var _black: ColorRect
var _title: Label
var _sub: Label
var _lettering: TitleLettering
var _title_fit := 1.0
var _title_alpha := 0.0
var _skip: Button
var _ui_root: Control

# option A
var _double: AstronautModel
var _shadow: MeshInstance3D
var _base_xf := Transform3D()       # the real player's body at the start
var _model_local := Transform3D()   # its model, relative to the body
var _shadow_local := Transform3D()  # its blob shadow, relative to the body
var _axis := Vector3.RIGHT          # rotating the start about this walks it forward
var _h0 := 0.0
var _walk_v := 1.0
var _path: SwoopPath                # the swoop playing (option A's or "c"'s scene 2)
var _a_t0 := 0.0                    # when the swoop starts on the intro clock (0, or C_CUT)
var _total := TOTAL_SEC             # from the lift to control for this kind
var _title_center := TITLE_CENTER_Y
var _data: Dictionary = {}           # the outing's intro data (see FOR A PLANET BUILDER)
var _start_xf := Transform3D()       # the player at the start: the frame "local_path" points are in
var _c_cut := C_CUT
var _terrain := true

# option B
var _shots: Array[Shot] = []        # compiled once: see `_build_b`
var _cuts := PackedFloat32Array()   # shot start times
var _zorp: Node3D                   # the waving double
var _zorp_shot := -1
var _pad_saved: Array = []          # the pad fixtures hidden during the swoop: [GeometryInstance3D, layers, cast_shadow]
var _pad_fix: Array[Node3D] = []     # the fixtures to hide (found once, behind the black)
var _pad_off := false
var _ambient: Array[CPUParticles3D] = []   # "c" scene 1's spores (the intro's own; nothing of the world's)

# trace
var _trace := false


## THE ENTRY (see FOR A PLANET BUILDER). Plays the start cutscene for `host` when its outing has intro data (`data`,
## or its world script's `intro_data()`) and the dev switch allows; otherwise does exactly the old lift (show the
## controls, fade the black away over PlanetSafari.FADE_SEC). True when control should be given now; false when the
## host is going away mid-intro (the caller stops: no control, no timer).
static func lift(host: PlanetSafari, data: Dictionary = {}) -> bool:
	var d := data if not data.is_empty() else data_for(host)
	var k := kind_for_data(d)
	if k == "":
		host.layer.show_awake_ui(true)
		await host.layer.fade_to(0.0, PlanetSafari.FADE_SEC)
		return true
	var intro := SafariIntro.new()
	intro.setup(host, k, d)
	host.add_child(intro)
	intro.start()
	await intro.done
	if not is_instance_valid(host):
		return false
	if intro.aborted or not host.is_inside_tree() or host.is_queued_for_deletion() or bool(host.get("_restored")):
		# The host is going away mid-intro (the intro's own _exit_tree said so): no control, but no locked player.
		if is_instance_valid(host.player):
			host.player.set_move_locked(false)
		return false
	return true


## The outing's intro data: its world script's `intro_data()`, or {} (none: today's start).
static func data_for(host: PlanetSafari) -> Dictionary:
	var content: Object = host.get("_content")
	if content != null and content.has_method("intro_data"):
		var d: Variant = content.call("intro_data")
		if d is Dictionary:
			return d
	return {}


## Which intro `data` plays under the dev switch: "a", "b", "c" or "" (today's start). Data that would not play
## cleanly (see `data_problem`) is refused with a push_warning: today's start, never a broken view.
static func kind_for_data(data: Dictionary) -> String:
	if data.is_empty():
		return ""
	var k := str(GameState.settings.get(SETTING, DEFAULT_KIND))
	if k == "off":
		return ""
	if k != "a" and k != "b" and k != "c":
		# A value that is none of the four (a corrupted save, "zzz", 1, null) plays the DEFAULT: it must not
		# silently turn the start cutscene off. Only an explicit "off" does that.
		k = DEFAULT_KIND
	if k == "c" and not data.has("scene1"):
		return ""   # no scene 1 = no "c": the old start (documented in FOR A PLANET BUILDER)
	if k == "b" and not data.has("tour"):
		return ""
	var why := data_problem(data, k)
	if why != "":
		push_warning("SafariIntro: the intro data cannot play (%s); the old start plays instead." % why)
		return ""
	return k


## "" when `data` can play as `k`, else what is wrong with it (types, too few points). Checked BEFORE anything is
## built, so a broken planet file costs one warning and today's start.
static func data_problem(data: Dictionary, k: String) -> String:
	for key: String in ["total", "cut"]:
		if data.has(key) and not (data[key] is float or data[key] is int):
			return "\"%s\" is not a number" % key
	if data.has("title") and not (data["title"] is String):
		return "\"title\" is not text"
	if data.has("subtitle") and not (data["subtitle"] is String):
		return "\"subtitle\" is not text"
	if data.has("title_style") and not (data["title_style"] is Dictionary):
		return "\"title_style\" is not a Dictionary"
	if data.has("title_lines"):
		if not (data["title_lines"] is Array or data["title_lines"] is PackedStringArray):
			return "\"title_lines\" is not a list"
		for l: Variant in data["title_lines"]:
			if not (l is String):
				return "\"title_lines\" holds something that is not text"
	if data.has("terrain_follow") and not (data["terrain_follow"] is bool):
		return "\"terrain_follow\" is not true/false"
	if data.has("double_light") and not (data["double_light"] is Dictionary):
		return "\"double_light\" is not a Dictionary"
	if data.has("double_light"):
		for key: String in ["energy", "range", "fade_sec"]:
			var v: Variant = (data["double_light"] as Dictionary).get(key, 0.0)
			if not (v is float or v is int):
				return "double_light \"%s\" is not a number" % key
	if data.has("swoop"):
		if not (data["swoop"] is Dictionary):
			return "\"swoop\" is not a Dictionary"
		for key: String in ["walk_m", "walk_steady", "walk_stop", "freeze", "push0", "push1"]:
			if (data["swoop"] as Dictionary).has(key) and not (data["swoop"][key] is float or data["swoop"][key] is int):
				return "swoop \"%s\" is not a number" % key
		for key: String in ["phi", "r", "h", "look_y", "lead"]:
			if (data["swoop"] as Dictionary).has(key) and not _vec3_list(data["swoop"][key], 2):
				return "swoop \"%s\" needs at least 2 Vector3(t, value, slope) keys" % key
	if k == "c":
		var why := _shot_problem(data.get("scene1"), "scene1")
		if why != "":
			return why
	if k == "b":
		if not (data["tour"] is Array) or (data["tour"] as Array).is_empty():
			return "\"tour\" is not a list of shots"
		for i in (data["tour"] as Array).size():
			var why := _shot_problem(data["tour"][i], "tour shot %d" % i)
			if why != "":
				return why
	return ""


static func _shot_problem(shot: Variant, label: String) -> String:
	if not (shot is Dictionary):
		return "%s is not a Dictionary" % label
	var sh := shot as Dictionary
	if sh.has("local_path"):
		if not _vec3_list(sh["local_path"], 2):
			return "%s \"local_path\" needs at least 2 Vector3 points" % label
	elif sh.has("path"):
		var p: Variant = sh["path"]
		if not (p is Array or p is PackedVector2Array) or int(p.size()) < 2:
			return "%s \"path\" needs at least 2 Vector2 points" % label
		for v: Variant in p:
			if not (v is Vector2):
				return "%s \"path\" holds something that is not a Vector2" % label
		if not (sh.get("height") is Vector2):
			return "%s needs a Vector2 \"height\" with its \"path\"" % label
	else:
		return "%s has no \"path\" or \"local_path\"" % label
	for key: String in ["look_from", "look_to"]:
		if sh.has(key) and not (sh[key] is Vector3 or str(sh[key]) == "fp"):
			return "%s \"%s\" is not a Vector3 or \"fp\"" % [label, key]
	for key: String in ["local_look_from", "local_look_to"]:
		if sh.has(key) and not (sh[key] is Vector3):
			return "%s \"%s\" is not a Vector3" % [label, key]
	if sh.has("secs") and not (sh["secs"] is float or sh["secs"] is int):
		return "%s \"secs\" is not a number" % label
	if sh.has("spores_at") and not (sh["spores_at"] is Vector2):
		return "%s \"spores_at\" is not a Vector2" % label
	if sh.has("local_spores_at") and not (sh["local_spores_at"] is Vector3):
		return "%s \"local_spores_at\" is not a Vector3" % label
	if sh.has("cast") and not (sh["cast"] is Dictionary):
		return "%s \"cast\" is not a Dictionary" % label
	return ""


static func _vec3_list(v: Variant, at_least: int) -> bool:
	if not (v is Array or v is PackedVector3Array):
		return false
	var n: int = v.size()
	if n < at_least:
		return false
	for e: Variant in v:
		if not (e is Vector3):
			return false
	return true


func setup(s: PlanetSafari, intro_kind: String, data: Dictionary = {}) -> void:
	safari = s
	kind = intro_kind
	_data = data
	name = "SafariIntro"


func _ready() -> void:
	process_priority = 20   # after CameraRig (10): the rig's lens is already this frame's when it is read
	_trace = OS.get_cmdline_user_args().has("--safari-intro-trace")


## Builds everything behind the black and starts the clock. `done` is emitted once, when control should
## return (or from `_exit_tree` if this node is freed first).
func start() -> void:
	skippable = bool(GameState.flags.get(SEEN_FLAG_PREFIX + kind, false))
	_rig_cam = safari.rig.get_view_camera()
	_build_card()
	EventBus.ui_modal_opened.emit(MODAL)
	_modal_open = true
	# Our black is up (navy, opaque, under SafariLayer's own): clear SafariLayer's so ours is the one that lifts.
	safari.layer.fade_to(0.0, 0.0)
	_ui_root = safari.layer.get_node_or_null("Root") as Control
	_cam = Camera3D.new()
	_cam.name = "IntroCamera"
	_cam.near = _rig_cam.near
	_cam.far = _rig_cam.far
	_cam.environment = _rig_cam.environment
	_cam.attributes = _rig_cam.attributes
	_cam.keep_aspect = _rig_cam.keep_aspect
	_cam.cull_mask = _rig_cam.cull_mask
	_cam.fov = INTRO_FOV
	add_child(_cam)
	_start_xf = safari.player.global_transform
	_terrain = bool(_data.get("terrain_follow", true))
	if kind == "a":
		_path = _path_a()
		_total = TOTAL_SEC
		_build_a()
		_find_pad_fixtures()
		_cam.cull_mask = _rig_cam.cull_mask | DOUBLE_BIT
	elif kind == "b":
		_build_b(_data.get("tour", []))
	else:
		_total = clampf(float(_data.get("total", C_TOTAL)), C_TOTAL_MIN, C_TOTAL_MAX)
		_c_cut = clampf(float(_data.get("cut", C_CUT)), 2.0, _total - 3.6)
		_path = _path_c(_total - _c_cut, _data.get("swoop", {}))
		_a_t0 = _c_cut
		_title_center = C_TITLE_CENTER_Y
		var scene: Dictionary = (_data["scene1"] as Dictionary).duplicate()
		scene["secs"] = _c_cut
		_build_b([scene])
		_build_ambient(scene)
		_build_a()
		_find_pad_fixtures()
		_cam.cull_mask = _rig_cam.cull_mask | DOUBLE_BIT
	# He vanishes when the dome covers the WHOLE frame - its angular radius reaches half the DIAGONAL field of
	# view - or, if the near plane would cut into the dome before that, just outside the near plane (helmet
	# radius + the near plane's corner distance). The visor dip (A_DIP_IN/OUT) covers whatever corner is left.
	_hide_dist = maxf(_helmet_radius() / sin(_half_diag_fov(_cam)), _helmet_radius() + _near_corner(_cam))
	if _path != null:
		_t_hide = _a_t0 + _find_hide_time()
	_cam.current = true
	# WARM-UP behind the black: one frame from each shot's pose, so whatever the intro shows for the first time
	# (the doubles, the brass camera, a corner of the planet the player has not looked at, the card's text) is
	# drawn - its shaders compiled - before anyone can see it. Measured without it: two 125-145 ms frames in
	# option B (the crystal field coming into view, and Zorp's stand-in's first frame).
	var us0 := Time.get_ticks_usec()
	if _lettering != null:
		# Baked once, behind the black, at the cap height the screen will really show at its largest (the fit,
		# the grow, and the window's stretch: 1.64 on a 1179-px-tall phone).
		# It renders during the first warm-up frame below (bake_finish after the loop).
		var stretch := get_tree().root.get_final_transform().get_scale().y
		_lettering.bake_start(TitleLettering.BUILD_CAP_PX * _title_fit * (1.0 + TITLE_GROW) * stretch * TITLE_BAKE_SCALE)
	_warming = true
	# The card's text is pre-drawn UNDER the opaque black (moved below it in the card's draw order) at full strength,
	# so its first visible frame is not its first draw, and no ghost of the name shows on the black before the lift.
	_card_under_black(true)
	# Each pose twice: at WARM_FOV (what any screen shape sees near the path) and at the intro's own INTRO_FOV. The wide
	# pose alone missed a one-time cost of the first frame drawn with a NARROW lens (measured 2026-10-20, 2556x1179:
	# Bolt 61-78 ms on the frame before the lift, 6 of 6 runs; the Tangle's original scene 1, from (46, 37) 1.8 m up,
	# 115-150 ms 0.5 s in, 3 of 3; Bolt: 58 degrees triggers it, 65 does not). It is in drawing the world's own
	# layer-1 geometry - a narrow frame with no Environment still paid it, a frame drawing nothing (cull mask 0, the
	# shadow pass only) did not - and spread over several objects (the planet's surface and props ~49 ms, the
	# safari's creatures and pad ~45 ms), so likely something first sampled when objects cover more of the screen
	# (unproven). Drawn once at the narrow lens on ANY pose, it never came back: both stalls gone, max 35 ms.
	for wt: float in _warm_times():
		for fv: float in [WARM_FOV, INTRO_FOV]:
			_apply_shot(wt, 0.0)
			_cam.fov = fv
			await get_tree().process_frame
			if _done or not is_inside_tree():
				return
	_warming = false
	if _lettering != null:
		_lettering.bake_finish()
		_log("title baked into a %s atlas" % str(_lettering.atlas_size))
	if _zorp != null:
		_zorp.visible = false
	# (The baked sprites exist only from here: they draw once more, still under the black - a 26 ms frame in B was
	# measured when their first draw was a visible frame.)
	_apply_shot(0.0, 0.0)
	await get_tree().process_frame
	if _done or not is_inside_tree():
		return
	_card_under_black(false)
	_running = true
	_t = 0.0
	_log("start kind=%s skippable=%s hide_dist=%.2f t_hide=%.3f warm=%d poses %.1f ms" % [kind, str(skippable),
		_hide_dist, _t_hide, _warm_times().size(), float(Time.get_ticks_usec() - us0) / 1000.0])
	if _path != null:
		# He must end exactly on the real player: his feet at the end of the walk vs the player's body.
		_log("double ends %.5f m from the player's start" % _frame_at(_walk_s(_path.total)).origin.distance_to(
			safari.player.global_position))


func _process(delta: float) -> void:
	if not _running or _done or _skipping:
		return
	if _confirming or get_tree().paused:
		return
	# One slow frame must not shorten the sequence (the Tangle: a 115 ms first frame made lift-to-control 8.39 s):
	# the clock steps at most MAX_STEP_SEC a frame, and the first running frame (whose delta holds the last frame
	# under the black) one 30 fps frame.
	var step := minf(delta, MAX_STEP_SEC if _t > 0.0 else 1.0 / 30.0)
	_t = minf(_t + step, _total)
	_apply_shot(_t, step)
	_apply_overlays(_t)
	if _skip != null:
		_skip.visible = skippable and _t >= SKIP_ARM_SEC and _t < _total - UI_FADE_SEC
	if _t >= _total:
		_finish(false)


# ======================================================================================== THE SHOTS
## Places the intro lens (and the doubles) for time `t`, then blends it into the rig's lens over the last
## HANDBACK_SEC.
func _apply_shot(t: float, delta: float) -> void:
	var xf: Transform3D
	var fov := INTRO_FOV
	if kind == "a":
		_hide_pad_fixtures(true)
		xf = _swoop(t, delta)
	elif kind == "b":
		xf = _shot_b(t, delta)
	else:
		xf = _shot_c(t, delta)
	var w := smoothstep(_total - HANDBACK_SEC, _total, t)
	if w > 0.0:
		var rx := _rig_cam.global_transform
		var q := xf.basis.get_rotation_quaternion().slerp(rx.basis.get_rotation_quaternion(), w)
		xf = Transform3D(Basis(q), xf.origin.lerp(rx.origin, w))
		fov = lerpf(INTRO_FOV, _rig_cam.fov, w)
	_cam.global_transform = xf
	_cam.fov = fov
	if _path != null and t >= _a_t0 and not _double_hidden and not _warming and _double != null:
		var helmet := _frame_at(_walk_s(t - _a_t0)) * Vector3(0.0, AstronautModel.HELMET_CY, 0.0)
		# At the vanish time found from the path (the same distance test, at the dip's darkest frame).
		if (_t_hide > 0.0 and t >= _t_hide) or xf.origin.distance_to(helmet) < _hide_dist:
			_double_hidden = true
			_cam.cull_mask = _rig_cam.cull_mask & ~DOUBLE_BIT
			_log("double hidden at t=%.3f (lens %.2f m from the helmet centre)" % [t, xf.origin.distance_to(helmet)])
		_helmet_share = 0.0 if _double_hidden else _dome_share(xf, fov, helmet)
		if _dl != null and _dl_fade > 0.0 and _t_hide > 0.0:
			_dl.light_energy = _dl_energy * (1.0 - smoothstep(_t_hide - _dl_fade, _t_hide, t))
	else:
		_helmet_share = 0.0
	if _trace:
		var f := -xf.basis.z
		print("[SafariIntro] t=%.3f pos=(%.3f,%.3f,%.3f) fwd=(%.3f,%.3f,%.3f) fov=%.2f w=%.3f" % [t, xf.origin.x,
			xf.origin.y, xf.origin.z, f.x, f.y, f.z, fov, w])


## A lens transform looking along `dir` with the planet's up at `pos`.
func _look(pos: Vector3, dir: Vector3) -> Transform3D:
	var up := safari.planet.up_at(pos)
	var d := dir.normalized()
	if absf(d.dot(up)) > 0.999:
		up = -_rig_cam.global_transform.basis.z
	return Transform3D(Basis.looking_at(d, up), pos)


# ---------------------------------------------------------------------------- option A
func _build_a() -> void:
	var player := safari.player
	_base_xf = player.global_transform
	var model := player.get_model()
	_model_local = _base_xf.affine_inverse() * model.global_transform
	var up := safari.start_dir.normalized()
	_axis = up.cross(safari.start_fwd).normalized()
	_h0 = safari.planet.height_at(up)
	_walk_v = _path.walk_m / (_path.walk_steady + 0.5 * (_path.walk_stop - _path.walk_steady))
	_double = AstronautModel.new()
	_double.name = "IntroDouble"
	add_child(_double)
	_double.set_carry_item(brass_camera_mesh(A_CAM_SCALE), Vector3(0.0, 0.0575 * A_CAM_SCALE, 0.0))
	_double.set_state("carry_walk")
	# The player's own blob shadow, copied (Compatibility draws no cast shadows: without it he floats).
	var src := player.get_node_or_null("BlobShadow") as MeshInstance3D
	if src != null:
		_shadow = MeshInstance3D.new()
		_shadow.name = "IntroShadow"
		_shadow.mesh = src.mesh
		_shadow.material_override = src.material_override
		_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_shadow_local = _base_xf.affine_inverse() * src.global_transform
		add_child(_shadow)
	for gi: Node in _geometry(self, []):
		if gi != _cam:
			(gi as GeometryInstance3D).layers = DOUBLE_BIT
	# A light that ONLY the double sees (its layer), where the world's own light is baked into vertex colours (the
	# cave): it rides with him, above and in front. Added behind the black, so any shader variant it needs compiles
	# in the warm-up.
	var dl: Variant = _data.get("double_light")
	if dl is Dictionary:
		var l := OmniLight3D.new()
		l.name = "IntroDoubleLight"
		l.light_color = (dl as Dictionary).get("color", Color(1.0, 0.95, 0.85))
		l.light_energy = float((dl as Dictionary).get("energy", 1.0))
		l.omni_range = float((dl as Dictionary).get("range", 4.0))
		l.light_cull_mask = DOUBLE_BIT
		l.shadow_enabled = false
		_double.add_child(l)
		_dl = l
		_dl_energy = l.light_energy
		_dl_fade = maxf(float((dl as Dictionary).get("fade_sec", 0.0)), 0.0)
		l.position = Vector3(0.0, 1.8, -1.0)


## Metres along the start heading from the start (negative = behind) at swoop time `t`.
func _walk_s(t: float) -> float:
	var tc := _path.walk_steady
	var td := _path.walk_stop - _path.walk_steady
	var d: float
	if t <= tc:
		d = _walk_v * maxf(t, 0.0)
	elif t < _path.walk_stop:
		var u := (t - tc) / td
		d = _walk_v * tc + _walk_v * td * (u - 0.5 * u * u)
	else:
		d = _path.walk_m
	return d - _path.walk_m


func _walk_speed(t: float) -> float:
	if t <= _path.walk_steady:
		return _walk_v
	if t >= _path.walk_stop:
		return 0.0
	return _walk_v * (1.0 - (t - _path.walk_steady) / (_path.walk_stop - _path.walk_steady))


## The real player's body frame carried `s` metres along the start heading over the sphere (feet on the
## ground there, up = the planet's up, -Z = the heading there). At s = 0 it IS the player's frame.
func _frame_at(s: float) -> Transform3D:
	var p := safari.planet
	var c := p.global_position
	# The arc's radius is the START's own distance from the centre, not the planet's radius: the cave's start is
	# ~600 m from the planet's centre (49 radii), and `s / p.radius` walked the double 44 m into the rock for a 0.9 m
	# walk (the cave builder's measurement, re-measured here: 43.6 m). On a planet's surface the two agree to the
	# ground's height.
	var rot := Basis(_axis, s / maxf((_base_xf.origin - c).length(), 0.01))
	var o := c + rot * (_base_xf.origin - c)
	var d := (o - c).normalized()
	if _terrain:
		o += d * (p.height_at(d) - _h0)
	return Transform3D(rot * _base_xf.basis, o)


## One swoop path (see THE SWOOP'S PATHS): time keys Vector3(t, value, slope per second) for each lens quantity.
class SwoopPath:
	var walk_m := 1.6
	var walk_steady := 1.1
	var walk_stop := 1.8
	var freeze := 2.2                  # no animation ticks from here: a rigid head
	var phi := PackedVector3Array()    # degrees round from straight ahead toward his LEFT
	var r := PackedVector3Array()      # metres out from him
	var h := PackedVector3Array()      # lens height above his feet
	var look_y := PackedVector3Array() # where it looks on him (height above his feet)
	var lead := PackedVector3Array()   # how far ahead of him it looks (metres)
	var push0 := 2.6                   # the look turns from him to the first-person direction over push0..push1
	var push1 := 3.65
	var total := 4.5                   # the swoop's own length; its last HANDBACK_SEC blend into the rig


## Option A: the round-1 path (side opening, round to behind, push in), with the two measured fixes.
static func _path_a() -> SwoopPath:
	var p := SwoopPath.new()
	var hc := AstronautModel.HELMET_CY
	p.walk_m = 1.6
	p.walk_steady = 1.1
	p.walk_stop = 1.8
	p.freeze = 2.2
	p.phi = PackedVector3Array([Vector3(0.0, 95.0, 0.0), Vector3(2.6, 180.0, 0.0)])
	p.r = PackedVector3Array([Vector3(0.0, 2.4, 0.0), Vector3(2.6, 1.45, -1.0), Vector3(3.65, 0.0, 0.0)])
	p.h = PackedVector3Array([Vector3(0.0, 1.5, 0.0), Vector3(3.65, hc, 0.0)])
	p.look_y = PackedVector3Array([Vector3(0.0, 0.75, 0.0), Vector3(2.6, hc, 0.0)])
	p.lead = PackedVector3Array([Vector3(0.0, 1.2, 0.0), Vector3(2.6, 0.0, 0.0)])
	p.push0 = 2.6
	p.push1 = 3.65
	p.total = TOTAL_SEC
	return p


## "c"'s scene 2 (the user: "pans out and flies behind the astronaut"): it opens CLOSE and a little LOW on him
## walking with the brass camera, pulls back and rises to show him in the garden, swings round his left side to
## behind him, pushes into the helmet (the visor dip), and settles into the first-person view.
static func _path_c(length: float = C_TOTAL - C_CUT, over: Dictionary = {}) -> SwoopPath:
	var p := SwoopPath.new()
	var hc := AstronautModel.HELMET_CY
	# A short walk off the deck's edge: from 1.6 m in (option A's) the close opening had the pad's pillar and fuel
	# hose right behind his head (seen in the frames).
	p.walk_m = 0.9
	p.walk_steady = 0.8
	p.walk_stop = 1.4
	p.freeze = 1.9
	# Opens at his rear-left three-quarter: the rocket, 1.6 m behind him at the start, is ~80 degrees off the lens
	# axis there (outside the ~45 degree half-width); from his side or front the pad's pole, sign and hose filled the
	# frame behind him (seen in the first frames).
	p.phi = PackedVector3Array([Vector3(0.0, 128.0, 0.0), Vector3(1.4, 148.0, 12.0), Vector3(3.0, 180.0, 0.0)])
	p.r = PackedVector3Array([Vector3(0.0, 1.7, 0.0), Vector3(1.4, 2.3, 0.0), Vector3(3.0, 1.45, -0.9),
		Vector3(3.85, 0.0, 0.0)])
	p.h = PackedVector3Array([Vector3(0.0, 0.9, 0.0), Vector3(1.4, 1.5, 0.0), Vector3(3.85, hc, 0.0)])
	p.look_y = PackedVector3Array([Vector3(0.0, 0.8, 0.0), Vector3(1.4, 0.95, 0.0), Vector3(3.0, hc, 0.0)])
	p.lead = PackedVector3Array([Vector3(0.0, 0.5, 0.0), Vector3(1.4, 0.7, 0.0), Vector3(3.0, 0.0, 0.0)])
	p.push0 = 3.0
	p.push1 = 3.85
	p.total = C_TOTAL - C_CUT
	# A planet's own scene-2 length: every key time stretched to fit (the moves keep their shape).
	var f := length / p.total
	if absf(f - 1.0) > 1e-4:
		for keys_name: String in ["phi", "r", "h", "look_y", "lead"]:
			var ks: PackedVector3Array = p.get(keys_name)
			for i in ks.size():
				ks[i] = Vector3(ks[i].x * f, ks[i].y, ks[i].z / f)
			p.set(keys_name, ks)
		p.walk_steady *= f
		p.walk_stop *= f
		p.freeze *= f
		p.push0 *= f
		p.push1 *= f
		p.total = length
	# The planet's overrides (FOR A PLANET BUILDER, "swoop").
	for key: String in ["walk_m", "walk_steady", "walk_stop", "freeze", "push0", "push1"]:
		if over.has(key):
			p.set(key, float(over[key]))
	for key: String in ["phi", "r", "h", "look_y", "lead"]:
		if over.has(key):
			p.set(key, PackedVector3Array(over[key]))
	return p


## The value of time keys `k` at `t`: cubic Hermite between neighbouring keys (each key's slope), held at the ends.
static func _keys_at(k: PackedVector3Array, t: float) -> float:
	var n := k.size()
	if t <= k[0].x:
		return k[0].y
	if t >= k[n - 1].x:
		return k[n - 1].y
	var i := 0
	while i < n - 2 and t > k[i + 1].x:
		i += 1
	var a := k[i]
	var b := k[i + 1]
	var dt := b.x - a.x
	var u := (t - a.x) / dt
	var u2 := u * u
	var u3 := u2 * u
	return (2.0 * u3 - 3.0 * u2 + 1.0) * a.y + (u3 - 2.0 * u2 + u) * dt * a.z \
		+ (-2.0 * u3 + 3.0 * u2) * b.y + (u3 - u2) * dt * b.z


## The swoop at INTRO time `t` (`_path`, starting at `_a_t0`). The double walks, then stops and is frozen.
func _swoop(t: float, delta: float) -> Transform3D:
	var tau := t - _a_t0
	var p := _path
	var frame := _frame_at(_walk_s(tau))
	if _double != null:
		_double.global_transform = frame * _model_local
		var v := _walk_speed(tau)
		_double.set_state("carry_walk" if v > 0.05 else "carry_idle")
		if tau < p.freeze:
			_double.tick(delta, v / Player.WALK_SPEED)
		if _shadow != null:
			_shadow.global_transform = frame * _shadow_local
	var phi := deg_to_rad(_keys_at(p.phi, tau))
	var r := _keys_at(p.r, tau)
	var h := _keys_at(p.h, tau)
	var look_y := _keys_at(p.look_y, tau)
	var lead := _keys_at(p.lead, tau)
	# Azimuth from straight ahead (-Z) toward his left (-X).
	var local := Vector3(-sin(phi) * r, h, -cos(phi) * r)
	var pos := frame * local
	# During the push the aim point slides from his helmet to PUSH_AIM_AHEAD in front of it along his heading, so
	# the lens always looks forward THROUGH his head and the aim never degenerates as the lens reaches the helmet.
	var ahead := smoothstep(p.push0, p.push1, tau) * PUSH_AIM_AHEAD if tau > p.push0 else 0.0
	var at_dir := frame * Vector3(0.0, look_y, -lead - ahead) - pos
	var end_pitch := deg_to_rad(A_END_PITCH_DEG)
	var end_dir := frame.basis * Vector3(0.0, sin(end_pitch), -cos(end_pitch))
	# The aim gives way to the first-person aim over push0..push1, continuously: no snap (it used to jump to the
	# first-person aim when the lens came within 5 cm of a helmet-centre target - 2.4 degrees in one frame, measured
	# by the cave builder; the sliding aim point above keeps the target well ahead of the lens).
	var k := smoothstep(p.push0, p.push1, tau) if tau > p.push0 else 0.0
	var dir := at_dir.normalized().lerp(end_dir.normalized(), k) if at_dir.length() > 1e-4 else end_dir
	return _look(pos, dir)


## "c" scene 1's AMBIENT LIFE, cosmetic only: a slow drift of spores over the scene's `spores_at` place - the
## intro's OWN particles (fixed seed, the world's spore look via PlanetPropMeshes.sparkle_material, which the world
## already draws with), so the world's random numbers, schedule and creatures are untouched. Shown in scene 1 only.
func _build_ambient(scene: Dictionary) -> void:
	var at: Variant = scene.get("spores_at")
	var lat: Variant = scene.get("local_spores_at")
	var g: Vector3
	var up: Vector3
	if lat is Vector3:
		# In the start frame's own metres (a cave or a rock), the motes' centre there; up = the start's up.
		g = _start_xf * (lat as Vector3)
		up = _start_xf.basis.y.normalized()
	elif at is Vector2:
		var d := safari.dir_from_start((at as Vector2).x, (at as Vector2).y)
		g = safari.planet.surface_point(d)
		up = safari.planet.up_at(g)
	else:
		return
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var cols: Array = scene.get("spore_cols", [Color("#e3b6dc")])
	for i in cols.size():
		var e := CPUParticles3D.new()
		e.name = "IntroSpores%d" % i
		var q := QuadMesh.new()
		q.size = Vector2(0.2, 0.2)
		e.mesh = q
		e.material_override = PlanetPropMeshes.sparkle_material(cols[i])
		e.amount = 28
		e.lifetime = 4.5
		e.preprocess = 4.5
		e.use_fixed_seed = true
		e.seed = 1019 + i
		e.local_coords = false
		e.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		e.emission_sphere_radius = 2.2
		e.direction = Vector3.UP
		e.spread = 25.0
		e.initial_velocity_min = 0.08
		e.initial_velocity_max = 0.22
		e.gravity = Vector3.ZERO
		e.scale_amount_min = 0.6
		e.scale_amount_max = 1.4
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 0.0))
		ramp.add_point(0.2, Color(1, 1, 1, 0.9))
		ramp.add_point(0.75, Color(1, 1, 1, 0.7))
		ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0.0))
		e.color_ramp = ramp
		add_child(e)
		e.global_transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(),
			g if lat is Vector3 else g + up * 0.9)
		e.direction = Vector3.UP
		e.emitting = true
		_ambient.append(e)


## "c": scene 1 (the world's one view, the double not drawn) until the cut, then the swoop.
func _shot_c(t: float, delta: float) -> Transform3D:
	var in_two := t >= _c_cut
	for e: CPUParticles3D in _ambient:
		if e.visible == in_two:
			e.visible = not in_two
	if _double != null and _double.visible != in_two:
		_double.visible = in_two
		if _shadow != null:
			_shadow.visible = in_two
	_hide_pad_fixtures(in_two)
	if not in_two:
		return _shot_b(t, delta)
	return _swoop(t, delta)


# ------------------------------------------------------------------------------ the pad's fixtures
## THE PAD'S CONTROL POST AND FLY SIGN are drawn by no camera during the swoop (scene 2 of "c", all of "a"). The pad
## turns toward each world's spawn while the start stands beside it, so they land round the start differently on
## every world (start frame, x right, z back: the control post at (+1.31, +0.97) on Zorp, (-0.09, +1.33) on Grig,
## (+0.80, -1.42) on Bolt; the sign's near post at (+1.52, -1.20) on Grig) and the one swoop cannot miss them all:
## Grig's sign post stood in the frame's right edge from 3.9 to 7.0 s and Vela's 4.9 to 6.8 s even with their
## mirrored paths (2026-10-20, measured with the probe's --sip-pad). Hidden with `layers` = 0 and no shadow, NEVER
## `visible` (the pad's own code owns that), every value put back at teardown; the rocket, deck, hose and mast stay.
## A fixture the first-person view at control would show is NOT hidden: it would pop in at the hand-back (Bolt's
## control post, ahead of the start, keeps showing - his data's `lead` aims past it).
const PAD_HIDE: PackedStringArray = ["ControlPost", "FlySign"]


func _find_pad_fixtures() -> void:
	var root := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	for nm: String in PAD_HIDE:
		var n := root.find_child(nm, true, false) as Node3D
		if n == null:
			continue
		if _in_first_person_view(n):
			_log("pad fixture %s stays drawn in the swoop (the first-person view at control shows it)" % nm)
			continue
		_pad_fix.append(n)


## True when any corner of any of `n`'s drawn parts is inside the rig's first-person frame (grown by 15%) - that
## frame is where the intro hands back to, so a part there that was hidden would pop in.
func _in_first_person_view(n: Node3D) -> bool:
	if _rig_cam == null or not is_instance_valid(_rig_cam):
		return true
	var vp := _rig_cam.get_viewport().get_visible_rect().size
	var parts: Array[Node] = [n]
	parts.append_array(n.find_children("*", "GeometryInstance3D", true, false))
	for g: Node in parts:
		if not (g is GeometryInstance3D):
			continue
		var gi := g as GeometryInstance3D
		var box := gi.global_transform * gi.get_aabb()
		for i in 9:
			var q := box.get_center() if i == 8 else box.get_endpoint(i)
			if _rig_cam.is_position_behind(q):
				continue
			var sp := _rig_cam.unproject_position(q)
			if sp.x > -vp.x * 0.15 and sp.x < vp.x * 1.15 and sp.y > -vp.y * 0.15 and sp.y < vp.y * 1.15:
				return true
	return false


func _hide_pad_fixtures(on: bool) -> void:
	if on == _pad_off:
		return
	_pad_off = on
	if on:
		for n: Node3D in _pad_fix:
			if not is_instance_valid(n):
				continue
			var parts: Array[Node] = [n]
			parts.append_array(n.find_children("*", "GeometryInstance3D", true, false))
			for g: Node in parts:
				if g is GeometryInstance3D:
					var gi := g as GeometryInstance3D
					_pad_saved.append([gi, gi.layers, gi.cast_shadow])
					gi.layers = 0
					gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		for e: Array in _pad_saved:
			if is_instance_valid(e[0]):
				(e[0] as GeometryInstance3D).layers = int(e[1])
				(e[0] as GeometryInstance3D).cast_shadow = int(e[2]) as GeometryInstance3D.ShadowCastingSetting
		_pad_saved.clear()


## Option A's double holds the cockpit's brass camera. CockpitProps._camera_prop is not reachable on its own
## (it writes into the cockpit's shared room mesh at the dash's spot, with a yaw and a strap lying on the
## dash), so this is the same camera - the cockpit's pieces, sizes and colours, on its room material - built
## alone, centred, the lens facing -Z (away from the chest), `k` times the size.
static func brass_camera_mesh(k: float) -> ArrayMesh:
	var kit := PlanetMeshKit.new()
	var c := Vector3.ZERO
	var yaw := Basis(Vector3.UP, PI)
	kit.rounded_box(c, Vector3(0.19, 0.115, 0.095) * k, 0.028 * k, CockpitProps.BRASS, yaw)
	kit.rounded_box(c + yaw * Vector3(0.0, -0.005, 0.0) * k, Vector3(0.195, 0.048, 0.1) * k, 0.02 * k,
		CockpitProps.BRASS_DARK, yaw)
	var lens_basis := yaw * Basis(Vector3.RIGHT, PI * 0.5)
	var front := c + yaw * Vector3(0.02, 0.0, 0.047) * k
	kit.cylinder(front, 0.043 * k, 0.04 * k, 0.042 * k, CockpitProps.BRASS_DARK, lens_basis, 20)
	kit.cylinder(front + yaw * Vector3(0.0, 0.0, 0.042) * k, 0.038 * k, 0.038 * k, 0.01 * k, CockpitProps.LENS,
		lens_basis, 20)
	kit.torus(front + yaw * Vector3(0.0, 0.0, 0.047) * k, 0.038 * k, 0.008 * k, CockpitProps.BRASS, lens_basis, 20)
	kit.rounded_box(c + yaw * Vector3(-0.052, 0.072, 0.0) * k, Vector3(0.048, 0.034, 0.048) * k, 0.012 * k,
		CockpitProps.BRASS_DARK, yaw)
	kit.cylinder(c + yaw * Vector3(0.056, 0.057, -0.01) * k, 0.013 * k, 0.013 * k, 0.02 * k, CockpitProps.KNOB, yaw, 10)
	kit.sphere(c + yaw * Vector3(0.07, 0.053, 0.033) * k, 0.03 * k, CockpitProps.BRASS_DARK.darkened(0.25),
		Vector3(1.2, 0.45, 1.0), 10, yaw)
	kit.sphere(c + yaw * Vector3(0.045, 0.06, 0.043) * k, 0.016 * k, Color("#d8c08c"), Vector3(1.4, 0.3, 0.8), 8, yaw)
	var m := kit.commit()
	m.surface_set_material(0, CockpitProps.room_material())
	return m


# ---------------------------------------------------------------------------- option B
## One shot of the tour, compiled once from the world script's data (no per-frame allocation after).
class Shot:
	var dirs: Array[Vector3] = []
	var arcs := PackedFloat32Array()
	var h0 := 1.5
	var h1 := 1.5
	var secs := 1.5
	var t0 := 0.0
	var ease := 0            # 0 linear, 1 ease out (arrive), 2 ease in and out
	var look_from := Vector3.ZERO
	var look_to := Vector3.ZERO
	var from_fp := false     # "fp": the safari's own first-person direction
	var to_fp := false
	var emote := ""
	var local := PackedVector3Array()   # "local_path": world points from the start frame (then dirs is unused)
	var local_arcs := PackedFloat32Array()


## Reads the world script's `intro_shots()` (see worlds/zorp.gd, THE SAFARI INTRO'S TOUR) into world-space
## paths once, so the per-frame step only interpolates.
func _build_b(raw: Array) -> void:
	var t0 := 0.0
	for i in raw.size():
		var r: Dictionary = raw[i]
		var sh := Shot.new()
		for p: Vector3 in r.get("local_path", []):
			sh.local.append(_above_ground(_start_xf * p))
		if not sh.local.is_empty():
			sh.local_arcs.append(0.0)
			for j in range(1, sh.local.size()):
				sh.local_arcs.append(sh.local_arcs[j - 1] + sh.local[j - 1].distance_to(sh.local[j]))
		for p: Vector2 in r.get("path", []):
			sh.dirs.append(safari.dir_from_start(p.x, p.y))
		sh.arcs.append(0.0)
		for j in range(1, sh.dirs.size()):
			sh.arcs.append(sh.arcs[j - 1] + sh.dirs[j - 1].angle_to(sh.dirs[j]))
		var hv: Vector2 = r.get("height", Vector2(1.5, 1.5))
		if hv.x < MIN_LENS_LIFT or hv.y < MIN_LENS_LIFT:
			push_warning("SafariIntro: a shot's height %s is under %.2f m; raised to it" % [str(hv), MIN_LENS_LIFT])
		sh.h0 = maxf(hv.x, MIN_LENS_LIFT)
		sh.h1 = maxf(hv.y, MIN_LENS_LIFT)
		sh.secs = float(r.get("secs", 1.5))
		sh.ease = {"linear": 0, "out": 1, "inout": 2}.get(str(r.get("ease", "linear")), 0)
		var lf: Variant = r.get("look_from", "fp")
		var lt: Variant = r.get("look_to", "fp")
		sh.from_fp = not (lf is Vector3) and not (r.get("local_look_from") is Vector3)
		sh.to_fp = not (lt is Vector3) and not (r.get("local_look_to") is Vector3)
		if r.get("local_look_from") is Vector3:
			sh.look_from = _start_xf * (r["local_look_from"] as Vector3)
		elif not sh.from_fp:
			sh.look_from = _look_point(lf as Vector3)
		if r.get("local_look_to") is Vector3:
			sh.look_to = _start_xf * (r["local_look_to"] as Vector3)
		elif not sh.to_fp:
			sh.look_to = _look_point(lt as Vector3)
		sh.t0 = t0
		_cuts.append(t0)
		t0 += sh.secs
		_shots.append(sh)
		var cast: Variant = r.get("cast")
		if cast is Dictionary and str((cast as Dictionary).get("npc", "")) != "":
			_build_zorp(sh, cast as Dictionary)
			_zorp_shot = i
	_build_card_text()
	if kind == "b" and absf(t0 - TOTAL_SEC) > 0.01:
		push_warning("SafariIntro: %s's intro shots last %.2f s, not %.2f" % [safari.planet_id, t0, TOTAL_SEC])


## A lens never goes under the ground: a "local_path" point lower than MIN_LENS_LIFT over the planet's ground there is
## raised to it, with a warning (where the ground IS the planet's - not with "terrain_follow": false, the cave).
const MIN_LENS_LIFT := 0.3
func _above_ground(w: Vector3) -> Vector3:
	if not _terrain or safari.planet == null:
		return w
	var c := safari.planet.global_position
	var d := (w - c).normalized()
	var floor_r := safari.planet.height_at(d) + MIN_LENS_LIFT
	if (w - c).length() < floor_r:
		push_warning("SafariIntro: a local_path point is %.2f m under the ground; raised to %.2f m above it" % [
			floor_r - (w - c).length(), MIN_LENS_LIFT])
		return c + d * floor_r
	return w


## Vector3(around_deg, bearing_deg, lift_m) from the start -> a world point.
func _look_point(v: Vector3) -> Vector3:
	return safari.ground_point(safari.dir_from_start(v.x, v.y), v.z)


func _build_zorp(sh: Shot, cast: Dictionary) -> void:
	var at: Vector2 = cast.get("at", Vector2.ZERO)
	var p := safari.planet
	var bed := safari.dir_from_start(at.x, at.y)
	var cam_end := sh.dirs[sh.dirs.size() - 1]
	# Beside the bed, toward where the shot's lens ends, facing it - on a spot clear of the plants.
	var toward := (cam_end - bed * cam_end.dot(bed)).normalized()
	var axis := bed.cross(toward).normalized()
	var stand := bed.rotated(axis, float(cast.get("out_m", 0.9)) / p.radius).normalized()
	if p.nearest_prop_distance(stand) < 0.45:
		for k: float in [0.6, -0.6, 1.2, -1.2]:
			var cand := stand.rotated(toward, k / p.radius).normalized()
			if p.nearest_prop_distance(cand) >= 0.45:
				stand = cand
				break
	var g := p.surface_point(stand)
	var up := p.up_at(g)
	var face := p.surface_point(cam_end) - g
	face -= up * face.dot(up)
	_zorp = NpcModels.make(str(cast.get("npc", "zorp")))
	_zorp.name = "IntroZorp"
	add_child(_zorp)
	_zorp.global_transform = Transform3D(Basis.looking_at(face.normalized(), up), g)
	_zorp.visible = false
	sh.emote = str(cast.get("emote", "wave"))


func _shot_b(t: float, delta: float) -> Transform3D:
	var i := _cuts.size() - 1
	while i > 0 and t < _cuts[i]:
		i -= 1
	var sh: Shot = _shots[i]
	var u := clampf((t - sh.t0) / sh.secs, 0.0, 1.0)
	var e := u
	if sh.ease == 1:
		e = 1.0 - (1.0 - u) * (1.0 - u)
	elif sh.ease == 2:
		e = smoothstep(0.0, 1.0, u)
	var pos: Vector3
	if not sh.local.is_empty():
		var nl := sh.local.size()
		pos = sh.local[0]
		if nl > 1:
			var want_l := e * sh.local_arcs[nl - 1]
			var jl := 0
			while jl < nl - 2 and want_l > sh.local_arcs[jl + 1]:
				jl += 1
			var seg_l := maxf(sh.local_arcs[jl + 1] - sh.local_arcs[jl], 1e-6)
			pos = sh.local[jl].lerp(sh.local[jl + 1], clampf((want_l - sh.local_arcs[jl]) / seg_l, 0.0, 1.0))
	else:
		var n := sh.dirs.size()
		var d := sh.dirs[0]
		if n > 1:
			var want := e * sh.arcs[n - 1]
			var j := 0
			while j < n - 2 and want > sh.arcs[j + 1]:
				j += 1
			var seg := maxf(sh.arcs[j + 1] - sh.arcs[j], 1e-6)
			d = sh.dirs[j].slerp(sh.dirs[j + 1], clampf((want - sh.arcs[j]) / seg, 0.0, 1.0))
		pos = safari.ground_point(d, lerpf(sh.h0, sh.h1, e))
	var fp_dir := -_rig_cam.global_transform.basis.z
	var k := smoothstep(0.0, 1.0, e)
	var dir: Vector3
	if sh.from_fp and sh.to_fp:
		dir = fp_dir
	elif sh.to_fp:
		dir = (sh.look_from - pos).normalized().lerp(fp_dir, k)
	elif sh.from_fp:
		dir = fp_dir.lerp((sh.look_to - pos).normalized(), k)
	else:
		dir = sh.look_from.lerp(sh.look_to, e) - pos
	# Zorp's double is only in his own shot, waving from its first frame.
	if _zorp != null and _warming:
		_zorp.visible = i == _zorp_shot
	elif _zorp != null:
		var on := i == _zorp_shot
		if on != _zorp.visible:
			_zorp.visible = on
			if on:
				_zorp.call("set_state", sh.emote)
		if on:
			_zorp.call("tick", delta, 0.0)
	return _look(pos, dir)


# ======================================================================================== THE CARD
func _build_card() -> void:
	_card_layer = CanvasLayer.new()
	_card_layer.name = "IntroCard"
	_card_layer.layer = CARD_LAYER
	add_child(_card_layer)
	_card_root = Control.new()
	_card_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_layer.add_child(_card_root)
	_black = ColorRect.new()
	_black.color = Color(UIStyle.NAVY, 1.0)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(_black)
	if skippable:
		# CockpitOverlay's Skip pill, the same look and the same place.
		_skip = Button.new()
		_skip.name = "SkipButton"
		_skip.text = "Skip"
		_skip.focus_mode = Control.FOCUS_NONE
		_skip.mouse_filter = Control.MOUSE_FILTER_STOP
		_skip.add_theme_stylebox_override("normal",
			UIStyle.make_pill_style(Color(0.09, 0.10, 0.20, 0.62), Color(0.55, 0.58, 0.72, 0.5), 2, 0, 22.0, 8.0))
		_skip.add_theme_stylebox_override("hover",
			UIStyle.make_pill_style(Color(0.13, 0.14, 0.26, 0.75), Color(0.70, 0.72, 0.85, 0.7), 2, 0, 22.0, 8.0))
		_skip.add_theme_stylebox_override("pressed",
			UIStyle.make_pill_style(Color(0.18, 0.19, 0.32, 0.85), Color(0.80, 0.82, 0.92, 0.8), 2, 0, 22.0, 8.0))
		_skip.add_theme_color_override("font_color", Color("#dfe2ee"))
		_skip.add_theme_color_override("font_hover_color", Color("#ffffff"))
		_skip.add_theme_color_override("font_pressed_color", Color("#ffffff"))
		_skip.add_theme_font_override("font", UIStyle.ui_font())
		_skip.add_theme_font_size_override("font_size", int(MobileUI.pick(UIStyle.SIZE_BODY, 26.0)))
		_skip.visible = false
		_skip.pressed.connect(_on_skip_button)
		_card_root.add_child(_skip)
	_card_root.resized.connect(_layout)
	_layout()


## Option B's name card: the planet's own name and the world's subtitle, centred in the upper third (clear of
## a landscape phone's notch at the sides and of the thumbs at the bottom corners).
func _build_card_text() -> void:
	var pd: PlanetData = safari.planet.data if safari.planet != null else null
	var name_text := str(_data.get("title", pd.display_name if pd != null else safari.planet_id.capitalize()))
	# The outing's own lettering (src/planet_safari/title_lettering.gd), built once here.
	var st: Dictionary = TitleLettering.full_style(_data.get("title_style", {}))
	var title_lines := PackedStringArray(_data.get("title_lines", st.get("lines", _split_title(name_text))))
	_lettering = TitleLettering.new()
	_lettering.name = "TitleLettering"
	_card_root.add_child(_lettering)
	_lettering.build(title_lines, st)
	_lettering.set_strength(0.0)
	var sub := str(_data.get("subtitle", ""))
	_sub = _card_label(sub, 30, 7)
	_sub.modulate.a = 0.0
	# Above the black, under the Skip pill.
	if _skip != null:
		_card_root.move_child(_skip, -1)
	_layout()


## Upper case; a name longer than 12 letters splits in two at the space nearest its middle.
static func _split_title(t: String) -> PackedStringArray:
	var u := t.to_upper()
	if u.length() <= 12 or not u.contains(" "):
		return PackedStringArray([u])
	var best := -1
	for i in u.length():
		if u[i] == " " and (best < 0 or absi(i - u.length() / 2) < absi(best - u.length() / 2)):
			best = i
	return PackedStringArray([u.substr(0, best), u.substr(best + 1)])


func _card_label(text: String, size: int, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UIStyle.CREAM)
	l.add_theme_color_override("font_outline_color", Color(UIStyle.NAVY, 0.85))
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_shadow_color", Color(UIStyle.NAVY, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 3)
	# The shadow drawn at the outline's own thickness: Baloo 2 keeps a glyph cache per (size, outline) pair for the
	# rest of the session, and the default shadow outline (1) was a second one - measured at 2556x1179, the subtitle
	# left +1.5 MB with it and +1.0 MB this way (showcase/sip_fontmem.tscn, one variant per process).
	l.add_theme_constant_override("shadow_outline_size", outline)
	_card_root.add_child(l)
	return l


func _layout() -> void:
	if _card_root == null:
		return
	var vp := _card_root.size
	if _lettering != null:
		# Centred in the middle of the screen, as big as fits TITLE_MAX_H x TITLE_MAX_W (subtitle included).
		var safe := MobileUI.safe_area() if MobileUI.is_mobile() else Vector4.ZERO
		var avail_w := (vp.x - safe.x - safe.z) * TITLE_MAX_W
		_sub.size = Vector2(vp.x, 0.0)
		_sub.reset_size()
		_sub.size.x = vp.x
		var sub_h := _sub.size.y
		var bs := _lettering.block_size
		_title_fit = minf((vp.y * TITLE_MAX_H - sub_h - 14.0) / maxf(bs.y, 1.0), avail_w / maxf(bs.x, 1.0))
		# The planet's backdrop (its "size" meta, centred on the block) at its LARGEST - grown by TITLE_GROW - stays
		# TITLE_EDGE inside the safe sides, and inside the top edge with the block at _title_center: Bolt's, Fen's
		# and Grig's crests ran past the top edge (the critic, 2026-10-20).
		var ext := Vector2(maxf(bs.x, _lettering.backdrop_extent.x), maxf(bs.y, _lettering.backdrop_extent.y))
		var g := 1.0 + TITLE_GROW
		var side_w := (vp.x - safe.x - safe.z) - 2.0 * TITLE_EDGE * vp.y
		var half_h := vp.y * (_title_center - TITLE_EDGE)
		_title_fit = minf(_title_fit, minf(side_w / maxf(ext.x * g, 1.0), 2.0 * half_h / maxf(ext.y * g, 1.0)))
		var block_h := bs.y * _title_fit + 14.0 + sub_h
		var cx := safe.x + (vp.x - safe.x - safe.z) * 0.5
		var top := vp.y * _title_center - block_h * 0.5
		var cy := top + bs.y * _title_fit * 0.5
		# And never past the top edge (the block's centre sits a little above _title_center: the subtitle is under it).
		var low := vp.y * TITLE_EDGE + ext.y * g * _title_fit * 0.5
		if cy < low:
			top += low - cy
			cy = low
		_lettering.position = Vector2(cx, cy)
		_lettering.scale = Vector2.ONE * _title_fit
		_sub.position = Vector2(cx - vp.x * 0.5, top + bs.y * _title_fit + 14.0)
	elif _title != null:
		_title.size = Vector2(vp.x, 0.0)
		_title.reset_size()
		_title.size.x = vp.x
		_title.position = Vector2(0.0, vp.y * 0.10)
		_sub.size = Vector2(vp.x, 0.0)
		_sub.reset_size()
		_sub.size.x = vp.x
		_sub.position = Vector2(0.0, _title.position.y + _title.size.y - 6.0)
	if _skip != null:
		var safe := MobileUI.safe_area() if MobileUI.is_mobile() else Vector4.ZERO
		# 44 pt minimum: the canvas is 720 rows tall, an iPhone landscape screen ~390 pt (CockpitOverlay).
		var h := MobileUI.pick(52.0, SKIP_MIN_PT * 720.0 / 390.0)
		_skip.custom_minimum_size = Vector2(h * 1.9, h)
		_skip.reset_size()
		_skip.position = Vector2(vp.x - _skip.size.x - 24.0 - safe.z, vp.y - _skip.size.y - 22.0 - safe.w)


## On: the card's text drawn under the black, at full strength (warm-up). Off: back above it, at strength 0.
func _card_under_black(on: bool) -> void:
	for n: CanvasItem in [_lettering, _title, _sub]:
		if n == null or not is_instance_valid(n):
			continue
		_card_root.move_child(n, 0 if on else _black.get_index() + 1)
		if n is TitleLettering:
			(n as TitleLettering).set_strength(1.0 if on else 0.0)
		else:
			n.modulate.a = 1.0 if on else 0.0
	if not on and _lettering != null and _sub != null:
		_card_root.move_child(_sub, _lettering.get_index() + 1)


## The black (the lift, option B's dips), the name card, and SafariLayer's controls fading in at the end.
func _apply_overlays(t: float) -> void:
	var a := 1.0 - smoothstep(0.0, LIFT_SEC, t)
	if _path != null and _t_hide > 0.0:
		var dip := smoothstep(_t_hide - A_DIP_IN, _t_hide, t) if t <= _t_hide \
			else 1.0 - smoothstep(_t_hide, _t_hide + A_DIP_OUT, t)
		if _helmet_share > VISOR_SHARE:
			dip = maxf(dip, 1.0 - VISOR_SHARE / _helmet_share)
		a = maxf(a, dip)
	if kind == "c":
		var hc := C_DIP_SEC * 0.5
		var dc := absf(t - _c_cut)
		if dc < hc:
			a = maxf(a, 1.0 - smoothstep(0.0, hc, dc))
	if kind == "b" or kind == "c":
		var half := DIP_SEC * 0.5
		for k in range(1, _cuts.size()):
			var dt := absf(t - _cuts[k])
			if dt < half:
				a = maxf(a, 1.0 - smoothstep(0.0, half, dt))
		var out := 1.0 - smoothstep(_total - CARD_OUT_SEC, _total, t)
		if _lettering != null:
			_title_alpha = title_alpha(t) if kind == "b" else title_alpha_c(t, _c_cut)
			_lettering.set_strength(_title_alpha)
			_lettering.visible = _title_alpha > 0.0
			var grow0 := TITLE_HOLD_END if kind == "b" else C_TITLE_IN1
			var grow1 := TITLE_GONE if kind == "b" else _c_cut - (C_CUT - C_TITLE_GONE)
			_lettering.scale = Vector2.ONE * _title_fit * (1.0 + TITLE_GROW * smoothstep(grow0, grow1, t))
			_sub.modulate.a = smoothstep(SUB_IN.x, SUB_IN.y, t) * _title_alpha
			_sub.visible = _sub.modulate.a > 0.0
		elif _title != null:
			_title.modulate.a = smoothstep(0.0, LIFT_SEC, t) * out
			_sub.modulate.a = smoothstep(LIFT_SEC * 0.9, LIFT_SEC * 2.0, t) * out
	_black.color.a = a
	if t >= _total - UI_FADE_SEC and _ui_root != null:
		if not _ui_shown:
			_ui_shown = true
			_ui_root.modulate.a = 0.0
			safari.layer.show_awake_ui(true)
		_ui_root.modulate.a = smoothstep(_total - UI_FADE_SEC, _total, t)


# ======================================================================================== THE END
## Everything this node changed, put back: the rig's lens current, our nodes gone, the controls shown and
## opaque, the modal closed. Safe to call twice and from `_exit_tree`.
func _teardown() -> void:
	_hide_pad_fixtures(false)
	if _cam != null and is_instance_valid(_cam):
		if _cam.current and _rig_cam != null and is_instance_valid(_rig_cam):
			_rig_cam.current = true
		_cam.current = false
		_cam.queue_free()
	_cam = null
	for n: Node in [_double, _shadow, _zorp, _card_layer]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_double = null
	_shadow = null
	_zorp = null
	_card_layer = null
	_skip = null
	if _ui_root != null and is_instance_valid(_ui_root):
		_ui_root.modulate.a = 1.0
	if _modal_open:
		_modal_open = false
		# A scene change has already cleared every modal (EventBus.reset_modals): only close ours if it is open.
		if EventBus.modal_counts().has(MODAL):
			EventBus.ui_modal_closed.emit(MODAL)


func _finish(skipped: bool) -> void:
	if _done:
		return
	_done = true
	_running = false
	if is_instance_valid(safari) and safari.layer != null:
		safari.layer.show_awake_ui(true)
	_teardown()
	GameState.flags[SEEN_FLAG_PREFIX + kind] = true
	_log("done kind=%s skipped=%s t=%.3f" % [kind, str(skipped), _t])
	done.emit(skipped)
	queue_free()


func _exit_tree() -> void:
	if _done:
		return
	aborted = true
	_done = true
	_running = false
	_teardown()
	done.emit(true)


# ======================================================================================== SKIP
func _on_skip_button() -> void:
	if not skippable or not _running or _done or _skipping or _confirming or _t < SKIP_ARM_SEC:
		return
	_ask_skip()


func _ask_skip() -> void:
	if _confirming or _skipping or _done:
		return
	_confirming = true
	if _skip != null:
		_skip.visible = false
	var go: bool = await SkipConfirm.ask(self, "Skip the intro?", "Skip", "Keep watching")
	_confirming = false
	if _done or not is_inside_tree() or _skipping:
		return
	if not go:
		for a in SKIP_ACTIONS:
			_skip_held[a] = Input.is_action_pressed(a)
		return
	_skipping = true
	_log("skip confirmed at t=%.3f" % _t)
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 1.0, SKIP_DIP_SEC)
	await tw.finished
	if _done or not is_inside_tree():
		return
	# The end state, behind the black: the rig's lens, the doubles gone, the card gone, the controls up.
	if _title != null:
		_title.visible = false
	if _lettering != null:
		_lettering.queue_free()
		_lettering = null
	if _sub != null:
		_sub.visible = false
	if _skip != null:
		_skip.visible = false
	if _rig_cam != null and is_instance_valid(_rig_cam):
		_rig_cam.current = true
	for e: CPUParticles3D in _ambient:
		if is_instance_valid(e):
			e.queue_free()
	_ambient.clear()
	for n: Node in [_double, _shadow, _zorp]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_double = null
	_shadow = null
	_zorp = null
	safari.layer.show_awake_ui(true)
	if _ui_root != null:
		_ui_root.modulate.a = 1.0
	var tw2 := create_tween()
	tw2.tween_property(_black, "color:a", 0.0, SKIP_LIFT_SEC)
	await tw2.finished
	if not is_inside_tree():
		return
	_finish(true)


## Keys and pad buttons open the same pop-up (only when skipping is offered). Clicks and taps do not: only
## the Skip pill (a Button) takes those.
func _input(event: InputEvent) -> void:
	if not skippable or not _running or _done or _skipping or _confirming or _t < SKIP_ARM_SEC:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo or k.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return
		get_viewport().set_input_as_handled()
		_ask_skip()
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		get_viewport().set_input_as_handled()
		_ask_skip()


## The action half, for Director timelines (`Input.action_press` sends no InputEvent): CockpitIntro's edges.
func _physics_process(_delta: float) -> void:
	if not skippable or not _running or _done or _skipping or _confirming:
		return
	var edge := false
	for a in SKIP_ACTIONS:
		var now := Input.is_action_pressed(a)
		if now and not bool(_skip_held.get(a, false)) and _skip_primed and _t >= SKIP_ARM_SEC:
			edge = true
		_skip_held[a] = now
	_skip_primed = true
	if edge:
		_ask_skip()


# ======================================================================================== HELPERS
## "c"'s title strength at time `t`: in, hold, out - gone before the cut (see C_TITLE_IN0 and the rest).
## The out times keep their distance from the cut (`cut` = the outing's own, C_CUT by default).
static func title_alpha_c(t: float, cut: float = C_CUT) -> float:
	var out0 := cut - (C_CUT - C_TITLE_OUT0)
	var gone := cut - (C_CUT - C_TITLE_GONE)
	return smoothstep(C_TITLE_IN0, C_TITLE_IN1, t) * (1.0 - smoothstep(out0, gone, t))


## Option B's title strength at time `t` (see TITLE_IN_END and the constants after it).
static func title_alpha(t: float) -> float:
	if t <= TITLE_IN_END:
		return smoothstep(0.0, TITLE_IN_END, t)
	if t <= TITLE_HOLD_END:
		return 1.0
	if t <= TITLE_DRIFT_END:
		return lerpf(1.0, TITLE_DRIFT_ALPHA, smoothstep(TITLE_HOLD_END, TITLE_DRIFT_END, t))
	if t <= TITLE_LINGER_END:
		return lerpf(TITLE_DRIFT_ALPHA, TITLE_LINGER_ALPHA, (t - TITLE_DRIFT_END) / (TITLE_LINGER_END - TITLE_DRIFT_END))
	if t < TITLE_GONE:
		return lerpf(TITLE_LINGER_ALPHA, 0.0, smoothstep(TITLE_LINGER_END, TITLE_GONE, t))
	return 0.0



## The poses the warm-up draws: option A's opening, mid-orbit and behind-the-head; the middle of each of
## option B's shots.
func _warm_times() -> PackedFloat32Array:
	if kind == "a":
		return PackedFloat32Array([0.0, 1.3, 2.6, 3.0])
	if kind == "c":
		var l2 := _total - _c_cut
		return PackedFloat32Array([_c_cut * 0.2, _c_cut * 0.75, _c_cut, _c_cut + l2 * 0.28, _c_cut + l2 * 0.57,
			_c_cut + l2 * 0.72])
	var out := PackedFloat32Array()
	for sh: Shot in _shots:
		out.append(sh.t0 + sh.secs * 0.5)
	return out



func _helmet_radius() -> float:
	var r := AstronautModel.HELMET_R
	return maxf(r.x, maxf(r.y, r.z)) * AstronautModel.HELMET_SCALE


## Half the diagonal field of view of `c` on this viewport (the corner ray's angle from the view axis).
static func _half_diag_fov(c: Camera3D) -> float:
	var th := tan(deg_to_rad(maxf(c.fov, INTRO_FOV)) * 0.5)
	var vp := c.get_viewport()
	var aspect := 16.0 / 9.0
	if vp != null:
		var sz := vp.get_visible_rect().size
		aspect = maxf(sz.x / maxf(sz.y, 1.0), 1.0)
	return atan(th * sqrt(1.0 + aspect * aspect))


## The share of the frame (lens `xf`, vertical `fov` degrees) the double's dome covers: rays through the centres of
## a HELMET_GRID grid of the frame, each inside the dome's angular radius or not. 1 with the lens inside the dome.
func _dome_share(xf: Transform3D, fov: float, helmet: Vector3) -> float:
	var r := _helmet_radius()
	var to := helmet - xf.origin
	var d := to.length()
	if d <= r:
		return 1.0
	var cos_r := cos(asin(r / d))
	var c := xf.basis.inverse() * (to / d)   # the dome's centre direction in the lens's own axes (-z ahead)
	var sz := get_viewport().get_visible_rect().size
	var ty := tan(deg_to_rad(fov) * 0.5)
	var tx := ty * sz.x / maxf(sz.y, 1.0)
	var n := 0
	for j in HELMET_GRID.y:
		var y := ty * (1.0 - 2.0 * (float(j) + 0.5) / float(HELMET_GRID.y))
		for i in HELMET_GRID.x:
			var x := tx * (2.0 * (float(i) + 0.5) / float(HELMET_GRID.x) - 1.0)
			if Vector3(x, y, -1.0).normalized().dot(c) >= cos_r:
				n += 1
	return float(n) / float(HELMET_GRID.x * HELMET_GRID.y)


## The swoop time when the lens first comes within _hide_dist of the helmet (the path is fixed, so it is found once).
func _find_hide_time() -> float:
	var tau := _path.push0
	while tau <= _path.push1:
		var xf := _swoop(_a_t0 + tau, 0.0)
		var helmet := _frame_at(_walk_s(tau)) * Vector3(0.0, AstronautModel.HELMET_CY, 0.0)
		if xf.origin.distance_to(helmet) < _hide_dist:
			return tau
		tau += 1.0 / 240.0
	return _path.push1


## Distance from the eye to a corner of the near plane: a lens closer than helmet radius + this to the
## helmet's centre would cut into the dome.
static func _near_corner(c: Camera3D) -> float:
	var th := tan(deg_to_rad(maxf(c.fov, INTRO_FOV)) * 0.5)
	var vp := c.get_viewport()
	var aspect := 16.0 / 9.0
	if vp != null:
		var s := vp.get_visible_rect().size
		aspect = maxf(s.x / maxf(s.y, 1.0), 1.0)
	return c.near * sqrt(1.0 + th * th + th * th * aspect * aspect)


func _geometry(n: Node, out: Array) -> Array:
	for c in n.get_children():
		if c is GeometryInstance3D:
			out.append(c)
		_geometry(c, out)
	return out


func _log(msg: String) -> void:
	print("[SafariIntro] " + msg)


## For tests: one line of plain values.
func debug_state() -> Dictionary:
	return {"kind": kind, "t": _t, "running": _running, "done": _done, "confirming": _confirming,
		"skipping": _skipping, "skippable": skippable, "lifting": _running and _t > 0.0,
		"double_hidden": _double_hidden, "skip_visible": _skip != null and is_instance_valid(_skip) and _skip.visible,
		"cam_current": _cam != null and is_instance_valid(_cam) and _cam.current,
		"title_alpha": _title_alpha,
		"title_drawn": _lettering != null and is_instance_valid(_lettering) and _lettering.is_visible_in_tree()}


func debug_skip_rect() -> Rect2:
	if _skip == null or not is_instance_valid(_skip) or not _skip.visible:
		return Rect2()
	return _skip.get_global_rect()
