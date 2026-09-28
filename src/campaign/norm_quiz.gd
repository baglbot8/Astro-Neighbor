class_name NormQuiz
extends RefCounted
## Norm's question bank, picker and quiz runner (docs/NORM_SPEC.md §5, §9 "NQUIZ owns norm_quiz.gd").
## Static data + static functions only - never instance this. NSYS calls this by its global class
## name (NORM_SPEC §9 API: "static func pick(...)", "static func run(...)"), unlike norm_lines.gd
## which is deliberately class_name-free and loaded by path (see `_LINES` below).
##
## Every question: {"id": String, "q": String, "answers": [right, wrong, wrong], "needs": Dictionary}.
## `answers[0]` is ALWAYS the right one in the data; callers see it shuffled (`pick`/`run` both hand
## out a fresh, shuffled copy - the source order in QUESTIONS is never exposed to the player).
## `needs` gates a question on what THIS save has already seen, all optional:
##   "met": PackedStringArray   every id must have GameState.flag("met_<id>") true
##   "parts": int               GameState.rocket_part_count() must be >= this
##   "story": bool               true requires GameState.story_done; absent/false gates nothing
##
## `dynamic` (S4 round, THE ORDER BUG fix below): when set, "answers" is IGNORED - `_eligible`
## checks `_dynamic_known` instead of (or as well as) `needs`, and `_answers_for` builds the real
## three answers from THIS SAVE at ask time, never from a literal. One of "order_first",
## "order_last", or "part_of:<npc>" - see the ship-parts block below for why a fixed parts-count
## gate cannot answer any of these three shapes of question.
##
## SOURCES (NORM_SPEC §5: "every right answer is TRUE in the game's own data"): each answer below is
## a literal or structural fact from src/characters/npc_data.gd, the src/planet/data/*.tres files,
## src/campaign/campaign_data.gd, and the mini-game data (src/minigames/minigame_system.gd + the
## per-world project files under src/projects/data/). The comment on every question names its exact
## source; showcase/nquiz_source_check.gd (a throwaway probe, not shipped) loads those real files at
## runtime and checks every one, printing a PASS/FAIL count.
##
## Written in Norm's voice (NORM_SPEC §5: "Fellow human, which neighbour...") - see norm_lines.gd for
## everything else he says. Every "q" <= 90 characters, every answer <= 20, so the pills fit a phone
## (NORM_SPEC §5, checked by showcase/nquiz_lengths_probe.gd against a real 2556x1179 --ui=mobile frame).

const ARM_DELAY := 0.6

## `norm_lines.gd` is deliberately `class_name`-free (NORM_SPEC §9), so it is reached by path, the
## same pattern visitor_system.gd uses for visitor_lines.gd (`const DATA := preload(...)`).
const _LINES := preload("res://src/campaign/norm_lines.gd")

## ============================================================================ THE BANK (48 entries)
## Source-file legend used in the trailing comments: ND = src/characters/npc_data.gd (DATA[id][...]),
## PT = src/planet/data/<id>.tres, CD = src/campaign/campaign_data.gd (PARTS), MG = mini-game data
## (minigame_system.gd GAMES + src/projects/data/<npc>.gd definition()'s "game" field).
const QUESTIONS: Array[Dictionary] = [
	# ---- neighbours: names, homes -----------------------------------------------------------
	{"id": "npc_name_zorp", "q": "Fellow human, who lives in the Violet Hollow?",
		"answers": ["Zorp", "Bolt", "Fen"], "needs": {"met": ["zorp"]}},
	# ND: zorp.planet == "zorp"; PT zorp.tres display_name "Zorp's Violet Hollow".
	{"id": "npc_name_bolt", "q": "Fellow human, which neighbour keeps a chrome yard?",
		"answers": ["Bolt", "Grig", "Vela"], "needs": {"met": ["bolt"]}},
	# ND: bolt.planet == "bolt"; PT bolt.tres display_name "Bolt's Chrome Yard".

	# ---- neighbours: jobs ---------------------------------------------------------------------
	{"id": "npc_job_zorp", "q": "Fellow human, what does Zorp grow?",
		"answers": ["The glowing garden", "Old bolts", "Carved stairs"], "needs": {"met": ["zorp"]}},
	# ND zorp.intro: "I'm Zorp. I grow the glowing garden here."
	{"id": "npc_job_bolt", "q": "Fellow human, what does Bolt count, endlessly?",
		"answers": ["Bolts", "Stars", "Footsteps"], "needs": {"met": ["bolt"]}},
	# ND bolt.intro: "I have counted 4,181 bolts. So far."
	{"id": "npc_job_fen", "q": "Fellow human, how does Fen spend the day?",
		"answers": ["Sunbathing", "Counting stars", "Selling clothes"], "needs": {"met": ["fen"]}},
	# ND fen.small_talk: "Sunbathing is my job. I'm very good at it."
	{"id": "npc_job_grig", "q": "Fellow human, what does Grig spend all day carving?",
		"answers": ["Stairs", "Ribbons", "Wires"], "needs": {"met": ["grig"]}},
	# ND grig.intro: "I'm Grig. I carved the big stairs up this hill."
	{"id": "npc_job_vela", "q": "Fellow human, what do Vela's dishes hear?",
		"answers": ["Songs from far away", "A herd of goats", "A radio station"], "needs": {"met": ["vela"]}},
	# ND vela.intro: "I'm Vela. My dishes hear songs from far away."
	{"id": "npc_job_pip_pop", "q": "Fellow human, which two run Cosmo Depot together?",
		"answers": ["Pip and Pop", "Stella and Nova", "Grig and Fen"], "needs": {"met": ["pip", "pop"]}},
	# ND pip.intro: "Welcome to Cosmo Depot! I'm Pip!"; pop.intro: "...and that's our shop! I'm Pop!"
	{"id": "npc_job_stella", "q": "Fellow human, what shop does Stella run?",
		"answers": ["Suit-Up", "Cosmo Depot", "Town Hall"], "needs": {"met": ["stella"]}},
	# ND stella.intro: "I'm Stella. I run Suit-Up."
	{"id": "npc_job_nova", "q": "Fellow human, what does DJ Nova run in the Commons?",
		"answers": ["The beats", "The clothes shop", "The telescope"], "needs": {"met": ["dj_nova"]}},
	# ND dj_nova.intro: "I'm DJ Nova. I run the beats around here."
	{"id": "npc_job_professor", "q": "Fellow human, how does Professor Comet spend his time?",
		"answers": ["Watching the sky", "Running the town", "Selling suits"], "needs": {"met": ["mayor_orbit"]}},
	# ND mayor_orbit.intro: "I'm Professor Comet. I watch the sky."

	# ---- neighbours: looks and sayings ---------------------------------------------------------
	{"id": "npc_saying_pip", "q": "Fellow human, who drew the shop's star logo?",
		"answers": ["Pip", "Pop", "Stella"], "needs": {"met": ["pip"]}},
	# ND pip.small_talk: "Our star logo? I drew it. Mostly."
	{"id": "npc_saying_pop", "q": "Fellow human, what is Pop known for?",
		"answers": ["Great hugs", "Fast talk", "Loud singing"], "needs": {"met": ["pop"]}},
	# ND pop.intro: "I give great hugs. Ask anyone."
	{"id": "npc_family_pop", "q": "Fellow human, what does Pip call Pop?",
		"answers": ["Best friend", "Cousin", "Boss"], "needs": {"met": ["pip", "pop"]}},
	# ND pip.intro: "Pop's my best friend. He's the muscle."
	{"id": "npc_saying_stella", "q": "Fellow human, finish Stella's rule: ___ first, always.",
		"answers": ["Boots", "Hats", "Gloves"], "needs": {"met": ["stella"]}},
	# ND stella.small_talk: "Boots first. Everything else follows boots."
	{"id": "npc_saying_nova", "q": "Finish DJ Nova's rule two: there are no rules, rule two is ___",
		"answers": ["Dance", "Silence", "Naps"], "needs": {"met": ["dj_nova"]}},
	# ND dj_nova.intro: "Rule one: there are no rules. Rule two: dance."
	{"id": "npc_saying_bolt", "q": "Fellow human, about how many bolts has Bolt counted?",
		"answers": ["4,181", "212", "904"], "needs": {"met": ["bolt"]}},
	# ND bolt.intro: "I have counted 4,181 bolts. So far." (literal numeral in source)
	{"id": "npc_saying_grig", "q": "Fellow human, what does Grig say is older than your planet?",
		"answers": ["His chisel", "His boots", "His hat"], "needs": {"met": ["grig"]}},
	# ND grig.small_talk: "My chisel is older than your planet. Probably."
	{"id": "npc_saying_vela", "q": "Fellow human, what happens to Vela's glass in the cold?",
		"answers": ["Gets foggy", "Cracks", "Turns blue"], "needs": {"met": ["vela"]}},
	# ND vela.small_talk: "My glass gets foggy on cold mornings. Oops."
	{"id": "npc_saying_fen", "q": "Fellow human, how many moons does Fen's world have?",
		"answers": ["None", "One", "Two"], "needs": {"met": ["fen"]}},
	# ND fen.small_talk: "No moon here. Just me and my big, warm sun."
	{"id": "npc_saying_professor", "q": "Fellow human, what does the Professor keep a notebook of?",
		"answers": ["Falling stars", "Broken clocks", "Lost socks"], "needs": {"met": ["mayor_orbit"]}},
	# ND mayor_orbit.small_talk: "I keep a notebook of every falling star."

	# ---- worlds: names --------------------------------------------------------------------------
	{"id": "world_name_zorp", "q": "Fellow human, what is Zorp's world called?",
		"answers": ["Zorp's Violet Hollow", "Bolt's Chrome Yard", "Fen's Long Dusk"], "needs": {"met": ["zorp"]}},
	# PT zorp.tres display_name.
	{"id": "world_name_bolt", "q": "Fellow human, what is Bolt's world called?",
		"answers": ["Bolt's Chrome Yard", "Grig's Chalk Steps", "Vela's Still Frost"], "needs": {"met": ["bolt"]}},
	# PT bolt.tres display_name.
	{"id": "world_name_fen", "q": "Fellow human, what is Fen's world called?",
		"answers": ["Fen's Long Dusk", "Zorp's Violet Hollow", "The Commons"], "needs": {"met": ["fen"]}},
	# PT fen.tres display_name.
	{"id": "world_name_grig", "q": "Fellow human, what is Grig's world called?",
		"answers": ["Grig's Chalk Steps", "Vela's Still Frost", "Little Orbit"], "needs": {"met": ["grig"]}},
	# PT grig.tres display_name.
	{"id": "world_name_vela", "q": "Fellow human, what is Vela's world called?",
		"answers": ["Vela's Still Frost", "Fen's Long Dusk", "The Commons"], "needs": {"met": ["vela"]}},
	# PT vela.tres display_name.
	{"id": "world_name_hub", "q": "Fellow human, what is the neighbourhood hub called?",
		"answers": ["The Commons", "Little Orbit", "The Plaza"], "needs": {"met": ["mayor_orbit"]}},
	# PT hub.tres display_name.
	{"id": "world_name_home", "q": "Fellow human, what is your own home world called?",
		"answers": ["Little Orbit", "The Commons", "Home Base"], "needs": {}},
	# PT home.tres display_name. No gate: it is the player's own world, known from the start.

	# ---- ship parts (CampaignData.PARTS names a part per world; the FITTING ORDER is the
	# player's choice, not fixed - see THE ORDER BUG, found in the map) --------------------------
	# THE ORDER BUG. CampaignData.PARTS is listed in RANGE-TIER order (Zorp/Bolt tier 0, Fen/Grig
	# tier 2, Vela tier 4 - campaign_data.gd :10-13, :21-25), not the order any one save actually
	# FITS its parts in. Zorp and Bolt are both reachable from the very start, in either order;
	# Fen and Grig both unlock together at 2 parts, in either order too - only Vela is pinned last
	# (she needs 4 parts already fitted just to be reached). So a raw "parts >= N" gate cannot say
	# WHICH part that is: `part_order_first` assumed Zorp Coil ("needs": {"parts": 1}) and was
	# wrong the moment a save did Bolt's project first; `part_name_fen` assumed 3 fitted parts must
	# include Fen's ("needs": {"parts": 3}) and was wrong whenever the 3rd one fitted was Grig's
	# instead (both tier 2, either order).
	# THE FIX. Every one of these six questions is resolved from THIS SAVE's own fitted order
	# (`GameState.rocket_parts`, appended in fitting order by `GameState.fit_rocket_part` -
	# game_state.gd :96, :249-254 - not the order parts are RECEIVED, which `handle_conversation`
	# controls and the player does not) at ask time, through the "dynamic" key below - see
	# `_dynamic_known` (eligibility) and `_answers_for` (the actual answer). A question drops out
	# entirely, not just gets answered wrong, the moment the fact it asks is not yet knowable in
	# this save ("or drop it when it cannot be known" - the fix this round was asked to make). The
	# "answers" arrays below are UNUSED for these six ids, kept empty only so every QUESTIONS entry
	# has the same shape - `_answers_for` rebuilds real ones from the save and `CampaignData.PARTS`
	# every time, so nothing here can go stale the way the literals it replaces did.
	{"id": "part_name_zorp", "q": "Fellow human, what is the ship part from Zorp's world?",
		"answers": [], "needs": {}, "dynamic": "part_of:zorp"},
	{"id": "part_name_bolt", "q": "Fellow human, what is the ship part from Bolt's world?",
		"answers": [], "needs": {}, "dynamic": "part_of:bolt"},
	{"id": "part_name_fen", "q": "Fellow human, what is the ship part from Fen's world?",
		"answers": [], "needs": {}, "dynamic": "part_of:fen"},
	{"id": "part_name_grig", "q": "Fellow human, what is the ship part from Grig's world?",
		"answers": [], "needs": {}, "dynamic": "part_of:grig"},
	{"id": "part_name_vela", "q": "Fellow human, what is the last ship part called?",
		"answers": [], "needs": {}, "dynamic": "part_of:vela"},
	{"id": "part_order_first", "q": "Fellow human, which ship part gets fitted first?",
		"answers": [], "needs": {}, "dynamic": "order_first"},
	{"id": "part_order_last", "q": "Fellow human, which ship part gets fitted last?",
		"answers": [], "needs": {}, "dynamic": "order_last"},
	# CD CampaignData.PARTS: part_zorp/part_bolt/part_fen/part_grig/part_vela, each carrying its
	# own "npc" and "name" - the source `_part_name`/`_part_id_for_npc` below read from directly.

	# ---- mini-games (minigame_system.gd GAMES + src/projects/data/<npc>.gd "game") --------------
	{"id": "minigame_zorp", "q": "Fellow human, which mini-game plays on Zorp's world?",
		"answers": ["Rings", "Catch", "Hunt"], "needs": {"met": ["zorp"]}},
	{"id": "minigame_bolt", "q": "Fellow human, which mini-game plays on Bolt's world?",
		"answers": ["Catch", "Rings", "Guide"], "needs": {"met": ["bolt"]}},
	{"id": "minigame_fen", "q": "Fellow human, which mini-game plays on Fen's world?",
		"answers": ["Guide", "Hunt", "Call"], "needs": {"met": ["fen"]}},
	{"id": "minigame_grig", "q": "Fellow human, which mini-game plays on Grig's world?",
		"answers": ["Hunt", "Guide", "Catch"], "needs": {"met": ["grig"]}},
	{"id": "minigame_vela", "q": "Fellow human, which mini-game plays on Vela's world?",
		"answers": ["Call", "Rings", "Hunt"], "needs": {"met": ["vela"]}},
	{"id": "minigame_owner_catch", "q": "Fellow human, which world plays the 'catch' game?",
		"answers": ["Bolt's Chrome Yard", "Zorp's Violet Hollow", "Grig's Chalk Steps"], "needs": {"met": ["bolt"]}},
	{"id": "minigame_owner_hunt", "q": "Fellow human, which world plays the 'hunt' game?",
		"answers": ["Grig's Chalk Steps", "Fen's Long Dusk", "Vela's Still Frost"], "needs": {"met": ["grig"]}},
	# src/projects/data/<id>.gd definition()["steps"][*]["game"], matched to minigame_system.gd GAMES.

	# ---- the hub buildings -----------------------------------------------------------------------
	{"id": "hub_building_professor", "q": "Fellow human, which building is Professor Comet's home?",
		"answers": ["Town Hall", "Suit-Up", "Cosmo Depot"], "needs": {"met": ["mayor_orbit"]}},
	{"id": "hub_building_stella", "q": "Fellow human, which building does Stella call home?",
		"answers": ["Suit-Up", "Town Hall", "The event space"], "needs": {"met": ["stella"]}},
	{"id": "hub_building_nova", "q": "Fellow human, which building does DJ Nova call home?",
		"answers": ["The event space", "Town Hall", "Suit-Up"], "needs": {"met": ["dj_nova"]}},
	{"id": "hub_building_pip_pop", "q": "Fellow human, which shop do Pip and Pop call home?",
		"answers": ["Cosmo Depot", "Suit-Up", "Town Hall"], "needs": {"met": ["pip", "pop"]}},
	# ND: mayor_orbit/stella/dj_nova/pip/pop each carry "building": "town_hall"/"clothes_store"/
	# "event_space"/"deco_store"; names cross-checked against each npc's own intro line.

	# ---- the Professor, a little more ------------------------------------------------------------
	{"id": "professor_tool", "q": "Fellow human, which tool does Professor Comet keep oiling?",
		"answers": ["His telescope", "His scissors", "His radio"], "needs": {"met": ["mayor_orbit"]}},
	# ND mayor_orbit.small_talk: "I oil my telescope on Sundays. Tradition." / "A good telescope is
	# worth two maps."

	# ---- the fleet, after the story only (docs/STORY_HOME_SPEC.md §5.6, replacing skiff_gift and skiff_replaces)
	{"id": "fleet", "q": "Fellow human, what broke the meteor into a shower?",
		"answers": ["Every ship, together", "Your rocket, alone", "A very big net"], "needs": {"story": true}},
	{"id": "streak", "q": "Fellow human, how did the Professor track the meteor?",
		"answers": ["In your photos", "A letter from Bolt", "He tripped on it"], "needs": {"story": true}},
	# src/campaign/finale_lines.gd MEETING (the Professor: "That streak is in your photos from every world." /
	# "Put them together, and I can track its path.") and SEND ("6 ships, flying for all of us");
	# src/campaign/finale_launch.gd flies all six ships into the meteor before it breaks into the shower.
]

## ============================================================================ picking
## True when `q`'s "needs" are met by the CURRENT GameState (NORM_SPEC §5), AND, for a "dynamic"
## question (the part-order fix below), the fact it asks is actually knowable in this save yet.
static func _eligible(q: Dictionary) -> bool:
	var needs: Dictionary = q.get("needs", {})
	for npc_id in needs.get("met", []):
		if not GameState.flag("met_%s" % npc_id):
			return false
	if needs.has("parts") and GameState.rocket_part_count() < int(needs["parts"]):
		return false
	if bool(needs.get("story", false)) and not GameState.story_done:
		return false
	return _dynamic_known(q)


## The part id CampaignData.PARTS gives `npc_id`'s world, or "" if that is not one of the five.
static func _part_id_for_npc(npc_id: String) -> String:
	for p in CampaignData.PARTS:
		if str(p.get("npc", "")) == npc_id:
			return str(p.get("id", ""))
	return ""


## The player-facing name CampaignData.PARTS gives `part_id`, or `part_id` itself if that id is not
## one of the five (should not happen - defensive so a bad id degrades to something printable
## rather than crashing a live quiz).
static func _part_name(part_id: String) -> String:
	for p in CampaignData.PARTS:
		if str(p.get("id", "")) == part_id:
			return str(p.get("name", part_id))
	return part_id


## Is `q`'s "dynamic" fact knowable RIGHT NOW in this save? True for every ordinary (non-dynamic)
## question. THE ORDER BUG's fix lives here: "part_of:<npc>" only becomes true once that specific
## part has actually been obtained (received from the neighbour OR already fitted - the same two
## places `project_system.gd:867` already checks, so this reads the save the same way the rest of
## the campaign does), never from a raw parts count; "order_first" needs at least one part fitted;
## "order_last" needs every part fitted (only then is the LAST one fixed and knowable).
static func _dynamic_known(q: Dictionary) -> bool:
	var dyn := str(q.get("dynamic", ""))
	if dyn == "":
		return true
	if dyn == "order_first":
		return GameState.rocket_parts.size() >= 1
	if dyn == "order_last":
		return GameState.rocket_parts.size() >= CampaignData.PARTS.size()
	if dyn.begins_with("part_of:"):
		var pid := _part_id_for_npc(dyn.substr(8))
		return pid != "" and (GameState.has_item(pid) or GameState.rocket_parts.has(pid))
	return true


## The three shown answers for `q`: the literal table entry for an ordinary question, or, for a
## "dynamic" one, a FRESH correct answer read from `GameState.rocket_parts` (this save's own
## fitted order) plus two distractors from the other four part names, shuffled with the caller's
## `rng` so a seeded run stays reproducible (NORM_SPEC §5's own rule for `pick`, extended here to
## `run`). Empty when a dynamic fact is not (or is no longer) knowable - `run` skips that question
## rather than ask something it cannot answer; `_eligible`/`_dynamic_known` above should already
## have kept it out of `pick`'s result, so this is the belt to that braces, not the normal path.
static func _answers_for(q: Dictionary, rng: RandomNumberGenerator) -> Array:
	var dyn := str(q.get("dynamic", ""))
	if dyn == "":
		return (q["answers"] as Array).duplicate()
	var correct := ""
	if dyn == "order_first" and GameState.rocket_parts.size() >= 1:
		correct = _part_name(str(GameState.rocket_parts[0]))
	elif dyn == "order_last" and GameState.rocket_parts.size() >= CampaignData.PARTS.size():
		correct = _part_name(str(GameState.rocket_parts[-1]))
	elif dyn.begins_with("part_of:"):
		correct = _part_name(_part_id_for_npc(dyn.substr(8)))
	if correct == "":
		return []
	var distractors: Array = []
	for p in CampaignData.PARTS:
		var nm := str(p.get("name", ""))
		if nm != "" and nm != correct:
			distractors.append(nm)
	distractors = _shuffled(distractors, rng)
	if distractors.size() < 2:
		return []
	return [correct, distractors[0], distractors[1]]


static func _eligible_questions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for q in QUESTIONS:
		if _eligible(q):
			out.append(q)
	return out

## Fisher-Yates using the CALLER'S rng, so a seeded `pick` is reproducible - Array.shuffle() always
## draws from the engine's own global RNG and cannot be seeded this way.
static func _shuffled(arr: Array, rng: RandomNumberGenerator) -> Array:
	var out := arr.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out

## Picks `n` eligible questions this save has not seen since the bank was last reset, marks them
## seen, and returns them (NORM_SPEC §5 API). Never repeats until the eligible-and-unseen pool would
## drop below 3, at which point `norm_seen_q` resets FIRST and this pick draws from the full eligible
## set again. Deterministic for a given `rng` state (the caller, NormSystem, seeds it per day).
static func pick(rng: RandomNumberGenerator, n: int = 3) -> Array[Dictionary]:
	var eligible := _eligible_questions()
	if eligible.is_empty():
		return []
	var seen: Array = (GameState.flags.get("norm_seen_q", []) as Array).duplicate()
	var unseen: Array[Dictionary] = []
	for q in eligible:
		if not seen.has(q["id"]):
			unseen.append(q)
	if unseen.size() < 3:
		# Reset: only drop the ids that are still eligible today, so a seen id that is no longer
		# eligible (a need this save has not met yet) cannot linger and shrink tomorrow's pool.
		seen = []
		unseen = eligible.duplicate()
	var pool := _shuffled(unseen, rng)
	var take: int = mini(n, pool.size())
	var result: Array[Dictionary] = []
	for i in range(take):
		var q: Dictionary = pool[i]
		result.append(q)
		if not seen.has(q["id"]):
			seen.append(q["id"])
	GameState.flags["norm_seen_q"] = seen
	return result

## ============================================================================ running
## Asks 3 (or fewer, if the bank is thin) picked questions through `runner.ask`, each with the three
## answers shuffled and a 0.6 s arm delay (NORM_SPEC §4.3). A right answer gets a short RIGHT line
## and moves on; the FIRST wrong answer ends the quiz immediately with a WRONG line and no further
## question. Returns true only when every question asked was answered right. Does NOT show WIN/BYE
## or grant a reward - NormSystem does that after `run` returns (NORM_SPEC §4.4, §9).
static func run(runner: DialogueRunner, npc: Node3D) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var picked := pick(rng, 3)
	if picked.is_empty():
		return false
	for q in picked:
		var answers := _answers_for(q, rng)
		# Belt-and-braces (see `_answers_for`'s own header): `pick` already filtered through
		# `_eligible`/`_dynamic_known`, so this should never fire in play - but a dynamic fact
		# that stopped being knowable between pick and ask (nothing in this save can actually do
		# that today; NormSystem's own talk is uninterrupted) is skipped, never asked half-blind.
		if answers.size() < 3:
			continue
		var correct: String = str(answers[0])
		var shown := _shuffled(answers, rng)
		var correct_index: int = shown.find(correct)
		var chosen: int = await runner.ask(npc, str(q["q"]), shown, ARM_DELAY)
		if chosen != correct_index:
			await runner.say(npc, [str(_LINES.WRONG.pick_random())])
			return false
		await runner.say(npc, [str(_LINES.RIGHT.pick_random())])
	return true
