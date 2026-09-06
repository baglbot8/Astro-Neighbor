class_name Conversation
extends RefCounted
## The whole "press E on a neighbour" flow, in one coroutine:
##
##   first meeting            -> introduction (3 lines)
##   first talk of the day    -> friendship-tier greeting (tracked per day in npc_data.talk_day)
##   then exactly one branch:
##     a gift is being delivered TO them   -> they open it, you get the reward
##     they have an active favour          -> progress nudge, or thanks + reward when it's done
##     they can offer a favour             -> a little small talk, the request, Yes / Maybe later
##     otherwise                           -> one line of small talk (never the previous one)
##   20 % chance of +1 friendship on any talk.
##
## A plain talk is two boxes (greeting + small talk); only favours go longer, per docs/STYLE_GUIDE.md.

const FRIENDSHIP_CHANCE := 0.20
const TIME_LINE_CHANCE := 0.25
const DECO_LINE_CHANCE := 0.20
const ACCEPT_OPTION := "Sure!"
const DECLINE_OPTION := "Maybe later"
const ASK_PROMPT := "Lend a hand?"


## Runs one full conversation. Awaits until the dialogue box closes.
## Refuses to start while another conversation is open: the DialogueBox is a single shared node, so
## a second concurrent caller would interleave its lines into the box the first one is still using.
static func run(npc: NPC, player: Node3D) -> void:
	var runner := DialogueRunner.get_or_create(npc)
	if runner == null:
		return
	if runner.is_active():
		push_warning("Conversation.run(%s) ignored: a conversation is already open" % npc.npc_id)
		return
	var favors := FavorSystem.get_or_create()
	var npc_id := npc.npc_id
	var state := GameState.npc_data(npc_id)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	runner.begin(npc, player)

	# ---- introduction / greeting -----------------------------------------------------------
	var met_flag := "met_%s" % npc_id
	if not GameState.flag(met_flag):
		GameState.set_flag(met_flag)
		var intro: Array = NpcData.get_data(npc_id).get("intro", [])
		if not intro.is_empty():
			await runner.say(npc, intro)
		npc.play_emote("wave")
	elif int(state.get("talk_day", -1)) != GameState.day_count:
		# first talk of this in-game day (GameState only carries a bool, so the day is tracked here)
		state["talk_day"] = GameState.day_count
		state["talked_today"] = true
		await runner.say(npc, [NpcData.greeting(npc_id, int(state.get("friendship", 0)), rng)])

	# ---- exactly one content branch --------------------------------------------------------
	if favors != null:
		var delivery := favors.delivery_for(npc_id)
		var active := favors.active_favor_for(npc_id)
		if not delivery.is_empty() and GameState.has_item(str(delivery.get("target_item", ""))):
			await _receive_gift(runner, npc, favors, delivery)
		elif not active.is_empty():
			if favors.is_ready_to_turn_in(active):
				await _hand_in(runner, npc, favors, active)
			else:
				await _progress(runner, npc, favors, active, rng)
		elif favors.can_offer(npc_id):
			await _offer(runner, npc, favors, rng)
		else:
			await _small_talk(runner, npc, rng)
	else:
		await _small_talk(runner, npc, rng)

	# ---- a talk sometimes warms them up ----------------------------------------------------
	if rng.randf() < FRIENDSHIP_CHANCE:
		GameState.add_friendship(npc_id, 1)
		AudioManager.play_sfx("friendship_up", -8.0)

	runner.finish()


# ============================================================================= branches
static func _small_talk(runner: DialogueRunner, npc: NPC, rng: RandomNumberGenerator) -> void:
	await runner.say(npc, [_flavour_line(npc, rng)])


## One line of colour: usually small talk, sometimes about the hour or the player's decorating.
static func _flavour_line(npc: NPC, rng: RandomNumberGenerator) -> String:
	var npc_id := npc.npc_id
	var roll := rng.randf()
	var line := ""
	if roll < TIME_LINE_CHANCE:
		line = NpcData.time_line(npc_id, GameState.time_of_day, rng)
	elif roll < TIME_LINE_CHANCE + DECO_LINE_CHANCE:
		var placed: Array = GameState.placed_decorations.get("home", [])
		line = NpcData.decoration_line(npc_id, placed.size(), rng)
	if line == "" or line == npc.last_small_talk():
		line = NpcData.small_talk(npc_id, npc.last_small_talk(), rng)
	npc.set_last_small_talk(line)
	return line


static func _offer(runner: DialogueRunner, npc: NPC, favors: FavorSystem, rng: RandomNumberGenerator) -> void:
	var offer := favors.make_offer(npc.npc_id)
	if offer.is_empty():
		await _small_talk(runner, npc, rng)
		return
	await runner.say(npc, [_flavour_line(npc, rng)])
	await runner.say(npc, favors.request_lines(offer))
	var choice: int = await runner.ask(npc, ASK_PROMPT, [ACCEPT_OPTION, DECLINE_OPTION])
	if choice == 0:
		favors.accept(offer)
		npc.play_emote("happy")
		await runner.say(npc, [_accept_line(offer)])
	else:
		favors.decline(npc.npc_id)
		var decline_lines := NpcData.favor_lines(npc.npc_id, "decline")
		await runner.say(npc, [decline_lines[0] if not decline_lines.is_empty() else "Another time!"])


static func _accept_line(offer: Dictionary) -> String:
	if str(offer.get("type", "")) == "deliver":
		return "Wonderful! It is in your hands now."
	return "Wonderful! I will be right here."


static func _progress(runner: DialogueRunner, npc: NPC, _favors: FavorSystem, favor: Dictionary, rng: RandomNumberGenerator) -> void:
	var lines: Array = NpcData.favor_lines(npc.npc_id, "progress")
	var remind: Array = NpcData.favor_lines(npc.npc_id, "remind")
	var pool: Array = remind if (not remind.is_empty() and rng.randf() < 0.5) else lines
	var text := str(pool[rng.randi_range(0, pool.size() - 1)]) if not pool.is_empty() else "Still working on it?"
	var summary := ""
	if str(favor.get("type", "")) == "deliver":
		summary = "(A gift for %s is in your bag.)" % _name_of(str(favor.get("deliver_to", "")))
	else:
		summary = "(%d of %d so far.)" % [mini(int(favor.get("progress", 0)), int(favor.get("count", 1))), int(favor.get("count", 1))]
	await runner.say(npc, [text, summary])


static func _hand_in(runner: DialogueRunner, npc: NPC, favors: FavorSystem, favor: Dictionary) -> void:
	var thanks: Array = NpcData.favor_lines(npc.npc_id, "thanks")
	if not thanks.is_empty():
		await runner.say(npc, [str(thanks[0])])
	var reward := favors.complete(favor, npc)
	var closing: Array = []
	if thanks.size() > 1:
		closing.append(str(thanks[1]))
	closing.append(_reward_line(reward))
	await runner.say(npc, closing)


static func _receive_gift(runner: DialogueRunner, npc: NPC, favors: FavorSystem, favor: Dictionary) -> void:
	var lines: Array = NpcData.favor_lines(npc.npc_id, "gift")
	if lines.is_empty():
		lines = ["A parcel! For me? How lovely."]
	await runner.say(npc, lines)
	npc.play_emote("happy")
	var reward := favors.complete(favor, npc)
	await runner.say(npc, ["Here, take this for the trip.", _reward_line(reward)])


static func _reward_line(reward: Dictionary) -> String:
	var item := str(reward.get("item_name", ""))
	var dust := int(reward.get("stardust", 0))
	if item != "":
		return "(You got a %s and %d Stardust!)" % [item, dust]
	return "(You got %d Stardust!)" % dust


static func _name_of(npc_id: String) -> String:
	return str(NpcData.get_data(npc_id).get("display_name", npc_id.capitalize()))
