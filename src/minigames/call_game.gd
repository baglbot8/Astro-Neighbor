extends Node3D
## CALL AND RESPONSE - the fifth mini-game: a Simon says between the four things a body can do
## (docs/CORE_LOOP.md "More mini-games, one per neighbour", item 5; the user, 2026-09-13: *"we can make
## the emote game more of a simon says? between Use, Jump, Fly and Emote?"*). It is Vela's game, but it
## runs with no neighbour too, on the same contract as every other kind: read minigame_system.gd's
## header first; catch_game.gd and ring_game.gd are the shipped games this file is shaped like.
##
## You stand in a ring on the ground near the neighbour. They CALL a pattern one move at a time: the
## move's symbol pops on a small card under the progress pill, its own note plays, and the neighbour
## acts it out where their body can (a hop for Jump, a wave for Emote). Then you ANSWER with the real
## controls, in order. Round 1 is two moves and each round adds one. A wrong move plays a soft "not
## quite" and the whole call plays again from its first move. No timer anywhere; nothing can be failed.
##
## ============================================================================== CONFIG (all optional)
##   "count": 3             rounds. Round i (from 0) is 2 + i moves long. Clamped to COUNT_RANGE.
##   "done": 1              rounds already answered: a resumed game starts at round done + 1.
##   "npc": "vela"          the caller. Without one the ring still works, with nobody standing at it
##                          (the dev menu's Play row sends only "owner", "count" and "flavour").
##   "center_dir": [x,y,z]  planet-local direction of the ring's centre, TRUSTED as given: a host that
##                          hand-picks a spot owns it, and a spot that breaks a WHERE THE RING GOES rule
##                          only pushes a warning naming the rule.
##   "ring_radius_m": 2.0   clamped to RING_RADIUS_RANGE, 1.2-2.0 (a bigger ring has no room on Grig).
##   "seed": 12345          fixes every round's pattern and where the spot search starts. Default:
##                          hashed from the owner and the planet, so one save always gets the same game.
##   "title": "..."         the progress pill's line. Default "Copy Vela's signal" ("Copy the signal").
##   "flavour": "spark"     the ring's colours, from catch_game.gd's FLAVOURS (one table for every game,
##                          read the way ring_game.gd reads it). Unknown -> "bolt" with a warning.
##
## ============================================================================== THE FOUR MOVES
## Read from the real input and the astronaut's real state on every PHYSICS TICK, after the astronaut's
## own step (`process_physics_priority`), so this file sees the same button and the same floor that
## player.gd acted on in that tick, and never keeps a clock of its own:
##   Use    "interact" pressed.
##   Emote  "emote" pressed. It counts even when the astronaut cannot emote right then (player.gd only
##          emotes on the floor): the slot fills and the note plays on the press, so it never looks
##          ignored.
##   Jump   a TAP of the Fly button ("boost" or "jump": Space, or Fly on the phone) - let go before
##          Player.BOOST_GROUND_DELAY - that made its OWN hop (A JUMP IS ITS OWN HOP, below).
##   Fly    a HOLD past BOOST_GROUND_DELAY that lit the thruster (Player.is_boosting()), or a press that
##          started in the air and lit it (up there player.gd lights it at once).
## The tap/hold split is timed on the press, not read off is_boosting() alone: a tap's own hop lifts the
## feet within ~0.08 s and a press still held then lights the thruster for a few ticks (player.gd drops
## the ground delay once airborne), which is how round 1 called a 0.10 s tap Fly 14 times out of 14.
## The hold is counted in ticks exactly as player.gd's `_boost_hold` counts it. Presses wait in one queue
## in the order they happened and each is judged only after the one before it, so "hold Fly, tap Emote"
## is judged Fly, then Emote.
##
## ============================================================================== A JUMP IS ITS OWN HOP
## Round 2 timed Jump from the raw button alone. MEASURED by its critic: two Jump taps 0.35 s apart or
## closer read Jump, Fly (the second press starts in the air, where any press lights the thruster), 28%
## of story games hold a Jump, Jump pair, and an F-key tap (boost only, no hop) read as Jump. The lead's
## rule: a Jump needs the feet on the ground; while the astronaut is in the air and the expected move is
## Jump a press is IGNORED, not wrong, and the card says "Land first, then tap Fly"; when the expected
## move is Fly it counts as Fly; a press that makes no hop never reads as Jump.
## FIX ROUND 1 MEASURED WRONG, both ways (its critic, touch and keyboard). It called a press "on the
## ground" when the feet had been up no longer than Player.COYOTE_TIME and took any height as the hop:
##   * a second tap 0.12-0.17 s after a Jump tap (0.28-0.37 m up, jet lit) re-used the first tap's hop
##     and counted a second Jump, 7 runs of 9;
##   * a tap 0.06 m above the floor said "Land first", and then player.gd's jump BUFFER (a jump pressed
##     up to Player.JUMP_BUFFER before landing fires on touchdown) hopped from the floor, uncounted, 4 of 4.
## So a Jump is matched to a hop, never to a height. Every stretch in the air that rises HOP_MIN_M is one
## hop, stamped with the tick its feet left the floor. A tap claims the first unclaimed hop that left the
## floor AFTER the tap went down and within `_hop_window_ticks` of it - the whole time player.gd can take
## to act on that press: JUMP_BUFFER to find the floor, JUMP_ANTICIPATION to crouch, and one tick for
## its float count. Nothing here is tuned; each case of the lead's rule falls out of that one match:
##   * a tap on the floor is a Jump the tick its hop is seen (about 0.1 s);
##   * a tap in the air is a Jump exactly when player.gd buffers it into a hop on landing;
##   * two taps during one hop are one Jump: the second finds no hop of its own;
##   * a tap that lifts nothing (F, or an emote holding the astronaut) is not a Jump.
## What a press that is not a Jump gets:
##   * from the air while Jump is expected: ignored, and "Land first" - at the press when the feet are
##     too high to land inside the buffer (`_may_land_in_buffer`), else once its window has passed;
##   * from the air while anything else is expected: Fly the tick the thruster lights (right when Fly is
##     expected, wrong otherwise), or nothing with an empty jet;
##   * any press that cannot count - an empty jet, or the astronaut busy with an emote (which blocks both
##     the jump and the thruster in player.gd) - a line on the card and nothing else. No sound and no
##     wobble: those mean "wrong", and this is not.
## MEASURED (Compatibility, Vela, TouchControls' real routing and real key events; the truth is player.gd's
## own jump launches, read per tick): [Jump, Jump] taps 0.05-0.60 s apart counted exactly the hops made in
## 46 of 46 runs on touch and 46 of 46 on the keyboard at 60 fps, and 23 of 23 on touch at 30 fps - 75
## second taps with no hop of their own ignored with the cue, 8 buffered into a hop and counted. Mashing
## at 0.10-0.35 s through [Jump, Jump, Jump]: 16 of 16 runs counted exactly the hops made.
##
## ============================================================================== PATTERNS
## Seeded from the base seed and the round index alone, never from anything live, so "done": N rebuilds
## exactly the round a fresh game would reach. Every adjacent pair is allowed except three, each a move
## the body cannot do straight after the one before it:
##   Fly -> Jump    still coming down. Brief rule 4 offers "not accepted until you land" or "patterns
##                  avoid it"; this file does both: patterns avoid it, and the land-first rule above is
##                  the net for Jump, Jump, which stays in.
##   Emote -> Jump  player.gd blocks the jump AND the thruster for the whole emote (wave 1.3 s, happy
##   Emote -> Fly   1.5 s, dance 2.8 s: AstronautModel.EMOTE_DURATIONS).
## An emote can still be playing a move or two later ([Emote, Use, Jump]); that press says "Let your
## emote finish" on the card instead of going silent. The cost of the three bans, MEASURED over 2000
## story games (rounds of 2, 3 and 4 moves): Use 31% and Emote 31% of moves, Fly 22%, Jump 16%, and a
## Jump, Jump pair in 22.8% of games.
##
## ============================================================================== WHERE THE RING GOES
## Every rule is checked on the ring's whole FOOTPRINT - the disc a move counts in, ring_radius_m +
## EXIT_HYSTERESIS_M - and from the ground up to Player.BOOST_MAX_HEIGHT, because moves count in the
## air above it too:
##   1. No Interactable reaches it: the nearest point of that column is further than the thing's own
##      `reach` + REACH_MARGIN_M from every Interactable in the tree, enabled or not. This is the rule
##      that keeps Use from starting a talk or a flight, and it covers every kind at once: neighbours
##      (2.2), the rocket pad (4.2 from above its deck), doors (3.0), pickups, benches, decorations.
##      ROUND 2 MEASURED WRONG: it kept 3.5 m from the pad's centre, inside the pad's 4.2 m reach, and a
##      real touch Use in the ring opened the rocket's "Where to?" picker (bolt seed 1006, zorp 1018).
##   2. Every neighbour's live position TALK_REACH + NEIGHBOUR_GAP_EXTRA_M from the ring's edge, every
##      building and the pad BUILDING_GAP_M (brief rule 1, kept as written). A neighbour who is not the
##      caller keeps walking (home_dir + wander_radius_m, NPC._pick_wander_target), so the footprint
##      also keeps TALK_REACH + REACH_MARGIN_M clear of that whole walk whenever the world has room;
##      only a world without room falls back to where they stand. MEASURED on a Hub dev start before
##      this: Pip walked to 0.25 m from the footprint, inside talk reach of its edge for 47 s of 90.
##   3. No prop on it: Planet.nearest_prop_distance() from the centre clears the footprint.
##   4. Flat and dry: the ground under the footprint stays within FLAT_TOLERANCE_M of the centre's
##      height (one of Grig's terrace risers is 0.47 m) and above the water line.
## Round 2 handed only the centre to find_free_dir_near with 0.9 m of clearance, so the disc landed on
## a bush and a Scrap on a hub dev start. Candidates here are rings of directions around the anchor
## (the neighbour's home, or a seeded spot when there is no neighbour), nearest first. The first clear
## one with a sight line to the caller wins; a clear one without sight is kept only when nothing within
## SIGHT_EXTRA_M further out has one. A world with no clear spot at all gets the least-blocked
## candidate, so the game always starts.
##
## The ring and its glow are built flat and then HUG THE GROUND: every vertex moves to the terrain under
## it. A flat ring on a round world floats r^2 / 2R at its rim before any terrain does (0.21 m on Grig),
## and round 2's flat ring floated 0.53 m on a Bolt dev start.
##
## ============================================================================== THE CARD
## One small card under the progress pill: [the called symbol] [what to do] [one slot per move]. A fixed
## spot on the screen, not a sign over the neighbour, because nothing turns the camera toward them (it
## turns when the player drags it): the round-2 critic found Vela off-screen in 4 of 4 approaches, so the
## card has to carry the whole call with the sound off.
## ROUND 2 MEASURED WRONG: a 226 px tall panel with the pill style's 400 px corners clipped "Round N -
## watch!", let "Not quite - watch again" spill outside, pushed its dots out of the bottom and covered
## the astronaut's head in every call frame. The card now:
##   * is the shared theme's "Toast" card (22 px corners, the toasts' fill, edge and shadow) with its
##     padding tightened, and the phone's type sizes from MobileUI.apply_theme, like the HUD's panels;
##   * is one row, CARD_TOP_* under the pill, ending above the astronaut's head (measured in the real
##     game scene: the builder report), and a call's first move waits until the astronaut's feet are
##     down, so no call plays over an astronaut still floating down from a Fly;
##   * sizes its text column once, to the widest line it will ever show, so no line clips and the card
##     keeps its width from one call step to the next;
##   * keys its wording to the device (MobileUI): "Jump: tap Fly" on a phone, "Jump: tap Space" on a
##     keyboard, with Use routed through MobileUI.interact_hint.
##
## ============================================================================== THE NEIGHBOUR
## wander_enabled(false) while the game runs, and back on in outro(). On every frame they are NOT
## talking and no modal is open, they turn toward the ring (`_turn_npc_to_ring`). ROUND 2 MEASURED
## WRONG: it turned them on every frame, so a talk mid-game fought the dialogue runner's face target and
## Vela spoke in profile, 49.5 deg off it (0.0 deg with the game off). Its in-place turn also fought
## NPC._tick_idle's look-at whenever the astronaut stood within 5 m outside the ring, leaving Vela 53.7
## deg off the ring and facing neither way; the turn is now written from this file's own copy.
##
## ============================================================================== PHONE AND HEAT
## docs/OPEN_ISSUES.md 44/47. The world side is one static ring built once: a Node3D and 2 MeshInstance3D
## (the band, the glow) = 2 draw calls, one shared body material. The card is 9 Controls plus 2 per slot
## that redraw only when something changes (a call step, a filled slot, a cue); the slots draw plain
## filled circles because each antialiased arc is a draw call of its own. Per frame: one footprint test
## and one facing write. Per physics tick: four input reads and two or three reads of the astronaut
## (floor, height, thruster); one small record per press, none per tick. The spot search runs once, in
## setup(), cheapest test first.
## One AudioStreamPlayer plays one shipped blip at fixed pitches. MEASURED (tree paused, same camera,
## Compatibility, 1560x720, two runs each): +0.09-0.10 ms render CPU and +31 draw calls answering a
## 4-move round, +0.12-0.16 ms and +58 answering a 7-move one, +0.10-0.14 ms and +33 calling; Forward+
## +0.01-0.02 ms. Fix round 2 moved the reads to the physics tick and changed no drawing: the same probe
## A/B in one busier session gave +0.13-0.16 ms for this file and +0.13-0.17 ms for round 1's, answering
## 7 moves; `_physics_process` costs about 1.1 us a tick. setup() is mostly 2-5 ms and at
## most 24 ms across 140 seeded starts on seven worlds; the first start of a session adds ~70 ms of
## loading this script.

const NOTE_SFX := "ui_tick"
const NOTE_VOLUME_DB := -6.0
const WRONG_SFX := "ui_cancel"
const WRONG_VOLUME_DB := -6.0
const ROUND_SFX := "pickup"
const FINISH_SFX := "quest_complete"

enum Move { USE, JUMP, FLY, EMOTE }
const MOVE_NAMES: PackedStringArray = ["Use", "Jump", "Fly", "Emote"]
## One shipped blip at four fixed pitches - root, third, fifth, octave - and the SAME note for a move's
## call and its answer (brief rule 3).
const NOTE_PITCH: PackedFloat32Array = [1.0, 1.25, 1.5, 2.0]

const MIN_PATTERN_LEN := 2
const COUNT_RANGE := Vector2i(1, 6)
const DEFAULT_COUNT := 3
## MEASURED: at 2.0 m every seed on all seven worlds found a clear spot (20 per world, with and without a
## caller); at 2.5 m Grig found none in 4 of 10 starts and fell back after ~230 ms, at 3.5 m in 16 of 20
## starts on Grig and Bolt. Smaller rings fit everywhere a 2.0 m one does.
const RING_RADIUS_RANGE := Vector2(1.2, 2.0)
const DEFAULT_RING_RADIUS_M := 2.0
## Leaving the ring needs this much more than entering it, so a foot on the line cannot flicker the
## round between paused and running.
const EXIT_HYSTERESIS_M := 0.35

## WHERE THE RING GOES. Rule 1's neighbour and building gaps are the brief's own numbers.
const NEIGHBOUR_GAP_EXTRA_M := 0.5
const BUILDING_GAP_M := 3.5
const REACH_MARGIN_M := 0.5
const FLAT_TOLERANCE_M := 0.15
## The margin Planet._find_free_dir keeps above the water line.
const WATER_GAP_M := 0.18
## Arc length between two ground samples under the footprint. MEASURED: at 12 samples around the edge
## (1.2 m apart) a Zorp spot (no caller, seed 1004) passed while its band crossed a river channel -
## 30 of 360 band samples under water, the ground 0.42 m down, about 1 m of the rim.
const GROUND_SAMPLE_M := 0.25
const SEARCH_STEP_M := 0.75
## Arc length between two candidates on one search ring: close to the anchor, and further out. MEASURED
## on Grig (the most cluttered world): at 1.5 m spacing everywhere, 8 of 20 seeds stepped over the few
## clear pockets 5-6 m from Grig's home (2 of 69 candidates at 0.5 m spacing) and put the ring 19-22 m
## away with no sight of Grig.
const SEARCH_SPACING_NEAR_M := 0.5
const SEARCH_NEAR_M := 10.0
const SEARCH_SPACING_FAR_M := 1.5
const SEARCH_MAX_M := 24.0
const SIGHT_EXTRA_M := 3.0
## The glow sits this far above the ground it hugs; the band's tube is centred on the ground, as before.
const GLOW_LIFT_M := 0.03
const GLOW_GRID := 8

## At least 0.6 s per called move (brief rule 2); this is the ON part only.
const CALL_STEP_S := 0.65
## A blank beat after each called move, added to CALL_STEP_S rather than cut from it: without it two
## identical moves in a row are one unchanging frame with the sound off.
const CALL_GAP_S := 0.20
## A beat to enjoy "Nice!" before the next call. Not a timer that can fail anyone.
const ROUND_GAP_S := 0.9
## A JUMP IS ITS OWN HOP: a stretch in the air counts as a hop once the feet are this far up. A tap's cut
## hop peaks near 0.39 m and passes this within two ticks of leaving the floor (MEASURED: 0.12 m on the
## launch tick). Only a tap still waiting inside its hop window can take a hop.
const HOP_MIN_M := 0.10
const CUE_S := 1.6
## `_judge_fly_button`'s answers besides a Move.
const NOTHING := -1
const PENDING := -2

## Flavours are catch_game.gd's own table (one source of truth since 2026-09-13).
const FLAVOURS := preload("res://src/minigames/catch_game.gd").FLAVOURS
const DEFAULT_FLAVOUR := "bolt"

## THE CARD. Its top sits this far below the safe-area top; MinigameSystem hangs the pill at
## UI_EDGE_DESKTOP / UI_EDGE_MOBILE, so these leave the pill's own height and a gap.
const CARD_TOP_DESKTOP := 66.0
const CARD_TOP_MOBILE := 112.0
const CARD_PAD_V := 8.0
const CARD_PAD_H := 14.0
const DISC_R_DESKTOP := 28.0
const DISC_R_MOBILE := 34.0
const SLOT_R_DESKTOP := 14.0
const SLOT_R_MOBILE := 16.0
const SLOT_GAP := 8
const CARD_GAP := 14

const TEXT_WAIT := "Step into the ring"
const TEXT_WATCH := "Watch the signal"
const TEXT_AGAIN := "Not quite - watch again"
const TEXT_TURN := "Your turn"
const TEXT_COPY := "Copy the signal"
const TEXT_NICE := "Nice!"
const TEXT_BUSY := "Let your emote finish"
const TEXT_FUEL := "Wait for your jet to refill"

enum State { WAIT_FOR_RING, CALLING, ANSWERING, ROUND_GAP }

var _system: MinigameSystem
var _planet: Planet
var _player: Player
var _npc: NPC
var _flavour: String = DEFAULT_FLAVOUR
var _title: String = ""
var _total: int = 0
var _done: int = 0
var _ring_radius_m: float = DEFAULT_RING_RADIUS_M
var _center_dir: Vector3 = Vector3.UP
var _center_pos: Vector3 = Vector3.ZERO
var _base_seed: int = 0

var _state := State.WAIT_FOR_RING
var _round_index: int = 0
var _pattern: Array[int] = []
var _call_i: int = 0
var _call_timer: float = 0.0
## True while the current call step's symbol is ON; false during its blank beat.
var _call_showing := false
## True from the start of a call until the astronaut's feet are down and its first move shows.
var _call_waiting := false
var _current_call_move: int = -1
var _answer_i: int = 0
var _gap_timer: float = 0.0
var _in_ring_cached := false
## True from a wrong move until the replayed call ends, so the card keeps saying why it is calling again.
var _replaying := false

var _prev_use := false
var _prev_emote := false
var _prev_thrust := false
## Seconds the feet have been off the floor (0 on the floor), per frame: a call's first move waits for it.
var _air_t := 0.0

## One press waiting for its verdict (THE FOUR MOVES). Use and Emote are known the tick they go down; a
## Fly-button press (`move` NOTHING) is judged from the ticks after it.
class PendingInput:
	var move := NOTHING
	## The physics tick it went down, and whether the feet were off the floor after that tick's step.
	var tick := 0
	var in_air := false
	## Ticks seen held (the press tick is 1, as in player.gd's `_boost_hold`), and whether it is up again.
	var held_ticks := 0
	var let_go := false
	## The thruster seen lit while this press was held; `lit_late` only once held past BOOST_GROUND_DELAY.
	var lit := false
	var lit_late := false
	var cued := false

## Oldest first. Only the newest Fly-button press can still be down (`_fly_down`).
var _inputs: Array[PendingInput] = []
var _fly_down: PendingInput = null

## A JUMP IS ITS OWN HOP, per physics tick: `_tick` counts ticks since setup; `_air_from` is the first tick
## of the current stretch in the air (-1 on the floor) and `_air_hopped` whether that stretch is a hop;
## `_hop_count` counts hops, `_hop_from` is the newest hop's first tick in the air, and `_hop_claimed` the
## count of the newest hop a tap has taken.
var _tick := 0
var _air_from := -1
var _air_hopped := false
var _hop_count := 0
var _hop_from := -1
var _hop_claimed := 0
## Set in setup() from player.gd's own constants and the physics rate (A JUMP IS ITS OWN HOP): how many
## ticks after a press its hop may leave the floor, and the held ticks that make a press a hold.
var _hop_window_ticks := 11
var _hold_min_ticks := 11

var _cue_text := ""
var _cue_timer := 0.0

## THE NEIGHBOUR's facing as this file last wrote it, and whether that copy is still the body's.
var _npc_turn := Quaternion.IDENTITY
var _npc_turn_live := false

## QA only: the last move handed to `_try_answer`, right or wrong.
var _last_detected_move: int = -1

var _note_player: AudioStreamPlayer
var _ring_node: Node3D

## WHERE THE RING GOES, collected once per search.
var _reachables: Array[Dictionary] = []
var _npc_dirs: Array[Vector3] = []
var _block_dirs: Array[Vector3] = []
## Neighbours who keep walking while the game runs (everyone but the caller): {"home", "radius"}.
var _walkers: Array[Dictionary] = []

var _ui: CanvasLayer
var _panel: PanelContainer
var _disc: Control
## The card's small top line (what is happening) and its bigger second line (what to do).
var _hint_label: Label
var _call_label: Label
var _slots_row: HBoxContainer
var _slot_ctrls: Array[Control] = []
var _slot_moves: Array[int] = []
var _slots_built_for: int = -1


# ============================================================================= setup
func setup(system: MinigameSystem, config: Dictionary) -> String:
	_system = system
	var tree := get_tree()
	if tree == null:
		return "not in a scene tree"
	_planet = tree.get_first_node_in_group("planet") as Planet
	if _planet == null:
		return "no planet here"
	_player = tree.get_first_node_in_group("player") as Player
	if _player == null:
		return "no player here"

	_total = clampi(int(config.get("count", DEFAULT_COUNT)), COUNT_RANGE.x, COUNT_RANGE.y)
	_done = clampi(int(config.get("done", 0)), 0, _total)
	_ring_radius_m = clampf(float(config.get("ring_radius_m", DEFAULT_RING_RADIUS_M)),
		RING_RADIUS_RANGE.x, RING_RADIUS_RANGE.y)
	_flavour = str(config.get("flavour", DEFAULT_FLAVOUR))
	if not FLAVOURS.has(_flavour):
		push_warning("call_game: unknown flavour '%s', using '%s'" % [_flavour, DEFAULT_FLAVOUR])
		_flavour = DEFAULT_FLAVOUR

	var npc_id := str(config.get("npc", ""))
	if npc_id != "":
		for n: Node in tree.get_nodes_in_group("npc"):
			if n is NPC and (n as NPC).npc_id == npc_id:
				_npc = n as NPC
				break
		if _npc == null:
			push_warning("call_game: npc '%s' not found; running with no caller" % npc_id)

	_base_seed = int(config["seed"]) if config.has("seed") \
		else hash([str(config.get("owner", "")), _planet.data.id, _planet.data.seed, "call"])
	var rng := RandomNumberGenerator.new()
	rng.seed = _base_seed
	_center_dir = _pick_ring_center(config, rng)
	_center_pos = _planet.surface_point(_center_dir)

	_title = str(config.get("title", ""))
	if _title == "":
		var who := ""
		if _npc != null:
			who = _npc.display_name if _npc.display_name != "" else _npc.npc_id.capitalize()
		_title = "Copy %s's signal" % who if who != "" else "Copy the signal"

	_round_index = _done
	if _done < _total:
		_pattern = _make_pattern(_round_index)
	_build_ring_visual()
	_build_audio()
	_build_ui()
	if _npc != null:
		_npc.wander_enabled(false)

	# THE FOUR MOVES are read after the astronaut's own physics step: a higher number runs later, and
	# the astronaut keeps the default 0. The hop window is player.gd's buffer and crouch in ticks, plus
	# the tick its float buffer count can add; a hold is BOOST_GROUND_DELAY in ticks, as `_boost_hold`
	# reaches it.
	process_physics_priority = 1
	var tps := float(Engine.physics_ticks_per_second)
	_hop_window_ticks = int(ceil((Player.JUMP_BUFFER + Player.JUMP_ANTICIPATION) * tps)) + 1
	_hold_min_ticks = int(ceil(Player.BOOST_GROUND_DELAY * tps - 0.001))

	_system.report_progress(_done, _total)
	if _done >= _total:
		# Handed a finished game: report it and let the system tidy up, as catch and rings do. No
		# processing in between - `_process` would otherwise run once on an empty pattern.
		set_process(false)
		set_physics_process(false)
		_finish.call_deferred()
		return ""
	_state = State.WAIT_FOR_RING
	_apply_state_visuals()
	return ""


func title() -> String:
	return _title


## The ring while the astronaut is away from it; nothing once they stand in it.
func hint_direction() -> Vector3:
	return Vector3.INF if _in_ring_cached else _center_pos


## The one thing this game changes outside itself is the neighbour's wander flag.
func outro() -> void:
	if _npc != null and is_instance_valid(_npc):
		_npc.wander_enabled(true)


# ============================================================================= per-frame
func _process(delta: float) -> void:
	if not is_instance_valid(_planet) or not is_instance_valid(_player):
		return
	var modal := EventBus.is_modal_open()
	if _ui != null:
		_ui.visible = not modal
	if modal:
		_npc_turn_live = false
		return

	_air_t = 0.0 if _player.is_on_floor() else _air_t + delta
	_turn_npc_to_ring(delta)
	if _cue_timer > 0.0:
		_cue_timer -= delta
		if _cue_timer <= 0.0:
			_cue_text = ""
			_apply_state_visuals()

	_in_ring_cached = _compute_in_ring()
	match _state:
		State.WAIT_FOR_RING:
			if _in_ring_cached:
				_start_calling()
		State.CALLING:
			if not _in_ring_cached:
				_pause_to_wait()
			else:
				_tick_calling(delta)
		State.ANSWERING:
			# The answer itself is read per physics tick (`_physics_process`).
			if not _in_ring_cached:
				_pause_to_wait()
		State.ROUND_GAP:
			if not _in_ring_cached:
				_pause_to_wait()
			else:
				_gap_timer -= delta
				if _gap_timer <= 0.0:
					_start_calling()


## THE FOUR MOVES, once per physics tick and after the astronaut's own step (setup() sets the priority).
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_tick += 1
	_track_feet()
	# Edges against the tick before. They are taken while a modal is open too, so a key still held when
	# the modal closes (the E or Space that answered it) is not a fresh press - the seeding player.gd's
	# _on_modal_changed does for the same reason (OPEN_ISSUES 42).
	var use_raw := Input.is_action_pressed("interact")
	var emote_raw := Input.is_action_pressed("emote")
	var thrust_raw := Input.is_action_pressed("boost") or Input.is_action_pressed("jump")
	var use_just := use_raw and not _prev_use
	var emote_just := emote_raw and not _prev_emote
	var thrust_just := thrust_raw and not _prev_thrust
	_prev_use = use_raw
	_prev_emote = emote_raw
	_prev_thrust = thrust_raw
	# A lift is a lift wherever it happens, so a press let go while a modal was open is not left down.
	if _fly_down != null and not thrust_raw:
		_fly_down.let_go = true
	# A move counts only while answering, inside the ring (or above it) and with no modal open. A press
	# still held when the answer starts has no edge here, so it never counts.
	if _state != State.ANSWERING or not _in_ring_cached or EventBus.is_modal_open():
		return
	if thrust_just:
		_fly_down = _queue_input(NOTHING)
		_fly_down.in_air = not _player.is_on_floor()
		# The verdict waits for the hop window, but the cue need not when no hop can come: say it at once.
		if _fly_down.in_air and _inputs.size() == 1 and _expected_move() == Move.JUMP and not _may_land_in_buffer():
			_show_cue(_land_first_text())
	if _fly_down != null and not _fly_down.let_go:
		_fly_down.held_ticks += 1
		if _player.is_boosting():
			_fly_down.lit = true
			_fly_down.lit_late = _fly_down.lit_late or _fly_down.held_ticks >= _hold_min_ticks
	if use_just:
		_queue_input(Move.USE)
	if emote_just:
		_queue_input(Move.EMOTE)
	_judge_inputs()


## THE NEIGHBOUR. This file keeps its own copy of their facing, turns THAT toward the ring at
## NPC.FACE_TURN_SPEED, and writes it back every frame: `_process` runs after the physics step, so the
## rendered frame always shows this turn, never a tug of war with NPC._tick_idle's look-at (turning the
## body in place from both sides left them facing neither way when the astronaut stood beside them).
## While they talk, or a modal is open, nothing is written; the copy is re-read from the body after, so
## they turn back from wherever the dialogue left them instead of snapping.
func _turn_npc_to_ring(delta: float) -> void:
	if _npc == null or not is_instance_valid(_npc):
		return
	if _npc.is_talking():
		_npc_turn_live = false
		return
	var up := _npc.up
	var to := _center_pos - _npc.global_position
	to -= up * to.dot(up)
	if to.length_squared() < 0.0001:
		return
	if not _npc_turn_live:
		_npc_turn = _npc.global_transform.basis.orthonormalized().get_rotation_quaternion()
		_npc_turn_live = true
	var target := Basis.looking_at(to.normalized(), up).get_rotation_quaternion()
	_npc_turn = _npc_turn.slerp(target, clampf(NPC.FACE_TURN_SPEED * delta, 0.0, 1.0))
	_npc.global_basis = Basis(_npc_turn)


## Inside the ring or anywhere in the air above it: the astronaut's direction from the planet centre
## ignores height. Entering uses the plain radius, leaving needs EXIT_HYSTERESIS_M more.
func _compute_in_ring() -> bool:
	var d := _planet.surface_distance(_planet.dir_of(_player.global_position), _center_dir)
	return d <= _ring_radius_m + (EXIT_HYSTERESIS_M if _in_ring_cached else 0.0)


# ============================================================================= judging a press
## A JUMP IS ITS OWN HOP: the stretches the feet spend off the floor, one tick at a time. A stretch that
## rises HOP_MIN_M - a hop, or the thruster lifting from standing - is counted once; only a tap claims one,
## and only inside its own window.
func _track_feet() -> void:
	if _player.is_on_floor():
		_air_from = -1
		return
	if _air_from < 0:
		_air_from = _tick
		_air_hopped = false
	if not _air_hopped and _player.get_ground_height() >= HOP_MIN_M:
		_air_hopped = true
		_hop_count += 1
		_hop_from = _air_from


func _queue_input(move: int) -> PendingInput:
	var p := PendingInput.new()
	p.move = move
	p.tick = _tick
	_inputs.append(p)
	return p


## Answers the queue from its oldest press, stopping at the first one whose verdict still depends on
## ticks to come. A wrong answer restarts the call, which empties the queue.
func _judge_inputs() -> void:
	while not _inputs.is_empty() and _state == State.ANSWERING:
		var p: PendingInput = _inputs[0]
		var move := p.move if p.move >= 0 else _judge_fly_button(p)
		if move == PENDING:
			return
		_inputs.pop_front()
		if p == _fly_down:
			_fly_down = null
		if move >= 0:
			_try_answer(move)


## THE FOUR MOVES and A JUMP IS ITS OWN HOP for one Fly-button press: a Move, NOTHING (with any cue
## already shown) or PENDING. Called only for the oldest press, so `_expected_move()` is the move it answers.
func _judge_fly_button(p: PendingInput) -> int:
	var expected := _expected_move()
	if p.in_air and expected != Move.JUMP:
		# Up there player.gd lights the thruster at once: a Fly, right or wrong, or an empty jet.
		if p.lit:
			return Move.FLY
		if not p.let_go:
			return PENDING
		_show_cue(_why_no_thrust() if expected == Move.FLY else "")
		return NOTHING
	if p.held_ticks >= _hold_min_ticks:
		# A hold. From the air, while a Jump is expected, it can never be one: the lead's "ignored".
		if p.in_air:
			_show_cue(_land_first_text())
			return NOTHING
		if p.lit_late:
			return Move.FLY
		if not p.cued and (expected == Move.JUMP or expected == Move.FLY):
			# Held long enough and still dark: the astronaut is emoting, or the jet is empty.
			p.cued = true
			_show_cue(_why_no_thrust())
		return NOTHING if p.let_go else PENDING
	if not p.let_go:
		return PENDING
	# A tap. It is a Jump when a hop no earlier tap has taken left the floor after it, in its window.
	var last := p.tick + _hop_window_ticks
	if _hop_count > _hop_claimed and _hop_from > p.tick and _hop_from <= last:
		_hop_claimed = _hop_count
		return Move.JUMP
	# Not yet: the window is still open, or the feet left the floor inside it and are still rising.
	if _tick <= last or (_air_from > p.tick and _air_from <= last and not _air_hopped):
		return PENDING
	if expected == Move.JUMP or expected == Move.FLY:
		if _astronaut_busy():
			_show_cue(TEXT_BUSY)
		elif expected == Move.JUMP and (p.in_air or not _player.is_on_floor()):
			_show_cue(_land_first_text())
	return NOTHING


func _land_first_text() -> String:
	return "Land first, then %s" % _control_words(Move.JUMP)


## Whether the feet could touch the floor inside player.gd's jump buffer (and its float tick): falling at
## the speed they have under gravity alone - the thruster only ever slows a fall - onto ground up to
## FLAT_TOLERANCE_M higher than the ground under them now. Only the early cue uses it; a wrong "no" costs
## a cue that clears when the Jump counts, never a Jump.
func _may_land_in_buffer() -> bool:
	var t := Player.JUMP_BUFFER + 1.0 / float(Engine.physics_ticks_per_second)
	var v_down := maxf(-_player.velocity.dot(_player.up), 0.0)
	var reach := v_down * t + 0.5 * _player.gravity_strength * t * t + FLAT_TOLERANCE_M
	return _player.get_ground_height() <= reach


func _reset_inputs() -> void:
	_inputs.clear()
	_fly_down = null


func _expected_move() -> int:
	return _pattern[_answer_i] if _answer_i >= 0 and _answer_i < _pattern.size() else -1


## player.gd blocks the jump and the thruster while an emote plays; the model's state names it.
func _astronaut_busy() -> bool:
	var model := _player.get_model()
	return model != null and AstronautModel.get_emote_duration(model.get_state()) > 0.0


func _why_no_thrust() -> String:
	if _astronaut_busy():
		return TEXT_BUSY
	if _player.get_boost_fuel() <= Player.BOOST_RESTART_FUEL:
		return TEXT_FUEL
	return ""


func _show_cue(text: String) -> void:
	if text == "":
		return
	_cue_text = text
	_cue_timer = CUE_S
	_apply_state_visuals()


# ============================================================================= round flow
## The first called move waits for the astronaut's feet (THE CARD): a call that starts while they are
## still coming down from a Fly shows its first moves over an astronaut high on the screen, under the
## card. Waiting to land is not a timer; nothing is lost.
func _start_calling() -> void:
	if _pattern.is_empty():
		return
	_state = State.CALLING
	_call_i = 0
	_call_timer = 0.0
	_call_showing = false
	_call_waiting = true
	_current_call_move = -1
	_answer_i = 0
	_reset_inputs()
	_cue_text = ""
	_cue_timer = 0.0
	_ensure_slots(_pattern.size())
	_apply_state_visuals()


## ON for CALL_STEP_S, then a blank beat of CALL_GAP_S, per called move.
func _tick_calling(delta: float) -> void:
	if _call_waiting:
		if _air_t > Player.COYOTE_TIME:
			return
		_call_waiting = false
		_call_showing = true
		_show_call_move(_pattern[0])
		return
	_call_timer += delta
	if _call_showing:
		if _call_timer < CALL_STEP_S:
			return
		_call_timer -= CALL_STEP_S
		_call_showing = false
		_hide_call_move()
	else:
		if _call_timer < CALL_GAP_S:
			return
		_call_timer -= CALL_GAP_S
		_call_i += 1
		_redraw_slots()
		if _call_i >= _pattern.size():
			_start_answering()
		else:
			_call_showing = true
			_show_call_move(_pattern[_call_i])


func _start_answering() -> void:
	_state = State.ANSWERING
	_answer_i = 0
	_replaying = false
	_current_call_move = -1
	_reset_inputs()
	_apply_state_visuals()
	_redraw_slots()


## Walking out pauses the round; walking back in restarts its call from the first move.
func _pause_to_wait() -> void:
	_state = State.WAIT_FOR_RING
	_replaying = false
	_call_waiting = false
	_current_call_move = -1
	_reset_inputs()
	_cue_text = ""
	_cue_timer = 0.0
	_ensure_slots(_pattern.size())
	_apply_state_visuals()


## Right: its note, its slot, the next move (or the round). Wrong: a soft cue, a wobble, and the call
## again from its first move.
func _try_answer(move: int) -> void:
	if _state != State.ANSWERING or _answer_i < 0 or _answer_i >= _pattern.size():
		return
	_last_detected_move = move
	if move == _pattern[_answer_i]:
		_play_note(move)
		_slot_moves[_answer_i] = move
		if _answer_i < _slot_ctrls.size() and is_instance_valid(_slot_ctrls[_answer_i]):
			_slot_ctrls[_answer_i].queue_redraw()
			UIStyle.bump(_slot_ctrls[_answer_i], 1.35, 0.26)
		_answer_i += 1
		if _cue_text != "":
			_cue_text = ""
			_cue_timer = 0.0
			_apply_state_visuals()
		if _answer_i >= _pattern.size():
			_on_round_complete()
	else:
		AudioManager.play_sfx(WRONG_SFX, WRONG_VOLUME_DB)
		_replaying = true
		if _panel != null:
			UIStyle.wobble(_panel, 6.0, 0.4)
		_start_calling()


func _on_round_complete() -> void:
	_done += 1
	# Persist first, celebrate second (minigame_system.gd: completion never waits on `finished`).
	if is_instance_valid(_system):
		_system.report_progress(_done, _total)
	AudioManager.play_sfx(ROUND_SFX, -4.0)
	if _done >= _total:
		_finish()
		return
	EventBus.toast_requested.emit("Signal matched! (%d/%d)" % [_done, _total], "")
	_round_index += 1
	_pattern = _make_pattern(_round_index)
	_state = State.ROUND_GAP
	_gap_timer = ROUND_GAP_S
	_reset_inputs()
	_apply_state_visuals()


func _finish() -> void:
	AudioManager.play_sfx(FINISH_SFX, -3.0)
	if is_instance_valid(_system):
		_system.report_finished(true)


## Round i (from 0) is MIN_PATTERN_LEN + i moves, a pure function of the base seed and i - see PATTERNS.
func _make_pattern(round_index: int) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_base_seed, round_index])
	var pat: Array[int] = []
	var prev := -1
	for _i in MIN_PATTERN_LEN + round_index:
		var options: Array[int] = [Move.USE, Move.JUMP, Move.FLY, Move.EMOTE]
		if prev == Move.FLY:
			options.erase(Move.JUMP)
		if prev == Move.EMOTE:
			options.erase(Move.JUMP)
			options.erase(Move.FLY)
		var pick: int = options[rng.randi_range(0, options.size() - 1)]
		pat.append(pick)
		prev = pick
	return pat


# ============================================================================= calling a move
func _show_call_move(move: int) -> void:
	_current_call_move = move
	_apply_state_visuals()
	if _disc != null:
		UIStyle.bump(_disc, 1.18, CALL_STEP_S * 0.55)
	_play_note(move)
	if _npc != null and is_instance_valid(_npc):
		match move:
			# STYLE_GUIDE.md "Motion": happy is the hop.
			Move.JUMP:
				_npc.play_emote("happy")
			Move.EMOTE:
				_npc.play_emote("wave")
			_:
				pass  # Use and Fly: no gesture, so a quick pattern never stacks emotes on the neighbour.


func _hide_call_move() -> void:
	_current_call_move = -1
	_apply_state_visuals()


func _play_note(move: int) -> void:
	if _note_player == null or _note_player.stream == null:
		return
	_note_player.pitch_scale = NOTE_PITCH[move]
	_note_player.play()


## "Jump: tap Fly" on a phone, "Jump: tap Space" on a keyboard.
func _move_hint(move: int) -> String:
	return "%s: %s" % [MOVE_NAMES[move], _control_words(move)]


func _control_words(move: int) -> String:
	var phone := MobileUI.is_mobile()
	match move:
		Move.USE:
			return MobileUI.interact_hint(false)
		Move.JUMP:
			return "tap Fly" if phone else "tap Space"
		Move.FLY:
			return "hold Fly" if phone else "hold Space"
		_:
			return "tap Emote" if phone else "press C"


# ============================================================================= where the ring goes
## See WHERE THE RING GOES. Returns a planet-local direction and never fails.
func _pick_ring_center(config: Dictionary, rng: RandomNumberGenerator) -> Vector3:
	_collect_obstacles()
	var given := _dir_from(config.get("center_dir", null))
	if given != Vector3.ZERO:
		var why := str(_spot_check(given, true)["why"])
		if why != "":
			push_warning("call_game: center_dir %s is in the way of '%s'; using it as given" % [str(given), why])
		return given

	var anchor := _npc.home_dir.normalized() if _npc != null else _planet.random_surface_dir(rng, [], 8.0)
	var turn := rng.randf() * TAU
	var first := (_ring_radius_m + NPC.TALK_REACH + NEIGHBOUR_GAP_EXTRA_M) if _npc != null else 0.0
	# Pass 0 also keeps clear of every walking neighbour's whole walk; pass 1, only for a world with no
	# room for that, drops it (rule 2 still holds against where they stand now).
	for pass_i in 2:
		var avoid_walks := pass_i == 0
		if not avoid_walks and _walkers.is_empty():
			break
		var hidden := Vector3.ZERO
		var hidden_band := 0.0
		var band := first
		while band <= SEARCH_MAX_M:
			for v: Vector3 in _band_dirs(anchor, band, turn):
				if str(_spot_check(v, true, avoid_walks)["why"]) != "":
					continue
				if _npc == null or _has_line_of_sight(v):
					return v
				if hidden == Vector3.ZERO:
					hidden = v
					hidden_band = band
			if hidden != Vector3.ZERO and band - hidden_band >= SIGHT_EXTRA_M:
				return hidden
			band += SEARCH_STEP_M
		if hidden != Vector3.ZERO:
			return hidden

	# Nowhere clear: the least-blocked candidate, so the game still starts. A coarser sweep (one band in
	# four, far spacing) - every rule is scored in full here, and this only runs on a world with no room.
	push_warning("call_game: no clear ring spot on '%s'; using the least blocked one" % _planet.data.id)
	var best := anchor
	var best_miss := INF
	var band := first
	while band <= SEARCH_MAX_M:
		for v: Vector3 in _band_dirs(anchor, band, turn, SEARCH_SPACING_FAR_M):
			var miss := float(_spot_check(v, false)["miss"])
			if miss < best_miss:
				best_miss = miss
				best = v
		band += SEARCH_STEP_M * 4.0
	return best


static func _dir_from(raw: Variant) -> Vector3:
	var v := Vector3.ZERO
	if raw is Vector3:
		v = raw
	elif raw is Array and (raw as Array).size() == 3:
		var a: Array = raw
		v = Vector3(float(a[0]), float(a[1]), float(a[2]))
	return v.normalized() if v.length_squared() > 0.0001 else Vector3.ZERO


## The candidates `band` metres from `anchor`, SEARCH_SPACING_* apart (or `spacing_m`), from angle `turn`.
func _band_dirs(anchor: Vector3, band: float, turn: float, spacing_m: float = 0.0) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if band < 0.01:
		out.append(anchor)
		return out
	var xf := _planet.surface_transform(anchor)
	var spacing := spacing_m if spacing_m > 0.0 else (SEARCH_SPACING_NEAR_M if band <= SEARCH_NEAR_M else SEARCH_SPACING_FAR_M)
	var n := clampi(int(ceil(TAU * band / spacing)), 8, 128)
	var arc := band / _planet.radius
	for k in n:
		var a := turn + TAU * float(k) / float(n)
		var tangent := xf.basis.x * cos(a) + xf.basis.z * sin(a)
		out.append((anchor * cos(arc) + tangent * sin(arc)).normalized())
	return out


func _collect_obstacles() -> void:
	_reachables.clear()
	_npc_dirs.clear()
	_block_dirs.clear()
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.is_inside_tree():
			continue
		var parent_name := str(it.get_parent().name) if it.get_parent() != null else ""
		_reachables.append({"pos": it.global_position, "reach": it.reach, "name": "%s/%s" % [parent_name, it.name]})
	_walkers.clear()
	for n: Node in get_tree().get_nodes_in_group("npc"):
		if n is Node3D:
			_npc_dirs.append(_planet.dir_of((n as Node3D).global_position))
		if n is NPC and n != _npc:
			_walkers.append({"home": (n as NPC).home_dir.normalized(), "radius": (n as NPC).wander_radius_m})
	_block_dirs.append(_planet.data.pad_dir.normalized())
	for bid: String in _planet.data.buildings:
		var bd := _planet.building_dir(bid)
		if bd != Vector3.ZERO:
			_block_dirs.append(bd)


## Every WHERE THE RING GOES rule at `v`, cheapest first. `first_only`: stop at the first broken rule
## (the search); otherwise add up how far every rule is missed, in metres (the least-blocked fallback).
## `avoid_walks`: the walking-neighbour rule too. Returns {"why": the first broken rule or "", "miss": metres}.
func _spot_check(v: Vector3, first_only: bool, avoid_walks: bool = false) -> Dictionary:
	var why := ""
	var miss := 0.0
	var edge := _ring_radius_m + EXIT_HYSTERESIS_M
	for d: Vector3 in _npc_dirs:
		var short := _ring_radius_m + NPC.TALK_REACH + NEIGHBOUR_GAP_EXTRA_M - _planet.surface_distance(v, d)
		if short > 0.0:
			why = why if why != "" else "a neighbour"
			miss += short
			if first_only:
				return {"why": why, "miss": miss}
	if avoid_walks:
		for w: Dictionary in _walkers:
			var short1 := float(w["radius"]) + NPC.TALK_REACH + REACH_MARGIN_M + edge \
				- _planet.surface_distance(v, w["home"])
			if short1 > 0.0:
				why = why if why != "" else "a walking neighbour's walk"
				miss += short1
				if first_only:
					return {"why": why, "miss": miss}
	for d: Vector3 in _block_dirs:
		var short2 := _ring_radius_m + BUILDING_GAP_M - _planet.surface_distance(v, d)
		if short2 > 0.0:
			why = why if why != "" else "a building or the pad"
			miss += short2
			if first_only:
				return {"why": why, "miss": miss}
	var short3 := edge - _planet.nearest_prop_distance(v)
	if short3 > 0.0:
		why = why if why != "" else "a prop"
		miss += short3
		if first_only:
			return {"why": why, "miss": miss}
	var centre := _planet.surface_point(v)
	for it: Dictionary in _reachables:
		var short4 := REACH_MARGIN_M - _reach_gap(v, centre, it)
		if short4 > 0.0:
			why = why if why != "" else "the reach of %s" % str(it["name"])
			miss += short4
			if first_only:
				return {"why": why, "miss": miss}
	var short5 := _ground_unevenness(v) - FLAT_TOLERANCE_M
	if short5 > 0.0:
		why = why if why != "" else "uneven or wet ground"
		miss += short5
	return {"why": why, "miss": miss}


## How far the nearest point of the footprint column (edge radius, ground to Player.BOOST_MAX_HEIGHT)
## sits outside the Interactable's own reach. Negative: the astronaut could reach it from the ring.
func _reach_gap(v: Vector3, centre: Vector3, it: Dictionary) -> float:
	var pos: Vector3 = it["pos"]
	var reach := float(it["reach"])
	var edge := _ring_radius_m + EXIT_HYSTERESIS_M
	# Every column point lies within edge + ceiling (+ a metre of terrain) of the centre's ground point,
	# so a thing further than that plus its reach cannot touch the column at all.
	if centre.distance_to(pos) > edge + Player.BOOST_MAX_HEIGHT + 1.0 + reach + REACH_MARGIN_M:
		return INF
	var pdir := _planet.dir_of(pos)
	var foot := pdir if _planet.surface_distance(v, pdir) <= edge else _planet.step_dir(v, pdir, edge)
	var base := _planet.surface_point(foot)
	var up := _planet.up_at(base)
	var t := clampf((pos - base).dot(up), 0.0, Player.BOOST_MAX_HEIGHT)
	return pos.distance_to(base + up * t) - reach


## Worst height difference between the ground under the footprint and its centre, sampled every
## GROUND_SAMPLE_M around three circles (half the radius, the band, the footprint's edge); INF when any
## of it is at or under the water line.
func _ground_unevenness(v: Vector3) -> float:
	var hc := _planet.height_at(v)
	var water := _planet.water_radius()
	if water > 0.0 and hc < water + WATER_GAP_M:
		return INF
	var xf := _planet.surface_transform(v)
	var worst := 0.0
	for rad: float in [_ring_radius_m * 0.5, _ring_radius_m, _ring_radius_m + EXIT_HYSTERESIS_M]:
		var n := int(ceil(TAU * rad / GROUND_SAMPLE_M))
		var arc := rad / _planet.radius
		for k in n:
			var a := TAU * float(k) / float(n)
			var tangent := xf.basis.x * cos(a) + xf.basis.z * sin(a)
			var h := _planet.height_at((v * cos(arc) + tangent * sin(arc)).normalized())
			if water > 0.0 and h < water + WATER_GAP_M:
				return INF
			worst = maxf(worst, absf(h - hc))
	return worst


## Soft preference: a terrain/building sight line from just above the ring to just above the caller,
## on the two layers player.gd's own interactable sight check uses.
func _has_line_of_sight(ring_dir: Vector3) -> bool:
	if _npc == null or not is_instance_valid(_npc):
		return true
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var p := _planet.surface_point(ring_dir)
	var a := p + _planet.up_at(p) * 1.1
	var b := _npc.global_position + _planet.up_at(_npc.global_position) * 1.1
	var q := PhysicsRayQueryParameters3D.create(a, b, 1 | (1 << 6))
	return space.intersect_ray(q).is_empty()


# ============================================================================= the ring
func _build_ring_visual() -> void:
	_ring_node = Node3D.new()
	_ring_node.name = "Ring"
	add_child(_ring_node)
	var xf := _planet.surface_transform(_center_dir)
	_ring_node.global_transform = xf

	var band := MeshInstance3D.new()
	band.name = "Band"
	band.mesh = _hug_ground(_ring_mesh(_flavour, _ring_radius_m), xf, 0.0)
	band.material_override = DecoItem.body_material()
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring_node.add_child(band)

	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * (_ring_radius_m * 2.0)
	plane.subdivide_width = GLOW_GRID
	plane.subdivide_depth = GLOW_GRID
	var glow := MeshInstance3D.new()
	glow.name = "Glow"
	glow.mesh = _hug_ground(plane, xf, GLOW_LIFT_M)
	glow.material_override = _glow_material(_flavour)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring_node.add_child(glow)


## A copy of `mesh` (authored flat in `xf`'s local space, +Y up) whose every vertex keeps its x and z
## and moves up or down by the ground's own height under it, plus `lift`. Once, at setup.
func _hug_ground(mesh: Mesh, xf: Transform3D, lift: float) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var inv := xf.affine_inverse()
	for i in verts.size():
		var v := verts[i]
		var ground := inv * _planet.surface_point(_planet.dir_of(xf * Vector3(v.x, 0.0, v.z)))
		verts[i] = Vector3(v.x, v.y + ground.y + lift, v.z)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## The wide band is the flavour's body pushed toward white by one fixed HSV move (the round-2 palette
## fix: the whole-frame "no dominant swatch above S 0.60" gate had been crossed by an amber band and an
## amber call disc together); the thin trim keeps the flavour's accent as shipped.
static func _ring_mesh(flavour: String, radius_m: float) -> Mesh:
	var f: Dictionary = FLAVOURS.get(flavour, FLAVOURS[DEFAULT_FLAVOUR])
	var kit := DecoKit.new()
	kit.torus(Vector3.ZERO, radius_m, radius_m * 0.055, _pastelize(Color(str(f["body"]))), Basis.IDENTITY, 30, 6)
	kit.torus(Vector3.ZERO, radius_m * 0.86, radius_m * 0.024, Color(str(f["accent"])), Basis.IDENTITY, 26, 4)
	return kit.commit()


## One fixed move for every colour: saturation cut by nearly two thirds, value lifted more than halfway
## to white.
static func _pastelize(c: Color) -> Color:
	return Color.from_hsv(c.h, c.s * 0.35, lerpf(c.v, 1.0, 0.55), c.a)


static var _glow_mats: Dictionary = {}


static func _glow_material(flavour: String) -> Material:
	if _glow_mats.has(flavour):
		return _glow_mats[flavour]
	var f: Dictionary = FLAVOURS.get(flavour, FLAVOURS[DEFAULT_FLAVOUR])
	var glow := Color(str(f["glow"]))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(glow.r, glow.g, glow.b, 0.15)
	m.albedo_texture = DecoItem.soft_dot_texture()
	m.disable_receive_shadows = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glow_mats[flavour] = m
	return m


# ============================================================================= audio
func _build_audio() -> void:
	_note_player = AudioStreamPlayer.new()
	_note_player.name = "Note"
	# AudioManager's own SFX bus - never a new bus (docs/OPEN_ISSUES.md 46).
	_note_player.bus = "SFX"
	var path := AudioManager.SFX_DIR + NOTE_SFX + ".wav"
	if ResourceLoader.exists(path):
		_note_player.stream = load(path)
	else:
		push_warning("call_game: missing sfx '%s'" % NOTE_SFX)
	_note_player.volume_db = NOTE_VOLUME_DB
	add_child(_note_player)


# ============================================================================= the card
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "CallHud"
	_ui.layer = MinigameSystem.UI_LAYER
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	MobileUI.apply_theme(root)
	_ui.add_child(root)

	_panel = PanelContainer.new()
	_panel.name = "CallCard"
	_panel.theme_type_variation = "Toast"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.offset_top = MobileUI.safe_area().y + MobileUI.pick(CARD_TOP_DESKTOP, CARD_TOP_MOBILE)
	root.add_child(_panel)
	# The toast card exactly, with its padding tightened top and bottom so the card ends higher above
	# the astronaut's head (THE CARD).
	var toast := _panel.get_theme_stylebox("panel").duplicate() as StyleBox
	toast.content_margin_top = CARD_PAD_V
	toast.content_margin_bottom = CARD_PAD_V
	toast.content_margin_left = CARD_PAD_H
	toast.content_margin_right = CARD_PAD_H
	_panel.add_theme_stylebox_override("panel", toast)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", CARD_GAP)
	_panel.add_child(row)

	# The disc is bumped on every call step, so it hangs from a plain holder: a container re-sorts only
	# its direct children, and would fight a scale tween on one.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2.ONE * 2.0 * MobileUI.pick(DISC_R_DESKTOP, DISC_R_MOBILE)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(holder)
	_disc = Control.new()
	_disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disc.draw.connect(_draw_disc)
	holder.add_child(_disc)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	_hint_label = UIStyle.make_label("", "Small")
	col.add_child(_hint_label)
	_call_label = UIStyle.make_label("", "")
	col.add_child(_call_label)
	_fit_text_column()

	_slots_row = HBoxContainer.new()
	_slots_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slots_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slots_row.add_theme_constant_override("separation", SLOT_GAP)
	row.add_child(_slots_row)
	_ensure_slots(_pattern.size())

	_panel.resized.connect(func() -> void:
		if _panel != null:
			UIStyle.center_pivot(_panel))
	UIStyle.center_pivot(_panel)
	UIStyle.pop_in(_panel, 0.22, 0.86)


## Both lines get the width of the widest text either will ever hold, measured with their own font, so
## nothing clips and the card never changes width between call steps.
func _fit_text_column() -> void:
	var lines := PackedStringArray([TEXT_WAIT, TEXT_COPY, TEXT_NICE, TEXT_BUSY, TEXT_FUEL,
		"Land first, then %s" % _control_words(Move.JUMP)])
	for m in MOVE_NAMES.size():
		lines.append(_move_hint(m))
	var tops := PackedStringArray([TEXT_WATCH, TEXT_AGAIN, TEXT_TURN])
	var w := maxf(_text_width(_call_label, lines), _text_width(_hint_label, tops))
	for label: Label in [_hint_label, _call_label]:
		var font := label.get_theme_font("font")
		label.custom_minimum_size = Vector2(w, ceilf(font.get_height(label.get_theme_font_size("font_size"))))


static func _text_width(label: Label, texts: PackedStringArray) -> float:
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var w := 0.0
	for t in texts:
		w = maxf(w, font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x)
	return ceilf(w) + 2.0


func _apply_state_visuals() -> void:
	if _hint_label == null:
		return
	var top := ""
	var line := ""
	match _state:
		State.WAIT_FOR_RING:
			line = TEXT_WAIT
		State.CALLING:
			top = TEXT_AGAIN if _replaying else TEXT_WATCH
			line = _move_hint(_current_call_move) if _current_call_move >= 0 else ""
		State.ANSWERING:
			top = TEXT_TURN
			line = _cue_text if _cue_text != "" else TEXT_COPY
		State.ROUND_GAP:
			line = TEXT_NICE
	_hint_label.text = top
	_call_label.text = line
	if _disc != null:
		_disc.queue_redraw()
	_redraw_slots()


func _ensure_slots(n: int) -> void:
	if _slots_row == null:
		return
	if _slots_built_for == n:
		for i in _slot_moves.size():
			_slot_moves[i] = -1
		_redraw_slots()
		return
	for c in _slots_row.get_children():
		_slots_row.remove_child(c)
		c.queue_free()
	_slot_ctrls = []
	_slot_moves = []
	var r := MobileUI.pick(SLOT_R_DESKTOP, SLOT_R_MOBILE)
	for i in n:
		var idx := i
		# Same holder pattern as the disc: a slot is bumped when it fills.
		var holder := Control.new()
		holder.custom_minimum_size = Vector2.ONE * (r * 2.0)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slots_row.add_child(holder)
		var s := Control.new()
		s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.draw.connect(func() -> void: _draw_slot(s, idx))
		holder.add_child(s)
		_slot_ctrls.append(s)
		_slot_moves.append(-1)
	_slots_built_for = n


func _redraw_slots() -> void:
	for c: Control in _slot_ctrls:
		if is_instance_valid(c):
			c.queue_redraw()


## The called symbol while calling (the disc stays lit through each blank beat), a check for "Nice!", a
## small ring for "step into the ring", and an empty well while you answer.
func _draw_disc() -> void:
	if not is_instance_valid(_disc):
		return
	var c := _disc.size * 0.5
	var r := minf(c.x, c.y)
	var rim := maxf(3.0, r * 0.14)
	match _state:
		State.CALLING:
			MobileUI.draw_disc(_disc, c, r, _pastelize(UIStyle.YELLOW), UIStyle.YELLOW, rim, 1.0)
			if _current_call_move >= 0:
				_draw_move_glyph(_disc, c, r * 0.60, _current_call_move, UIStyle.TEXT_BROWN)
		State.ROUND_GAP:
			MobileUI.draw_disc(_disc, c, r, _pastelize(UIStyle.GREEN), UIStyle.GREEN_EDGE, rim, 1.0)
			_disc.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.36, 0.0), c + Vector2(-r * 0.08, r * 0.28),
				c + Vector2(r * 0.40, -r * 0.30)]), UIStyle.TEXT_BROWN, maxf(3.0, r * 0.14), true)
		State.WAIT_FOR_RING:
			MobileUI.draw_disc(_disc, c, r, UIStyle.CREAM_INSET, UIStyle.CREAM_EDGE, rim, 1.0)
			_disc.draw_arc(c, r * 0.44, 0.0, TAU, 32, UIStyle.TEXT_SOFT, maxf(3.0, r * 0.12), true)
		_:
			MobileUI.draw_disc(_disc, c, r, UIStyle.CREAM_INSET, UIStyle.CREAM_EDGE, rim, 1.0)


## Calling: a dot lights as its move is called. Answering: the answered move's own symbol.
func _draw_slot(ctrl: Control, idx: int) -> void:
	if not is_instance_valid(ctrl):
		return
	var c := ctrl.size * 0.5
	var r := minf(c.x, c.y)
	var filled := false
	var glyph := -1
	if _state == State.CALLING:
		filled = idx < _call_i or (idx == _call_i and not _call_waiting)
	elif idx < _slot_moves.size() and _slot_moves[idx] >= 0:
		filled = true
		glyph = _slot_moves[idx]
	# Two filled circles (rim, then fill) rather than MobileUI.draw_disc's circle and two arcs: up to
	# seven slots are on screen, and each arc is its own draw call (PHONE AND HEAT).
	if filled:
		ctrl.draw_circle(c, r, _pastelize(UIStyle.YELLOW_EDGE))
		ctrl.draw_circle(c, r - 3.0, _pastelize(UIStyle.YELLOW))
		if glyph >= 0:
			_draw_move_glyph(ctrl, c, r * 0.62, glyph, UIStyle.TEXT_BROWN)
	else:
		ctrl.draw_circle(c, r, UIStyle.CREAM_EDGE)
		ctrl.draw_circle(c, r - 3.0, UIStyle.CREAM_INSET)


## The touch buttons' own symbols where one exists (brief rule 2): Jump is MobileUI.draw_chevron, as
## TouchButton.Glyph.JUMP draws it; Fly and Emote repeat TouchButton._draw_flame / _draw_star's point
## maths (private methods of another Control). Use has no touch glyph, so it gets a tap mark.
func _draw_move_glyph(ctrl: Control, c: Vector2, r: float, move: int, ink: Color) -> void:
	match move:
		Move.JUMP:
			MobileUI.draw_chevron(ctrl, c + Vector2(0.0, -r * 0.10), r * 0.72, ink)
		Move.FLY:
			_draw_flame(ctrl, c, r, ink)
		Move.EMOTE:
			_draw_star(ctrl, c, r, ink)
		_:
			_draw_use_mark(ctrl, c, r, ink)


func _draw_flame(ci: CanvasItem, c: Vector2, r: float, ink: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(0.0, -r), Vector2(r * 0.62, -r * 0.05), Vector2(r * 0.30, r * 0.75),
		Vector2(0.0, r * 0.30), Vector2(-r * 0.30, r * 0.75), Vector2(-r * 0.62, -r * 0.05)])
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + p)
	ci.draw_colored_polygon(out, Color(UIStyle.ORANGE, 0.85))
	var closed := out.duplicate()
	closed.append(out[0])
	ci.draw_polyline(closed, ink, 3.0, true)


func _draw_star(ci: CanvasItem, c: Vector2, r: float, ink: Color) -> void:
	var inner := r * 0.42
	var pts := PackedVector2Array()
	for i in 10:
		var ang := deg_to_rad(-90.0) + float(i) * deg_to_rad(36.0)
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r if i % 2 == 0 else inner))
	ci.draw_colored_polygon(pts, Color(UIStyle.YELLOW, 0.9))
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, ink, 2.5, true)


## A dot with two ripples: "press here".
func _draw_use_mark(ci: CanvasItem, c: Vector2, r: float, ink: Color) -> void:
	ci.draw_circle(c, r * 0.30, ink)
	ci.draw_arc(c, r * 0.64, 0.0, TAU, 26, Color(ink, 0.85), 3.0, true)
	ci.draw_arc(c, r * 0.98, 0.0, TAU, 30, Color(ink, 0.55), 3.0, true)


# ============================================================================= QA
func debug_report(tag: String = "") -> void:
	var names: Array[String] = []
	for m: int in _pattern:
		names.append(MOVE_NAMES[m])
	var queue: Array[String] = []
	for p: PendingInput in _inputs:
		queue.append("%s@%d(air=%s held=%d up=%s lit=%s late=%s)" % [MOVE_NAMES[p.move] if p.move >= 0 else "FlyBtn",
			p.tick, str(p.in_air), p.held_ticks, str(p.let_go), str(p.lit), str(p.lit_late)])
	print(("CALL %s state=%s round=%d/%d call_i=%d answer_i=%d pattern=%s in_ring=%s center_dir=%s radius=%.2f " +
		"npc=%s last_move=%s tick=%d air_from=%d hops=%d/%d claimed hop_from=%d queue=%s cue='%s'") % [
		tag, State.keys()[_state], _round_index + 1, _total, _call_i, _answer_i, str(names), str(_in_ring_cached),
		str(_center_dir), _ring_radius_m, _npc.npc_id if _npc != null and is_instance_valid(_npc) else "-",
		MOVE_NAMES[_last_detected_move] if _last_detected_move >= 0 else "-", _tick, _air_from, _hop_count,
		_hop_claimed, _hop_from, str(queue), _cue_text])


## Rounds 1..n's patterns, read ahead (`_make_pattern` is pure), so a timeline can be written against them.
func debug_peek_patterns(n: int) -> void:
	for i in n:
		var names: Array[String] = []
		for m: int in _make_pattern(i):
			names.append(MOVE_NAMES[m])
		print("CALLPEEK round=%d pattern=%s" % [i + 1, str(names)])


## Every WHERE THE RING GOES rule at the chosen spot, as margins (positive = clear), re-collected now.
func debug_placement() -> void:
	_collect_obstacles()
	var edge := _ring_radius_m + EXIT_HYSTERESIS_M
	for d: Vector3 in _npc_dirs:
		print("CALLPLACE npc gap=%.2f need=%.2f" % [_planet.surface_distance(_center_dir, d) - _ring_radius_m,
			NPC.TALK_REACH + NEIGHBOUR_GAP_EXTRA_M])
	for w: Dictionary in _walkers:
		print("CALLPLACE walking neighbour's walk gap=%.2f need=%.2f" % [_planet.surface_distance(_center_dir, w["home"])
			- float(w["radius"]) - edge, NPC.TALK_REACH + REACH_MARGIN_M])
	for d: Vector3 in _block_dirs:
		print("CALLPLACE building/pad gap=%.2f need=%.2f" % [_planet.surface_distance(_center_dir, d) - _ring_radius_m,
			BUILDING_GAP_M])
	print("CALLPLACE prop gap from footprint=%.2f" % (_planet.nearest_prop_distance(_center_dir) - edge))
	var centre := _planet.surface_point(_center_dir)
	var gaps: Array = []
	for it: Dictionary in _reachables:
		var g := _reach_gap(_center_dir, centre, it)
		if g < 50.0:
			gaps.append([g, str(it["name"]), float(it["reach"])])
	gaps.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for i in mini(gaps.size(), 6):
		print("CALLPLACE reach %s reach=%.2f column gap beyond reach=%.2f need=%.2f" % [gaps[i][1], gaps[i][2], gaps[i][0], REACH_MARGIN_M])
	print("CALLPLACE ground unevenness=%.3f tolerance=%.2f sight=%s" % [_ground_unevenness(_center_dir), FLAT_TOLERANCE_M,
		str(_has_line_of_sight(_center_dir))])
	if _npc != null and is_instance_valid(_npc):
		print("CALLPLACE home dist=%.2f" % _planet.surface_distance(_center_dir, _npc.home_dir))
