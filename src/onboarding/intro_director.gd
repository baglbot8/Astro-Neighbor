class_name IntroDirector
extends Node
## The first ten minutes. Spawned by `world.gd` as /root/World/Onboarding on every planet load; it
## works out for itself whether there is anything to do.
##
## THE SHAPE
##   beat 0  GREET    a radio call from Mayor Orbit, ~3 s after you land on your own planet.
##                    Says the dome is yours and saves the game, that there are three bits of
##                    furniture in your bag, and that the neighbours are on the other worlds.
##                    Offers "I know my way about" for anyone replaying — that skips the whole thing.
##   beat 1  MOVE     walk MOVE_DIST metres.            -> "That's the way. Hold Shift to run."
##   beat 2  COLLECT  pick up any collectible.          -> "Stardust! The plaza shops take it."
##   beat 3  PLACE    place a decoration.               -> "It is yours. Press E on it to pick it up."
##   beat 4  FLY      board the rocket and land somewhere new.
##                    Completed on ARRIVAL (this node is destroyed by the scene change), so the
##                    welcome toast lands on the new planet where it means something.
##
## NOTHING IS GATED. Every beat is a nudge through `HintChannel`, never a lock: a player who ignores
## the mayor can walk off, fly away, and the beats simply tick themselves off behind them. Each beat
## has its own flag in `GameState.flags`, so it survives save/load and can never replay. A beat the
## player has already done (shards in the bag, decorations on the ground, a planet behind them) is
## retired silently at load rather than being demanded again.
##
## Flags: intro_greeted, intro_beat_move, intro_beat_collect, intro_beat_place, intro_beat_fly,
##        intro_done.
##
## COMMAND LINE (Director timelines)
##   --intro      run the intro even though a Director timeline is driving (opt-in, see below)
##   --no-intro   never run it
## The intro freezes the player for a conversation, which would break every existing timeline that
## presses move_forward at t=0.5. So under a Director it is OFF unless the timeline asks for it with
## `--intro`. Without a Director (i.e. a human, and tools/check.sh) it is ON.

enum Beat { GREET, MOVE, COLLECT, PLACE, FLY, DONE }

const FLAG_DONE := "intro_done"
const FLAG_GREETED := "intro_greeted"
const BEAT_FLAGS := {
	Beat.MOVE: "intro_beat_move",
	Beat.COLLECT: "intro_beat_collect",
	Beat.PLACE: "intro_beat_place",
	Beat.FLY: "intro_beat_fly",
}

## Seconds after the world loads before the radio crackles: the arrival banner has had its moment
## and SceneRouter's fade-in is done.
const GREET_DELAY := 3.0
## Metres of walking that count as "you have got the hang of this".
const MOVE_DIST := 7.0
## A single frame's movement larger than this is a teleport / spawn snap, not walking.
const MOVE_STEP_MAX := 1.5
## How long each beat waits before offering its hint, so the player gets to work it out first.
const HINT_AFTER_GREET := 6.0
const HINT_AFTER_BEAT := 2.0

const MAYOR_ACCENT := Color("#c9a15c")

## Current beat (a Beat value; typed int so untyped loop variables never need an enum cast).
var _beat: int = Beat.DONE
var _running := false
var _time := 0.0
var _beat_time := 0.0
var _hinted := false
var _greeting := false
var _player: Node3D
var _last_pos := Vector3.ZERO
var _walked := 0.0


func _ready() -> void:
	HintChannel.get_or_create()
	# Fires whatever the intro is doing: the first favour ever accepted should say where to review it.
	EventBus.favor_accepted.connect(_on_favor_accepted)
	EventBus.collectible_picked.connect(_on_collectible_picked)
	EventBus.decoration_placed.connect(_on_decoration_placed)
	EventBus.planet_leave_requested.connect(_on_leave_requested)

	if not _intro_allowed():
		return
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


func _intro_allowed() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.has("--no-intro"):
		return false
	if Director.is_active() and not args.has("--intro"):
		return false
	return true


# ============================================================================= beat bookkeeping
## Marks beats the player has demonstrably already done, so we never ask for something twice.
## Runs on every load, which is what makes the intro safe to resume from a save.
func _retire_beats_already_done() -> void:
	# Landed here from somewhere else: they can already fly, and they have walked.
	if GameState.previous_planet_id != "":
		_set_beat(Beat.MOVE, true)
		if GameState.current_planet_id != GameState.previous_planet_id:
			_complete_fly_on_arrival()
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
	HintChannel.request("intro_flew", "You flew! %s is all yours to poke about." % where, "check", 1.2)
	HintChannel.request("intro_talk", "Stand by a neighbour and press E to say hello.", "heart", 3.0)
	# Flying is the last beat. A player who reached another world without picking up a shard or
	# placing anything has plainly got the idea, so the rest is retired rather than nagged for.
	_skip_all()


func _first_unfinished() -> int:
	if not GameState.flag(FLAG_GREETED):
		return Beat.GREET
	for b: int in [Beat.MOVE, Beat.COLLECT, Beat.PLACE, Beat.FLY]:
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
	if _beat == Beat.DONE:
		_finish()


func _finish() -> void:
	_running = false
	if GameState.flag(FLAG_DONE):
		return
	GameState.set_flag(FLAG_DONE)


# ============================================================================= per-frame
func _process(delta: float) -> void:
	if not _running or _greeting:
		return
	_time += delta
	_beat_time += delta
	match _beat:
		Beat.GREET:
			_tick_greet()
		Beat.MOVE:
			_tick_move(delta)
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
		HintChannel.request("intro_moved", "That's the way. Hold Shift to run.", "check")
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
		Beat.FLY: return "intro_fly"
	return ""


func _hint_text(b: int) -> String:
	match b:
		Beat.MOVE: return "Have a wander — WASD walks, Shift runs."
		Beat.COLLECT: return "Yellow shards are Stardust. Press E to grab one."
		Beat.PLACE: return "Press Tab to open your bag and place something."
		Beat.FLY: return "Zorp and Bolt live out there. Take the rocket."
	return ""


func _hint_icon(b: int) -> String:
	match b:
		Beat.COLLECT: return "stardust_shard"
		Beat.PLACE: return "deco_moon_lamp"
	return "star"


# ============================================================================= world events
func _on_collectible_picked(_kind: String, _world_pos: Vector3) -> void:
	if not _running or GameState.flag(BEAT_FLAGS[Beat.COLLECT]):
		return
	HintChannel.mark_acted(_hint_key(Beat.COLLECT))
	_set_beat(Beat.COLLECT)
	HintChannel.request("intro_collected", "Stardust! The plaza shops love the stuff.", "stardust", 0.9)
	if _beat == Beat.COLLECT:
		_advance()


func _on_decoration_placed(_planet_id: String, _instance_id: String, _item_id: String) -> void:
	if not _running or GameState.flag(BEAT_FLAGS[Beat.PLACE]):
		return
	HintChannel.mark_acted(_hint_key(Beat.PLACE))
	_set_beat(Beat.PLACE)
	HintChannel.request("intro_placed", "Yours now. Walk up and press E to move it.", "check", 0.9)
	if _beat == Beat.PLACE:
		_advance()


## Boarding the rocket ends the intro. The scene is about to change, so the celebration is queued
## for the arrival (see _complete_fly_on_arrival) rather than toasted into a fade-out.
func _on_leave_requested(_planet_id: String) -> void:
	if not _running:
		return
	HintChannel.mark_acted(_hint_key(Beat.FLY))
	HintChannel.mark_acted("rocket_pad")
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
	var radio := RadioSpeaker.make("mayor_orbit_radio", "Mayor Orbit (radio)", "elder", MAYOR_ACCENT)
	player.add_child(radio)
	# Just in front of the astronaut's chest. CameraRig.focus_on swings to a side-on two-shot and
	# parks its pivot near this point, so a small offset frames the astronaut listening; anything
	# further ahead pushes them out of frame entirely (measured: 1.0 m forward lost them completely).
	radio.position = Vector3(0.0, 0.30, -0.45)
	AudioManager.play_sfx("ui_open", -8.0)
	runner.begin(radio, player)

	# Each string is ONE box (DialogueBox advances between array entries); "\n" gives a box its
	# second line. Seven boxes including the choice, per docs/STYLE_GUIDE.md "Writing".
	await runner.say(radio, [
		"Ahoy? Ahoy! Mayor Orbit here, on the radio.",
		"You must be our new neighbour. Welcome, welcome!",
	])
	var known: int = await runner.ask(radio, "Settling in?", ["Show me around", "I know my way about"])
	if known == 1:
		await runner.say(radio, [
			"Ha! An old hand. Off you go, then.",
			"Shout if the sky misbehaves.",
		])
		_skip_all()
	else:
		await runner.say(radio, [
			"Your dome is a short walk away. White, with a\nmailbox. Its door tucks the day away and saves it.",
			"Your bag holds three bits of furniture already.\nPut them wherever pleases you. Nobody will tut.",
			"When you get restless, take the rocket.\nZorp and Bolt live out on the other worlds.",
			"I am at the Town Hall on Starport Plaza.\nThe kettle is decorative. The bench is not.",
			"Right. Off you go — check that mailbox, I sent\nsomething. Have a wander on the way.",
		])
	runner.finish()
	if is_instance_valid(radio):
		radio.queue_free()
	GameState.set_flag(FLAG_GREETED)
	_greeting = false
	if player.has_method("play_emote"):
		player.call("play_emote", "wave")
	_advance()


## "I know my way about": everything is ticked off, quietly, and no hint ever fires.
func _skip_all() -> void:
	for b: int in [Beat.MOVE, Beat.COLLECT, Beat.PLACE, Beat.FLY]:
		_set_beat(b, true)


# ============================================================================= helpers
func _find_player() -> Node3D:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player
