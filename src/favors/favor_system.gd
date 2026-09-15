class_name FavorSystem
extends Node
## Generates, tracks and pays out neighbour favors (ARCHITECTURE §6). One instance per world, created
## lazily as a child of /root/World:
##
##   var favors := FavorSystem.get_or_create()
##   if favors.can_offer("zorp"):
##       var offer := favors.make_offer("zorp")     # nothing is committed yet
##       ... ask the player ...
##       favors.accept(offer)                       # or favors.decline("zorp")
##   if favors.is_ready_to_turn_in(favor): favors.complete(favor, npc)
##
## Templates
##   fetch    collect N of the collectible that grows on that NPC's own planet (extra ones are
##            spawned near the NPC so the errand is always completable)
##   bring    N of a material from anywhere in the system
##   deliver  carry "gift_<npc>" to a different neighbour, usually on another planet
##   play     play that neighbour's own mini-game again, on their world (below)
##
## State lives in GameState.favors (plain dictionaries, so it saves and loads), and is restored on
## every planet load. Progress is driven by EventBus.item_added / collectible_picked for fetch/bring,
## and by MinigameSystem's signals for "play" (see below). "deliver" has no progress: it completes the
## moment the recipient is talked to with the gift in hand (conversation.gd).
##
## ============================================================================= FAVOURS FOLLOW THE STORY
## (docs/CORE_LOOP.md "Visits and favours", decided 2026-09-13, Phase 4 builder J.)
##
## 1. GATE - while CampaignData.gates_on(), a neighbour who has a project (a definition exists in
##    res://src/projects/data/<npc>.gd) offers no favour until that project's part has been handed
##    over (GameState.projects[npc]["done"]). A neighbour with no project (the Commons crowd) is never
##    gated. Gates off (the story finished, or an old save that loads that way) gates nobody - see
##    `_project_unfinished`. ProjectSystem is looked up BY PATH (`PROJECT_SYSTEM_PATH`,
##    ResourceLoader.exists then load().call()), never by class_name, exactly like world.gd's own
##    ProjectSystem hookup: a build missing that file must still run every other favour untouched.
## 2. OCCASIONALLY - once a neighbour clears the gate above and has no active favour, whether they
##    have one TODAY is a coin flip seeded only by (npc_id, day_count): `FAVOR_CHANCE` (a Phase 6
##    pacing number, start 0.5). The flip is a `RandomNumberGenerator` seeded with `hash()` of the two
##    - never the system's live `_rng` - so it reads the same after a save and a fresh-process reload
##    on the same day (`_day_roll_passes`), and it never lands on two game days running: a day right
##    after one that had an offer (accepted or declined - both write `last_favor_day`) never rolls at
##    all (`_day_eligible`). This applies to every neighbour, gated or not - a Commons neighbour keeps
##    "now and then", not "every talk", per CORE_LOOP.
## 3. MINI-GAME FAVOURS - once ProjectSystem.played_minigames() lists a neighbour's game (their project
##    step is past, or the story is over), about one in three of their favours (`PLAY_FAVOR_CHANCE`) is
##    "play" instead of fetch/bring/deliver: play their game again, on their own world, then talk to
##    them. Hosted the way a project step hosts a mini-game - MinigameSystem.start(kind, config) under
##    owner `"favor:<npc>:<day>"` - but progress lives in the favour's OWN dictionary
##    ("game", "game_planet", "game_config", "owner", "progress" as done, "count" as total), never a
##    new GameState field. Lifecycle:
##      * started in `accept()`, and again by `_restore()` on every `EventBus.planet_loaded` while the
##        favour is still active and its `game_planet` is the one just landed on ("fly away and back -
##        it restarts at its saved count").
##      * YIELDS - `_start_play_game` never calls `MinigameSystem.start()` while a DIFFERENT owner's
##        game is already running (a replay from the Commons board, or a project step's own game); it
##        waits instead. When that other game's `finished` signal fires, `_on_minigame_finished` checks
##        whether an unmet play favour belongs on the CURRENT planet and starts it then
##        (`_resume_play_favor_here`) - so the favour's game "comes back after" whatever replaced it.
##      * progress is written from `MinigameSystem.progress_changed`, matched by `running_owner()`, so
##        it is safe against the finished signal being missed (same rule ProjectSystem's mini-game
##        steps follow).
##      * `complete()` cancels the favour's own game (`stop_owner`) the moment it is paid; `drop()`
##        does the same for a favour abandoned before that.
##      * hand-in is the ordinary favour talk: `is_ready_to_turn_in` is true once `progress >= count`,
##        `complete()` pays like any other favour.
## Every other favour type, reward, marker and gift behaves exactly as it did before this section.

## "stardust_shard" was removed from this list on 2026-09-11 (lead, end of Phase 1). Phase 1 builder D
## took the shards off home, hub and grig - the only worlds that grew them - and they have no shop
## price, so a "bring N stardust shards" favor could never be finished: a soft-lock found by the
## Phase 1 integration check. Stardust now comes from helping neighbours (docs/CORE_LOOP.md).
const MATERIALS: PackedStringArray = ["moon_flower", "crystal_chunk", "gear_bit"]
const FETCH_MIN := 2
const FETCH_MAX := 4
const BRING_MIN := 2
const BRING_MAX := 3
const REWARD_STARDUST_MIN := 60
const REWARD_STARDUST_MAX := 140
const FRIENDSHIP_ON_COMPLETE := 2
const SPAWN_CLEARANCE := 0.8
const SPAWN_RADIUS_M := 9.0
const NODE_NAME := "FavorSystem"
## Loaded by path, never by class_name (see the header) - a build missing ProjectSystem simply never
## gates or offers a "play" favour, exactly as world.gd falls back for it today.
const PROJECT_SYSTEM_PATH := "res://src/projects/project_system.gd"
## Phase 6 pacing number (docs/CORE_LOOP.md "Visits and favours"): chance an eligible, ungated
## neighbour has a favour on a given game day. Free to retune; nothing else depends on the value.
const FAVOR_CHANCE := 0.5
## Phase 6 pacing number: share of a neighbour's favours, once their mini-game is unlocked, that ask
## to play it again instead of an ordinary fetch/bring/deliver errand.
const PLAY_FAVOR_CHANCE := 1.0 / 3.0

## Trust tiers (docs/ARCHITECTURE.md §11), on top of GameState's 0-100 friendship value. Separate
## from NpcData.tier_for()'s 0-2/3-5/6+ greeting tiers on purpose — those are tuned for how fast
## dialogue should vary and would make "best friend" trivial to hit; these gate real rewards, so they
## sit higher up the same scale.
const TRUST_PAL := 15
const TRUST_BEST_FRIEND := 30
## +% reward stardust once a neighbour trusts you at each tier.
const PAL_STARDUST_BONUS := 0.2
const BEST_FRIEND_STARDUST_BONUS := 0.4
## One-time signature gift each neighbour hands over the first time they hit "best friend" — always
## granted instead of the usual random reward roll, and never again after (GameState.flags gates it).
## Every id here must exist in the Catalog with a real scene, or the block at `_award()` grants a
## decoration the player can never place. Fen and Grig take the two remaining price-0 legendaries:
## the Gravity Well Fountain for the pan of mirror pools, the Ring-Planet Globe for the ringed world.
## Vela takes the Whisper Array, which was ADDED for her: the four legendaries above were already
## spoken for, and a neighbour missing from this dict is skipped in silence at `_award()` — her
## "thanks" line promised a gift the system had no item for.
const SIGNATURE_REWARD := {
	"zorp": "deco_wish_star", "bolt": "deco_robot_dog",
	"fen": "deco_gravity_fountain", "grig": "deco_ring_globe",
	"vela": "deco_whisper_array",
}

var _rng := RandomNumberGenerator.new()
var _planet: Planet
var _forced_template: String = ""


## Finds the world's FavorSystem, creating it under /root/World the first time.
static func get_or_create() -> FavorSystem:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var host: Node = tree.root.get_node_or_null("World")
	if host == null:
		host = tree.current_scene
	if host == null:
		host = tree.root
	var existing := host.get_node_or_null(NODE_NAME)
	if existing is FavorSystem:
		return existing as FavorSystem
	var fs := FavorSystem.new()
	fs.name = NODE_NAME
	host.add_child(fs)
	return fs


func _ready() -> void:
	_rng.randomize()
	EventBus.item_added.connect(_on_item_added)
	EventBus.collectible_picked.connect(_on_collectible_picked)
	EventBus.planet_loaded.connect(_on_planet_loaded)
	# "play" favours ride the same MinigameSystem every other mini-game host uses. MinigameSystem is
	# core, always-shipped infrastructure (ProjectSystem itself calls it by class_name), unlike
	# ProjectSystem which is looked up by path above - see the header.
	var games := MinigameSystem.get_or_create()
	if games != null:
		games.progress_changed.connect(_on_minigame_progress)
		games.finished.connect(_on_minigame_finished)
	_restore()


# ============================================================================= queries
## The NPC's active favor, or {} when they have none.
func active_favor_for(npc_id: String) -> Dictionary:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("npc", "")) == npc_id and str(f.get("state", "")) == "active":
			return f
	return {}


## An active delivery addressed *to* this NPC (they are the recipient), or {}.
func delivery_for(npc_id: String) -> Dictionary:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active" or str(f.get("type", "")) != "deliver":
			continue
		if str(f.get("deliver_to", "")) == npc_id:
			return f
	return {}


## True when this NPC may offer a new favor: no active favour, their project (if they have one) is
## done or the campaign is off, and today's roll passed - see `_would_offer_today` and the header.
func can_offer(npc_id: String) -> bool:
	if not active_favor_for(npc_id).is_empty():
		return false
	return _would_offer_today(npc_id)


## True when the goods are in hand (or the delivery has arrived, or the mini-game is finished) and the
## favor can be turned in.
func is_ready_to_turn_in(favor: Dictionary) -> bool:
	if favor.is_empty():
		return false
	var kind := str(favor.get("type", ""))
	if kind == "deliver":
		return false        # completed by talking to the recipient, not the giver
	if kind == "play":
		return int(favor.get("progress", 0)) >= int(favor.get("count", 1))
	return GameState.item_count(str(favor.get("target_item", ""))) >= int(favor.get("count", 1))


## True when this neighbour should be showing the "!" marker: they can offer a favour, they have one
## ready to hand in, or a gift addressed to them is in the player's bag. One pass over GameState
## .favors instead of the three `active_favor_for` / `is_ready_to_turn_in` / `delivery_for` calls the
## marker used to make every 0.45 s per NPC.
func has_marker(npc_id: String) -> bool:
	var has_active := false
	var ready := false
	var gift_in_bag := false
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active":
			continue
		var kind := str(f.get("type", ""))
		if str(f.get("npc", "")) == npc_id:
			has_active = true
			if kind != "deliver" and is_ready_to_turn_in(f):
				ready = true
		elif kind == "deliver" and str(f.get("deliver_to", "")) == npc_id:
			if GameState.has_item(str(f.get("target_item", ""))):
				gift_in_bag = true
	if ready or gift_in_bag:
		return true
	if has_active:
		return false
	return _would_offer_today(npc_id)


## Short human-readable lines for the HUD / quest log, e.g. "Bolt: 2/3 Gear Bits".
func active_favors_summary() -> Array[String]:
	var out: Array[String] = []
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active":
			continue
		var who := _npc_name(str(f.get("npc", "")))
		var kind := str(f.get("type", ""))
		if kind == "deliver":
			out.append("%s: deliver a gift to %s" % [who, _npc_name(str(f.get("deliver_to", "")))])
		elif kind == "play":
			out.append("%s: play %s (%d/%d)" % [who, _game_title(f),
				mini(int(f.get("progress", 0)), int(f.get("count", 1))), int(f.get("count", 1))])
		else:
			out.append("%s: %d/%d %s" % [who, mini(int(f.get("progress", 0)), int(f.get("count", 1))),
				int(f.get("count", 1)), _item_name(str(f.get("target_item", "")), int(f.get("count", 1)))])
	return out


# ============================================================================= offering
## Builds (but does not commit) a favor for this NPC. Returns {} when nothing sensible is available.
func make_offer(npc_id: String) -> Dictionary:
	var data := NpcData.get_data(npc_id)
	if data.is_empty():
		return {}
	# MINI-GAME FAVOURS (header §3): about one in three, once a game of theirs is unlocked.
	var play_entry := _pick_minigame_entry(npc_id)
	var want_play := not play_entry.is_empty() and (_forced_template == "play" \
		or (_forced_template == "" and _rng.randf() < PLAY_FAVOR_CHANCE))
	if want_play:
		return _make_play_offer(npc_id, play_entry)
	var kinds := _templates_for(npc_id)
	if kinds.is_empty():
		return {}
	var kind: String = kinds[_rng.randi_range(0, kinds.size() - 1)]
	if _forced_template != "" and kinds.has(_forced_template):
		kind = _forced_template
	var favor := {
		"id": "%s_d%d_%d" % [npc_id, GameState.day_count, _rng.randi_range(100, 999)],
		"npc": npc_id,
		"type": kind,
		"target_item": "",
		"count": 1,
		"progress": 0,
		"state": "offered",
		"reward_item": "",
		"reward_stardust": _rng.randi_range(REWARD_STARDUST_MIN, REWARD_STARDUST_MAX),
		"deliver_to": "",
	}
	match kind:
		"fetch":
			favor["target_item"] = _local_collectible(npc_id)
			favor["count"] = _rng.randi_range(FETCH_MIN, FETCH_MAX)
		"bring":
			favor["target_item"] = _foreign_material(npc_id)
			favor["count"] = _rng.randi_range(BRING_MIN, BRING_MAX)
		"deliver":
			var target := _delivery_target(npc_id)
			if target == "":
				return {}
			favor["deliver_to"] = target
			favor["target_item"] = "gift_%s" % npc_id
			favor["count"] = 1
	return favor


## The NPC's own words for this offer, with the item and count filled in.
func request_lines(favor: Dictionary) -> Array:
	var npc_id := str(favor.get("npc", ""))
	var kind := str(favor.get("type", "fetch"))
	if kind == "play":
		return _play_request_lines(favor)
	var raw := NpcData.favor_lines(npc_id, kind)
	var count := int(favor.get("count", 1))
	var out: Array = []
	for line: Variant in raw:
		var text := str(line)
		if text.contains("%d") and text.contains("%s"):
			out.append(text % [count, _item_name(str(favor.get("target_item", "")), count)])
		elif text.contains("%s"):
			out.append(text % _npc_name(str(favor.get("deliver_to", ""))))
		else:
			out.append(text.replace("%%", "%"))
	return out


## Commits an offer: stores it, toasts, plays the accept sting, hands over the gift for deliveries.
func accept(favor: Dictionary) -> void:
	if favor.is_empty():
		return
	var npc_id := str(favor.get("npc", ""))
	var kind := str(favor.get("type", ""))
	favor["state"] = "active"
	if kind == "play":
		favor["owner"] = "favor:%s:%d" % [npc_id, GameState.day_count]
		favor["progress"] = 0
	elif kind != "deliver":
		favor["progress"] = mini(GameState.item_count(str(favor["target_item"])), int(favor["count"]))
	GameState.favors[str(favor["id"])] = favor
	GameState.npc_data(npc_id)["last_favor_day"] = GameState.day_count
	EventBus.favor_offered.emit(str(favor["id"]), npc_id)
	EventBus.favor_accepted.emit(str(favor["id"]))
	AudioManager.play_sfx("quest_accept")
	if kind == "deliver":
		_hand_over_gift(favor)
		EventBus.toast_requested.emit("Deliver the gift to %s" % _npc_name(str(favor["deliver_to"])), str(favor["target_item"]))
	elif kind == "play":
		_start_play_game(GameState.favors[str(favor["id"])])
		EventBus.toast_requested.emit("New favour: play %s with %s" % [_game_title(favor), _npc_name(npc_id)], "stardust_shard")
	else:
		_spawn_fetch_targets(favor)
		EventBus.toast_requested.emit("New favour: %d %s" % [int(favor["count"]),
			_item_name(str(favor["target_item"]), int(favor["count"]))], str(favor["target_item"]))


## DEBUG/TEST hook (used by tests/director/*.json): pins every following offer to one template, so an
## automated play-through is deterministic. Pass "" to go back to random. Ignored unless a Director
## timeline is running, so a stray call can never rig favours in a real save.
func debug_force_template(kind: String) -> void:
	if not Director.is_active():
		push_warning("FavorSystem.debug_force_template ignored: no Director timeline is running")
		return
	_forced_template = kind


## Deprecated name, kept because existing tests/director/*.json timelines call it. Same gate.
func force_template(kind: String) -> void:
	debug_force_template(kind)


## DEBUG/TEST hook: builds and immediately accepts an offer for `npc_id`, skipping the dialogue UI -
## for a Director timeline exercising a favour's own mechanics (a "play" favour's mini-game, say)
## without scripting a whole conversation. Same Director-only gate as `debug_force_template`.
func debug_offer_and_accept(npc_id: String) -> Dictionary:
	if not Director.is_active():
		push_warning("FavorSystem.debug_offer_and_accept ignored: no Director timeline is running")
		return {}
	var offer := make_offer(npc_id)
	if not offer.is_empty():
		accept(offer)
	return offer


## DEBUG/TEST hook: turns in `npc_id`'s current active favour exactly as a hand-in talk would, with no
## live DialogueRunner needed. Same Director-only gate.
func debug_complete_active(npc_id: String) -> void:
	if not Director.is_active():
		push_warning("FavorSystem.debug_complete_active ignored: no Director timeline is running")
		return
	var favor := active_favor_for(npc_id)
	if not favor.is_empty():
		complete(favor)


## DEV HOOK (Phase 5, HOOKS - docs/PHASE5_SPEC.md, no Director required, unlike the debug_* pair above
## which stays Director-gated for the old npc_favor_save / crit_fav_save timelines): builds and accepts
## an offer of exactly `kind` ("fetch" | "bring" | "deliver" | "play") for `npc_id`, replacing whatever
## favour they already had active so every kind can be tested on demand. Reuses `_forced_template` /
## `make_offer` under the hood (toggled and restored, so it never leaks into a later random offer) -
## the same mechanism the Director-only hook already trusts. Returns a status string; "" is never
## returned, so the dev menu always has something to show.
func dev_offer_and_accept(npc_id: String, kind: String) -> String:
	if NpcData.get_data(npc_id).is_empty():
		return "%s is not a neighbour" % npc_id
	if not ["fetch", "bring", "deliver", "play"].has(kind):
		return "unknown favour kind '%s'" % kind
	var existing := active_favor_for(npc_id)
	if not existing.is_empty():
		drop(str(existing.get("id", "")))
	var saved := _forced_template
	_forced_template = kind
	var offer := make_offer(npc_id)
	_forced_template = saved
	if offer.is_empty() or str(offer.get("type", "")) != kind:
		return "%s has no '%s' favour available right now (e.g. no valid delivery target)" % [_npc_name(npc_id), kind]
	accept(offer)
	return "%s: new %s favour accepted" % [_npc_name(npc_id), kind]


## DEV HOOK (Phase 5, HOOKS, no Director required): fills in exactly what `is_ready_to_turn_in` needs
## for `npc_id`'s active favour - the missing collect items, or a play favour's progress to its full
## count - then pays it out through the real `complete()`, exactly as a hand-in talk would. Never
## invents anything `complete()` itself does not already check, so this never desyncs from a normal
## playthrough's own reward roll, trust bonus or signature-gift logic.
func dev_complete_active(npc_id: String) -> String:
	var favor := active_favor_for(npc_id)
	if favor.is_empty():
		return "%s has no active favour" % _npc_name(npc_id)
	var kind := str(favor.get("type", ""))
	match kind:
		"play":
			favor["progress"] = int(favor.get("count", 1))
			GameState.favors[str(favor["id"])] = favor
		"deliver":
			if not GameState.has_item(str(favor.get("target_item", ""))):
				GameState.add_item(str(favor.get("target_item", "")))
		_:
			var item_id := str(favor.get("target_item", ""))
			var need := int(favor.get("count", 1)) - GameState.item_count(item_id)
			if need > 0:
				GameState.add_item(item_id, need)
	var result := complete(favor)
	var extra := (", +%s" % str(result.get("item_name", ""))) if str(result.get("item_name", "")) != "" else ""
	return "%s: favour paid out (+%d stardust%s)" % [_npc_name(npc_id), int(result.get("stardust", 0)), extra]


## Player said no: the NPC will not ask again today.
func decline(npc_id: String) -> void:
	GameState.npc_data(npc_id)["last_favor_day"] = GameState.day_count


## Cancels an active favour outright (not wired to any UI today; here so a future "give up" affordance
## or a debug tool has a clean single call). Stops the favour's own mini-game first, same as `complete`.
func drop(favor_id: String) -> void:
	var favor: Dictionary = GameState.favors.get(favor_id, {})
	if favor.is_empty():
		return
	if str(favor.get("type", "")) == "play":
		_cancel_play_game(favor)
	GameState.favors.erase(favor_id)


# ============================================================================= completing
## Pays out a finished favor. Returns {"item_id", "item_name", "stardust"} for the thank-you lines.
func complete(favor: Dictionary, npc: Node = null) -> Dictionary:
	var npc_id := str(favor.get("npc", ""))
	var kind := str(favor.get("type", "fetch"))
	var item_id := str(favor.get("target_item", ""))
	var count := int(favor.get("count", 1))
	if kind == "deliver":
		GameState.remove_item(item_id, 1)
		var player := _player()
		if player != null and player.has_method("set_carry_item"):
			player.call("set_carry_item", "")
	elif kind == "play":
		_cancel_play_game(favor)
	else:
		GameState.remove_item(item_id, count)

	# Trust tier is read BEFORE this completion's own friendship bump, so the bonus reflects
	# standing trust rather than the favour that just happened to tip it over.
	var trust_before := int(GameState.npc_data(npc_id).get("friendship", 0))

	var reward: Dictionary = Catalog.random_reward_decoration(_rng)
	var reward_id := str(reward.get("id", "")) if not reward.is_empty() else ""
	var reward_name := str(reward.get("name", "")) if not reward.is_empty() else ""
	var stardust := int(favor.get("reward_stardust", REWARD_STARDUST_MIN))
	if reward_id != "":
		GameState.add_item(reward_id)
	else:
		stardust += 40        # no decoration catalogue yet: pay in stardust instead
	if trust_before >= TRUST_BEST_FRIEND:
		stardust = int(round(stardust * (1.0 + BEST_FRIEND_STARDUST_BONUS)))
	elif trust_before >= TRUST_PAL:
		stardust = int(round(stardust * (1.0 + PAL_STARDUST_BONUS)))
	GameState.add_stardust(stardust)
	GameState.add_friendship(npc_id, FRIENDSHIP_ON_COMPLETE)
	var trust_after := int(GameState.npc_data(npc_id).get("friendship", 0))
	GameState.npc_data(npc_id)["favors_done"] = int(GameState.npc_data(npc_id).get("favors_done", 0)) + 1

	favor["state"] = "done"
	GameState.favors.erase(str(favor.get("id", "")))
	EventBus.favor_completed.emit(str(favor.get("id", "")), reward_id, stardust)
	AudioManager.play_sfx("quest_complete")
	if reward_id != "":
		EventBus.toast_requested.emit("You got a %s!" % reward_name, reward_id)
	EventBus.toast_requested.emit("+%d Stardust" % stardust, "stardust_shard")

	# One-time signature gift the first time trust crosses "best friend" — on top of the usual
	# reward roll above, not instead of it.
	var signature_id := str(SIGNATURE_REWARD.get(npc_id, ""))
	var signature_flag := "signature_unlocked_%s" % npc_id
	if signature_id != "" and trust_after >= TRUST_BEST_FRIEND and not GameState.flag(signature_flag):
		GameState.set_flag(signature_flag)
		GameState.add_item(signature_id)
		var signature_name := str(Catalog.get_item(signature_id).get("name", signature_id))
		EventBus.toast_requested.emit("%s trusts you completely! Bonus: %s" % [_npc_name(npc_id), signature_name], signature_id)

	if npc != null and npc.has_method("play_emote"):
		npc.call("play_emote", "happy")
	var player2 := _player()
	if player2 != null and player2.has_method("play_emote"):
		player2.call("play_emote", "happy")
	return {"item_id": reward_id, "item_name": reward_name, "stardust": stardust}


# ============================================================================= progress
func _on_item_added(item_id: String, _count: int) -> void:
	refresh_progress(item_id)


func _on_collectible_picked(kind: String, _world_pos: Vector3) -> void:
	refresh_progress(kind)


## Recomputes progress for every active favour that wants `item_id`, straight from the inventory, and
## toasts when the number changed. Deliberately idempotent: item_added and collectible_picked both
## fire for one pickup, and running twice must not double-count.
func refresh_progress(item_id: String) -> void:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		var kind := str(f.get("type", ""))
		if str(f.get("state", "")) != "active" or kind == "deliver" or kind == "play":
			continue
		if str(f.get("target_item", "")) != item_id:
			continue
		var target := int(f.get("count", 1))
		var before := int(f.get("progress", 0))
		var now := mini(GameState.item_count(item_id), target)
		if now == before:
			continue
		f["progress"] = now
		EventBus.favor_progress.emit(key, now, target)
		if now <= before:
			continue
		if now >= target:
			EventBus.toast_requested.emit("Favour ready: talk to %s" % _npc_name(str(f.get("npc", ""))), item_id)
		else:
			EventBus.toast_requested.emit("%d/%d %s" % [now, target, _item_name(item_id, target)], item_id)


func _on_planet_loaded(_planet_id: String) -> void:
	_planet = null
	_restore()


## Re-registers runtime gift items, re-spawns fetch targets, and resumes a "play" favour's mini-game
## (if its world is the one just loaded) after a planet load / save load.
func _restore() -> void:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active":
			continue
		var kind := str(f.get("type", ""))
		if kind == "deliver":
			_register_gift_item(str(f.get("npc", "")))
			if GameState.has_item(str(f.get("target_item", ""))):
				var player := _player()
				if player != null and player.has_method("set_carry_item"):
					player.call("set_carry_item", str(f.get("target_item", "")))
		elif kind == "play":
			_start_play_game(f)
		else:
			_spawn_fetch_targets(f)


# ============================================================================= pacing (header §1, §2)
## True while `npc_id` still has a project running during the campaign story - see the header §1.
## Looked up BY PATH so a build missing project_system.gd never gates a favour (it just has none to
## gate: `definition_for` would not exist to call).
static func _project_unfinished(npc_id: String) -> bool:
	if not CampaignData.gates_on() or not ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		return false
	var ps: Variant = load(PROJECT_SYSTEM_PATH)
	if not (ps is GDScript) or not (ps as GDScript).has_method("definition_for"):
		return false
	if ((ps as GDScript).call("definition_for", npc_id) as Dictionary).is_empty():
		return false          # no project at all (the Commons crowd) - never gated
	return not bool((GameState.projects.get(npc_id, {}) as Dictionary).get("done", false))


## True on a game day this neighbour is even allowed to roll for a favour: not the same day one was
## already asked or declined (`last_favor_day`, unchanged meaning), and not the day right after one
## was - so an offer never lands on two game days running. `last_favor_day == 0` is "never yet", not
## "day 0" (GameState.day_count starts at 1), so day 1 is never mistaken for a repeat.
static func _day_eligible(npc_id: String) -> bool:
	var last := int(GameState.npc_data(npc_id).get("last_favor_day", 0))
	if last >= GameState.day_count:
		return false
	if last > 0 and last == GameState.day_count - 1:
		return false
	return true


## Deterministic pass/fail for (npc_id, day): seeded from `hash()` of the pair, never the system's own
## live `_rng`, so it reads the same after a save and a fresh-process reload on the same day. The same
## pattern `_spawn_fetch_targets` already uses to keep favour spawn points stable across a reload.
static func _day_roll_passes(npc_id: String, day: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [npc_id, day])
	return rng.randf() < FAVOR_CHANCE


## Combines §1 and §2: whether `npc_id` would have a favour to offer today, ignoring whether one is
## already active (callers check that separately - `can_offer`, `has_marker`).
func _would_offer_today(npc_id: String) -> bool:
	if _project_unfinished(npc_id):
		return false
	if not _day_eligible(npc_id):
		return false
	return _day_roll_passes(npc_id, GameState.day_count)


# ============================================================================= minigame favours (§3)
## Every unlocked mini-game step of this neighbour's that this build can actually start, from
## ProjectSystem.played_minigames() (looked up by path, see the header). Filtered by
## `MinigameSystem.has_game` because a step may name a kind that is registered in
## `MinigameSystem.GAMES` before its script exists (docs on that const) - such a step must never be
## offered as a favour that can't actually start.
static func _minigame_entries_for(npc_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		return out
	var ps: Variant = load(PROJECT_SYSTEM_PATH)
	if not (ps is GDScript) or not (ps as GDScript).has_method("played_minigames"):
		return out
	for entry: Variant in ((ps as GDScript).call("played_minigames") as Array):
		var e := entry as Dictionary
		if str(e.get("npc", "")) == npc_id and MinigameSystem.has_game(str(e.get("game", ""))):
			out.append(e)
	return out


func _pick_minigame_entry(npc_id: String) -> Dictionary:
	var entries := _minigame_entries_for(npc_id)
	if entries.is_empty():
		return {}
	return entries[_rng.randi_range(0, entries.size() - 1)]


## Builds an unaccepted "play" favour from a `played_minigames()` entry. `owner` is filled in by
## `accept()`, once the day it starts on is known.
func _make_play_offer(npc_id: String, entry: Dictionary) -> Dictionary:
	return {
		"id": "%s_d%d_%d" % [npc_id, GameState.day_count, _rng.randi_range(100, 999)],
		"npc": npc_id,
		"type": "play",
		"target_item": "",
		"count": maxi(1, int(entry.get("count", 1))),
		"progress": 0,
		"state": "offered",
		"reward_item": "",
		"reward_stardust": _rng.randi_range(REWARD_STARDUST_MIN, REWARD_STARDUST_MAX),
		"deliver_to": "",
		"game": str(entry.get("game", "")),
		"game_planet": str(entry.get("planet", npc_id)),
		"game_config": (entry.get("config", {}) as Dictionary).duplicate(true),
		"owner": "",
	}


static func _play_request_lines(favor: Dictionary) -> Array:
	var npc_id := str(favor.get("npc", ""))
	var raw := NpcData.favor_lines(npc_id, "play")
	if not raw.is_empty():
		return raw.duplicate()
	return ["Fancy another round of %s?" % _game_title(favor)]


static func _game_title(favor: Dictionary) -> String:
	var cfg: Dictionary = favor.get("game_config", {})
	var t := str(cfg.get("title", ""))
	return t if t != "" else str(favor.get("game", "")).capitalize()


## Finds the running game's owner among GameState.favors, or {}. Used both to write progress back
## (`_on_minigame_progress`) and to recognise our own game ending (`_on_minigame_finished`).
static func _play_favor_for_owner(owner_id: String) -> Dictionary:
	if owner_id == "":
		return {}
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("type", "")) == "play" and str(f.get("owner", "")) == owner_id:
			return f
	return {}


## The active, not-yet-met "play" favour whose game belongs on the CURRENT planet, or {}.
func _active_play_favor_on_current_planet() -> Dictionary:
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		if str(f.get("state", "")) != "active" or str(f.get("type", "")) != "play":
			continue
		if int(f.get("progress", 0)) >= int(f.get("count", 1)):
			continue          # already met - waiting on the hand-in talk, no game needed
		if str(f.get("game_planet", "")) != GameState.current_planet_id:
			continue
		return f
	return {}


## Starts (or resumes) a "play" favour's mini-game, resuming from its saved `progress`. A no-op off
## this favour's own world, and YIELDS rather than fighting for the slot: it never calls
## MinigameSystem.start() while a DIFFERENT owner's game is already running (a Commons replay, or a
## project step) - see the header §3. `_on_minigame_finished` retries this once that other game ends.
func _start_play_game(favor: Dictionary) -> void:
	if str(favor.get("game_planet", "")) != GameState.current_planet_id:
		return
	var games := MinigameSystem.get_or_create()
	if games == null:
		return
	var owner_id := str(favor.get("owner", ""))
	if games.is_running() and games.running_owner() != owner_id:
		return
	var cfg: Dictionary = (favor.get("game_config", {}) as Dictionary).duplicate(true)
	cfg["count"] = int(favor.get("count", 1))
	cfg["done"] = int(favor.get("progress", 0))
	cfg["owner"] = owner_id
	games.start(str(favor.get("game", "")), cfg)


## Cancels a "play" favour's game, but only if it is the one actually running right now.
static func _cancel_play_game(favor: Dictionary) -> void:
	var games := MinigameSystem.find()
	if games != null and games.is_running() and games.running_owner() == str(favor.get("owner", "")):
		games.stop_owner(str(favor.get("owner", "")), "favour ended")


## MinigameSystem.progress_changed: writes progress into whichever favour owns the running game (the
## host, per MinigameSystem's own contract, is responsible for persisting it - not the `finished`
## signal, which can be missed).
func _on_minigame_progress(_kind: String, done: int, total: int) -> void:
	var games := MinigameSystem.find()
	if games == null:
		return
	var favor := _play_favor_for_owner(games.running_owner())
	if favor.is_empty():
		return
	if total > 0:
		favor["count"] = total
	favor["progress"] = mini(done, int(favor["count"]))
	GameState.favors[str(favor["id"])] = favor
	EventBus.favor_progress.emit(str(favor["id"]), int(favor["progress"]), int(favor["count"]))


## MinigameSystem.finished: either OUR OWN favour's game just ended (toast + mark ready on success;
## a cancel needs nothing more, progress up to the last tick is already saved), or someone else's did
## and it is time to try resuming any play favour waiting on this world (header §3's "yields").
func _on_minigame_finished(_kind: String, success: bool, cfg: Dictionary) -> void:
	var own_favor := _play_favor_for_owner(str(cfg.get("owner", "")))
	if not own_favor.is_empty():
		if success:
			own_favor["progress"] = int(own_favor.get("count", 1))
			GameState.favors[str(own_favor["id"])] = own_favor
			EventBus.favor_progress.emit(str(own_favor["id"]), int(own_favor["progress"]), int(own_favor["count"]))
			EventBus.toast_requested.emit("Favour ready: talk to %s" % _npc_name(str(own_favor.get("npc", ""))), "stardust_shard")
		return
	var waiting := _active_play_favor_on_current_planet()
	if not waiting.is_empty():
		_start_play_game(waiting)


# ============================================================================= helpers
func _templates_for(npc_id: String) -> Array:
	var out: Array = ["bring"]
	if _local_collectible(npc_id) != "":
		out.append("fetch")
	if _delivery_target(npc_id) != "":
		out.append("deliver")
	return out


## The collectible that grows on this NPC's own planet (their `fetch` errand).
func _local_collectible(npc_id: String) -> String:
	var pid := str(NpcData.get_data(npc_id).get("planet", ""))
	var data := _planet_data(pid)
	if data == null:
		return ""
	# Scrap is a counter (GameState.scrap), not a bag item - collectible.gd skips add_item() for it -
	# so item_count("scrap") stays 0 and a fetch for scrap could never finish. Since Phase 1 home and
	# the hub grow ONLY scrap, so without this filter every hub neighbour's fetch was a soft-lock, and
	# 1 in 5 fetches on the other worlds too. A planet with nothing else offers no fetch at all.
	var kinds: Array = []
	for k: String in data.collectible_kind.split(",", false):
		var kind := k.strip_edges()
		if kind != "" and kind != "scrap":
			kinds.append(kind)
	if kinds.is_empty():
		return ""
	return str(kinds[_rng.randi_range(0, kinds.size() - 1)])


## A material that does *not* grow where this NPC lives, so `bring` means a trip.
func _foreign_material(npc_id: String) -> String:
	var local := _local_collectible(npc_id)
	var pool: Array = []
	for m: String in MATERIALS:
		if m != local:
			pool.append(m)
	if pool.is_empty():
		# Unreachable with three MATERIALS. Never fall back to stardust_shard: no world grows it now.
		return MATERIALS[0]
	return str(pool[_rng.randi_range(0, pool.size() - 1)])


## Another known neighbour, preferring one on a different planet (that is the point of a delivery).
func _delivery_target(npc_id: String) -> String:
	var home := str(NpcData.get_data(npc_id).get("planet", ""))
	var far: Array = []
	var near: Array = []
	for other: String in NpcData.ids():
		if other == npc_id:
			continue
		var p := str(NpcData.get_data(other).get("planet", ""))
		if p == home:
			near.append(other)
		else:
			far.append(other)
	if not far.is_empty():
		return str(far[_rng.randi_range(0, far.size() - 1)])
	if not near.is_empty():
		return str(near[_rng.randi_range(0, near.size() - 1)])
	return ""


## Registers "gift_<npc>" in the Catalog at runtime and puts it in the player's hands.
func _hand_over_gift(favor: Dictionary) -> void:
	var npc_id := str(favor.get("npc", ""))
	var item_id := _register_gift_item(npc_id)
	GameState.add_item(item_id)
	var player := _player()
	if player != null and player.has_method("set_carry_item"):
		player.call("set_carry_item", item_id)


func _register_gift_item(npc_id: String) -> String:
	var item_id := "gift_%s" % npc_id
	if not Catalog.has_item(item_id):
		var who := _npc_name(npc_id)
		Catalog.register({
			"id": item_id,
			"name": "%s's Gift" % who,
			"kind": "favor_item",
			"category": "material",
			"rarity": "common",
			"price": 0,
			"desc": "A wrapped parcel from %s. Do not shake it." % who,
			"icon_color": str(NpcData.get_data(npc_id).get("accent", "#ffe27a")),
		})
	return item_id


## Scatters extra collectibles of the favour's kind near the NPC so the errand is always finishable.
func _spawn_fetch_targets(favor: Dictionary) -> void:
	if str(favor.get("type", "")) != "fetch":
		return
	var kind := str(favor.get("target_item", ""))
	var pid := str(NpcData.get_data(str(favor.get("npc", ""))).get("planet", ""))
	if pid != GameState.current_planet_id:
		return
	var planet := _find_planet()
	if planet == null or planet.collectibles_root == null:
		return
	var needed := int(favor.get("count", 1)) - int(favor.get("progress", 0))
	if needed <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([str(favor.get("id", "")), GameState.day_count])
	var home: Vector3 = _home_dir(str(favor.get("npc", "")), planet)
	for i in needed + 1:
		var spawn_id := "favor_%s_%d" % [str(favor.get("id", "")), i]
		if Collectible.was_picked_today(pid, spawn_id):
			continue
		if planet.collectibles_root.has_node("Collectible_" + spawn_id):
			continue
		var dir := planet.find_free_dir_near(rng, home, SPAWN_RADIUS_M, SPAWN_CLEARANCE, 40)
		if dir == Vector3.ZERO:
			dir = planet.find_free_dir(rng, SPAWN_CLEARANCE, 40, true)
		if dir == Vector3.ZERO:
			continue
		var c := Collectible.new()
		c.setup(kind, spawn_id, pid)
		c.transform = planet.surface_transform(dir, Vector3.FORWARD)
		planet.collectibles_root.add_child(c)


func _home_dir(npc_id: String, planet: Planet) -> Vector3:
	var d := NpcData.get_data(npc_id)
	var hd: Variant = d.get("home_dir", Vector3.UP)
	var v: Vector3 = hd if hd is Vector3 else Vector3.UP
	var building := str(d.get("building", ""))
	if building != "" and planet.has_method("building_dir"):
		var bd: Vector3 = planet.building_dir(building)
		if bd != Vector3.ZERO:
			v = bd
	return v.normalized()


func _find_planet() -> Planet:
	if _planet != null and is_instance_valid(_planet):
		return _planet
	var p := get_tree().get_first_node_in_group("planet")
	_planet = p as Planet
	return _planet


func _planet_data(planet_id: String) -> PlanetData:
	if planet_id == "":
		return null
	var path := "res://src/planet/data/%s.tres" % planet_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as PlanetData


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


static func _npc_name(npc_id: String) -> String:
	var d := NpcData.get_data(npc_id)
	return str(d.get("display_name", npc_id.capitalize()))


## "3 Gear Bits" / "1 Gear Bit" — the plural is only added when the catalogue has no plural of its own.
static func _item_name(item_id: String, count: int) -> String:
	var def := Catalog.get_item(item_id)
	var base := str(def.get("name", item_id.capitalize().replace("_", " ")))
	if count > 1 and not base.ends_with("s"):
		return base + "s"
	return base


# ============================================================================= QA
## One line a Director timeline or a critic can assert against. Prints only.
##   {"t": 8, "call": {"node": "/root/World/FavorSystem", "method": "debug_report", "args": ["tag"]}}
func debug_report(tag: String = "") -> void:
	var rows: Array = []
	for key: String in GameState.favors:
		var f: Dictionary = GameState.favors[key]
		rows.append("%s(%s,%s,%s,%d/%d,item=%s,owner=%s)" % [key, f.get("npc", ""), f.get("type", ""),
			f.get("state", ""), int(f.get("progress", 0)), int(f.get("count", 1)),
			f.get("target_item", ""), f.get("owner", "")])
	print("FAVORS %s day=%d %s" % [tag, GameState.day_count, ", ".join(rows)])
