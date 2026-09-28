class_name ProfessorAsk
extends RefCounted
## THE PROFESSOR'S FIRST TASK (docs/PLANET_SAFARI_SPEC.md 15.3, user ruling 2026-09-26). The flight
## that carried his old lantern-fish is retired (15.1), so his task moved onto the planets: "when you
## visit a neighbour, photograph them for my records, and bring it to me at the Commons". It still ends
## where you meet him in person (the user's 2026-09-22 ruling, docs/STORY_SPINE_SPEC.md 2.5).
##
## Static functions only, no autoload - same shape as `PhotoAsks`/`CampaignData`/`NormQuiz`. The task
## is OPENED by `src/onboarding/intro_director.gd` (his radio call, `_campaign_call` -> `open_task()`),
## and this file is the only place that ever closes it.
##
## THE ROUTE (docs/PLANET_SAFARI_SPEC.md 17.2 item 2): `Conversation.run` -> `ProfessorAsk.handles
## (npc_id)` -> `ProfessorAsk.run(runner, npc, first_meeting)`. `handles()` is the gate (mayor_orbit,
## the task open - a photo need not be in hand); `run()` is the whole talk either way - the hand-in
## (delighted, a thank-you payment ONCE, the task closes) with a photo, the reminder without one, and
## never a favour or the planet-safari offer that talk. `ready()` (photo already in hand) still gates
## one narrower thing: whether `conversation.gd` skips its generic stranger intro on his first meeting.
##
## STATE, in GameState.flags (plain flags, saved with everything else):
##   OPEN_FLAG  "professor_neighbour_photo_open"  - true from the radio call until he is paid
##   DONE_FLAG  "professor_photo_done"            - true once he has paid, forever. The SAME key the
##              lantern-fish task used, on purpose: a save that already delivered the lantern-fish was
##              paid for his first task, and must not be asked (or paid) again.
##
## MET WHEN (15.3): the journal holds ANY neighbour photo. Read through the SkyJournal autoload's own
## API (`friend_ids()`: every neighbour with a favourite photo kept - the Friends/Neighbours page), never
## by writing to it; sky_journal.gd is another builder's file. See `neighbour_photo_id`.

const NPC_ID := "mayor_orbit"
## The retired flight task's sight id. Kept only so an old save can be recognised and migrated.
const OLD_ASK_ID := "lantern_fish"
## The old name of the same constant, for any caller that still reads it.
const ASK_ID := OLD_ASK_ID

## Set the moment `run()` pays out; see the header. Read by `intro_director.gd::_campaign_call` so the
## dev menu's "replay call" can never re-open and re-pay a task that is already done.
const DONE_FLAG := "professor_photo_done"
## Set by the radio call (`open_task`), cleared by `run()` (and never re-set once DONE_FLAG is).
const OPEN_FLAG := "professor_neighbour_photo_open"

## THE PAYMENT, unchanged from the lantern-fish task (a modest thank-you, not an economy change; paid in
## STARDUST - the lead's 2026-09-22 unit fix). Spec 15.3 names the number: 15 stardust, once.
const PROFESSOR_PAY := 15


## Opens the task. Called by the radio call; a no-op once he has been paid (the dev menu's replay).
static func open_task() -> void:
	migrate_old_ask()
	if GameState.flag(DONE_FLAG):
		return
	GameState.set_flag(OPEN_FLAG)


static func is_open() -> bool:
	migrate_old_ask()
	return GameState.flag(OPEN_FLAG) and not GameState.flag(DONE_FLAG)


## AN OLD SAVE (spec 15.3 "migrated cleanly, no stuck state"). A save made after his radio call but
## before he was paid holds the retired sky ask `PhotoAsks["lantern_fish"]` with "by": "professor".
## With the space safari off that sight can never be photographed, so the ask would sit open for ever.
## It is removed here and turned into the new task - the same promise (bring him a photo at the
## Commons), now one the player can keep. A save that already has DONE_FLAG just loses the stale ask.
## Idempotent and cheap: called from every gate below and on every world load (intro_director `_ready`).
static func migrate_old_ask() -> void:
	if str(PhotoAsks.get_ask(OLD_ASK_ID).get("by", "")) != "professor":
		return
	PhotoAsks.remove(OLD_ASK_ID)
	if not GameState.flag(DONE_FLAG):
		GameState.set_flag(OPEN_FLAG)
	print("[ProfessorAsk] migrated the old lantern-fish ask -> neighbour-photo task (open=%s done=%s)" % [
		str(GameState.flag(OPEN_FLAG)), str(GameState.flag(DONE_FLAG))])


## True only when THIS talk should be handed to `run()` instead of the Professor's usual talk: it is
## him, his task is open, and the journal already holds a neighbour photo. Still used at
## `conversation.gd` ~76 (and only there) to decide whether the generic stranger `intro` is skipped on
## his first meeting - it is, only when a photo is already in hand, because only then does `run()`'s
## own first line stand in for it (see that comment). See `handles()` for the talk-wide gate.
static func ready(npc_id: String) -> bool:
	if npc_id != NPC_ID:
		return false
	if not is_open():
		return false
	return has_neighbour_photo()


## True whenever THIS TALK belongs to the Professor's task - him, and the task open - whether or not a
## neighbour photo is in hand yet (docs/PLANET_SAFARI_SPEC.md 17.2 item 2, part b). Replaces `ready()`
## as the gate at `conversation.gd` ~94: with a photo, `run()` does the hand-in; without one, it gives
## the 5.2 reminder instead - and either way that is the WHOLE talk, never a favour and never the
## planet-safari offer (the user's 2026-09-27 report: he said nothing at all with the task open and no
## photo in hand, so a random favour or the safari offer could follow instead).
static func handles(npc_id: String) -> bool:
	if npc_id != NPC_ID:
		return false
	return is_open()


static func has_neighbour_photo() -> bool:
	return neighbour_photo_id() != ""


## The npc id of the neighbour whose photo he takes ("" when the journal holds none): the first one
## kept. Reads the SkyJournal autoload's public `friend_ids()`; falls back to the saved flag that same
## autoload writes (`GameState.flags["planet_journal"]` - its "friends", then any kept record whose kind
## is "neighbour", then any kept record of a subject whose OWN WORLD ROSTER carries "friend": "<npc>" -
## docs/PLANET_SAFARI_SPEC.md 17.2 item 2a: Bolt's own tune-up (an "event", not a "neighbour" kept
## record) counts as a photo of Bolt, and this also covers a save that already holds one, no re-take
## needed) for a bare probe with no autoload in the tree. Never writes anything.
static func neighbour_photo_id() -> String:
	var journal := _journal()
	if journal != null and journal.has_method("friend_ids"):
		var ids: Variant = journal.call("friend_ids")
		if ids is Array and not (ids as Array).is_empty():
			return str((ids as Array)[0])
	var blob: Variant = GameState.flags.get("planet_journal", {})
	if blob is Dictionary:
		var friends: Variant = (blob as Dictionary).get("friends", {})
		if friends is Dictionary and not (friends as Dictionary).is_empty():
			return str((friends as Dictionary).keys()[0])
		var recs: Variant = (blob as Dictionary).get("records", {})
		if recs is Dictionary:
			for k in (recs as Dictionary):
				var r: Variant = (recs as Dictionary)[k]
				if r is Dictionary and str((r as Dictionary).get("kind", "")) == "neighbour":
					# "<planet>:<id>" - a neighbour subject's id is its npc id.
					return str(k).get_slice(":", 1)
			for k in (recs as Dictionary):
				var friend_id := _roster_friend(str(k))
				if friend_id != "":
					return friend_id
	return ""


## The "friend" a world's own safari roster names for kept-record key "<planet>:<subject_id>" - "" for
## an ordinary creature or event (no such key on its roster entry) or a planet with no safari at all.
## Reads `PlanetSafari.manifest()` (public, static, another builder's file) rather than duplicating its
## per-world roster tables here.
static func _roster_friend(key: String) -> String:
	var planet_id := key.get_slice(":", 0)
	var subject_id := key.get_slice(":", 1)
	if planet_id == "" or subject_id == "":
		return ""
	var roster: Variant = PlanetSafari.manifest(planet_id).get("roster", [])
	if not (roster is Array):
		return ""
	for entry: Variant in roster:
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == subject_id:
			return str((entry as Dictionary).get("friend", ""))
	return ""


## The whole talk. Caller (`Conversation.run`) has already checked `handles()` and ends the
## conversation right after this returns, whether that was a hand-in or the reminder below - never a
## favour and never the planet-safari offer, that talk (docs/PLANET_SAFARI_SPEC.md 17.2 item 2).
## `first_meeting`: the player has never met him face to face before this talk (conversation.gd skips
## its generic stranger intro when `ready()` too, so this names him instead - see that comment).
static func run(runner: DialogueRunner, npc: NPC, first_meeting: bool = false) -> void:
	var who_id := neighbour_photo_id()
	var lines: Array = []
	if first_meeting:
		if who_id == "":
			# NO PHOTO YET (round-2 fix, STORY_SPINE_SPEC.md 6.4 again): `ready()` is false here, so
			# `conversation.gd` ~76 already played the generic stranger `intro` - which is itself his
			# self-introduction ("Oh! Hello! ... I'm Professor Comet. / I watch the sky. / If it
			# twinkles, I've probably named it."). Repeating "Oh! Hello there — I'm Professor Comet."
			# here introduced him a second time in the same talk. Only the radio-voice reveal is new
			# information, so that is all this half keeps.
			lines.append("That crackly voice on the radio? That was me!")
		else:
			# WITH a photo already in hand, `ready()` is true, so `conversation.gd` skipped the
			# generic intro entirely - this line is his ONLY self-introduction, unchanged.
			lines.append("Oh! Hello there — I'm Professor Comet.\nThat crackly voice on the radio? That was me!")
		# THE METEOR, in person (docs/STORY_HOME_SPEC.md 5.2) - what the radio call already said, and
		# what it means here: everyone packing, nobody left behind, and where HE stands on it.
		lines.append_array([
			"Mind the boxes. Everyone's packing to leave.",
			"They'll all fly out together, once your ship is fixed.",
			"Nobody gets left behind. That's how it is here.",
			"Not me, though. I say that meteor can be pushed.",
		])
	if who_id == "":
		# THE REMINDER (docs/PLANET_SAFARI_SPEC.md 17.2 item 2 / STORY_HOME_SPEC.md 5.2): his task is
		# open and the journal holds no neighbour photo yet - a short reminder, never a favour and never
		# the safari offer, this talk (whether or not it is also his first meeting).
		lines.append_array([
			"Snapped a neighbour yet? On their own world, mind.",
			"Bring the photo here. I'll be charting.",
		])
		await runner.say(npc, lines)
		return
	var who := Journal.npc_name(who_id)
	lines.append("A photo of %s, for my records!\nDelightful. Simply delightful." % who)
	# WHY he wants it (the user, 2026-09-27: "im not sure why he needed the picture") - said once, right
	# after the thanks, so the ask is never left unexplained again.
	lines.append("I'm tracking that meteor. Every sky you photograph helps.")
	if _grade_of(who_id) == "Smudge":
		# The old task's gentle extra line for a soft photo (never mocking, one short box). It teaches
		# the same hold-to-focus the first safari's first pause teaches.
		lines.append("A touch soft, but I don't mind one bit.\nHold the shutter next time — let it settle.")
	await runner.say(npc, lines)
	npc.play_emote("happy")
	# Close the task BEFORE paying (the lantern-fish round's measured bug: a save between paying and
	# closing replayed the thanks on reload and paid twice). From here on a save sees the task done.
	GameState.set_flag(OPEN_FLAG, false)
	GameState.set_flag(DONE_FLAG)
	GameState.add_stardust(PROFESSOR_PAY)
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit("The Professor pays %d stardust for your photo!" % PROFESSOR_PAY, "stardust")
	print("[ProfessorAsk] paid %d stardust for a photo of %s (done=%s open=%s)" % [PROFESSOR_PAY, who_id,
		str(GameState.flag(DONE_FLAG)), str(GameState.flag(OPEN_FLAG))])
	await runner.say(npc, [
		"Here — for your trouble, and my thanks.",
		"Your neighbours will want pictures too, you know.\nKeep that camera handy.",
	])


# ============================================================================= helpers
## `/root/SkyJournal` is a node and this file is static-only, so it is reached through the main loop.
static func _journal() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null:
		return null
	return loop.root.get_node_or_null("SkyJournal")


## The grade of the kept neighbour photo, "" when unknown. Read-only, through `friend_record_for`.
static func _grade_of(npc_id: String) -> String:
	if npc_id == "":
		return ""
	var journal := _journal()
	if journal == null or not journal.has_method("friend_record_for"):
		return ""
	var rec: Variant = journal.call("friend_record_for", npc_id)
	if not (rec is Dictionary):
		return ""
	return str((rec as Dictionary).get("grade", ""))
