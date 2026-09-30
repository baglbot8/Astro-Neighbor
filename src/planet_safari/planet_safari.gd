class_name PlanetSafari
extends Node3D
## THE PLANET SAFARI (docs/PLANET_SAFARI_SPEC.md 5.2-5.4, 6; builder P3, 2026-09-23).
##
## Three minutes in first person on a neighbour's world while it WAKES UP, then it goes back to sleep.
## This node exists only while a safari runs: `/root/World/PlanetSafari`, created when the player says
## yes to the host neighbour, freed after the review. Outside it the planet is exactly today's planet.
##
## ------------------------------------------------------------------------------------------ FLOW
##   Conversation (src/dialogue/conversation.gd, one hook) -> `offer_in_conversation`: the host named by
##     the planet's MANIFEST (`manifest(pid)`: its world script's `const MANIFEST`, safari_world.gd, or the
##     PLANETS fallback) asks its "ask" line once per game day per planet (flag keyed by the day, like
##     replay_board.gd). "Not now" is fine and he asks again next talk; once it has run he says the yard
##     is asleep until tomorrow. Yes -> `request_start`, which waits for the talk to close.
##   Fade to black -> PhotoMode.begin, the player to the start beside the pad facing a fixed heading,
##     CameraRig.set_first_person(true) looking START_PITCH_DEG (10) below level (spec 13.3), Player.set_safari_walk(true), the world script builds, every
##     new mesh is drawn once behind the black (warm-up) -> fade in. The world clock runs as normal; day
##     or night and the rare day are fixed at the start.
##   AWAKE for DURATION seconds. Two modes: WALKING (stick, drag to look, the Camera button) and CAMERA
##     UP (movement locked - only the Walk button or the camera key lowers it, never the stick - finer
##     look, viewfinder, zoom 45..12 deg, shutter: a TAP focuses at once on the first thing in the focus
##     ring and takes it; a press-and-hold lets the focus settle on the subject itself and the release
##     takes a sharper one. The ring seeing only sky keeps the last lock - see `_refocus`). A shutter with
##     NO subject in the frame takes no picture and uses no plate: "Nothing to photograph here." (13.1).
##   Asleep: the world script's `go_to_sleep`, a last puff at every awake subject, SLEEP_SEC later
##     fade to black, everything restored (player back where they stood, first person off, PhotoMode
##     off), fade in, then the review (REVIEW_SCRIPT, builder P5; a plain list until it exists).
##
## ------------------------------------------------------------------------------------------ THE API
## Builder P4 (and every later planet) writes content against this, in ONE file per planet:
## `res://src/planet_safari/worlds/<planet_id>.gd`, `extends SafariWorld` (safari_world.gd). It is
## loaded by planet id when a safari starts; until it exists a planet in PLANETS runs
## PLACEHOLDER_WORLD. The script also carries the planet's MANIFEST (host, offer lines, roster with tiers -
## safari_world.gd, THE MANIFEST) and may use the shared pacing director (SafariWorld.Pacing, same file).
## Inside `build(safari)`:
##
## SUBJECTS - things that can be photographed.
##   safari.add_subject({
##     "id":     "nut_crab",          # unique on this planet; the journal key is "<planet>:<id>"
##     "name":   "Nut-crab",          # what the review and journal call it
##     "rarity": 1,                   # 1..4, the flight's scale; optional - default from the roster tier
##     "tier":   "creature",          # optional; default: the MANIFEST roster's tier for this id
##     "band":   Vector2(0.15, 0.45), # best SIZE: projected diameter as a fraction of frame HEIGHT
##     "node":   some_node3d,         # the subject; scored at node.global_transform * "offset"
##     "offset": Vector3(0, 0.3, 0),  # optional, local
##     "radius": 0.35,                # metres; its sphere for size, focus lock and sight rays
##     "moment": func(t): return {"mult": 1.8, "line": "mid-spout!"},  # optional, see below
##     "awake":  func(): return true, # optional; see "awake" below
##     "event":  "sky_whale",         # optional: awake only while that event runs
##     "kind":   "creature",          # optional free text: creature / event / neighbour / rare
##     "front":  func(): return face_dir, # optional: the world-space unit vector its FACE points along
##   }) -> String key
##   FRONT (spec 11.1, fixed by the lead): with it the photo gets a FACING score out of 10,
##     (dot(front, subject -> lens) + 1) * 5 - facing you 10, side-on 5, its back 0 - folded into the
##     grade (SafariPhotoScorer, CRAFT). Without it (a shower, a geyser) there is no Facing score and
##     the review shows no Facing bar. Called once per subject per shutter, at the instant it fires.
##   MOMENT: called with the safari clock `t` at the instant the shutter fires. Return a Dictionary
##     {"mult": 1.0..2.4, "line": String} (or a bare float). 1.0 = nothing special; the flight's own
##     ceiling is 2.4 (SafariScoring.MOMENT_CEILING). Gallery grade needs a moment.
##   AWAKE (whether it can be in a photo right now): the "awake" Callable if given; else, with an
##     "event", while that event runs; else while its node is visible in the tree. A subject is
##     "woke" the first frame it is awake - the end counts the woke ones you never photographed.
##
## EVENTS - the schedule. Times are seconds since the planet woke (0..DURATION).
##   safari.add_event({
##     "id": "sky_whale", "name": "The Sky Whale",
##     "start": 8.0, "end": 30.0, "warn": 8.0,   # warn = seconds of warning before start
##     "dir": safari.dir_from_start(180.0, 0.0),  # where on the sphere (unit vector)
##     "when": "any",       # "day" / "night" / "any" - fixed at the start of the safari
##     "rare": "any",       # "only" (rare day only) / "never" (not on a rare day) / "any"
##     "overlap_ok": true,  # false = a push_warning if another eligible event overlaps it in time
##     "on_warn":  func(ev): ...,             # the sight and the sound of the warning
##     "on_start": func(ev): ...,
##     "on_tick":  func(ev, t_in, delta): ..., # every frame while it runs
##     "on_end":   func(ev): ...,
##   }) -> bool (false = not eligible today; no hook of it will ever run)
##   safari.event_running(id) -> bool
##
## PLACES AND HELPERS
##   safari.planet / .player / .rig    the world's nodes
##   safari.start_dir, safari.start_fwd the start point (unit dir) and heading (world tangent)
##   safari.dir_from_start(around_deg, bearing_deg) -> Vector3   a point `around_deg` round the planet
##       from the start, along a bearing measured from the start heading (+ = to the right). 90 = a
##       quarter round, 180 = the far side.
##   safari.ground_point(dir, lift_m = 0.0) -> Vector3            on the surface, lifted along "up"
##   safari.surface_xform(dir) -> Transform3D                    upright there, facing the start heading
##   safari.puff_at(pos, amount = 16, colour = cream)            a one-shot CPU steam puff (warmed)
##   safari.announce(text, secs = 3.0)                            a line of text on screen
##   safari.elapsed / .is_night / .is_rare_day / .planet_id / .day / DURATION
##   safari.rare_event_up() -> bool   a rare / rare-day subject is awake (the pacing director's quiet rule)
##   PlanetSafari.manifest(pid) / roster_entry(pid, id) / has_safari(pid)   the manifest, read and checked
##
## RULES FOR CONTENT (each cost this project a round): build under your SafariWorld node only; every
## mesh and CPU particle you make in `build` is warmed behind the fade for you, but anything created
## LATER is not - make it in `build` and hide it. No GPU particles (they stalled every visit), no new
## lights (a light count change recompiles), creatures as a few shared-material shapes animated in
## code (a character model is ~58 draw calls).
##
## ------------------------------------------------------------------------------------------ THE END
## `session_finished(session)` fires once, after the restore, and `PlanetSafari.last_session` keeps it:
##   planet_id, day, is_night, is_rare_day, duration, film_start, film_left,
##   photos: Array of {index, t, image (Image, PHOTO_W wide, in memory only), subject_key,
##     subject_name, rarity, scores {centred, size, focus, rarity, and facing ONLY when the subject has a
##     front} (ints 0..10), has_facing (bool), raw (the floats; raw.facing is -1 with no front),
##     craft, skill, grade (the PLANET scale, SafariScoring.planet_grade, spec 13.1), grade_idx (0..3),
##     moment (bool: caught, the one-grade lift), price, moment_mult, moment_line, others (the other subjects in the frame,
##     same fields, no image), fov, focus_m, held_s, capture_ms},
##   photographed: keys named by a photo; woke: keys that woke; missed_count: woke - photographed;
##   refused: shutter presses with nothing in the frame (no picture, no plate).
## Then the review: `load(REVIEW_SCRIPT).present(host: Node, session: Dictionary)`, awaited - a
## static coroutine builder P5 provides, which returns when the player closes it. Until that file
## exists, SafariLayer shows a plain list. The end NEVER names a subject you did not photograph; it
## only says how many woke up that you missed (spec 6.1).

signal photo_taken(photo: Dictionary)
## The shutter fired with no subject in the frame: no picture was taken and no plate was used (13.1).
signal photo_refused(t: float)
signal session_finished(session: Dictionary)

## The planet is awake this long (spec 5.2: three minutes).
const DURATION := 180.0
## Black fade in and out.
const FADE_SEC := 0.45
## From the last puff to the fade.
const SLEEP_SEC := 2.4
## The puff covers the subject before it vanishes: hidden this long after the puff starts.
const SLEEP_PUFF_HIDE_SEC := 0.2
## DialogueRunner.RELEASE_TIME: its finish() tweens the camera's fov back over this long, and a
## first-person switch inside that tween would be overwritten by it.
const DIALOGUE_RELEASE_SEC := 0.5

const WORLDS_DIR := "res://src/planet_safari/worlds/"
const PLACEHOLDER_WORLD := "res://src/planet_safari/placeholder_world.gd"
## Builder P5's review screen. `static func present(host: Node, session: Dictionary)` (awaitable).
const REVIEW_SCRIPT := "res://src/planet_safari/review/safari_review.gd"
const NODE_NAME := "PlanetSafari"

## THE FALLBACK MANIFESTS (spec 12.5). Each world now describes its own safari in a `const MANIFEST` in
## its world script (safari_world.gd, THE MANIFEST) and `manifest(pid)` reads it. A world whose script
## has no MANIFEST yet falls back to its entry here, the tables as they were before 12.5, so Bolt keeps
## working until his world script is converted - then his entry here can go. Same shape as a MANIFEST.
## Lines in the host's own voice (Bolt counts things and speaks like a maintenance log). The roster is
## the journal's old PLANET_ROSTER (sky_journal.gd) with the spring-hopper added (spec 13.3: it was
## missing) and each subject's tier from worlds/bolt.gd's header.
const PLANETS := {
	"bolt": {
		"host": "bolt",
		"offer": "The yard wakes up for three minutes a day. Creatures. Events. Worth a photograph.",
		"ask": "Photo safari?",
		"yes": "Proceed to the landing pad. Three minutes. Then the yard sleeps.",
		"no": "Understood. The offer stands until midnight.",
		"asleep": "The yard's asleep now. Come back tomorrow.",
		"roster": [
			{"id": "nut_crab", "name": "Nut-crab", "tier": "creature"},
			{"id": "gear_beetle", "name": "Gear-beetle", "tier": "creature"},
			{"id": "spring_hopper", "name": "Spring-hopper", "tier": "creature"},
			{"id": "bolt", "name": "Bolt", "tier": "neighbour"},
			{"id": "sky_whale", "name": "The Sky Whale", "tier": "rare"},
			{"id": "big_geyser", "name": "The Big Geyser", "tier": "uncommon"},
			{"id": "ring_rain", "name": "Ring Rain", "tier": "common"},
			{"id": "scrap_snail", "name": "The Scrap Snail", "tier": "common"},
			{"id": "tune_up", "name": "Bolt's Tune-up", "tier": "uncommon"},
			{"id": "spark_moth", "name": "Spark-moths", "tier": "night"},
			{"id": "great_magnet", "name": "The Great Magnet", "tier": "rare_day"},
		],
	},
}
## The offer lines every manifest must carry; one it leaves out is a warning and says the plain line here.
const MANIFEST_LINES := {
	"offer": "My world wakes up for three minutes a day. Want to photograph it?",
	"ask": "Photo safari?",
	"yes": "Off you go, then. It starts at the landing pad.",
	"no": "Another time, then.",
	"asleep": "Everything's asleep now. Come back tomorrow.",
}
## The shutter pressed with no subject in the frame: no picture, no plate (spec 13.1).
const NOTHING_LINE := "Nothing to photograph here."
## The safari starts looking this far below level, so the ground ahead is in view (spec 13.3).
const START_PITCH_DEG := -10.0
const YES_OPTION := "Let's go!"
const NO_OPTION := "Not now"
const FLAG_DAY_PREFIX := "planet_safari_day_"
const FLAG_ASLEEP_PREFIX := "planet_safari_asleep_said_"

## world.gd's own step off the pad (`_spawn_player`: 3.2 m sideways so we do not spawn in the rocket).
const PAD_STEP_M := 3.2

## Photos are kept in memory this wide (height from the frame's aspect).
const PHOTO_W := 512
## Focus: while the shutter is held the focus distance glides from the tap's lock toward the subject's
## own distance in log space with this time constant (63% of the way in one tau, 95% in three). A
## stated feel pick.
const FOCUS_TAU := 0.25
## "Settled": within this many stops (log2) of the target - 3.5% of the distance, and a focus score
## of 9.5+ on the target.
const FOCUS_SETTLED_STOPS := 0.05
## The focus ring's reach. Nothing inside it within this range (the sky) = keep the last lock.
const FOCUS_FAR_M := 60.0

const PHOTO_MODE_OFF_FOV := 45.0

## THE ZOOM NUDGE (spec 11.1, R3): while the camera is up and the subject the viewfinder is on fills less
## of the frame than its band's low end (its SIZE would score under 10), SafariLayer shows this beside
## the zoom control. At full zoom the only way to a bigger shot is walking closer, so it says that.
const NUDGE_ZOOM := "Zoom in for a bigger shot."
const NUDGE_CLOSER := "Get closer for a bigger shot."
## The viewfinder is re-read this often (5 a second: at most one subject's sight rays per read).
const NUDGE_EVERY := 0.2
## A change of nudge must hold this long before it shows or goes, so a subject sitting right at its
## band's edge does not blink the line. A stated feel pick (two reads).
const NUDGE_HOLD := 0.4

## THE FIRST PLANET SAFARI TEACHES ITSELF, LIGHTLY (docs/PLANET_SAFARI_SPEC.md 15.4). Three short,
## skippable pauses, on the first planet safari only, each fired by the moment it teaches:
##   "camera"  the first time the camera goes up      - tap to snap, hold to let the focus settle
##   "zoom"    the first time a subject is small       - pinch or slide to zoom in (the zoom nudge
##             in frame                                  firing NUDGE_ZOOM is the moment)
##   "film"    the first plate used                    - you have N shots each safari
## A lesson already done is skipped: one whose pause was already shown (saved, so a quit mid-safari
## does not repeat it), and "zoom" once the player has zoomed on their own. During a pause the whole
## tree is paused, so the safari's three-minute clock (`elapsed`, the sun-dial), the schedule, the
## content and the world clock are all frozen; the card itself runs PROCESS_MODE_ALWAYS (SafariLayer).
## "Skip tips" on the card ends the teaching for good.
##
## WHICH SAFARI IS THE FIRST (`_tips_wanted`): TIPS_FLAG (a Dictionary lesson -> true) is created the
## first time a safari starts with tips; TIPS_OVER_FLAG is set when a safari that had tips reaches its
## end (or every lesson is done, or "Skip tips"). A save that ran a planet safari BEFORE this build (it
## has a FLAG_DAY_PREFIX key but no TIPS_FLAG) is treated as past its first safari and never paused.
##
## TEST RUNS: an automated run must not sit on a card waiting for a finger. Tips are OFF in any run
## whose user args include a "--ps-" test-player arg (tools/ps_*.gd) or `--safari-tips=off`, and
## `--safari-tips=on` turns them back on for a run that has test args (the save's history still
## decides, exactly as in the game). The game itself passes no args, so the player always gets them.
const TIPS_FLAG := "planet_safari_tips"
const TIPS_OVER_FLAG := "planet_safari_tips_over"
const TIP_ORDER: Array[String] = ["camera", "zoom", "film"]
const TIP_MODAL := "safari_tip"
## THE END BUTTON AND THE OUT-OF-FILM CARD (docs/PLANET_SAFARI_SPEC.md 17.2.1, the user: "We should
## have an End Safari button ... I ran out of film and there was nothing for me to do until the time
## was up"). Both share `_go_to_sleep` with the natural end (spec 5.2's THE END): a normal end - the
## review, the pay, the day's safari counted as used (already true the moment `_run` spends the day
## flag, whichever way the safari ends).
const END_MODAL := "safari_end"
const FILM_OUT_MODAL := "safari_film_out"
## "Zoomed on their own": the lens this far (degrees) inside the wide end.
const TIP_ZOOMED_DEG := 0.5

## THE PHOTO HOVER (docs/JUNGLE_PLANET_SPEC.md 6; builder HOVER). Moss's lesson sets this flag; from then on
## every safari shows SafariLayer's Hover button (key H): one tap lifts the astronaut Player.HOVER_HEIGHT and
## holds them while its small tank lasts, then they drift down (Player, "photo hover"). The camera works as
## normal up there. The meteor survey turns it on whatever the flag (MeteorSurveyLevel).
const HOVER_FLAG := "hover_learned"
## Said once per game, the first safari with the hover, after the opening line has gone.
const HOVER_HINT_FLAG := "planet_safari_hover_hint"
const HOVER_HINT_AT := 6.0
const HOVER_HINT := "Tap Hover to rise and look around!"
const HOVER_HINT_KEYS := "Press V to hover and look around!"

enum Phase { PENDING, FADE_IN, AWAKE, SLEEPING, FADE_OUT, REVIEW, DONE }

## The safari running right now, or null.
static var current: PlanetSafari
## planet id -> its manifest (see `manifest`), read once per launch.
static var _manifests: Dictionary = {}
## The last finished session (see the header).
static var last_session: Dictionary = {}

var phase: int = Phase.PENDING
var planet_id := ""
var day := 0
var is_night := false
var is_rare_day := false
var elapsed := 0.0

var world: Node
var planet: Planet
var player: Player
var rig: CameraRig
var start_dir := Vector3.UP
var start_fwd := Vector3.FORWARD

var camera_up := false
var film_start := 0
var film_left := 0
## Focus distance in metres (starts at the planet's radius: the width of the yard).
var focus_m := 10.0
var focus_target_m := 10.0
var focus_target_key := ""
var holding := false
var hold_s := 0.0
var capturing := false
## The camera-up zoom, remembered while walking.
var camera_fov := 45.0
## The zoom nudge on screen now ("" = none; NUDGE_ZOOM or NUDGE_CLOSER) and what the viewfinder is on
## (SafariPhotoScorer.aim_subject, re-read every NUDGE_EVERY while the camera is up; {} = nothing).
var zoom_nudge := ""
var aim_info: Dictionary = {}
var _nudge_clock := 0.0
var _nudge_want := ""
var _nudge_want_s := 0.0

var layer: SafariLayer
var _content: SafariWorld
var _subjects: Dictionary = {}     # key -> spec
var _subject_order: Array = []
var _events: Array = []
var _woke: Dictionary = {}
var _photos: Array = []
var _saved_xform: Transform3D
var _puff_mat: StandardMaterial3D
var _puff_mesh: SphereMesh
var _restored := false
var _debug := false
## Frame-time bookkeeping for the report: the longest frame while awake, and around each shutter.
var _max_frame_ms := 0.0
var _capture_log: Array = []
## Shutter presses refused because nothing was in the frame (spec 13.1).
var _refused := 0
## The first safari's pauses (spec 15.4; see TIPS_FLAG). `tips_on` is decided once, at the start.
var tips_on := false
var tip_up := false
var _tip_pending := false
var _tip_log: Array = []
## THE END BUTTON's own confirm, and the once-only out-of-film offer (see END_MODAL/FILM_OUT_MODAL).
var _end_pending := false
## True while this photo mode offers the hover (see HOVER_FLAG).
var hover_enabled := false
var _hover_hint_due := false
var _film_out_offered := false


# ======================================================================================== OFFER
## The ONE hook conversation.gd calls, after the talk's own content. Awaitable. Does nothing unless
## `npc` is the host of the planet the player stands on and that planet has a safari.
static func offer_in_conversation(runner: DialogueRunner, npc: Node) -> void:
	var pid := GameState.current_planet_id
	var npc_id := str(npc.get("npc_id"))
	if not is_host(pid, npc_id) or PhotoMode.active or current != null:
		return
	if ran_today(pid):
		var said_key := FLAG_ASLEEP_PREFIX + pid
		if int(GameState.flags.get(said_key, -1)) == GameState.day_count:
			return
		GameState.flags[said_key] = GameState.day_count
		await runner.say(npc, [_line(pid, "asleep")])
		return
	await runner.say(npc, [_line(pid, "offer")])
	var choice: int = await runner.ask(npc, _line(pid, "ask"), [YES_OPTION, NO_OPTION])
	if choice != 0:
		await runner.say(npc, [_line(pid, "no")])
		return
	await runner.say(npc, [_line(pid, "yes")])
	request_start(npc.get_tree())


static func _line(pid: String, key: String) -> String:
	return str(manifest(pid).get(key, MANIFEST_LINES.get(key, "")))


## True when `npc_id` offers the safari on `planet`.
static func is_host(pid: String, npc_id: String) -> bool:
	var m := manifest(pid)
	return not m.is_empty() and str(m.get("host", "")) == npc_id


## True when `pid` has a safari: a world script with a MANIFEST, or a fallback entry in PLANETS.
static func has_safari(pid: String) -> bool:
	return not manifest(pid).is_empty()


## THE MANIFEST of planet `pid` (safari_world.gd, THE MANIFEST): the `const MANIFEST` of its world script
## `worlds/<pid>.gd`, or its PLANETS fallback entry when that script has none; {} for a planet with no
## safari. Checked once and cached: a manifest with no host is not used; a missing line is filled from
## MANIFEST_LINES; each roster entry is {id, name, tier} with a known tier. Also carries "source":
## "manifest" or "fallback".
static func manifest(pid: String) -> Dictionary:
	if _manifests.has(pid):
		return _manifests[pid]
	var m: Dictionary = {}
	var source := ""
	var path := WORLDS_DIR + pid + ".gd"
	if pid != "" and ResourceLoader.exists(path):
		var scr: Variant = load(path)
		if scr is Script:
			var consts: Dictionary = (scr as Script).get_script_constant_map()
			if consts.get("MANIFEST") is Dictionary:
				m = (consts["MANIFEST"] as Dictionary).duplicate(true)
				source = "manifest"
	if m.is_empty() and PLANETS.has(pid):
		m = (PLANETS[pid] as Dictionary).duplicate(true)
		source = "fallback"
	if not m.is_empty():
		m = _checked_manifest(pid, m)
		if not m.is_empty():
			m["source"] = source
	_manifests[pid] = m
	return m


static func _checked_manifest(pid: String, m: Dictionary) -> Dictionary:
	if str(m.get("host", "")) == "":
		push_warning("PlanetSafari: the %s MANIFEST names no host; that planet offers no safari" % pid)
		return {}
	for k: String in MANIFEST_LINES:
		if str(m.get(k, "")) == "":
			push_warning("PlanetSafari: the %s MANIFEST has no \"%s\" line; the plain one is said" % [pid, k])
			m[k] = MANIFEST_LINES[k]
	var roster: Array = []
	for raw: Variant in m.get("roster", []):
		if not (raw is Dictionary) or str((raw as Dictionary).get("id", "")) == "":
			push_warning("PlanetSafari: the %s MANIFEST roster has an entry with no id: %s" % [pid, str(raw)])
			continue
		var e := (raw as Dictionary).duplicate()
		var tier := str(e.get("tier", ""))
		if not SafariWorld.TIER_RARITY.has(tier):
			push_warning("PlanetSafari: the %s MANIFEST gives %s the tier \"%s\" (one of %s)" % [pid, e["id"], tier,
				str(SafariWorld.TIER_RARITY.keys())])
			e["tier"] = ""
		e["name"] = str(e.get("name", str(e["id"]).capitalize()))
		roster.append(e)
	m["roster"] = roster
	return m


## The roster entry of subject `id` on `pid` ({} when the roster does not list it).
static func roster_entry(pid: String, id: String) -> Dictionary:
	for e: Dictionary in manifest(pid).get("roster", []):
		if str(e["id"]) == id:
			return e
	return {}


## Once per game day per planet: the day the last safari on this planet STARTED.
static func ran_today(pid: String) -> bool:
	return int(GameState.flags.get(FLAG_DAY_PREFIX + pid, -1)) == GameState.day_count


static func can_offer(pid: String, npc_id: String) -> bool:
	return is_host(pid, npc_id) and not ran_today(pid) and current == null and not PhotoMode.active


## One day in `one_in` is a rare day, fixed by the planet and the day number (so a reload cannot
## re-roll it). `--safari-rare` / `--safari-common` force it for a test run.
static func is_rare_day_for(pid: String, day_n: int, one_in: int) -> bool:
	var args := OS.get_cmdline_user_args()
	if args.has("--safari-rare"):
		return true
	if args.has("--safari-common"):
		return false
	if one_in <= 1:
		return true
	return posmod(("%s:%d" % [pid, day_n]).hash(), one_in) == 0


## Creates the safari node under /root/World; it starts as soon as no talk or other modal is open.
static func request_start(tree: SceneTree) -> PlanetSafari:
	if current != null or tree == null:
		return null
	var w := tree.root.get_node_or_null("World")
	if w == null:
		return null
	var s := PlanetSafari.new()
	s.name = NODE_NAME
	w.add_child(s)
	return s


# ======================================================================================== LIFE CYCLE
func _ready() -> void:
	current = self
	_debug = OS.get_cmdline_user_args().has("--safari-debug")
	world = get_parent()
	# By node path, the paths world.gd documents as fixed (its `camera_rig` var is never assigned).
	planet = world.get_node_or_null("Planet") as Planet
	player = world.get_node_or_null("Player") as Player
	rig = world.get_node_or_null("CameraRig") as CameraRig
	planet_id = GameState.current_planet_id
	layer = SafariLayer.new()
	layer.safari = self
	add_child(layer)
	_run()


func _exit_tree() -> void:
	# Whatever ends this node - the review closing, a rocket, a quit - the gate must not outlive it:
	# PhotoMode is a static and would hide the HUD on every later world.
	if not _restored:
		_restore(false)
	if current == self:
		current = null


func _run() -> void:
	# Wait for the talk to close and the dialogue camera to finish releasing.
	while EventBus.is_modal_open() or _dialogue_active():
		await get_tree().process_frame
	await get_tree().create_timer(DIALOGUE_RELEASE_SEC + 0.05).timeout
	if planet == null or player == null or rig == null:
		push_warning("PlanetSafari: world pieces missing; no safari.")
		_restored = true
		queue_free()
		return
	# Decided BEFORE today's day flag is written: `_tips_wanted` reads whether any safari ran before.
	tips_on = _tips_wanted()
	# Spend today's safari NOW, at the start, so a quit or reload mid-safari cannot buy a second one.
	day = GameState.day_count
	GameState.flags[FLAG_DAY_PREFIX + planet_id] = day
	if SaveManager.has_method("autosave_allowed") and SaveManager.autosave_allowed():
		SaveManager.save_game()
	var hour := GameState.time_of_day
	is_night = hour < WorldClock.SUN_RISE_HOUR or hour >= WorldClock.SUN_SET_HOUR
	_saved_xform = player.global_transform
	player.set_move_locked(true)
	phase = Phase.FADE_IN
	await layer.fade_to(1.0, FADE_SEC)
	if not is_instance_valid(player):
		return
	_begin_behind_black()
	await _warm_up()
	layer.show_awake_ui(true)
	await layer.fade_to(0.0, FADE_SEC)
	player.set_move_locked(false)
	phase = Phase.AWAKE
	elapsed = 0.0
	# On the teaching safari the opening line is only the first step; the rest comes as each moment does.
	layer.intro_hint(tips_on and not _tip_seen("camera"))
	_log("awake: planet=%s day=%d night=%s rare=%s film=%d start=%s fwd=%s tips=%s seen=%s" % [planet_id, day,
		str(is_night), str(is_rare_day), film_left, str(start_dir), str(start_fwd), str(tips_on),
		str(_tips_seen().keys())])


func _begin_behind_black() -> void:
	PhotoMode.begin(planet_id)
	# ECON (2026-09-29): the camera upgrade (film_capacity) and any spare plates bought at Cosmo
	# Depot (GameState.take_film_spares, used up here) both load into this trip.
	film_start = GameState.film_capacity() + GameState.take_film_spares()
	film_left = film_start
	focus_m = planet.radius
	focus_target_m = focus_m
	# The world script decides the rare day's odds and may move the start.
	var script_path := WORLDS_DIR + planet_id + ".gd"
	var scr: Variant = load(script_path) if ResourceLoader.exists(script_path) else load(PLACEHOLDER_WORLD)
	_content = (scr as Script).new() as SafariWorld if scr is Script else null
	if _content == null:
		_content = SafariWorld.new()
	_content.name = "Content"
	_content.safari = self
	is_rare_day = is_rare_day_for(planet_id, day, _content.rare_one_in)
	_place_start()
	rig.reseat_behind_player()
	rig.set_first_person(true)
	_set_start_pitch()
	rig.set_fov_deg(PHOTO_MODE_OFF_FOV)
	player.set_safari_walk(true)
	hover_enabled = bool(GameState.flags.get(HOVER_FLAG, false))
	player.set_safari_hover(hover_enabled)
	_hover_hint_due = hover_enabled and not GameState.flags.get(HOVER_HINT_FLAG, false)
	_make_puff_material()
	add_child(_content)
	_content.build(self)
	_check_overlaps()
	_check_roster()


## The first-person view starts START_PITCH_DEG below level (spec 13.3). set_first_person(true) levels it,
## so this runs after. CameraRig has no pitch setter yet (asked for in the report): its own
## `set_view_pitch_deg` when it gains one, else its first-person pitch field directly.
func _set_start_pitch() -> void:
	if rig.has_method("set_view_pitch_deg"):
		rig.call("set_view_pitch_deg", START_PITCH_DEG)
	elif "_fp_pitch" in rig:
		rig.set("_fp_pitch", deg_to_rad(START_PITCH_DEG))


## Beside the pad the way world.gd spawns a player off it, facing straight away from the rocket.
func _place_start() -> void:
	var pd: PlanetData = planet.data
	var pad := pd.pad_dir.normalized()
	var dir := pad
	var side := pad.cross(Vector3.UP)
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	dir = (pad + side.normalized() * (PAD_STEP_M / planet.radius)).normalized()
	if _content.start_dir != Vector3.ZERO:
		dir = _content.start_dir.normalized()
	var fwd := dir - pad
	if _content.start_heading != Vector3.ZERO:
		fwd = _content.start_heading
	fwd -= dir * fwd.dot(dir)
	if fwd.length_squared() < 1e-6:
		fwd = Vector3.FORWARD - dir * Vector3.FORWARD.dot(dir)
	start_dir = dir
	start_fwd = fwd.normalized()
	player.dev_teleport(planet.surface_point(dir))
	player.place_on_planet(dir, start_fwd)


## Draws every mesh and CPU particle the content made, once, 2 cm big, 1 m in front of the lens,
## for a few frames behind the black - the ShaderWarmup recipe (src/world/shader_warmup.gd) for this
## node's own materials, so their first appearance is not a shader compile.
func _warm_up() -> void:
	var cam := rig.get_view_camera()
	if cam == null:
		return
	var holder := Node3D.new()
	holder.name = "WarmUp"
	add_child(holder)
	var sources: Array = []
	_collect_geometry(_content, sources)
	var puff := _new_puff(Vector3.ZERO, 8, Color.WHITE)
	sources.append(puff)
	var i := 0
	for g: Node in sources:
		var copy: Node3D = null
		if g is CPUParticles3D:
			copy = (g as CPUParticles3D).duplicate(0) as Node3D
			for c in copy.get_children():
				c.queue_free()
			(copy as CPUParticles3D).emitting = true
		elif g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var mi := MeshInstance3D.new()
			var src := g as MeshInstance3D
			mi.mesh = src.mesh
			mi.material_override = src.material_override
			for si in range(src.get_surface_override_material_count()):
				mi.set_surface_override_material(si, src.get_surface_override_material(si))
			copy = mi
		elif g is MultiMeshInstance3D:
			copy = (g as MultiMeshInstance3D).duplicate(0) as Node3D
		if copy == null:
			continue
		holder.add_child(copy)
		copy.visible = true
		copy.scale = Vector3.ONE * 0.02
		copy.position = Vector3((float(i % 7) - 3.0) * 0.03, (float(i / 7) - 2.0) * 0.03, 0.0)
		i += 1
	puff.queue_free()
	for f in range(3):
		if not is_instance_valid(cam):
			break
		holder.global_transform = cam.global_transform * Transform3D(Basis(), Vector3(0, 0, -1.0))
		await get_tree().process_frame
	holder.queue_free()
	_log("warm-up: %d copies drawn" % i)


func _collect_geometry(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			out.append(c)
		_collect_geometry(c, out)


func _process(delta: float) -> void:
	if phase != Phase.AWAKE:
		return
	_max_frame_ms = maxf(_max_frame_ms, delta * 1000.0)
	elapsed += delta
	_run_schedule(delta)
	_mark_woke()
	if _content != null:
		_content.tick(elapsed, delta)
	_update_camera_mode(delta)
	if _hover_hint_due and elapsed >= HOVER_HINT_AT:
		_hover_hint_due = false
		GameState.flags[HOVER_HINT_FLAG] = true
		announce(HOVER_HINT if MobileUI.is_mobile() else HOVER_HINT_KEYS, 3.5)
	if elapsed >= DURATION:
		_go_to_sleep()


func _dialogue_active() -> bool:
	var r := get_tree().root.find_child(DialogueRunner.RUNNER_NAME, true, false)
	return r != null and r.has_method("is_active") and bool(r.call("is_active"))


# ======================================================================================== REGISTRY
func add_subject(spec: Dictionary) -> String:
	var id := str(spec.get("id", ""))
	if id == "":
		push_warning("PlanetSafari.add_subject: no id")
		return ""
	var key := "%s:%s" % [planet_id, id]
	var s := spec.duplicate()
	s["key"] = key
	var entry := roster_entry(planet_id, id)
	var tier := str(spec.get("tier", entry.get("tier", "")))
	s["tier"] = tier
	s["name"] = str(spec.get("name", entry.get("name", id.capitalize())))
	s["rarity"] = clampi(int(spec.get("rarity", SafariWorld.TIER_RARITY.get(tier, 1))), 1, 4)
	s["radius"] = maxf(float(spec.get("radius", 0.5)), 0.01)
	if not s.has("band"):
		s["band"] = Vector2(0.2, 0.6)
	if _subjects.has(key):
		push_warning("PlanetSafari.add_subject: duplicate id %s" % id)
	else:
		_subject_order.append(key)
	_subjects[key] = s
	return key


func add_event(spec: Dictionary) -> bool:
	var ev := spec.duplicate()
	ev["id"] = str(spec.get("id", "event_%d" % _events.size()))
	ev["start"] = float(spec.get("start", 0.0))
	ev["end"] = maxf(float(spec.get("end", DURATION)), float(ev["start"]))
	ev["warn"] = maxf(float(spec.get("warn", 0.0)), 0.0)
	ev["dir"] = (spec.get("dir", start_dir) as Vector3).normalized()
	var when := str(spec.get("when", "any"))
	var rare := str(spec.get("rare", "any"))
	var ok := (when == "any" or (when == "night") == is_night) \
		and (rare == "any" or (rare == "only") == is_rare_day)
	ev["eligible"] = ok
	ev["warned"] = false
	ev["started"] = false
	ev["ended"] = false
	_events.append(ev)
	return ok


func event_running(id: String) -> bool:
	for ev: Dictionary in _events:
		if str(ev["id"]) == id:
			return bool(ev["eligible"]) and bool(ev["started"]) and not bool(ev["ended"])
	return false


func subject(key_or_id: String) -> Dictionary:
	if _subjects.has(key_or_id):
		return _subjects[key_or_id]
	return _subjects.get("%s:%s" % [planet_id, key_or_id], {})


## Every subject that can be in a photo right now.
func awake_subjects() -> Array:
	var out: Array = []
	for key: String in _subject_order:
		var s: Dictionary = _subjects[key]
		if _is_awake(s):
			out.append(s)
	return out


func _is_awake(s: Dictionary) -> bool:
	var n: Variant = s.get("node")
	if not (n is Node3D) or not is_instance_valid(n) or not (n as Node3D).is_inside_tree():
		return false
	var aw: Variant = s.get("awake")
	if aw is Callable and (aw as Callable).is_valid():
		return bool((aw as Callable).call())
	var ev_id := str(s.get("event", ""))
	if ev_id != "":
		return event_running(ev_id)
	return (n as Node3D).is_visible_in_tree()


func _mark_woke() -> void:
	for key: String in _subject_order:
		if not _woke.has(key) and _is_awake(_subjects[key]):
			_woke[key] = elapsed


func _run_schedule(delta: float) -> void:
	for ev: Dictionary in _events:
		if not bool(ev["eligible"]) or bool(ev["ended"]):
			continue
		var s: float = ev["start"]
		if not bool(ev["warned"]) and elapsed >= s - float(ev["warn"]):
			ev["warned"] = true
			_call(ev.get("on_warn"), [ev])
		if not bool(ev["started"]) and elapsed >= s:
			ev["started"] = true
			_log("event start %s t=%.2f" % [ev["id"], elapsed])
			_call(ev.get("on_start"), [ev])
		if bool(ev["started"]):
			if elapsed >= float(ev["end"]):
				ev["ended"] = true
				_log("event end %s t=%.2f" % [ev["id"], elapsed])
				_call(ev.get("on_end"), [ev])
			else:
				_call(ev.get("on_tick"), [ev, elapsed - s, delta])


func _call(c: Variant, args: Array) -> void:
	if c is Callable and (c as Callable).is_valid():
		(c as Callable).callv(args)


## Every id the world registered should be in its manifest's roster (the journal's "????" rows and the
## pacing director's tiers come from it). The journal still learns any it does not list.
func _check_roster() -> void:
	var m := manifest(planet_id)
	if m.is_empty():
		return
	var unlisted: Array = []
	for key: String in _subject_order:
		var id := key.get_slice(":", 1)
		if roster_entry(planet_id, id).is_empty():
			unlisted.append(id)
	if not unlisted.is_empty():
		push_warning("PlanetSafari: %s registered subjects its roster does not list: %s" % [planet_id, str(unlisted)])
	_log("manifest: planet=%s source=%s host=%s roster=%d registered=%d" % [planet_id, str(m.get("source", "")),
		str(m.get("host", "")), (m.get("roster", []) as Array).size(), _subject_order.size()])


## True while a RARE event is up (spec 13.2: the pacing director stays quiet): any awake subject of tier
## "rare" or "rare_day" (SafariWorld.QUIET_TIERS), or, for a subject with no tier, rarity 4 on something
## that is not a creature or the neighbour (Bolt's whale and magnet before his manifest). An eligible
## running event whose spec carries "tier": "rare"/"rare_day" counts too.
func rare_event_up() -> bool:
	for ev: Dictionary in _events:
		if SafariWorld.QUIET_TIERS.has(str(ev.get("tier", ""))) and bool(ev["eligible"]) \
				and bool(ev["started"]) and not bool(ev["ended"]):
			return true
	for s: Dictionary in awake_subjects():
		var tier := str(s.get("tier", ""))
		if SafariWorld.QUIET_TIERS.has(tier):
			return true
		if tier == "" and int(s.get("rarity", 1)) >= 4 and not ["creature", "neighbour"].has(str(s.get("kind", ""))):
			return true
	return false


func _check_overlaps() -> void:
	var el: Array = _events.filter(func(e: Dictionary) -> bool: return bool(e["eligible"]))
	for i in range(el.size()):
		for j in range(i + 1, el.size()):
			var a: Dictionary = el[i]
			var b: Dictionary = el[j]
			var overlap := float(a["start"]) < float(b["end"]) and float(b["start"]) < float(a["end"])
			if overlap and not (bool(a.get("overlap_ok", true)) and bool(b.get("overlap_ok", true))):
				push_warning("PlanetSafari: events %s and %s overlap but one says overlap_ok = false" % [a["id"], b["id"]])


# ======================================================================================== PLACES
## `around_deg` round the planet from the start along a bearing from the start heading (+ = right).
func dir_from_start(around_deg: float, bearing_deg: float) -> Vector3:
	var h := start_fwd.rotated(start_dir, -deg_to_rad(bearing_deg)).normalized()
	var a := deg_to_rad(around_deg)
	return (start_dir * cos(a) + h * sin(a)).normalized()


func ground_point(dir: Vector3, lift_m: float = 0.0) -> Vector3:
	var d := dir.normalized()
	return planet.surface_point(d) + planet.up_at(planet.surface_point(d)) * lift_m


func surface_xform(dir: Vector3) -> Transform3D:
	return planet.surface_transform(dir.normalized(), start_fwd)


func announce(text: String, secs: float = 3.0) -> void:
	if layer != null:
		layer.banner(text, secs)


# ======================================================================================== PUFFS
func _make_puff_material() -> void:
	_puff_mat = StandardMaterial3D.new()
	_puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_puff_mat.vertex_color_use_as_albedo = true
	_puff_mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	_puff_mesh = SphereMesh.new()
	_puff_mesh.radius = 0.12
	_puff_mesh.height = 0.24
	_puff_mesh.radial_segments = 8
	_puff_mesh.rings = 4
	_puff_mesh.material = _puff_mat


func _new_puff(pos: Vector3, amount: int, colour: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = _puff_mesh
	p.amount = maxi(amount, 1)
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 1.2
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.4
	p.gravity = Vector3.ZERO
	p.damping_min = 0.8
	p.damping_max = 1.2
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(colour, 0.85))
	ramp.set_color(1, Color(colour, 0.0))
	p.color_ramp = ramp
	p.position = pos
	return p


## A one-shot puff at `pos`, oriented to the local up. Frees itself.
func puff_at(pos: Vector3, amount: int = 16, colour: Color = UIStyle.CREAM) -> void:
	if _puff_mat == null:
		return
	var p := _new_puff(Vector3.ZERO, amount, colour)
	add_child(p)
	var up := planet.up_at(pos) if planet != null else Vector3.UP
	var b := Basis(Quaternion(Vector3.UP, up))
	p.global_transform = Transform3D(b, pos)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)


# ======================================================================================== CAMERA UP
func set_camera_up(on: bool) -> void:
	if phase != Phase.AWAKE or on == camera_up:
		return
	if not on and holding:
		holding = false
	camera_up = on
	zoom_nudge = ""
	_nudge_want = ""
	_nudge_want_s = 0.0
	_nudge_clock = NUDGE_EVERY   # the first read is on the first camera-up frame
	aim_info = {}
	# THE STEADY GRIP (GOODS, docs/JUNGLE_PLANET_SPEC.md 6.1): owned -> the camera up walks slowly
	# (Player.STEADY_WALK_SPEED) instead of locking. The meteor survey inherits this function, so it has it too.
	var grip := on and GameState.flag(CameraGoods.GRIP_FLAG)
	player.set_move_locked(on and not grip)
	player.set_steady_walk(grip)
	rig.set_zoom_input_drives_fov(on)
	rig.set_fov_deg(camera_fov if on else PHOTO_MODE_OFF_FOV)
	_apply_look_scale()
	AudioManager.play_sfx("ui_tick" if on else "ui_close", -6.0)
	_log("camera %s fov=%.1f" % ["UP" if on else "down", rig.get_fov_deg()])
	if on:
		_tip("camera")


## Walking: the rig's normal look. Camera up: a finger drag of one pixel turns the view by one
## pixel's worth of lens (fov / frame height), so what is under the finger stays under it at every
## zoom - an exact inversion, no tuned constant.
func _apply_look_scale() -> void:
	if not camera_up:
		rig.set_look_sensitivity_scale(1.0)
		return
	var h := get_viewport().get_visible_rect().size.y
	var deg_per_px := rig.get_fov_deg() / maxf(h, 1.0)
	rig.set_look_sensitivity_scale(deg_per_px / CameraRig.MOUSE_YAW_DEG_PER_PX)


func set_zoom_fov(deg: float) -> void:
	if not camera_up:
		return
	rig.set_fov_deg(deg)
	camera_fov = rig.get_fov_deg()
	_apply_look_scale()


func _update_camera_mode(delta: float) -> void:
	if not camera_up:
		return
	# Pinch and wheel move the rig's fov directly; follow it.
	var f := rig.get_fov_deg()
	if not is_equal_approx(f, camera_fov):
		camera_fov = f
		_apply_look_scale()
	# Zoomed in on their own: the zoom lesson is already learnt (spec 15.4 "already-done lessons are
	# skipped").
	if tips_on and camera_fov < CameraRig.FP_FOV_DEFAULT - TIP_ZOOMED_DEG and not _tip_seen("zoom"):
		_tip_mark("zoom", "zoomed on their own")
	# Camera up locks walking, full stop (spec 8.2): the stick never lowers it - a thumb resting on the
	# stick while aiming would drop the camera. Only the Walk button (or the camera key) does.
	_update_nudge(delta)
	if holding:
		hold_s += delta
		_refocus(false)
		var k := 1.0 - exp(-delta / FOCUS_TAU)
		focus_m = exp(lerpf(log(focus_m), log(maxf(focus_target_m, 0.1)), k))


## The zoom nudge (spec 11.1): what the viewfinder is on, and whether it is smaller than its band.
func _update_nudge(delta: float) -> void:
	_nudge_clock += delta
	if _nudge_clock >= NUDGE_EVERY:
		_nudge_clock = 0.0
		var cam := rig.get_view_camera()
		if cam != null:
			aim_info = SafariPhotoScorer.aim_subject(cam, get_viewport().get_visible_rect().size,
				awake_subjects(), _space(), _exclude())
	var want := ""
	if not aim_info.is_empty():
		var short := SafariPhotoScorer.stops_too_small(float(aim_info["size_frac"]), aim_info["band"] as Vector2)
		if short > 0.0:
			want = NUDGE_CLOSER if camera_fov <= CameraRig.FP_FOV_MIN + 0.05 else NUDGE_ZOOM
	if want == zoom_nudge:
		_nudge_want = want
		_nudge_want_s = 0.0
		return
	if want != _nudge_want:
		_nudge_want = want
		_nudge_want_s = 0.0
	_nudge_want_s += delta
	if _nudge_want_s >= NUDGE_HOLD:
		zoom_nudge = want
		_log("nudge \"%s\" on=%s size_frac=%.3f band=%s fov=%.1f" % [zoom_nudge, str(aim_info.get("key", "")),
			float(aim_info.get("size_frac", 0.0)), str(aim_info.get("band", "")), camera_fov])
		# The first time a subject is small in the frame and the lens can still zoom (spec 15.4).
		if zoom_nudge == NUDGE_ZOOM:
			_tip("zoom")


## Reads the focus ring (SafariPhotoScorer.centre_ray_focus). `snap` (the shutter going down): the lens
## focuses AT ONCE on the first surface in the ring - a tap photographs a subject in focus, not the
## last thing the lens was set to. Every frame the shutter is held: the target becomes the subject's
## own centre distance, which the lens glides to (holding makes it better, not possible). The ring
## seeing nothing within FOCUS_FAR_M (the sky, a subject slipping out between frames): keep the last
## lock - never jump to the far distance (spec 8.2).
func _refocus(snap: bool) -> void:
	var cam := rig.get_view_camera()
	if cam == null:
		return
	var frame := get_viewport().get_visible_rect().size
	var r := SafariPhotoScorer.centre_ray_focus(cam, frame, awake_subjects(), _space(), _exclude(),
		FOCUS_FAR_M, SafariLayer.AF_RING_R)
	if not bool(r["hit"]):
		return
	focus_target_m = maxf(float(r["dist"]), 0.1)
	focus_target_key = str(r["key"])
	if snap:
		focus_m = maxf(float(r["near"]), 0.1)


func focus_settled() -> bool:
	return holding and absf(log(focus_m / maxf(focus_target_m, 0.1)) / log(2.0)) <= FOCUS_SETTLED_STOPS


func shutter_down() -> void:
	if phase != Phase.AWAKE or not camera_up or capturing:
		return
	if film_left <= 0:
		announce("Out of film! Just look around.", 2.0)
		return
	holding = true
	hold_s = 0.0
	_refocus(true)


func shutter_up() -> void:
	if not holding:
		return
	holding = false
	if phase != Phase.AWAKE or not camera_up or film_left <= 0:
		return
	_take_photo()


## The Hover button / H key (see HOVER_FLAG): a tap starts a hover, a tap while hovering lets go.
func hover_press() -> void:
	if phase != Phase.AWAKE or not hover_enabled or not is_instance_valid(player):
		return
	# Found the button on their own: no need for the hint.
	if _hover_hint_due:
		_hover_hint_due = false
		GameState.flags[HOVER_HINT_FLAG] = true
	var was := player.is_hovering()
	var now := player.toggle_hover()
	if now == was and not now:
		announce("Jetpack's refilling. Land for a moment.", 1.6)
		AudioManager.play_sfx("blocked", -10.0)
		return
	AudioManager.play_sfx("ui_tick" if now else "ui_close", -8.0)
	_log("hover %s fuel=%.2f h=%.2f" % ["UP" if now else "off", player.get_hover_fuel(), player.get_ground_height()])


func _space() -> PhysicsDirectSpaceState3D:
	return get_world_3d().direct_space_state if is_inside_tree() else null


func _exclude() -> Array[RID]:
	var ex: Array[RID] = []
	if is_instance_valid(player):
		ex.append(player.get_rid())
	return ex


# ======================================================================================== THE END BUTTON
## SafariLayer's End button (top-right corner): one tap only opens the confirm - "End the safari?
## Your photos are kept." with End / Keep exploring (spec 17.2.1). A shutter held when the pause fires
## is let go without a picture, exactly as the tip pause does, so no plate is spent behind the card.
func request_end() -> void:
	if phase != Phase.AWAKE or _end_pending or tip_up or _tip_pending:
		return
	_end_pending = true
	holding = false
	layer.cancel_pointers()
	EventBus.ui_modal_opened.emit(END_MODAL)
	get_tree().paused = true
	var confirmed: bool = await layer.show_choice_card("End the safari? Your photos are kept.",
		"End", "Keep exploring")
	if is_inside_tree():
		get_tree().paused = false
	EventBus.ui_modal_closed.emit(END_MODAL)
	_end_pending = false
	if phase != Phase.AWAKE:
		return
	if confirmed:
		_log("end: player ended early at t=%.2f film_left=%d photos=%d" % [elapsed, film_left, _photos.size()])
		_go_to_sleep()


## THE OUT-OF-FILM CARD (spec 17.2.1, the user: "I ran out of film and there was nothing for me to do
## until the time was up"). Fired once, after the last plate's flash and its own "film" tip (if any)
## have had their moment, offering "See your photos" (ends now, same as the End button confirmed) or
## "Keep walking" (the End button stays there; the clock keeps running to DURATION as normal).
func _offer_film_out() -> void:
	if _film_out_offered or phase != Phase.AWAKE or film_left > 0:
		return
	_film_out_offered = true
	while phase == Phase.AWAKE and (capturing or tip_up or _tip_pending or _end_pending):
		await get_tree().process_frame
	if phase != Phase.AWAKE:
		return
	# The last plate's own shutter flash is still fading here (a 0.32 s tween started by _capture) -
	# the same wait _show_tip takes before its own "film" tip, so this card never opens over a still
	# half-white frame from the last photo.
	await get_tree().create_timer(0.45).timeout
	if phase != Phase.AWAKE:
		return
	if not is_inside_tree() or get_tree().paused or EventBus.is_modal_open() or _dialogue_active():
		return
	holding = false
	layer.cancel_pointers()
	EventBus.ui_modal_opened.emit(FILM_OUT_MODAL)
	get_tree().paused = true
	var end_now: bool = await layer.show_choice_card("Out of film! See your photos, or keep walking?",
		"See your photos", "Keep walking")
	if is_inside_tree():
		get_tree().paused = false
	EventBus.ui_modal_closed.emit(FILM_OUT_MODAL)
	if phase != Phase.AWAKE:
		return
	if end_now:
		_log("end: film ran out, player chose to see photos at t=%.2f" % elapsed)
		_go_to_sleep()


# ======================================================================================== THE PICTURE
func _take_photo() -> void:
	var t := elapsed
	var cam := rig.get_view_camera()
	var vp := get_viewport()
	var frame := vp.get_visible_rect().size
	var res := SafariPhotoScorer.score_frame(cam, frame, awake_subjects(), focus_m, _space(), _exclude(), t)
	if (res["best"] as Dictionary).is_empty():
		# NO SUBJECT IN THE FRAME (spec 13.1): no picture, no plate - and a line, so the press is not dead.
		announce(NOTHING_LINE, 1.8)
		AudioManager.play_sfx("ui_close", -8.0)
		_refused += 1
		_log("refused t=%.2f: nothing in the frame (film %d kept) | %s" % [t, film_left, _why_not(cam, frame)])
		photo_refused.emit(t)
		return
	capturing = true
	film_left -= 1
	# The frame itself, with no 2D on it: every canvas item is culled for exactly the one frame
	# the picture is read from (Viewport.canvas_cull_mask; nothing's `visible` is touched).
	var saved_mask := vp.canvas_cull_mask
	vp.canvas_cull_mask = 0
	var us0 := Time.get_ticks_usec()
	# A HEADLESS test run (tools/ps_*_player.gd with --fixed-fps) draws nothing and never signals a drawn
	# frame: it scores the same maths and keeps no pixels. The game itself never runs headless.
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		await RenderingServer.frame_post_draw
	var us1 := Time.get_ticks_usec()
	var img: Image = null if headless else vp.get_texture().get_image()
	var us2 := Time.get_ticks_usec()
	vp.canvas_cull_mask = saved_mask
	if layer != null:
		layer.flash()
	AudioManager.play_sfx("place", -2.0)
	var full := Vector2i(img.get_width(), img.get_height()) if img != null else Vector2i.ZERO
	if img != null and img.get_width() > PHOTO_W:
		var h := maxi(1, int(round(float(img.get_height()) * PHOTO_W / float(img.get_width()))))
		img.resize(PHOTO_W, h, Image.INTERPOLATE_BILINEAR)
	if img != null and img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)   # the frame has no alpha worth keeping: 3/4 of the memory
	var us3 := Time.get_ticks_usec()
	var photo := _photo_record(res, img, t)
	photo["capture_ms"] = {"wait_draw": (us1 - us0) / 1000.0, "get_image": (us2 - us1) / 1000.0,
		"resize": (us3 - us2) / 1000.0, "full": full}
	_photos.append(photo)
	_capture_log.append(photo["capture_ms"])
	_log("photo #%d t=%.2f subject=%s scores=%s grade=%s price=%d focus_m=%.2f fov=%.1f held=%.2f capture=%s" % [
		photo["index"], t, photo["subject_key"], str(photo["scores"]), photo["grade"], photo["price"],
		focus_m, photo["fov"], photo["held_s"], str(photo["capture_ms"])])
	photo_taken.emit(photo)
	capturing = false
	# The first plate used (spec 15.4).
	_tip("film")
	# The last plate used (spec 17.2.1): offer to end now or keep walking.
	if film_left <= 0:
		_offer_film_out.call_deferred()


## For the log of a refused shutter: each awake subject and why it is not in the photo.
func _why_not(cam: Camera3D, frame: Vector2) -> String:
	var out: PackedStringArray = []
	for s: Dictionary in awake_subjects():
		var p := SafariPhotoScorer.subject_point(s)
		var why := "?"
		if cam.is_position_behind(p):
			why = "behind"
		else:
			var sp := cam.unproject_position(p)
			var r := float(s.get("radius", 0.5))
			var d := cam.global_position.distance_to(p)
			var r_px := tan(asin(clampf(r / maxf(d, 0.01), 0.0, 1.0))) / tan(deg_to_rad(cam.fov) * 0.5) * frame.y * 0.5
			if SafariPhotoScorer.inside_fraction(sp, r_px, frame) <= 0.0:
				why = "off@(%d,%d)" % [int(sp.x), int(sp.y)]
			elif SafariPhotoScorer.seen_fraction(cam, p, r, _space(), _exclude()) <= 0.0:
				why = "hidden"
		out.append("%s:%s" % [str(s.get("id", "")), why])
	return " ".join(out) if not out.is_empty() else "nothing awake"


func _photo_record(res: Dictionary, img: Image, t: float) -> Dictionary:
	var best: Dictionary = res["best"]
	var others: Array = []
	for e: Dictionary in res["all"]:
		if e != best:
			others.append(_public_entry(e))
	var p := {
		"index": _photos.size(),
		"t": t,
		"image": img,
		"subject_key": str(best.get("key", "")),
		"subject_name": str(best.get("name", "")),
		"rarity": int(best.get("rarity", 0)),
		"scores": {
			"centred": int(round(float(best.get("centred", 0.0)))),
			"size": int(round(float(best.get("size", 0.0)))),
			"focus": int(round(float(best.get("focus", 0.0)))),
			"rarity": int(best.get("rarity10", 0)),
		},
		"has_facing": bool(best.get("has_facing", false)),
		"raw": _public_entry(best) if not best.is_empty() else {},
		"craft": float(best.get("craft", 0.0)),
		"skill": float(best.get("skill", 0.0)),
		"grade": str(best.get("grade", SafariScoring.GRADES[0])),
		"grade_idx": int(best.get("grade_idx", 0)),
		"moment": bool(best.get("moment", false)),
		"price": int(best.get("price", 0)),
		"moment_mult": float(best.get("moment_mult", 1.0)),
		"moment_line": str(best.get("moment_line", "")),
		"others": others,
		"fov": rig.get_fov_deg(),
		"focus_m": focus_m,
		"held_s": hold_s,
	}
	if bool(best.get("has_facing", false)):
		(p["scores"] as Dictionary)["facing"] = int(round(float(best.get("facing", 0.0))))
	return p


func _public_entry(e: Dictionary) -> Dictionary:
	var out := e.duplicate()
	out.erase("screen")
	return out


# ======================================================================================== THE END
func _go_to_sleep() -> void:
	holding = false
	if is_instance_valid(player) and player.is_hovering():
		player.stop_hover(true)
	if camera_up:
		set_camera_up(false)   # before the phase changes: set_camera_up only acts while AWAKE
	phase = Phase.SLEEPING
	player.set_move_locked(true)
	var self_hiding := false
	if _content != null:
		self_hiding = _content.go_to_sleep()
	var sleepers := awake_subjects()
	for s: Dictionary in sleepers:
		puff_at(SafariPhotoScorer.subject_point(s), 18)
	if not self_hiding:
		get_tree().create_timer(SLEEP_PUFF_HIDE_SEC).timeout.connect(func() -> void:
			for s: Dictionary in sleepers:
				var n: Variant = s.get("node")
				if n is Node3D and is_instance_valid(n):
					(n as Node3D).visible = false)
	# The first safari is over: no pauses on any later one, whatever lessons were left (spec 15.4).
	if tips_on:
		GameState.set_flag(TIPS_OVER_FLAG)
		_log("tips: first safari over, shown=%s" % str(_tip_log))
	layer.banner("The planet yawns and goes back to sleep...", SLEEP_SEC + 0.5)
	_log("asleep at t=%.2f max_frame_ms=%.1f" % [elapsed, _max_frame_ms])
	await get_tree().create_timer(SLEEP_SEC).timeout
	phase = Phase.FADE_OUT
	await layer.fade_to(1.0, FADE_SEC)
	var session := _build_session()
	_restore(true)
	layer.show_awake_ui(false)
	await get_tree().process_frame
	await layer.fade_to(0.0, FADE_SEC)
	last_session = session
	session_finished.emit(session)
	phase = Phase.REVIEW
	if ResourceLoader.exists(REVIEW_SCRIPT):
		var rv: Variant = load(REVIEW_SCRIPT)
		if rv is Script:
			await (rv as Script).call("present", world, session)
		else:
			await layer.show_plain_review(session)
	else:
		await layer.show_plain_review(session)
	phase = Phase.DONE
	_log("done")
	queue_free()


func _build_session() -> Dictionary:
	var named: Dictionary = {}
	for p: Dictionary in _photos:
		var k := str(p["subject_key"])
		if k != "":
			named[k] = true
	var missed := 0
	for k: String in _woke:
		if not named.has(k):
			missed += 1
	return {
		"planet_id": planet_id,
		"day": day,
		"is_night": is_night,
		"is_rare_day": is_rare_day,
		"duration": DURATION,
		"film_start": film_start,
		"film_left": film_left,
		"photos": _photos.duplicate(),
		"photographed": named.keys(),
		"woke": _woke.keys(),
		"missed_count": missed,
		"max_frame_ms": _max_frame_ms,
		"refused": _refused,
	}


## Everything back as it was before the safari. `teleport` false = the scene is going away anyway
## (a rocket, a quit): only the static gate and what outlives this node are put back.
func _restore(teleport: bool) -> void:
	if _restored:
		return
	_restored = true
	PhotoMode.end()
	if _content != null and is_instance_valid(_content):
		_content.queue_free()
		_content = null
	if is_instance_valid(player):
		player.set_safari_hover(false)
		player.set_steady_walk(false)
	hover_enabled = false
	if not teleport:
		return
	if is_instance_valid(rig):
		rig.set_zoom_input_drives_fov(false)
		rig.set_look_sensitivity_scale(1.0)
		rig.set_first_person(false)
	if is_instance_valid(player):
		player.set_safari_walk(false)
		player.set_move_locked(false)
		player.dev_teleport(_saved_xform.origin)
		player.global_transform = _saved_xform
		player.velocity = Vector3.ZERO
	if is_instance_valid(rig):
		rig.reseat_behind_player()
	camera_up = false


# ======================================================================================== DEBUG
func _log(msg: String) -> void:
	print("[PlanetSafari] " + msg)


## Everything a test needs to read, in one line of plain values.
func debug_state() -> Dictionary:
	return {
		"phase": phase, "elapsed": elapsed, "camera_up": camera_up, "film_left": film_left,
		"focus_m": focus_m, "focus_target_m": focus_target_m, "holding": holding,
		"fov": rig.get_fov_deg() if is_instance_valid(rig) else -1.0,
		"photos": _photos.size(), "woke": _woke.keys(), "photo_mode": PhotoMode.active,
		"hover": {"enabled": hover_enabled, "on": is_instance_valid(player) and player.is_hovering(),
			"fuel": player.get_hover_fuel() if is_instance_valid(player) else 0.0,
			"h": player.get_ground_height() if is_instance_valid(player) else 0.0},
		"awake": awake_subjects().map(func(s: Dictionary) -> String: return str(s["key"])),
		"max_frame_ms": _max_frame_ms,
		"zoom_nudge": zoom_nudge,
		"aim": aim_info.duplicate(),
		"refused": _refused,
		"pitch": rig.get_view_pitch_deg() if is_instance_valid(rig) else 0.0,
		"tips_on": tips_on, "tip_up": tip_up, "tips_seen": _tips_seen().keys(), "tip_log": _tip_log.duplicate(),
		"end_pending": _end_pending, "film_out_offered": _film_out_offered,
		"choice_up": is_instance_valid(layer) and layer.choice_showing(),
	}


# ======================================================================================== THE FIRST SAFARI'S PAUSES
## See TIPS_FLAG's header. Read once, at the start of a safari, before today's day flag is written.
func _tips_wanted() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.has("--safari-tips=off"):
		return false
	if not args.has("--safari-tips=on"):
		for a: String in args:
			if a.begins_with("--ps-"):
				return false
	if GameState.flag(TIPS_OVER_FLAG):
		return false
	if not (GameState.flags.get(TIPS_FLAG) is Dictionary):
		# No teaching safari has started on this save yet. One that ran a safari BEFORE this build is
		# past its first: never pause it.
		for k in GameState.flags.keys():
			if str(k).begins_with(FLAG_DAY_PREFIX):
				GameState.set_flag(TIPS_OVER_FLAG)
				_log("tips: an older save that already ran a safari (%s) - no pauses" % str(k))
				return false
		GameState.flags[TIPS_FLAG] = {}
	for key: String in TIP_ORDER:
		if not _tip_seen(key):
			return true
	GameState.set_flag(TIPS_OVER_FLAG)
	return false


func _tips_seen() -> Dictionary:
	var d: Variant = GameState.flags.get(TIPS_FLAG, {})
	return d if d is Dictionary else {}


func _tip_seen(key: String) -> bool:
	return bool(_tips_seen().get(key, false))


## Marks a lesson done and saves it in the flag at once, so a quit straight after cannot repeat it.
func _tip_mark(key: String, why: String) -> void:
	var d := _tips_seen().duplicate()
	d[key] = true
	GameState.flags[TIPS_FLAG] = d
	_tip_log.append({"key": key, "why": why, "t": snappedf(elapsed, 0.01)})
	_log("tip %s marked done (%s) at t=%.2f" % [key, why, elapsed])


## The moment for lesson `key` has come. Shown on the next idle frame, if it is still wanted then.
func _tip(key: String) -> void:
	if not tips_on or tip_up or _tip_pending or _tip_seen(key):
		return
	_show_tip.call_deferred(key)


func _tip_text(key: String) -> String:
	var phone := MobileUI.is_mobile()
	match key:
		"camera":
			return ("Tap the shutter to snap.\nHold it to let the focus settle, then let go." if phone
				else "Click to snap.\nHold to let the focus settle, then let go.")
		"zoom":
			return ("Small in the frame?\nPinch or slide to zoom in." if phone
				else "Small in the frame?\nScroll the wheel or slide to zoom in.")
		"film":
			return "You have %d shots each safari.\nMake them count!" % film_start
	return ""


## THE PAUSE. The whole tree stops (the safari clock, its schedule and content, the world clock); the
## card (SafariLayer.show_tip, PROCESS_MODE_ALWAYS) waits for "Got it" or "Skip tips". A shutter held
## when the pause fires is let go without a picture, so no plate is spent behind the card.
func _show_tip(key: String) -> void:
	if not tips_on or tip_up or _tip_pending or _tip_seen(key) or phase != Phase.AWAKE or capturing:
		return
	# Let the moment itself show first: the viewfinder draw after the camera goes up (two frames), and
	# the shutter flash fading after the first photo (its 0.32 s tween would freeze half-white behind
	# the card otherwise).
	_tip_pending = true
	if key == "film":
		await get_tree().create_timer(0.45).timeout
	else:
		await get_tree().process_frame
		await get_tree().process_frame
	_tip_pending = false
	if not tips_on or _tip_seen(key) or phase != Phase.AWAKE or capturing:
		return
	if not is_inside_tree() or get_tree().paused or EventBus.is_modal_open() or _dialogue_active():
		return   # not now; the next time the moment comes round, it is asked again
	var text := _tip_text(key)
	if text == "":
		return
	tip_up = true
	_tip_mark(key, "shown")
	holding = false
	layer.cancel_pointers()
	var t0 := elapsed
	var clock0 := GameState.time_of_day
	var wall0 := Time.get_ticks_msec()
	EventBus.ui_modal_opened.emit(TIP_MODAL)
	get_tree().paused = true
	var n := TIP_ORDER.find(key) + 1
	var skip_all: bool = await layer.show_tip(text, n, TIP_ORDER.size())
	if is_inside_tree():
		get_tree().paused = false
	EventBus.ui_modal_closed.emit(TIP_MODAL)
	tip_up = false
	print("[SafariTip] %s shown %d ms; safari clock %.3f -> %.3f, world clock %.4f -> %.4f; %s" % [key,
		Time.get_ticks_msec() - wall0, t0, elapsed, clock0, GameState.time_of_day,
		"SKIP ALL" if skip_all else "got it"])
	if skip_all:
		for k: String in TIP_ORDER:
			if not _tip_seen(k):
				_tip_mark(k, "skip tips")
		tips_on = false
		GameState.set_flag(TIPS_OVER_FLAG)
	elif TIP_ORDER.all(func(k: String) -> bool: return _tip_seen(k)):
		GameState.set_flag(TIPS_OVER_FLAG)


## Dev menu (World tab): the next planet safari teaches itself again, on this save.
static func debug_reset_tips() -> void:
	GameState.flags[TIPS_FLAG] = {}
	GameState.set_flag(TIPS_OVER_FLAG, false)
