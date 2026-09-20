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
	{"id": "npc_job_zorp", "q": "Fellow human, what does Zorp collect?",
		"answers": ["Facts about Earth", "Old bolts", "Falling stars"], "needs": {"met": ["zorp"]}},
	# ND zorp.intro: "I am Zorp. I collect facts about Earth."
	{"id": "npc_job_bolt", "q": "Fellow human, what does Bolt count, endlessly?",
		"answers": ["Bolts", "Stars", "Footsteps"], "needs": {"met": ["bolt"]}},
	# ND bolt.intro: "I have counted 4,181 bolts. So far."
	{"id": "npc_job_fen", "q": "Fellow human, how does Fen spend the day?",
		"answers": ["Watching the pools", "Counting stars", "Selling clothes"], "needs": {"met": ["fen"]}},
	# ND fen.intro: "I am Fen. I watch the pools. That is the work."
	{"id": "npc_job_grig", "q": "Fellow human, what does Grig spend all day cutting?",
		"answers": ["Steps", "Ribbons", "Wires"], "needs": {"met": ["grig"]}},
	# ND grig.intro: "I am Grig. I cut the steps. All of them."
	{"id": "npc_job_vela", "q": "Fellow human, what does Vela keep on her world?",
		"answers": ["The sky array", "A herd of goats", "A radio station"], "needs": {"met": ["vela"]}},
	# ND vela.intro: "I am Vela. I keep the array and its records."
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
	{"id": "npc_saying_pip", "q": "Fellow human, how many antennae does Pip have?",
		"answers": ["One", "Two", "Three"], "needs": {"met": ["pip"]}},
	# ND pip.small_talk: "One antenna. Best antenna. Fact."
	{"id": "npc_saying_pop", "q": "Fellow human, how many antennae does Pop have?",
		"answers": ["Two", "One", "None"], "needs": {"met": ["pop"]}},
	# ND pop.intro: "Two antennae. Double the listening!"
	{"id": "npc_family_pop", "q": "Fellow human, Pop is Pip's what?",
		"answers": ["Brother", "Cousin", "Boss"], "needs": {"met": ["pip", "pop"]}},
	# ND pip.intro: "That's my brother Pop. He has two antennae."
	{"id": "npc_saying_stella", "q": "Finish Stella's line: visor tints are the new ___",
		"answers": ["Hemlines", "Sunglasses", "Footwear"], "needs": {"met": ["stella"]}},
	# ND stella.small_talk: "Visor tints are the new hemlines."
	{"id": "npc_saying_nova", "q": "Finish DJ Nova's rule two: there are no rules, rule two is ___",
		"answers": ["Dance", "Silence", "Naps"], "needs": {"met": ["dj_nova"]}},
	# ND dj_nova.intro: "Rule one: there are no rules. Rule two: dance."
	{"id": "npc_saying_bolt", "q": "Fellow human, about how many bolts has Bolt counted?",
		"answers": ["4,181", "212", "904"], "needs": {"met": ["bolt"]}},
	# ND bolt.intro: "I have counted 4,181 bolts. So far." (literal numeral in source)
	{"id": "npc_saying_grig", "q": "Fellow human, about how many steps has Grig cut?",
		"answers": ["904", "4,181", "9,000"], "needs": {"met": ["grig"]}},
	# ND grig.intro: "Nine hundred and four. I number every one." (904 = nine hundred and four)
	{"id": "npc_saying_vela", "q": "Fellow human, how many hours of sky has Vela logged?",
		"answers": ["Nine thousand", "Nine hundred", "Ninety"], "needs": {"met": ["vela"]}},
	# ND vela.intro: "Nine thousand hours of sky, all of it filed."
	{"id": "npc_saying_fen", "q": "Fellow human, how many years of notes has Fen kept?",
		"answers": ["Nine", "Four", "Twelve"], "needs": {"met": ["fen"]}},
	# ND fen.intro: "Nine years of notes. Pool four moved. Twice."
	{"id": "npc_saying_professor", "q": "Fellow human, about how many stars has the Professor named?",
		"answers": ["212", "904", "4,181"], "needs": {"met": ["mayor_orbit"]}},
	# ND mayor_orbit.small_talk: "I've named 212 stars. I forget which ones."

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

	# ---- ship parts (CampaignData.PARTS, fitting order) -----------------------------------------
	{"id": "part_name_zorp", "q": "Fellow human, what is the ship part from Zorp's world?",
		"answers": ["Zorp Coil", "Bolt Gear", "Fen Cell"], "needs": {"parts": 1}},
	{"id": "part_name_bolt", "q": "Fellow human, what is the ship part from Bolt's world?",
		"answers": ["Bolt Gear", "Zorp Coil", "Grig Valve"], "needs": {"parts": 2}},
	{"id": "part_name_fen", "q": "Fellow human, what is the ship part from Fen's world?",
		"answers": ["Fen Cell", "Vela Core", "Bolt Gear"], "needs": {"parts": 3}},
	{"id": "part_name_grig", "q": "Fellow human, what is the ship part from Grig's world?",
		"answers": ["Grig Valve", "Fen Cell", "Zorp Coil"], "needs": {"parts": 4}},
	{"id": "part_name_vela", "q": "Fellow human, what is the last ship part called?",
		"answers": ["Vela Core", "Grig Valve", "Bolt Gear"], "needs": {"parts": 5}},
	{"id": "part_order_first", "q": "Fellow human, which ship part gets fitted first?",
		"answers": ["Zorp Coil", "Vela Core", "Grig Valve"], "needs": {"parts": 1}},
	{"id": "part_order_last", "q": "Fellow human, which ship part gets fitted last?",
		"answers": ["Vela Core", "Zorp Coil", "Bolt Gear"], "needs": {"parts": 5}},
	# CD CampaignData.PARTS, in array order: part_zorp, part_bolt, part_fen, part_grig, part_vela.

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

	# ---- the skiff, after the story only -----------------------------------------------------------
	{"id": "skiff_gift", "q": "Fellow human, what do your friends give you after the story?",
		"answers": ["A skiff", "A new rocket", "A trophy"], "needs": {"story": true}},
	{"id": "skiff_replaces", "q": "Fellow human, what does the skiff stand in for on every pad?",
		"answers": ["The rocket", "The telescope", "The mini-game"], "needs": {"story": true}},
	# src/rocket/rocket_model.gd: `const LOOK_SKIFF := "skiff"`; header: "'skiff' is the friends' gift
	# after the story"; `look()`/`set_look(s)` take "rocket" or "skiff", the two things it stands in
	# for on the pad (model_height() 3.2 for the rocket, 2.3 for the skiff).
]

## ============================================================================ picking
## True when `q`'s "needs" are met by the CURRENT GameState (NORM_SPEC §5).
static func _eligible(q: Dictionary) -> bool:
	var needs: Dictionary = q.get("needs", {})
	for npc_id in needs.get("met", []):
		if not GameState.flag("met_%s" % npc_id):
			return false
	if needs.has("parts") and GameState.rocket_part_count() < int(needs["parts"]):
		return false
	if bool(needs.get("story", false)) and not GameState.story_done:
		return false
	return true

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
		var answers: Array = (q["answers"] as Array).duplicate()
		var correct: String = str(answers[0])
		var shown := _shuffled(answers, rng)
		var correct_index: int = shown.find(correct)
		var chosen: int = await runner.ask(npc, str(q["q"]), shown, ARM_DELAY)
		if chosen != correct_index:
			await runner.say(npc, [str(_LINES.WRONG.pick_random())])
			return false
		await runner.say(npc, [str(_LINES.RIGHT.pick_random())])
	return true
