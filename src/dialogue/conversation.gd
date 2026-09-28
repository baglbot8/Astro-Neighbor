class_name Conversation
extends RefCounted
## The whole "press E on a neighbour" flow, in one coroutine:
##
##   first meeting            -> introduction (3 lines)
##   first talk of the day    -> friendship-tier greeting (tracked per day in npc_data.talk_day)
##   a light link that names them (project_system.gd "talk" step "npc") ALWAYS completes here next,
##                                unconditionally - see the comment at that call below
##   then exactly one branch:
##     a gift is being delivered TO them   -> they open it, you get the reward
##     they have an active favour          -> progress nudge, or thanks + reward when it's done
##     they can offer a favour             -> a little small talk, the request, Yes / Maybe later
##     otherwise                           -> one line of small talk (never the previous one)
##   20 % chance of +1 friendship on any talk.
##
## A plain talk is two boxes (greeting + small talk); only favours go longer, per docs/STYLE_GUIDE.md.
##
## A VISITOR is the one exception to all of the above (Phase 4, src/campaign/visitor_system.gd): a
## neighbour standing on the player's home world for today's visit. Every talk with them goes to the
## visit (its ask, progress, done and goodbye lines) through the NPC's `visit_host` - no introduction,
## no greeting, no light link, no project, no favour, no small talk and no random friendship. On their
## own world the same neighbour is not a visitor and talks exactly as before.

const FRIENDSHIP_CHANCE := 0.20
const TIME_LINE_CHANCE := 0.25
const DECO_LINE_CHANCE := 0.20
const ACCEPT_OPTION := "Sure!"
## HINTS (2026-09-21, src/sky/sky_hints.gd, checked first in `_flavour_line` below): a neighbour's
## rare-sighting hint is its own thing, in its own voice, not competing with the ordinary flavour
## pool for a roll. SkyHints.maybe_hint_line does its own internal chance check and returns "" on
## most talks, so this is a pass-through, never a second independent chance stacked on top.
const DECLINE_OPTION := "Maybe later"
const ASK_PROMPT := "Lend a hand?"
## Phase 2 (docs/BUILD_PLAN.md): builder E's project system. Loaded by path, not by class_name, so
## this file still parses before E's file exists - the hook below is inert until then.
const PROJECT_SYSTEM_PATH := "res://src/projects/project_system.gd"


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

	# ---- a visitor at your crash site talks about the visit and nothing else -----------------
	if npc.is_visitor() and npc.visit_host.has_method("handle_conversation"):
		await npc.visit_host.handle_conversation(runner, npc)
		runner.finish()
		return

	# ---- introduction / greeting -----------------------------------------------------------
	var met_flag := "met_%s" % npc_id
	var first_meeting := false
	if not GameState.flag(met_flag):
		GameState.set_flag(met_flag)
		first_meeting = true
		# SKIPPED for the Professor's own first meeting (S5 round 2, STORY_SPINE_SPEC.md 6.4): when
		# he already asked for this exact photo by radio and it is in hand, ProfessorAsk.run below
		# is his WHOLE first meeting - it names him and places him as the radio voice in one line.
		# Playing the generic stranger `intro` here first (his old "Oh! Hello! ... I'm Professor
		# Comet...") introduced him once, then ProfessorAsk.run introduced the radio call a second
		# time right before thanking the player - the defect 6.4 names word for word. This is a
		# REORDER (nothing plays before his own line), not an extra line stacked on top of it.
		if not (npc_id == ProfessorAsk.NPC_ID and ProfessorAsk.ready(npc_id)):
			var intro: Array = NpcData.get_data(npc_id).get("intro", [])
			if not intro.is_empty():
				await runner.say(npc, intro)
		npc.play_emote("wave")
	elif int(state.get("talk_day", -1)) != GameState.day_count:
		# first talk of this in-game day (GameState only carries a bool, so the day is tracked here)
		state["talk_day"] = GameState.day_count
		state["talked_today"] = true
		await runner.say(npc, [NpcData.greeting(npc_id, int(state.get("friendship", 0)), rng)])

	# ---- the Professor takes his photo task in person, right after any greeting -------------
	# S4 THE FIRST FLIGHT (docs/STORY_SPINE_SPEC.md 2.5) as amended by docs/PLANET_SAFARI_SPEC.md 17.2
	# item 2: the ONE hook this file gets for the whole feature - everything else about him lives in
	# src/campaign/professor_ask.gd. `ProfessorAsk.handles(npc_id)` is true for him whenever his task
	# is open, photo in hand or not - `run()` below does the hand-in with one, the reminder without,
	# and EITHER WAY that is the whole talk: never a favour, never the safari offer, this talk (the
	# user's 2026-09-27 report: with the task open and no photo, he said nothing at all, and something
	# else - a favour, small talk - filled the gap instead). `first_meeting` (S5 round 2, 6.4) tells him
	# this IS his first meeting - and the block above already SKIPPED the generic stranger `intro` for
	# `ready()`'s narrower case (a photo already in hand), so `ProfessorAsk.run` below is his whole
	# first meeting then: it names him and places him, not the player, as the voice on the radio, in one
	# line, instead of a generic intro followed by a second introduction right before his thanks.
	if ProfessorAsk.handles(npc_id):
		await ProfessorAsk.run(runner, npc, first_meeting)
		runner.finish()
		return

	# ---- ONE QUESTION PER TALK (docs/PLANET_SAFARI_SPEC.md 8.2) ------------------------------
	# The planet safari's offer below gives way to anything else this talk carries: a first meeting,
	# a project step (a light link completing here, or their own project), a gift, or any favour -
	# offered, nudged or handed in. `story_beat` records it; project steps are caught from the
	# EventBus signal both project paths emit, so this file does not reach into project_system.gd.
	var story_beat := first_meeting
	var steps_done := {"n": 0}
	var on_step := func(_owner_id: String, _step_i: int) -> void:
		steps_done["n"] = int(steps_done["n"]) + 1
	EventBus.project_step_completed.connect(on_step)

	# ---- a light link to this neighbour always completes here, unconditionally --------------
	# docs/CORE_LOOP.md "More mini-games, one per neighbour": a project step ELSEWHERE may name
	# this neighbour as who FINISHES it (project_system.gd STEP "talk" "npc"). Checked before
	# anything below - even a favour of theirs that is ready to hand in - so a live link never has
	# to wait a talk for something else to clear first; their own project, favour or gift below
	# still happens in this SAME talk, right after, exactly as if the link had not happened
	# (`complete_live_link` only speaks the link's own lines and returns - it never marks this
	# talk "handled").
	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var link_host = load(PROJECT_SYSTEM_PATH).get_or_create()
		if link_host != null and link_host.has_method("complete_live_link"):
			await link_host.complete_live_link(runner, npc)

	# ---- exactly one content branch --------------------------------------------------------
	# A neighbour's PROJECT comes first (Phase 2, docs/BUILD_PLAN.md). Wired by the lead ahead of
	# builder E, against the contract: ProjectSystem.get_or_create() (static) and
	# handle_conversation(runner, npc, player) -> bool. It returns true whenever this neighbour has an
	# active project - including "come back tomorrow" - so a random favor never competes with the
	# project for the same conversation (favor_system.can_offer has no campaign gate of its own).
	# Two things still go before the project, both from the Phase 2 checks:
	# - project_system.gd returns FALSE when a delivery gift for this neighbour is in the bag (builder
	#   E's one exception, accepted by the lead), so the delivery branch below must stay FIRST.
	# - a favour already accepted from this neighbour and ready to hand in: a project that starts later
	#   (a Phase 1 campaign save loaded by this build) would otherwise hold it for three game days.
	var project_handled := false
	var project_moved := false
	var active_now: Dictionary = favors.active_favor_for(npc_id) if favors != null else {}
	var favor_ready := not active_now.is_empty() and favors.is_ready_to_turn_in(active_now)
	if not favor_ready and ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var projects = load(PROJECT_SYSTEM_PATH).get_or_create()
		if projects != null and projects.has_method("handle_conversation"):
			var before := _project_mark(npc_id)
			project_handled = await projects.handle_conversation(runner, npc, player)
			# LEAD 2026-09-24 (PLANET_SAFARI_SPEC 9.2): the project claims EVERY talk, including its
			# "come back tomorrow" and "how's it going" nudges. Only a talk that MOVED the project - a
			# new project, a new ask, a step completed - is a story beat. Measured on the user's own
			# save (bolt step 1, not yet asked): every talk was a tomorrow-nudge and the safari was
			# never offered.
			project_moved = project_handled and _project_mark(npc_id) != before
	if project_moved:
		story_beat = true
	if project_handled:
		pass
	elif favors != null:
		var delivery := favors.delivery_for(npc_id)
		var active := favors.active_favor_for(npc_id)
		if not delivery.is_empty() and GameState.has_item(str(delivery.get("target_item", ""))):
			story_beat = true
			await _receive_gift(runner, npc, favors, delivery)
		elif not active.is_empty():
			# LEAD 2026-09-24 (PLANET_SAFARI_SPEC 9.1): only a hand-in is a story beat. A progress nudge
			# is not a question, and counting it blocked the safari offer for as long as a favour stayed
			# open (measured: accept Bolt's first favour, then 5 talks with no offer).
			if favors.is_ready_to_turn_in(active):
				story_beat = true
				await _hand_in(runner, npc, favors, active)
			else:
				await _progress(runner, npc, favors, active, rng)
		elif favors.can_offer(npc_id):
			if await _offer(runner, npc, favors, rng):
				story_beat = true
		else:
			await _small_talk(runner, npc, rng)
	else:
		await _small_talk(runner, npc, rng)
	if EventBus.project_step_completed.is_connected(on_step):
		EventBus.project_step_completed.disconnect(on_step)
	if int(steps_done["n"]) > 0:
		story_beat = true

	# ---- the planet safari (docs/PLANET_SAFARI_SPEC.md 5.2, 8.2) ---------------------------
	# THE ONE HOOK for the planet safari (builder P3): on their own world, the host neighbour asks
	# "Photo safari?" once per game day - and only in a talk that carried nothing else (`story_beat`
	# above: one question per talk). A talk that had a favour, a project step, a gift or a first
	# meeting ends without it; the next plain talk asks. Everything else - who hosts which planet, the
	# day flag, the lines, the start - lives in src/planet_safari/planet_safari.gd. Inert for every
	# other neighbour.
	if not story_beat:
		await PlanetSafari.offer_in_conversation(runner, npc)

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
	var hint_line := SkyHints.maybe_hint_line(npc_id, rng)
	if hint_line != "":
		return hint_line
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


## True when a favour was actually asked (false: nothing to offer, so it was plain small talk).
static func _offer(runner: DialogueRunner, npc: NPC, favors: FavorSystem, rng: RandomNumberGenerator) -> bool:
	var offer := favors.make_offer(npc.npc_id)
	if offer.is_empty():
		await _small_talk(runner, npc, rng)
		return false
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
	return true


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


## Where this neighbour's project stands: exists, step, asked, done. Two talks with the same mark did
## not move the project (docs/PLANET_SAFARI_SPEC.md 9.2).
static func _project_mark(npc_id: String) -> String:
	var st = GameState.projects.get(npc_id, null)
	if not (st is Dictionary):
		return "none"
	return "%s|%s|%s" % [st.get("step", -1), st.get("asked", false), st.get("done", false)]
