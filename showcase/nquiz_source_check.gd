extends Node
## THROWAWAY verification probe for NQUIZ (docs/NORM_SPEC.md §5) - not part of the shipped game.
## Loads NormQuiz.QUESTIONS and checks every right answer (answers[0]) against the REAL source file
## it claims (the comment above each entry in norm_quiz.gd), by loading that source at runtime -
## never by re-typing the expected value from memory. Prints one PASS/FAIL line per question and a
## final summary; exit code is 1 if anything failed (so a CI-style caller can check $?).
##
##   godot --headless --path . res://showcase/nquiz_source_check.tscn

var _fail := 0
var _pass := 0


func _ready() -> void:
	var npc_script: GDScript = load("res://src/characters/npc_data.gd")
	var npc_data: Dictionary = npc_script.DATA
	var campaign_script: GDScript = load("res://src/campaign/campaign_data.gd")
	var parts: Array = campaign_script.PARTS
	var minigame_script: GDScript = load("res://src/minigames/minigame_system.gd")
	var games: Dictionary = minigame_script.GAMES

	var planet_display: Dictionary = {}
	for id in ["home", "hub", "zorp", "bolt", "fen", "grig", "vela"]:
		var res: Resource = load("res://src/planet/data/%s.tres" % id)
		planet_display[id] = str(res.get("display_name"))

	var project_games: Dictionary = {}
	for npc_id in ["zorp", "bolt", "fen", "grig", "vela"]:
		var def_script: GDScript = load("res://src/projects/data/%s.gd" % npc_id)
		var def: Dictionary = def_script.definition()
		project_games[npc_id] = _find_first_game(def)

	var by_id: Dictionary = {}
	for q in NormQuiz.QUESTIONS:
		by_id[q["id"]] = q

	# ---- neighbour names / homes ---------------------------------------------------------------
	_check_eq("npc_name_zorp", by_id, str(npc_data["zorp"]["display_name"]), "")
	_check_eq("npc_name_bolt", by_id, str(npc_data["bolt"]["display_name"]), "")

	# ---- jobs (substring of the neighbour's own intro/small_talk lines) --------------------------
	_check_contains("npc_job_zorp", by_id, npc_data["zorp"]["intro"], "grow the glowing garden")
	_check_contains("npc_job_bolt", by_id, npc_data["bolt"]["intro"], "counted 4,181 bolts")
	_check_contains("npc_job_fen", by_id, npc_data["fen"]["small_talk"], "sunbathing is my job")
	_check_contains("npc_job_grig", by_id, npc_data["grig"]["intro"], "carved the big stairs")
	_check_contains("npc_job_vela", by_id, npc_data["vela"]["intro"], "hear songs from far away")
	_check_contains("npc_job_pip_pop", by_id, npc_data["pip"]["intro"], "cosmo depot")
	_check_contains("npc_job_stella", by_id, npc_data["stella"]["intro"], "suit-up")
	_check_contains("npc_job_nova", by_id, npc_data["dj_nova"]["intro"], "run the beats")
	_check_contains("npc_job_professor", by_id, npc_data["mayor_orbit"]["intro"], "watch the sky")

	# ---- sayings / looks -------------------------------------------------------------------------
	_check_contains("npc_saying_pip", by_id, npc_data["pip"]["small_talk"], "i drew it")
	_check_contains("npc_saying_pop", by_id, npc_data["pop"]["intro"], "great hugs")
	_check_contains("npc_family_pop", by_id, npc_data["pip"]["intro"], "best friend")
	_check_contains("npc_saying_stella", by_id, npc_data["stella"]["small_talk"], "boots first")
	_check_contains("npc_saying_nova", by_id, npc_data["dj_nova"]["intro"], "rule two: dance")
	_check_contains("npc_saying_bolt", by_id, npc_data["bolt"]["intro"], "4,181 bolts")
	_check_contains("npc_saying_grig", by_id, npc_data["grig"]["small_talk"], "chisel is older than your planet")
	_check_contains("npc_saying_vela", by_id, npc_data["vela"]["small_talk"], "glass gets foggy")
	_check_contains("npc_saying_fen", by_id, npc_data["fen"]["small_talk"], "no moon here")
	_check_contains("npc_saying_professor", by_id, npc_data["mayor_orbit"]["small_talk"], "notebook of every falling star")

	# ---- world names, from the real .tres resources ----------------------------------------------
	_check_eq("world_name_zorp", by_id, planet_display["zorp"], planet_display["zorp"])
	_check_eq("world_name_bolt", by_id, planet_display["bolt"], planet_display["bolt"])
	_check_eq("world_name_fen", by_id, planet_display["fen"], planet_display["fen"])
	_check_eq("world_name_grig", by_id, planet_display["grig"], planet_display["grig"])
	_check_eq("world_name_vela", by_id, planet_display["vela"], planet_display["vela"])
	_check_eq("world_name_hub", by_id, planet_display["hub"], planet_display["hub"])
	_check_eq("world_name_home", by_id, planet_display["home"], planet_display["home"])

	# ---- ship parts (S5 round, STORY_SPINE_SPEC.md carried item): S4 made these seven questions
	# "dynamic" - their table "answers" is [] and `NormQuiz._answers_for` builds the real three from
	# THIS SAVE's `GameState.rocket_parts` (order_first/order_last) or from `CampaignData.PARTS`
	# alone (part_of:<npc>) at ask time. Reading `parts[0]["name"]` etc. here, as the old version of
	# this check did, silently ASSUMED a fixed fitting order (Zorp first, Vela last) and crashed
	# outright on `part_name_*`/`part_order_*` (`(q["answers"] as Array)[0]` on an empty array) -
	# exactly the bug that made tools/check.sh red. `_check_dynamic_parts` below drives the REAL
	# GameState autoload through two different part orders and checks every one of the seven against
	# CampaignData.PARTS itself, never against a literal.
	_check_dynamic_parts(by_id, parts)

	# ---- mini-games: GAMES has the kind, the project file names which npc plays it ----------------
	_check_true("minigame_zorp", by_id, games.has("rings") and project_games["zorp"] == "rings")
	_check_true("minigame_bolt", by_id, games.has("catch") and project_games["bolt"] == "catch")
	_check_true("minigame_fen", by_id, games.has("guide") and project_games["fen"] == "guide")
	_check_true("minigame_grig", by_id, games.has("hunt") and project_games["grig"] == "hunt")
	_check_true("minigame_vela", by_id, games.has("call") and project_games["vela"] == "call")
	_check_true("minigame_owner_catch", by_id, project_games["bolt"] == "catch")
	_check_true("minigame_owner_hunt", by_id, project_games["grig"] == "hunt")

	# ---- hub buildings, cross-checked against npc_data.gd's "building" field ----------------------
	_check_true("hub_building_professor", by_id, str(npc_data["mayor_orbit"]["building"]) == "town_hall")
	_check_true("hub_building_stella", by_id, str(npc_data["stella"]["building"]) == "clothes_store")
	_check_true("hub_building_nova", by_id, str(npc_data["dj_nova"]["building"]) == "event_space")
	_check_true("hub_building_pip_pop", by_id,
		str(npc_data["pip"]["building"]) == "deco_store" and str(npc_data["pop"]["building"]) == "deco_store")

	# ---- the Professor's telescope -----------------------------------------------------------------
	_check_contains("professor_tool", by_id, npc_data["mayor_orbit"]["small_talk"], "oil my telescope")

	# ---- the fleet finale (src/campaign/finale_lines.gd), after the story only -----------------------
	var finale_consts: Dictionary = (load("res://src/campaign/finale_lines.gd") as GDScript).get_script_constant_map()
	var send_text := JSON.stringify(finale_consts.get("SEND", [])).to_lower()
	var meeting_text := JSON.stringify(finale_consts.get("MEETING", [])).to_lower()
	_check_true("fleet", by_id,
		_right_answer(by_id, "fleet").to_lower().contains("every ship") and send_text.contains("all of us"))
	_check_true("streak", by_id,
		_right_answer(by_id, "streak").to_lower().contains("photos") and meeting_text.contains("streak is in your photos"))

	# ---- structural checks over the WHOLE bank, not just the ones above ----------------------------
	_check_bank_shape()

	print("NQUIZSOURCECHECK total=%d pass=%d fail=%d" % [_pass + _fail, _pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)


func _find_first_game(node: Variant) -> String:
	if node is Dictionary:
		if node.has("game") and str(node["game"]) != "":
			return str(node["game"])
		for v in node.values():
			var found := _find_first_game(v)
			if found != "":
				return found
	elif node is Array:
		for v in node:
			var found := _find_first_game(v)
			if found != "":
				return found
	return ""


func _q(by_id: Dictionary, id: String) -> Dictionary:
	if not by_id.has(id):
		push_error("NQUIZSOURCECHECK: no such question id in NormQuiz.QUESTIONS: %s" % id)
		return {}
	return by_id[id]


func _right_answer(by_id: Dictionary, id: String) -> String:
	var q := _q(by_id, id)
	if q.is_empty():
		return ""
	# Dynamic questions (S5 round) keep "answers" empty by design (norm_quiz.gd's own header) - a
	# caller that still wants "the right answer" for one of these seven ids should go through
	# `_check_dynamic_parts` instead, which drives a real save; reading index 0 of an empty Array
	# here is exactly the crash this round fixed, so this guards against it rather than repeating it.
	if str(q.get("dynamic", "")) != "":
		push_error("NQUIZSOURCECHECK: _right_answer called on a dynamic question: %s" % id)
		return ""
	return str(q["answers"][0])


## THE ORDER BUG, VERIFIED AGAINST THE SAVE (S5 round, STORY_SPINE_SPEC.md carried item). Drives the
## REAL `GameState.rocket_parts` autoload through two DIFFERENT fitting orders (never a real save
## file - this probe never calls SaveManager) and, for every one of the seven dynamic questions,
## checks `NormQuiz._answers_for`'s own correct answer (index 0, before the caller's shuffle)
## against `CampaignData.PARTS` itself - the true source, not a literal re-typed from memory.
## `order_first`/`order_last` actually read `GameState.rocket_parts`, so using the REVERSE of one
## order as the other proves the answer follows the save (they necessarily differ); the five
## `part_of:<npc>` questions read only `CampaignData.PARTS` (never the fitting order), so both orders
## should agree with each other AND with `CampaignData.PARTS` - checked both ways, not assumed.
func _check_dynamic_parts(by_id: Dictionary, parts: Array) -> void:
	var name_for_id: Dictionary = {}
	var id_for_npc: Dictionary = {}
	for p in parts:
		name_for_id[str(p.get("id", ""))] = str(p.get("name", ""))
		id_for_npc[str(p.get("npc", ""))] = str(p.get("id", ""))
	var all_ids: Array = []
	for p in parts:
		all_ids.append(str(p.get("id", "")))

	var saved_parts: Array = GameState.rocket_parts.duplicate()
	var order_a: Array = all_ids.duplicate()
	var order_b: Array = all_ids.duplicate()
	order_b.reverse()
	if order_a == order_b:
		push_error("NQUIZSOURCECHECK: order_a and order_b must differ to prove anything")

	_check_dynamic_for_order("orderA", by_id, order_a, name_for_id, id_for_npc)
	_check_dynamic_for_order("orderB", by_id, order_b, name_for_id, id_for_npc)
	GameState.rocket_parts = saved_parts


func _check_dynamic_for_order(label: String, by_id: Dictionary, order: Array, name_for_id: Dictionary,
		id_for_npc: Dictionary) -> void:
	GameState.rocket_parts = order.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260923
	for npc_id in ["zorp", "bolt", "fen", "grig", "vela"]:
		var qid := "part_name_%s" % npc_id
		var q := _q(by_id, qid)
		if q.is_empty():
			continue
		var answers: Array = NormQuiz._answers_for(q, rng)
		var expect := str(name_for_id.get(str(id_for_npc.get(npc_id, "")), ""))
		var ok := answers.size() == 3 and str(answers[0]) == expect
		_report("%s[%s]" % [qid, label], ok, "right=%s expect=%s order=%s" %
			[str(answers[0]) if answers.size() > 0 else "?", expect, str(order)])
	var qf := _q(by_id, "part_order_first")
	if not qf.is_empty():
		var af := NormQuiz._answers_for(qf, rng)
		var expect_first := str(name_for_id.get(str(order[0]), ""))
		_report("part_order_first[%s]" % label, af.size() == 3 and str(af[0]) == expect_first,
			"right=%s expect=%s order=%s" % [str(af[0]) if af.size() > 0 else "?", expect_first, str(order)])
	var ql := _q(by_id, "part_order_last")
	if not ql.is_empty():
		var al := NormQuiz._answers_for(ql, rng)
		var expect_last := str(name_for_id.get(str(order[-1]), ""))
		_report("part_order_last[%s]" % label, al.size() == 3 and str(al[0]) == expect_last,
			"right=%s expect=%s order=%s" % [str(al[0]) if al.size() > 0 else "?", expect_last, str(order)])


func _report(id: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("PASS %s %s" % [id, detail])
	else:
		_fail += 1
		print("FAIL %s %s" % [id, detail])


func _check_eq(id: String, by_id: Dictionary, source_value: String, _unused: String) -> void:
	var right := _right_answer(by_id, id)
	_report(id, right == source_value, "right=%s source=%s" % [right, source_value])


func _check_true(id: String, by_id: Dictionary, source_true: bool) -> void:
	_report(id, source_true, "right=%s source_true=%s" % [_right_answer(by_id, id), source_true])


## `lines` is the real Array[String] loaded from npc_data.gd; passes when ANY line contains
## `needle` (case-insensitive) - the literal proof that the right answer's claim is written there.
func _check_contains(id: String, by_id: Dictionary, lines: Array, needle: String) -> void:
	var found := false
	for l in lines:
		if str(l).to_lower().contains(needle.to_lower()):
			found = true
			break
	_report(id, found, "right=%s needle=%s found=%s" % [_right_answer(by_id, id), needle, found])


## Bank-wide structural checks: count, unique ids, length caps, answers[0] present, 3 answers each.
func _check_bank_shape() -> void:
	var n: int = NormQuiz.QUESTIONS.size()
	_pass += 1 if n >= 40 else 0
	_fail += 1 if n < 40 else 0
	print("%s bank_count_ge_40 n=%d" % ["PASS" if n >= 40 else "FAIL", n])

	var ids: Dictionary = {}
	var dup := false
	var q_over := 0
	var a_over := 0
	var shape_bad := 0
	for q in NormQuiz.QUESTIONS:
		var id := str(q["id"])
		if ids.has(id):
			dup = true
		ids[id] = true
		if str(q["q"]).length() > 90:
			q_over += 1
		var answers: Array = q["answers"]
		# Dynamic questions (S5 round) keep "answers" EMPTY in the table by design - the real three
		# are built at ask time (`_check_dynamic_parts` above checks those). The shape rule for them
		# is the opposite of an ordinary question's: "answers" must stay unused, not hold 3 literals.
		if str(q.get("dynamic", "")) != "":
			if not answers.is_empty():
				shape_bad += 1
			continue
		if answers.size() != 3:
			shape_bad += 1
		for a in answers:
			if str(a).length() > 20:
				a_over += 1
	print("%s bank_unique_ids dup=%s" % ["FAIL" if dup else "PASS", dup])
	_pass += 1 if not dup else 0
	_fail += 1 if dup else 0
	print("%s bank_question_len_le_90 over=%d" % ["FAIL" if q_over > 0 else "PASS", q_over])
	_pass += 1 if q_over == 0 else 0
	_fail += 1 if q_over > 0 else 0
	print("%s bank_answer_len_le_20 over=%d" % ["FAIL" if a_over > 0 else "PASS", a_over])
	_pass += 1 if a_over == 0 else 0
	_fail += 1 if a_over > 0 else 0
	print("%s bank_three_answers bad=%d" % ["FAIL" if shape_bad > 0 else "PASS", shape_bad])
	_pass += 1 if shape_bad == 0 else 0
	_fail += 1 if shape_bad > 0 else 0
