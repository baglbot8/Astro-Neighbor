class_name IntroDirector
extends Node
## The first ten minutes. Spawned by `world.gd` as /root/World/Onboarding on every planet load; it
## works out for itself whether there is anything to do.
##
## TWO SHAPES, chosen once per scene by `CampaignData.gates_on()`:
##
## THE CAMPAIGN ("Stranded", docs/CORE_LOOP.md) - a new game:
##   crash    `CrashIntro`, once ever (flag intro_crash_done): your survey ship is bonked by an
##            asteroid in deep space and crash-lands on the pad at home, one continuous shot with no
##            cut (STYLE_GUIDE R2.5), skippable by any press. Only at home, only on a fresh start.
##   beat 0  GREET    Professor Comet radios in: he saw it all on his scope, is relieved you are in
##                    one piece, and says what to do. "I'll manage" skips every hint.
##   beat 1  MOVE     walk MOVE_DIST metres.
##   beat 2  SCRAP    pick up scrap (EventBus.scrap_changed with a positive delta).
##   beat 3  ROCKET   look at the rocket: within ROCKET_LOOK_DIST and facing it for ROCKET_LOOK_HOLD,
##                    or pressing Fly on it.
##   beat 4  FLY      land on another world - in the campaign, the Commons, Zorp or Bolt.
##   The old furniture beat and its "three bits of furniture" line are not in this flow.
##
## THE OLD TUTORIAL - old saves that never finished it, and Director timelines without --campaign:
##   beat 0  GREET    the same radio call shape as before (2 boxes, a choice, 5 boxes - the existing
##                    intro timelines tap through exactly that many), now in Professor Comet's voice.
##   beat 1  MOVE, beat 2 COLLECT (any collectible), beat 3 PLACE (a decoration), beat 4 FLY.
##
## NOTHING IS GATED. Every beat is a nudge through `HintChannel`, never a lock: a player who ignores
## the Professor can walk off, fly away, and the beats tick themselves off behind them. Each beat has
## its own flag in `GameState.flags`, so it survives save/load and can never replay. A beat the
## player has already done (scrap or shards collected, decorations placed, a planet behind them, a
## part on the rocket) is retired silently at load rather than being demanded again.
##
## Flags: intro_crash_done, intro_greeted, intro_beat_move, intro_beat_scrap, intro_beat_rocket,
##        intro_beat_collect, intro_beat_place, intro_beat_fly, intro_done.
##
## COMMAND LINE (Director timelines)
##   --intro      run the intro even though a Director timeline is driving (opt-in, see below)
##   --no-intro   never run it
## The intro freezes the player for a conversation (and the crash for a whole shot), which would
## break every existing timeline that presses move_forward at t=0.5. So under a Director it is OFF
## unless the timeline asks for it with `--intro`; the crash additionally needs the campaign, i.e.
## `--new-game --campaign --intro`. Without a Director (a human, and tools/check.sh) it is ON.

enum Beat { GREET, MOVE, COLLECT, PLACE, SCRAP, ROCKET, FLY, DONE }

const FLAG_DONE := "intro_done"
const FLAG_GREETED := "intro_greeted"
## Set the moment the crash STARTS, so a quit half way through can never play it twice.
const FLAG_CRASH := "intro_crash_done"
const BEAT_FLAGS := {
	Beat.MOVE: "intro_beat_move",
	Beat.COLLECT: "intro_beat_collect",
	Beat.PLACE: "intro_beat_place",
	Beat.SCRAP: "intro_beat_scrap",
	Beat.ROCKET: "intro_beat_rocket",
	Beat.FLY: "intro_beat_fly",
}
const LEGACY_BEATS := [Beat.MOVE, Beat.COLLECT, Beat.PLACE, Beat.FLY]
const CAMPAIGN_BEATS := [Beat.MOVE, Beat.SCRAP, Beat.ROCKET, Beat.FLY]

## Seconds after the world loads before the radio crackles: the arrival banner has had its moment
## and SceneRouter's fade-in is done.
const GREET_DELAY := 3.0
## Seconds from the crash handing control back to the radio call: the camera's hand-back blend has
## settled and the astronaut is standing still, so the call's push-in starts from a calm frame.
const CRASH_TO_RADIO := 0.9
## Metres of walking that count as "you have got the hang of this".
const MOVE_DIST := 7.0
## A single frame's movement larger than this is a teleport / spawn snap, not walking.
const MOVE_STEP_MAX := 1.5
## How long each beat waits before offering its hint, so the player gets to work it out first.
const HINT_AFTER_GREET := 6.0
const HINT_AFTER_BEAT := 2.0
## "Looked at the rocket": standing within this many metres of its base (the pad deck is 2.55 m in
## radius, so this is "on or beside the pad"), facing within this angle of it, for this long - long
## enough that walking past the pad on the way somewhere else does not count.
const ROCKET_LOOK_DIST := 6.0
const ROCKET_LOOK_DEG := 40.0
const ROCKET_LOOK_HOLD := 0.5

## Professor Comet's accent - the same brass as his NpcData "accent", so the radio name tag and
## his tag on the Commons match.
const PROFESSOR_ACCENT := Color("#c9a15c")
## How far to the astronaut's side the campaign call's radio hangs (see `_hang_campaign_radio`).
## The rig's pivot slides 0.975x this toward it (0.75 of the way to the midpoint of the astronaut and
## a focus point 2.6x out), so the bruised rocket, off to that side, comes into the two-shot.
const RADIO_SIDE_M := 1.2

## Current beat (a Beat value; typed int so untyped loop variables never need an enum cast).
var _beat: int = Beat.DONE
var _campaign := false
var _running := false
var _time := 0.0
var _beat_time := 0.0
var _hinted := false
var _greeting := false
var _crashing := false
var _crash: CrashIntro
var _player: Node3D
var _last_pos := Vector3.ZERO
var _walked := 0.0
var _look_time := 0.0


func _ready() -> void:
	HintChannel.get_or_create()
	# Fires whatever the intro is doing: the first favour ever accepted should say where to review it.
	EventBus.favor_accepted.connect(_on_favor_accepted)
	EventBus.collectible_picked.connect(_on_collectible_picked)
	EventBus.decoration_placed.connect(_on_decoration_placed)
	EventBus.planet_leave_requested.connect(_on_leave_requested)
	EventBus.scrap_changed.connect(_on_scrap_changed)
	EventBus.ui_modal_opened.connect(_on_modal_opened)

	if not _intro_allowed():
		return
	# Read once: the gates cannot flip mid-scene in Phase 1, and a flow that switched shape half way
	# through a beat would ask for the wrong thing.
	_campaign = CampaignData.gates_on()
	if GameState.flag(FLAG_DONE):
		return
	_retire_beats_already_done()
	_beat = _first_unfinished()
	if _beat == Beat.DONE:
		_finish()
		return
	_running = true
	_beat_time = 0.0
	_hinted = false
	if _beat == Beat.GREET and _crash_due():
		call_deferred("_start_crash")


func _intro_allowed() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.has("--no-intro"):
		return false
	if Director.is_active() and not args.has("--intro"):
		return false
	return true


## A new campaign game at home that has not seen the crash: nobody has flown anywhere yet (so this
## is not an arrival), and the radio call has not happened (so this is not a save made after it).
func _crash_due() -> bool:
	return _campaign and GameState.current_planet_id == "home" and GameState.previous_planet_id == "" \
		and not GameState.flag(FLAG_CRASH) and not GameState.flag(FLAG_GREETED)


func _order() -> Array:
	return CAMPAIGN_BEATS if _campaign else LEGACY_BEATS


# ============================================================================= beat bookkeeping
## Marks beats the player has demonstrably already done, so we never ask for something twice.
## Runs on every load, which is what makes the intro safe to resume from a save.
func _retire_beats_already_done() -> void:
	# Landed here from somewhere else: they can already fly, they have walked, and they have been
	# inside the rocket.
	if GameState.previous_planet_id != "":
		_set_beat(Beat.MOVE, true)
		_set_beat(Beat.ROCKET, true)
		if GameState.current_planet_id != GameState.previous_planet_id:
			_complete_fly_on_arrival()
	if _campaign:
		# Picked scrap up at some point (a new game starts with STARTING_SCRAP), or already fitted a
		# part, which costs scrap and means the rocket has been looked at closely.
		var parts := GameState.rocket_part_count()
		if GameState.scrap > GameState.STARTING_SCRAP or parts > 0:
			_set_beat(Beat.SCRAP, true)
		if parts > 0:
			_set_beat(Beat.ROCKET, true)
	else:
		# Anything collectible in the bag means they know how to pick things up.
		for entry: Dictionary in Journal.field_guide():
			if GameState.item_count(str(entry.get("item", ""))) > 0:
				_set_beat(Beat.COLLECT, true)
				break
		# Anything on the ground anywhere means they know how to decorate.
		for pid: String in GameState.PLANET_IDS:
			var placed: Array = GameState.placed_decorations.get(pid, [])
			if not placed.is_empty():
				_set_beat(Beat.PLACE, true)
				break
	# The greeting only ever happens at home. Anywhere else, treat it as said.
	if GameState.current_planet_id != "home":
		GameState.set_flag(FLAG_GREETED)


## Beat 4 lands here: the player boarded the rocket last scene and this scene is the new planet.
func _complete_fly_on_arrival() -> void:
	if GameState.flag(BEAT_FLAGS[Beat.FLY]):
		return
	_set_beat(Beat.FLY, true)
	var where := Journal.planet_name(GameState.current_planet_id)
	if _campaign:
		HintChannel.request("intro_flew", "You made it to %s! Ask around for help." % where, "check", 1.2)
	else:
		HintChannel.request("intro_flew", "You flew! %s is all yours to poke about." % where, "check", 1.2)
	HintChannel.request("intro_talk", _say_hello_text(), "heart", 3.0)
	# Flying is the last beat. A player who reached another world without doing the rest has
	# plainly got the idea, so the rest is retired rather than nagged for.
	_skip_all()


func _first_unfinished() -> int:
	if not GameState.flag(FLAG_GREETED):
		return Beat.GREET
	for b: int in _order():
		if not GameState.flag(BEAT_FLAGS[b]):
			return b
	return Beat.DONE


func _set_beat(b: int, quiet: bool = false) -> void:
	if not BEAT_FLAGS.has(b) or GameState.flag(BEAT_FLAGS[b]):
		return
	GameState.set_flag(BEAT_FLAGS[b])
	if quiet:
		# The player worked it out unprompted — retire the hint instead of firing it late.
		HintChannel.mark_acted(_hint_key(b))


func _advance() -> void:
	_beat = _first_unfinished()
	_beat_time = 0.0
	_hinted = false
	_look_time = 0.0
	if _beat == Beat.DONE:
		_finish()


func _finish() -> void:
	_running = false
	if GameState.flag(FLAG_DONE):
		return
	GameState.set_flag(FLAG_DONE)


# ============================================================================= the crash
func _start_crash() -> void:
	if _crash != null or not is_inside_tree():
		return
	GameState.set_flag(FLAG_CRASH)
	_crashing = true
	_crash = CrashIntro.new()
	_crash.name = "CrashIntro"
	_crash.finished.connect(_on_crash_finished)
	add_child(_crash)


func _on_crash_finished(_skipped: bool) -> void:
	_crashing = false
	# The radio call follows CRASH_TO_RADIO seconds after control returns (see _tick_greet).
	_time = maxf(_time, GREET_DELAY - CRASH_TO_RADIO)


# ============================================================================= per-frame
func _process(delta: float) -> void:
	if not _running or _greeting or _crashing:
		return
	_time += delta
	_beat_time += delta
	match _beat:
		Beat.GREET:
			_tick_greet()
		Beat.MOVE:
			_tick_move(delta)
		Beat.ROCKET:
			_tick_rocket(delta)
		_:
			pass
	_tick_hint()


func _tick_greet() -> void:
	if _time < GREET_DELAY:
		return
	if EventBus.is_modal_open() or SceneRouter.is_busy() or get_tree().paused:
		return
	if GameState.current_planet_id != "home":
		GameState.set_flag(FLAG_GREETED)
		_advance()
		return
	_play_greeting()


func _tick_move(delta: float) -> void:
	var p := _find_player()
	if p == null:
		return
	if _last_pos == Vector3.ZERO:
		_last_pos = p.global_position
		return
	var step := p.global_position.distance_to(_last_pos)
	_last_pos = p.global_position
	if step > MOVE_STEP_MAX or delta <= 0.0:
		return
	_walked += step
	if _walked >= MOVE_DIST:
		HintChannel.mark_acted(_hint_key(Beat.MOVE))
		_set_beat(Beat.MOVE)
		HintChannel.request("intro_moved", _moved_text(), "check")
		_advance()


## Near the rocket and facing it, held for ROCKET_LOOK_HOLD. Facing is the astronaut's own (not the
## camera's): "turn to look at it" is the act being asked for.
func _tick_rocket(delta: float) -> void:
	var p := _find_player() as PlanetBody
	var r := _find_rocket()
	if p == null or r == null or not p.visible or EventBus.is_modal_open():
		_look_time = 0.0
		return
	var to := r.global_position - p.global_position
	var flat := to - p.up * to.dot(p.up)
	var ok := to.length() <= ROCKET_LOOK_DIST and flat.length_squared() > 1e-6 \
		and flat.normalized().dot(p.surface_forward()) >= cos(deg_to_rad(ROCKET_LOOK_DEG))
	_look_time = _look_time + delta if ok else 0.0
	if _look_time >= ROCKET_LOOK_HOLD:
		_rocket_seen()


func _rocket_seen() -> void:
	if GameState.flag(BEAT_FLAGS[Beat.ROCKET]):
		return
	HintChannel.mark_acted(_hint_key(Beat.ROCKET))
	_set_beat(Beat.ROCKET)
	HintChannel.request("intro_rocket_seen", "Rusty and dented. She'll only hop to nearby worlds.", "star", 0.3)
	if _beat == Beat.ROCKET:
		_advance()


## Offers the current beat's hint once, after a decent pause. HintChannel does the rest: it will not
## show it over a conversation, will not repeat it, and drops it if the player acts first.
func _tick_hint() -> void:
	if _hinted or _beat == Beat.GREET or _beat == Beat.DONE:
		return
	var wait := HINT_AFTER_GREET if _beat == Beat.MOVE else HINT_AFTER_BEAT
	if _beat_time < wait:
		return
	_hinted = true
	HintChannel.request(_hint_key(_beat), _hint_text(_beat), _hint_icon(_beat))


func _hint_key(b: int) -> String:
	match b:
		Beat.MOVE: return "intro_move"
		Beat.COLLECT: return "intro_collect"
		Beat.PLACE: return "intro_place"
		Beat.SCRAP: return "intro_scrap"
		Beat.ROCKET: return "intro_rocket"
		Beat.FLY: return "intro_fly"
	return ""


## Hint copy, in the words of the front end the player is actually holding: "WASD" and "press E"
## mean nothing on a phone (docs/STYLE_GUIDE.md R2.10).
func _hint_text(b: int) -> String:
	var mobile := MobileUI.is_mobile()
	match b:
		Beat.MOVE:
			var how := "drag the left stick to walk." if mobile else "WASD walks, Shift runs."
			return ("Have a look around — " if _campaign else "Have a wander — ") + how
		Beat.COLLECT:
			# Not "yellow shards" any more: home and the Commons grow scrap now (the scrap builder's
			# home.tres / hub.tres), and an old save meets this hint there first.
			return "See something shiny? %s to pick it up." % _grab_verb()
		Beat.PLACE:
			return "Tap the bag button to place something." if mobile \
				else "Press Tab to open your bag and place something."
		Beat.SCRAP:
			return "Crash scrap is lying about. %s to grab it." % _grab_verb()
		Beat.ROCKET:
			return "Walk up to your rocket and take a look at her."
		Beat.FLY:
			if _campaign:
				return "Take the rocket to %s, Zorp or Bolt." % Journal.planet_name("hub")
			return "Zorp and Bolt live out there. Take the rocket."
	return ""


func _hint_icon(b: int) -> String:
	match b:
		Beat.COLLECT: return "star"
		Beat.PLACE: return "deco_moon_lamp"
		Beat.SCRAP: return _scrap_icon()
	return "star"


func _grab_verb() -> String:
	return "Tap the big button" if MobileUI.is_mobile() else "Press E"


func _moved_text() -> String:
	return "That's the way. Push the stick further to run." if MobileUI.is_mobile() \
		else "That's the way. Hold Shift to run."


func _say_hello_text() -> String:
	return "Stand by a neighbour and tap the big button." if MobileUI.is_mobile() \
		else "Stand by a neighbour and press E to say hello."


## The scrap item's own swatch once the scrap builder has registered it in the Catalog; the star
## until then, so a toast never shows a missing icon.
static func _scrap_icon() -> String:
	return "scrap" if not Catalog.get_item("scrap").is_empty() else "star"


# ============================================================================= world events
func _on_collectible_picked(kind: String, _world_pos: Vector3) -> void:
	# Campaign scrap is counted through scrap_changed; a shard picked up during the campaign is not
	# the lesson being taught, so it does not fire the old "Stardust!" toast.
	if _campaign or not _running or GameState.flag(BEAT_FLAGS[Beat.COLLECT]):
		return
	HintChannel.mark_acted(_hint_key(Beat.COLLECT))
	_set_beat(Beat.COLLECT)
	# Say what was actually picked up: the old toast said "Stardust!" for the scrap that home grows
	# now (measured: "You got a Scrap!" then "Stardust! ..." in the old-tutorial timeline).
	var line := "Got it! Pick-ups go straight in your bag."
	var icon := "check"
	if kind == "stardust_shard":
		line = "Stardust! The plaza shops love the stuff."
		icon = "stardust"
	elif kind == "scrap":
		line = "Scrap! It's handy for fixing things."
		icon = _scrap_icon()
	HintChannel.request("intro_collected", line, icon, 0.9)
	if _beat == Beat.COLLECT:
		_advance()


func _on_scrap_changed(_new_amount: int, delta: int) -> void:
	if delta <= 0 or not _campaign or not _running or GameState.flag(BEAT_FLAGS[Beat.SCRAP]):
		return
	HintChannel.mark_acted(_hint_key(Beat.SCRAP))
	_set_beat(Beat.SCRAP)
	HintChannel.request("intro_scrapped", "Scrap! It mends rockets. Grab any you see.", _scrap_icon(), 0.9)
	if _beat == Beat.SCRAP:
		_advance()


func _on_decoration_placed(_planet_id: String, _instance_id: String, _item_id: String) -> void:
	if _campaign or not _running or GameState.flag(BEAT_FLAGS[Beat.PLACE]):
		return
	HintChannel.mark_acted(_hint_key(Beat.PLACE))
	_set_beat(Beat.PLACE)
	HintChannel.request("intro_placed", "Yours now. Walk up and press E to move it.", "check", 0.9)
	if _beat == Beat.PLACE:
		_advance()


## The pad opens a "cutscene" modal the moment you press Fly on it (its destination card). Doing
## that from beside the rocket is looking at it, whatever the facing test thought.
func _on_modal_opened(modal_name: String) -> void:
	if modal_name != "cutscene" or not _campaign or not _running or _crashing:
		return
	if GameState.flag(BEAT_FLAGS[Beat.ROCKET]) or not GameState.flag(FLAG_GREETED):
		return
	var p := _find_player()
	var r := _find_rocket()
	if p != null and r != null and p.global_position.distance_to(r.global_position) <= ROCKET_LOOK_DIST:
		_rocket_seen()


## Boarding the rocket ends the intro. The scene is about to change, so the celebration is queued
## for the arrival (see _complete_fly_on_arrival) rather than toasted into a fade-out.
func _on_leave_requested(_planet_id: String) -> void:
	if not _running:
		return
	HintChannel.mark_acted(_hint_key(Beat.FLY))
	HintChannel.mark_acted("rocket_pad")
	if _campaign:
		_set_beat(Beat.ROCKET, true)
	_running = false


## The first favour the player ever accepts: tell them where they can read it back.
func _on_favor_accepted(_favor_id: String) -> void:
	HintChannel.request("journal_intro", "Press P, then Favours, to see what you promised.", "check", 2.6)


# ============================================================================= the radio call
func _play_greeting() -> void:
	if _greeting:
		return
	_greeting = true
	_run_greeting()


func _run_greeting() -> void:
	var runner := DialogueRunner.get_or_create(self)
	var player := _find_player()
	if runner == null or player == null or runner.is_active():
		# No box (or somebody else is talking): try again next frame rather than losing the intro.
		_greeting = false
		_time = GREET_DELAY - 0.5
		return
	# The id carries the voice: "mayor_orbit_radio" -> NpcData "mayor_orbit" -> the shared doot
	# (radio_speaker.gd resolve_voice). Only the shown name is Professor Comet's.
	var radio := RadioSpeaker.make("mayor_orbit_radio", "%s (radio)" % Journal.npc_name("mayor_orbit"),
		"elder", PROFESSOR_ACCENT)
	if _campaign:
		_hang_campaign_radio(radio, player)
	else:
		player.add_child(radio)
		# Just in front of the astronaut's chest. CameraRig.focus_on swings to a side-on two-shot and
		# parks its pivot near this point, so a small offset frames the astronaut listening; anything
		# further ahead pushes them out of frame entirely (measured: 1.0 m forward lost them completely).
		radio.position = Vector3(0.0, 0.30, -0.45)
	AudioManager.play_sfx("ui_open", -8.0)
	runner.begin(radio, player)
	if _campaign:
		await _campaign_call(runner, radio)
	else:
		await _legacy_call(runner, radio)
	runner.finish()
	if is_instance_valid(radio):
		radio.queue_free()
	GameState.set_flag(FLAG_GREETED)
	_greeting = false
	if player.has_method("play_emote"):
		player.call("play_emote", "wave")
	_advance()


## WHERE THE CAMPAIGN CALL'S RADIO HANGS - which decides where the camera goes. CameraRig.focus_on
## turns the heading 85% of the way to side-on ACROSS the astronaut-to-speaker line, and
## DialogueRunner throws its focus point FOCUS_REACH (2.6x) past the speaker. With the radio 0.45 m in
## front of the chest, as the old tutorial has it, that is a 76 deg swing: the critic measured it 0.9 s
## after the crash handed control back at up to 5.2 deg and 1.0 m a frame, coming to rest on the FLY
## gateway's post, which then filled the frame for all eight boxes. Hung out to the SIDE instead -
## square to the camera heading, on the rocket's side - the side-on heading IS the current heading:
## no swing, only the rig's push-in and its pivot sliding toward the rocket, which brings the bruised
## rocket into the two-shot the Professor is talking about. Measured on the same run shape: the
## opening push-in now peaks at 1.04 deg and 0.23 m a frame. The 1.43 deg/frame FOV step that remains
## is DialogueRunner's own 45 -> 30 deg push-in, the same in every conversation. Parented to the world,
## not the astronaut: DialogueRunner turns the astronaut to face the voice, and a child would swing
## round with that turn and drag the focus point - and the camera - behind them.
func _hang_campaign_radio(radio: Node3D, player: Node3D) -> void:
	var host := player.get_parent()
	if host != null:
		host.add_child(radio)
	else:
		add_child(radio)
	var up := player.global_basis.y.normalized()
	if player is PlanetBody:
		up = (player as PlanetBody).up.normalized()
	var fwd := -player.global_basis.z
	var rig := get_node_or_null("/root/World/CameraRig")
	if rig != null and rig.has_method("get_camera_forward"):
		fwd = rig.call("get_camera_forward") as Vector3
	fwd = (fwd - up * fwd.dot(up)).normalized()
	var side := fwd.cross(up).normalized()
	var r := _find_rocket()
	if r != null and (r.global_position - player.global_position).dot(side) < 0.0:
		side = -side
	radio.global_position = player.global_position + side * RADIO_SIDE_M + up * 0.30


## The campaign's call, straight after the crash: he saw it, he is relieved, and he says what to
## do in the order the beats ask for it. Each string is ONE box; "\n" gives a box its second line
## (<= 60 characters a line, STYLE_GUIDE "Writing").
func _campaign_call(runner: DialogueRunner, radio: Node3D) -> void:
	await runner.say(radio, [
		"Hello? Is this thing on? Oh! Professor Comet here.\nAre you all right down there?",
		"Oh, thank the stars. I saw it all on my scope.\nWhat a tumble! Quite the landing, too.",
	])
	var solo: int = await runner.ask(radio, "Shall I talk you through it?", ["Yes, please", "I'll manage"])
	if solo == 1:
		await runner.say(radio, [
			"Splendid. I'll keep my scope on you.\nShout if the sky misbehaves.",
		])
		_skip_all()
		return
	await runner.say(radio, [
		"First, have a little look around.\nYou've landed somewhere rather nice.",
		"That rock knocked scrap all over the place.\nPick it up. Scrap mends things.",
		"Then check your rocket. I'm afraid she's badly\nbruised. She'll only reach the nearest worlds.",
		"%s, Zorp and Bolt are a short hop.\nFly over and ask for help. Folk are kind here." % Journal.planet_name("hub"),
		"I'll keep my scope on you. Off you go!",
	])


## The old tutorial's call, for old saves and non-campaign timelines. Same box count as it always
## had (2, a choice, 5) so the timelines that tap through it still line up; the words are a
## sky-watcher's now, not a mayor's.
func _legacy_call(runner: DialogueRunner, radio: Node3D) -> void:
	await runner.say(radio, [
		"Hello? Is this thing on? Oh! Professor Comet here.",
		"You must be our new neighbour. Welcome, welcome!",
	])
	var known: int = await runner.ask(radio, "Settling in?", ["Show me around", "I know my way about"])
	if known == 1:
		await runner.say(radio, [
			"Ha! An old hand. Off you go, then.",
			"Shout if the sky misbehaves.",
		])
		_skip_all()
		return
	await runner.say(radio, [
		"Your dome is a short walk away. White, with a\nmailbox. Its door tucks the day away and saves it.",
		"Your bag holds three bits of furniture already.\nPut them wherever pleases you. Nobody will tut.",
		"When you get restless, take the rocket.\nZorp and Bolt live out on the other worlds.",
		"I watch the sky from %s. Telescope,\nnotebook, and a biscuit I keep mislaying." % Journal.planet_name("hub"),
		"Right. Off you go — check that mailbox, I sent\nsomething. Have a wander on the way.",
	])


## "I know my way about" / "I'll manage": everything is ticked off, quietly, and no hint ever fires.
func _skip_all() -> void:
	for b: int in _order():
		_set_beat(b, true)


# ============================================================================= helpers
func _find_player() -> Node3D:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player


## The parked RocketModel on /root/World/Rocket (rocket_pad.gd's public `rocket`), or null.
func _find_rocket() -> Node3D:
	var pad := get_node_or_null("/root/World/Rocket")
	if pad == null:
		return null
	return pad.get("rocket") as Node3D
