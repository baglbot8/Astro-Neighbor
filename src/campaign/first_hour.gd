class_name FirstHour
extends Node
## THE FIRST HOUR ON THE COMMONS (docs/INTRO_SPEC.md section 7, user-approved 2026-10-18).
##
## A new game reaches only home and the Commons at first. On the Commons the Professor sends the player
## to three residents, each holding one bit of a "patch" for the ship. Three small errands, no flights:
##   Pip     sweep PIP_SCRAP pieces of scrap off the Commons (her shop front is a mess; you keep the scrap)
##   Pop     find the bit he dropped - it rolled toward the event space, between his shop and the stage
##   Stella  borrow her tape and walk to your rocket on the pad to measure the dent, then come back
## With all three bits the Professor fits the patch (a dialogue, a chime and two emotes - NOT the part
## celebration, which only exists on home and would step the rocket's finish). The patch is not a ship
## part: it is never in CampaignData.PARTS and never counts in GameState.rocket_part_count(), so the
## rusty finish and Departure Day are unchanged. Fitting it sets PATCH_FLAG, which opens Zorp and Bolt
## (CampaignData.needs_patch). Then he says the photographer lines (option A, "one last look"), opens his
## photo task (ProfessorAsk.open_task) and hands over a parcel of glow bulbs for Zorp. Talking to Zorp
## with the parcel plays his delivery lines, then his project starts exactly as it does today.
##
## NOT a ProjectSystem project (that system only loads the five neighbours and has no deliver step).
## STATE: plain entries in GameState.flags, saved with everything else, no save-schema change:
##   first_patch          the patch is fitted (CampaignData's gate reads it through patch_fitted())
##   fh_started           the Professor has sent the player to the three residents
##   fh_<id>_asked        that resident has given their errand (pip / pop / stella)
##   fh_<id>_bit          that resident has handed over their bit
##   fh_pip_scrap         int: scrap picked up on the Commons since Pip asked
##   fh_<id>_nudges       int: progress talks so far (picks the next, more specific, nudge line)
##   fh_pop_found         Pop's dropped bit has been picked up
##   fh_stella_measured   the player walked to the rocket with Stella's tape
##   fh_parcel            carrying Zorp's glow bulbs
##   fh_parcel_done       the bulbs were delivered
## GameState.reset_new_game() clears all of them (its from_dict({}) sets flags = {}).
##
## OLD SAVES. Gates off (an old save, a finished story, a Director run without --campaign): nothing here
## runs and every world stays open. A campaign save made BEFORE this file existed that has already
## reached Zorp or Bolt (a part fitted, a project started, either neighbour met, a pickup made there, or
## standing there now) counts as patched (`_legacy_progress`), so it is never shut out of a world it has
## been to. A campaign save that never got that far meets the chain on its next talk with the Professor.
##
## HOOKS (all in src/dialogue/conversation.gd, the same shape as ProfessorAsk.handles):
##   FirstHour.handles(npc_id) -> FirstHour.run(runner, npc, first_meeting) is the whole talk.
##   FirstHour.parcel_for(npc_id) -> FirstHour.deliver_parcel(runner, npc), then the talk goes on.
## THE WORLD SIDE (the scrap and Pop's bit on the ground, Stella's tape check, the carried parcel) is this
## node, /root/World/FirstHour, created on every planet load that needs it (the static hook below) and
## whenever an errand starts in a talk.
##
## NO CLOCK: nothing here counts down or mentions a deadline (docs/STORY_HOME_SPEC.md 2.2).

const PATCH_FLAG := "first_patch"
const STARTED_FLAG := "fh_started"
const PARCEL_FLAG := "fh_parcel"
const PARCEL_DONE_FLAG := "fh_parcel_done"
const PIP_SCRAP_FLAG := "fh_pip_scrap"
const POP_FOUND_FLAG := "fh_pop_found"
const STELLA_MEASURED_FLAG := "fh_stella_measured"

const PROFESSOR_ID := "mayor_orbit"
const RESIDENTS: Array[String] = ["pip", "pop", "stella"]
const PARCEL_TO := "zorp"
const HUB := "hub"
const NODE_NAME := "FirstHour"

## Scrap pickups Pip asks for. A hub scrap pickup is one walk-up each; 4 is a short sweep, not a grind.
const PIP_SCRAP := 4
## Within this many metres of the rocket pad's centre counts as "measured the rocket". The pad's own
## Fly reach is 4.2 m (rocket_pad.gd), so standing at the rocket always counts.
const MEASURE_REACH_M := 5.0
## How often the node checks the tape (seconds). A walk-up check, not a frame-exact one.
const POLL_SEC := 0.25
## Pop's bit lands within this many surface metres of the event space, at least BIT_CLEARANCE_M from
## any prop or building zone (Planet.find_free_dir_near), on a fixed seed so it is in the same spot on
## every load.
const BIT_NEAR_M := 9.0
## ROUND 2 (critic, 2026-10-18): searched around the stage itself, the bit landed 8.6 m out on the far
## side, behind the bandshell and the planet's curve, 18.5 m from Pop - invisible from his shop, the pad
## and the stage front in phone frames. It now lies ON THE LINE from the stage to Pop's shop: the first
## point from BIT_LINE_FROM_M to BIT_LINE_TO_M out from the stage (BIT_LINE_STEP_M apart) that is
## BIT_CLEARANCE_M clear of every prop and BIT_BUILDING_CLEAR_M from every building's centre (the hub
## buildings reach ~4.1 m from theirs, planet.gd). Planet.find_free_dir_near could not be used: the
## whole gap between the two buildings is inside their reserved discs (measured: every sample from 4 to
## 12 m out was in the "event_space" or "deco_store" zone), and its rejection sampling over the whole
## sphere almost never lands in a 3-4 m band (64 tries, about 0.7% of the sphere).
const BIT_LINE_FROM_M := 6.0
const BIT_LINE_TO_M := 9.0
const BIT_LINE_STEP_M := 0.25
const BIT_BUILDING_CLEAR_M := 5.0
const BIT_CLEARANCE_M := 0.9
const BIT_SALT := 7741
const SCRAP_NEAR_M := 8.0
const SCRAP_SALT := 7742
## The parcel's carry colour: Catalog entry registered at runtime for the carried-box tint only. It is
## never put in the bag (the parcel is a flag), so it cannot be sold, placed or lost.
const PARCEL_CARRY_ID := "fh_glow_bulbs"
const PARCEL_COLOR := "#8fdcff"
const BRASS := Color("#c9a15c")
const BRASS_DARK := Color("#8a6a34")

# ---------------------------------------------------------------------------------------- lines
# Every box is at most 60 characters with the longest pickable name (6 letters) filled in; checked by
# showcase/first_hour_probe.gd. %s is the player's name (GameState.player_style["name"]).
const DISPATCH := [
	"Now then, %s. About that poor ship of yours.",
	"It needs a patch, or it won't hop any further.",
	"Pip, Pop and Stella each have a bit of one.",
	"Ask them nicely, then bring all three bits to me.",
]
const PROGRESS_NONE := "No bits yet? Pip, Pop and Stella have them."
const PROGRESS_SOME := "%d of 3 bits so far. Splendid!"
const PROGRESS_LEFT := "Still to see: %s."
const FIT_BEFORE := [
	"All three bits! Hand them over, %s.",
	"A twist here, a tap there... and a good thump.",
]
const FIT_AFTER := [
	"There! Patched. Not pretty, but it will hop.",
	"Zorp and Bolt are in reach now.",
]
## Option A, "one last look" (INTRO_SPEC 1.6 and 7.4). Stella's "done" lines notice the camera first,
## so he has heard it from her.
const PHOTOGRAPHER := [
	"Stella tells me you carry a camera everywhere.",
	"A photographer? Splendid!",
	"Nobody can see all of their own world.",
	"Your photos could show what they might leave behind.",
	"Help them, and they will help fix your ship.",
]
const PHOTO_ASK := [
	"Snap a neighbour on their own world, then show me.",
	"A last look at home, so they can see what they'd miss.",
]
const PARCEL := [
	"First, a parcel for Zorp. His rivers are dimming.",
	"Spare glow bulbs. Fragile, so no juggling!",
]
const PARCEL_REMINDER := [
	"Zorp's glow bulbs! His rivers are waiting.",
	"Your rocket's on the pad. It can reach him now.",
]
## Zorp, right after his own first-meeting intro and right before his project's intro ("Oh no, oh no!
## My rivers are going dark!"), which follows in the same talk.
const ZORP_PARCEL := [
	"A parcel? From the Professor? For me?",
	"Glow bulbs! Thank you for carrying them so far!",
	"But bulbs won't be enough. Not this time...",
]

const TOAST_SENT := "Find Pip, Pop and Stella on the Commons"
const TOAST_BIT := "Patch bit from %s! (%d of 3)"
const TOAST_SCRAP := "Scrap for Pip: %d of %d"
const TOAST_SCRAP_DONE := "That's enough scrap! Back to Pip."
const TOAST_POP_FOUND := "Found Pop's patch bit! Back to Pop."
const TOAST_TAPE := "Stella lent you her tape measure"
const TOAST_MEASURED := "Dent measured! Back to Stella."
const TOAST_PATCH := "Patch fitted! Zorp and Bolt are in reach."
const TOAST_PARCEL := "You got glow bulbs for Zorp!"
const TOAST_DELIVERED := "Delivered the glow bulbs!"
const BIT_PROMPT := "Pick up"

var _poll := 0.0
var _bit: Node3D


# ===================================================================================== state (static)
## The patch is in: the flag, or a pre-feature campaign save that already reached Zorp or Bolt.
static func patch_fitted() -> bool:
	return GameState.flag(PATCH_FLAG) or _legacy_progress()


## True while the first hour is running: campaign gates on and the patch not yet fitted.
static func chain_active() -> bool:
	return CampaignData.gates_on() and not patch_fitted()


static func parcel_held() -> bool:
	return GameState.flag(PARCEL_FLAG) and not GameState.flag(PARCEL_DONE_FLAG)


static func bits() -> int:
	var n := 0
	for id: String in RESIDENTS:
		if GameState.flag(_bit_flag(id)):
			n += 1
	return n


static func pip_scrap() -> int:
	return int(GameState.flags.get(PIP_SCRAP_FLAG, 0))


## A campaign save from before this feature that has already been to Zorp or Bolt. Read-only.
static func _legacy_progress() -> bool:
	if GameState.rocket_part_count() > 0:
		return true
	for id: String in CampaignData.PATCH_GATED:
		if GameState.flag("met_" + id) or GameState.projects.has(id) \
				or GameState.picked_collectibles.has(id) or GameState.current_planet_id == id:
			return true
	return false


static func _asked_flag(id: String) -> String:
	return "fh_%s_asked" % id


static func _bit_flag(id: String) -> String:
	return "fh_%s_bit" % id


## The resident's own task is done and only the hand-in talk is left.
static func task_met(id: String) -> bool:
	match id:
		"pip":
			return pip_scrap() >= PIP_SCRAP
		"pop":
			return GameState.flag(POP_FOUND_FLAG)
		"stella":
			return GameState.flag(STELLA_MEASURED_FLAG)
	return false


static func _player_name() -> String:
	return str(GameState.player_style.get("name", "Astro"))


static func _named(lines: Array) -> Array:
	var out: Array = []
	for l: Variant in lines:
		var s := str(l)
		out.append(s % _player_name() if s.contains("%s") else s)
	return out


static func _resident_lines(id: String, key: String) -> Array:
	var block: Variant = NpcData.get_data(id).get("first_hour", {})
	if not (block is Dictionary):
		return []
	var lines: Variant = (block as Dictionary).get(key, [])
	return (lines as Array).duplicate() if lines is Array else []


# ===================================================================================== the talk hooks
## True when this whole talk belongs to the first hour (conversation.gd ends the talk after `run`).
static func handles(npc_id: String) -> bool:
	if npc_id == PROFESSOR_ID:
		return chain_active() or parcel_held()
	if RESIDENTS.has(npc_id):
		return chain_active() and GameState.flag(STARTED_FLAG)
	return false


static func run(runner: DialogueRunner, npc: NPC, first_meeting: bool = false) -> void:
	if npc.npc_id == PROFESSOR_ID:
		await _run_professor(runner, npc, first_meeting)
	else:
		await _run_resident(runner, npc, npc.npc_id)


## True when talking to `npc_id` should hand over the parcel first (the talk then goes on as normal).
static func parcel_for(npc_id: String) -> bool:
	return npc_id == PARCEL_TO and parcel_held()


static func deliver_parcel(runner: DialogueRunner, npc: NPC) -> void:
	# Clear first (the lantern-fish lesson in professor_ask.gd): a save mid-talk never re-delivers.
	GameState.set_flag(PARCEL_DONE_FLAG)
	GameState.set_flag(PARCEL_FLAG, false)
	_set_carry("")
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit(TOAST_DELIVERED, "star")
	await runner.say(npc, ZORP_PARCEL)
	npc.play_emote("happy")
	print("[FirstHour] parcel delivered to %s" % npc.npc_id)


static func _run_professor(runner: DialogueRunner, npc: NPC, first_meeting: bool) -> void:
	if not chain_active():
		await runner.say(npc, PARCEL_REMINDER)
		return
	var lines: Array = []
	if first_meeting:
		# conversation.gd already played his generic stranger intro (no photo is ever in hand here).
		lines.append_array(ProfessorAsk.first_meeting_lines(false))
	if not GameState.flag(STARTED_FLAG):
		GameState.set_flag(STARTED_FLAG)
		lines.append_array(_named(DISPATCH))
		await runner.say(npc, lines)
		AudioManager.play_sfx("quest_accept")
		EventBus.toast_requested.emit(TOAST_SENT, "star")
		ensure()
		print("[FirstHour] sent to the residents (first_meeting=%s)" % str(first_meeting))
		return
	var have := bits()
	if have < RESIDENTS.size():
		lines.append(PROGRESS_NONE if have == 0 else PROGRESS_SOME % have)
		if have > 0:
			lines.append(PROGRESS_LEFT % _names_left())
		await runner.say(npc, lines)
		return
	lines.append_array(_named(FIT_BEFORE))
	await runner.say(npc, lines)
	_fit_patch(npc)
	await runner.say(npc, FIT_AFTER + PHOTOGRAPHER + PHOTO_ASK + PARCEL)
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit(TOAST_PARCEL, PARCEL_CARRY_ID)


## Every state change of the fitting, committed together BEFORE the long talk that follows, so a save
## made mid-talk already holds the patch, the open photo task and the parcel.
static func _fit_patch(npc: NPC) -> void:
	GameState.set_flag(PATCH_FLAG)
	ProfessorAsk.open_task()
	GameState.set_flag(PARCEL_FLAG)
	_register_parcel()
	_set_carry(PARCEL_CARRY_ID)
	AudioManager.play_sfx("part_fitted")
	npc.play_emote("happy")
	var p := _player()
	if p != null and p.has_method("play_emote"):
		p.call("play_emote", "happy")
	EventBus.toast_requested.emit(TOAST_PATCH, "star")
	print("[FirstHour] patch fitted: parts=%d task_open=%s parcel=%s" % [GameState.rocket_part_count(),
		str(ProfessorAsk.is_open()), str(parcel_held())])


static func _names_left() -> String:
	var left: Array[String] = []
	for id: String in RESIDENTS:
		if not GameState.flag(_bit_flag(id)):
			left.append(str(NpcData.get_data(id).get("display_name", id)))
	if left.size() <= 1:
		return "".join(left)
	return ", ".join(left.slice(0, left.size() - 1)) + " and " + left[left.size() - 1]


static func _run_resident(runner: DialogueRunner, npc: NPC, id: String) -> void:
	if GameState.flag(_bit_flag(id)):
		await runner.say(npc, _resident_lines(id, "after"))
		return
	if not GameState.flag(_asked_flag(id)):
		GameState.set_flag(_asked_flag(id))
		var ask := _resident_lines(id, "ask")
		if id == "pip":
			ask = ask.map(func(l: Variant) -> String: return str(l) % PIP_SCRAP if str(l).contains("%d") else str(l))
		await runner.say(npc, ask)
		AudioManager.play_sfx("quest_accept")
		if id == "stella":
			EventBus.toast_requested.emit(TOAST_TAPE, "star")
		var node := ensure()
		if node != null:
			node.refresh_world()
		print("[FirstHour] %s asked" % id)
		return
	if not task_met(id):
		# One progress box per talk, stepping through the list and staying on the last one, so a
		# second nudge can be more specific than the first (Pop: round-2 critic note).
		var pool := _resident_lines(id, "progress")
		var key := "fh_%s_nudges" % id
		var n := int(GameState.flags.get(key, 0))
		GameState.flags[key] = n + 1
		var nudge: Array = [pool[mini(n, pool.size() - 1)]] if not pool.is_empty() else []
		if id == "pip":
			nudge = nudge.map(func(l: Variant) -> String:
				return str(l) % [pip_scrap(), PIP_SCRAP] if str(l).contains("%d") else str(l))
		await runner.say(npc, nudge)
		return
	GameState.set_flag(_bit_flag(id))
	await runner.say(npc, _resident_lines(id, "done"))
	npc.play_emote("happy")
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit(TOAST_BIT % [str(NpcData.get_data(id).get("display_name", id)), bits()], "star")
	print("[FirstHour] bit from %s (%d of 3)" % [id, bits()])


# ===================================================================================== the world node
static var _hooked := false


static func _static_init() -> void:
	_hook()


static func _hook() -> void:
	if _hooked:
		return
	_hooked = true
	if not EventBus.planet_loaded.is_connected(_on_planet_loaded):
		EventBus.planet_loaded.connect(_on_planet_loaded)


static func _on_planet_loaded(_planet_id: String) -> void:
	if chain_active() or parcel_held():
		var n := ensure()
		if n != null:
			n.refresh_world()


## The world's FirstHour node, created under /root/World the first time. null with no World.
static func ensure() -> FirstHour:
	_hook()
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var world := tree.root.get_node_or_null("World")
	if world == null:
		return null
	var existing := world.get_node_or_null(NODE_NAME) as FirstHour
	if existing != null:
		return existing
	var n := FirstHour.new()
	n.name = NODE_NAME
	world.add_child(n)
	return n


func _ready() -> void:
	if not EventBus.collectible_picked.is_connected(_on_collectible_picked):
		EventBus.collectible_picked.connect(_on_collectible_picked)
	refresh_world()


## Puts the world in step with the flags: the carried parcel anywhere; Pip's scrap and Pop's bit on
## the Commons while their errands are open. Idempotent - safe on every load and every talk.
func refresh_world() -> void:
	if parcel_held():
		_register_parcel()
		_set_carry(PARCEL_CARRY_ID)
	if GameState.current_planet_id != HUB or not chain_active():
		return
	var planet := _planet()
	if planet == null:
		return
	if GameState.flag(_asked_flag("pip")) and not GameState.flag(_bit_flag("pip")) and not task_met("pip"):
		_spawn_scrap(planet)
	if GameState.flag(_asked_flag("pop")) and not GameState.flag(POP_FOUND_FLAG):
		_spawn_bit(planet)


func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = POLL_SEC
	if GameState.current_planet_id != HUB or not chain_active():
		return
	if not GameState.flag(_asked_flag("stella")) or GameState.flag(STELLA_MEASURED_FLAG):
		return
	var planet := _planet()
	var p := _player()
	if planet == null or p == null:
		return
	if p.global_position.distance_to(planet.pad_transform().origin) <= MEASURE_REACH_M:
		GameState.set_flag(STELLA_MEASURED_FLAG)
		AudioManager.play_sfx("pickup_item")
		EventBus.toast_requested.emit(TOAST_MEASURED, "star")
		print("[FirstHour] stella: rocket measured")


func _on_collectible_picked(kind: String, _pos: Vector3) -> void:
	if kind != "scrap" or GameState.current_planet_id != HUB or not chain_active():
		return
	if not GameState.flag(_asked_flag("pip")) or GameState.flag(_bit_flag("pip")) or task_met("pip"):
		return
	var n := pip_scrap() + 1
	GameState.flags[PIP_SCRAP_FLAG] = n
	EventBus.toast_requested.emit(TOAST_SCRAP_DONE if n >= PIP_SCRAP else TOAST_SCRAP % [n, PIP_SCRAP], "scrap")
	print("[FirstHour] pip scrap %d/%d" % [n, PIP_SCRAP])


## Enough scrap pickups near Pip's shop that her errand can always be finished today, even after the
## Commons was swept bare (the favour system's own fetch rule, `_spawn_fetch_targets`). Extra ones on
## top of the Commons' own scrap; any scrap picked up on the Commons counts.
func _spawn_scrap(planet: Planet) -> void:
	if planet.collectibles_root == null:
		return
	var needed := PIP_SCRAP - pip_scrap()
	var rng := planet.make_rng(SCRAP_SALT)
	var centre := planet.building_dir("deco_store")
	for i in needed + 1:
		var spawn_id := "fh_pip_%d" % i
		var dir := planet.find_free_dir_near(rng, centre, SCRAP_NEAR_M, 0.8, 40)
		if Collectible.was_picked_today(HUB, spawn_id) or planet.collectibles_root.has_node("Collectible_" + spawn_id):
			continue
		if dir == Vector3.ZERO:
			dir = planet.find_free_dir(rng, 0.8, 40)
		if dir == Vector3.ZERO:
			continue
		var c := Collectible.new()
		c.setup("scrap", spawn_id, HUB)
		c.transform = planet.surface_transform(dir, Vector3.FORWARD)
		planet.collectibles_root.add_child(c)


func _spawn_bit(planet: Planet) -> void:
	if _bit != null and is_instance_valid(_bit):
		return
	var rng := planet.make_rng(BIT_SALT)
	var stage := planet.building_dir("event_space")
	var dir := _bit_dir_toward_pop(planet)
	if dir == Vector3.ZERO:
		dir = planet.find_free_dir_near(rng, stage, BIT_NEAR_M, BIT_CLEARANCE_M, 64)
	if dir == Vector3.ZERO:
		dir = planet.find_free_dir(rng, BIT_CLEARANCE_M, 64)
	if dir == Vector3.ZERO:
		push_warning("FirstHour: no free spot for Pop's bit")
		return
	var bit := LostBit.new()
	bit.name = "PopsPatchBit"
	bit.picked.connect(_on_bit_picked)
	bit.transform = planet.surface_transform(dir, Vector3.FORWARD)
	add_child(bit)
	_bit = bit
	print("[FirstHour] pop's bit at dir=%s (%.1f m from the event space, %.1f m from Pop's shop)" % [str(dir),
		planet.surface_distance(dir, stage), planet.surface_distance(dir, planet.building_dir("deco_store"))])


## The first clear spot on the line from the stage to Pop's shop (see BIT_LINE_FROM_M). ZERO if none.
static func _bit_dir_toward_pop(planet: Planet) -> Vector3:
	var stage := planet.building_dir("event_space")
	var shop := planet.building_dir("deco_store")
	if stage == Vector3.ZERO or shop == Vector3.ZERO:
		return Vector3.ZERO
	var t := BIT_LINE_FROM_M
	while t <= BIT_LINE_TO_M:
		var d := planet.step_dir(stage, shop, t)
		var clear := planet.nearest_prop_distance(d) >= BIT_CLEARANCE_M and not planet.is_underwater(d)
		for b: String in ["town_hall", "deco_store", "clothes_store", "event_space"]:
			if planet.surface_distance(d, planet.building_dir(b)) < BIT_BUILDING_CLEAR_M:
				clear = false
		if clear:
			return d
		t += BIT_LINE_STEP_M
	return Vector3.ZERO


func _on_bit_picked() -> void:
	GameState.set_flag(POP_FOUND_FLAG)
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit(TOAST_POP_FOUND, "star")
	print("[FirstHour] pop's bit picked up")


# ===================================================================================== helpers
static func _register_parcel() -> void:
	if Catalog.has_item(PARCEL_CARRY_ID):
		return
	Catalog.register({
		"id": PARCEL_CARRY_ID,
		"name": "Glow Bulbs",
		"kind": "favor_item",
		"category": "material",
		"rarity": "common",
		"price": 0,
		"desc": "Spare glow bulbs for Zorp's rivers. Fragile!",
		"icon_color": PARCEL_COLOR,
	})


static func _set_carry(item_id: String) -> void:
	var p := _player()
	if p != null and p.has_method("set_carry_item"):
		p.call("set_carry_item", item_id)


static func _player() -> Node3D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node3D


static func _planet() -> Planet:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("planet") as Planet


# ===================================================================================== Pop's bit
## The bit Pop dropped: a small brass plate with four rivets, bobbing and sparkling like any pickup so
## it reads as "pick me up", with a warm ground glow so it can be spotted from a few metres. Built with
## the decoration kit and the shared metal material - no imported art.
class LostBit extends Interactable:
	signal picked()

	const BOB_Y := 0.38
	## ROUND 2: 1.6x the first size (a 0.64 m plate) so it reads from the stage front and Pop's spot on
	## a phone; the first one was a 0.40 m plate, smaller than a scrap pickup's glow.
	const SIZE := 1.6
	var _visual: Node3D
	var _t := 0.0
	var _done := false

	func _init() -> void:
		prompt_text = BIT_PROMPT
		reach = 2.4
		require_facing = false

	func _ready() -> void:
		super._ready()
		var shape := CollisionShape3D.new()
		var s := SphereShape3D.new()
		s.radius = 0.6
		shape.shape = s
		shape.position = Vector3(0.0, 0.4, 0.0)
		add_child(shape)
		_build()

	func _build() -> void:
		_visual = Node3D.new()
		_visual.name = "Visual"
		add_child(_visual)
		var kit := DecoKit.new()
		var tilt := Basis(Vector3.RIGHT, deg_to_rad(18.0))
		kit.rbox(Vector3.ZERO, Vector3(0.40, 0.06, 0.32), 0.03, BRASS, tilt)
		for x: float in [-0.14, 0.14]:
			for z: float in [-0.10, 0.10]:
				kit.sphere(tilt * Vector3(x, 0.04, z), 0.03, BRASS_DARK, Vector3(1.0, 0.6, 1.0), 6)
		var mi := MeshInstance3D.new()
		mi.mesh = kit.commit()
		mi.material_override = DecoItem.metal_material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_visual.add_child(mi)
		_visual.position.y = BOB_Y
		_visual.scale = Vector3.ONE * SIZE
		var sparkle := Color("#ffd9a0")
		var p := CPUParticles3D.new()
		p.name = "Sparkles"
		p.amount = 20
		p.lifetime = 1.5
		p.local_coords = true
		p.position = Vector3(0.0, 0.3 + BOB_Y, 0.0)
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.5
		p.direction = Vector3.UP
		p.spread = 30.0
		p.initial_velocity_min = 0.15
		p.initial_velocity_max = 0.4
		p.gravity = Vector3(0.0, 0.25, 0.0)
		p.scale_amount_min = 0.5
		p.scale_amount_max = 1.0
		var g := Gradient.new()
		g.set_color(0, Color(sparkle.r, sparkle.g, sparkle.b, 0.0))
		g.add_point(0.25, sparkle)
		g.set_color(g.get_point_count() - 1, Color(sparkle.r, sparkle.g, sparkle.b, 0.0))
		p.color_ramp = g
		var q := QuadMesh.new()
		q.size = Vector2(0.085, 0.085)
		q.material = PlanetPropMeshes.sparkle_material(Color.WHITE)
		p.mesh = q
		add_child(p)
		var disc := MeshInstance3D.new()
		var dm := QuadMesh.new()
		dm.size = Vector2(1.6, 1.6)
		dm.orientation = PlaneMesh.FACE_Y
		disc.mesh = dm
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		glow.albedo_color = Color(sparkle.r, sparkle.g, sparkle.b, 0.14)
		glow.disable_receive_shadows = true
		glow.albedo_texture = PlanetPropMeshes.soft_dot_texture()
		disc.material_override = glow
		disc.position.y = 0.03
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(disc)

	func _process(delta: float) -> void:
		if _done or _visual == null:
			return
		_t += delta
		_visual.position.y = BOB_Y + sin(_t * 2.4) * 0.09
		_visual.rotation.y += delta * 1.4

	func interact(player: Node3D) -> void:
		if _done:
			return
		_done = true
		enabled = false
		set_focused(false)
		interacted.emit(player)
		picked.emit()
		var tw := create_tween()
		tw.tween_property(_visual, "scale", Vector3.ONE * SIZE * 1.35, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_visual, "scale", Vector3(0.01, 0.01, 0.01), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(queue_free)
