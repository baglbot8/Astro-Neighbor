extends Node
## LOGIC PROBE for the first hour on the Commons (docs/INTRO_SPEC.md 7; src/campaign/first_hour.gd).
## No world, no rendering, no input: it sets GameState directly and reads the real functions back.
## tools/check.sh runs it like every showcase scene, and every failed check is a push_error, so a
## regression here fails check.sh.
##
##   godot --headless --path <copy> --quit-after 30 res://showcase/first_hour_probe.tscn
##
## Checks
##   1. every new dialogue box <= 60 characters, filled with the longest pickable name (6 letters) and
##      the longest neighbour name, and the picker's patch pill text
##   2. no clock / deadline wording in any new line
##   3. the gate: new game (zorp, bolt closed; home, hub open), after the patch (all three open, the
##      later tiers unchanged), an old save, a finished story, a pre-feature campaign save that already
##      reached Zorp or Bolt, reset_new_game clears the flag
##   4. the patch is not a part: rocket_part_count() and finish_stage() unchanged by it
##   5. the talk gates (FirstHour.handles) and ProfessorAsk.open_task called twice / with the task
##      already open from an old radio call
##   6. other planet_in_range callers: the favour system's reachability and Norm's candidate worlds
##   7. favours during the gate: across many real make_offer rolls no Commons neighbour asks for a
##      material from, or a delivery to, a closed world; "bring" returns once the patch is fitted
## It leaves GameState as a fresh new game when it is done (it never saves; autosave is off here).

const NAMES := ["Astro", "Juno", "Pebble", "Mochi", "Skye", "Pixel", "Sprout", "Ember"]
const LINE_MAX := 60
## Words a no-clock line must not carry (docs/STORY_HOME_SPEC.md 2.2).
const CLOCK_WORDS := ["deadline", "hurry", "minute", "hour", "day", "countdown", "clock", "in time",
	"soon", "quick", "late", "before it", "time's", "running out", "tick"]

var _checks := 0
var _fail := 0


func _ready() -> void:
	_check_lines()
	_check_gate()
	_check_handles()
	_check_callers()
	GameState.reset_new_game()
	print("FIRSTHOURPROBE checks=%d fail=%d" % [_checks, _fail])
	get_tree().quit(1 if _fail > 0 else 0)


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ok   %s" % what)
	else:
		_fail += 1
		push_error("FIRSTHOURPROBE FAIL %s" % what)


# ------------------------------------------------------------------------------------------- lines
func _all_new_lines() -> Array[String]:
	var out: Array[String] = []
	var longest := ""
	for n: String in NAMES:
		if n.length() > longest.length():
			longest = n
	var named: Array = []
	for arr: Array in [FirstHour.DISPATCH, FirstHour.FIT_BEFORE, FirstHour.FIT_AFTER, FirstHour.PHOTOGRAPHER,
			FirstHour.PHOTO_ASK, FirstHour.PARCEL, FirstHour.PARCEL_REMINDER, FirstHour.ZORP_PARCEL]:
		named.append_array(arr)
	for l: Variant in named:
		var s := str(l)
		out.append(s % longest if s.contains("%s") else s)
	out.append(FirstHour.PROGRESS_NONE)
	out.append(FirstHour.PROGRESS_SOME % 2)
	out.append(FirstHour.PROGRESS_LEFT % "Pip, Pop and Stella")
	for id: String in FirstHour.RESIDENTS:
		var block: Dictionary = NpcData.get_data(id).get("first_hour", {})
		_ok(not block.is_empty(), "%s has first_hour lines" % id)
		for key: String in ["ask", "progress", "done", "after"]:
			var lines: Array = block.get(key, [])
			_ok(not lines.is_empty(), "%s.first_hour.%s is not empty" % [id, key])
			for l: Variant in lines:
				var s := str(l)
				if s.count("%d") == 2:
					s = s % [99, 99]
				elif s.count("%d") == 1:
					s = s % 99
				out.append(s)
	# ProfessorAsk's reworded hand-in, with the longest neighbour display name.
	var who := ""
	for id: String in ["zorp", "bolt", "fen", "grig", "vela"]:
		var n := str(NpcData.get_data(id).get("display_name", id))
		if n.length() > who.length():
			who = n
	out.append("A photo of %s! Simply delightful." % who)
	out.append("One last look at home, so nothing gets left behind.")
	out.append(PadDestinationPicker.PATCH_TEXT)
	return out


func _check_lines() -> void:
	print("[1-2] line boxes and clock words")
	var lines := _all_new_lines()
	var longest := 0
	for s: String in lines:
		longest = maxi(longest, s.length())
		_ok(s.length() <= LINE_MAX and not s.contains("\n"), "%2d chars: %s" % [s.length(), s])
		var low := s.to_lower()
		for w: String in CLOCK_WORDS:
			if low.contains(w):
				_ok(false, "clock word '%s' in: %s" % [w, s])
	print("  %d new boxes, longest %d characters" % [lines.size(), longest])
	# The Professor's source must not say the old reason any more.
	var src := FileAccess.get_file_as_string("res://src/campaign/professor_ask.gd")
	_ok(not src.contains("\"A photo of %s, for my records!"), "professor_ask.gd no longer says 'for my records'")


# -------------------------------------------------------------------------------------------- gate
func _ranges() -> String:
	var bits: Array[String] = []
	for id: String in ["home", "hub", "zorp", "bolt", "fen", "grig", "vela"]:
		bits.append("%s=%s" % [id, "open" if CampaignData.planet_in_range(id) else "shut"])
	return " ".join(bits)


func _check_gate() -> void:
	print("[3-4] the gate")
	_ok(not Director.is_active(), "no Director timeline (gates read as in real play)")
	GameState.reset_new_game()
	print("  new game: %s" % _ranges())
	_ok(CampaignData.gates_on(), "new game: gates on")
	_ok(CampaignData.planet_in_range("home") and CampaignData.planet_in_range("hub"), "new game: home and hub open")
	_ok(not CampaignData.planet_in_range("zorp") and not CampaignData.planet_in_range("bolt"), "new game: zorp and bolt shut")
	_ok(CampaignData.needs_patch("zorp") and CampaignData.needs_patch("bolt") and not CampaignData.needs_patch("hub")
		and not CampaignData.needs_patch("fen"), "needs_patch only for zorp and bolt")
	var parts_before := GameState.rocket_part_count()
	var finish_before := CampaignData.finish_stage()
	GameState.set_flag(FirstHour.PATCH_FLAG)
	print("  patched:  %s" % _ranges())
	_ok(CampaignData.planet_in_range("zorp") and CampaignData.planet_in_range("bolt") and CampaignData.planet_in_range("hub"),
		"after the patch: zorp, bolt, hub open")
	_ok(not CampaignData.planet_in_range("fen") and not CampaignData.planet_in_range("vela"), "after the patch: fen and vela still need parts")
	_ok(GameState.rocket_part_count() == parts_before and parts_before == 0, "patch is not a part: rocket_part_count %d -> %d" % [parts_before, GameState.rocket_part_count()])
	_ok(CampaignData.finish_stage() == finish_before and finish_before == 0, "finish stage stays rusty: %d -> %d" % [finish_before, CampaignData.finish_stage()])
	var ids: Array[String] = []
	for p: Dictionary in CampaignData.PARTS:
		ids.append(str(p["id"]))
	_ok(not ids.has(FirstHour.PATCH_FLAG) and CampaignData.PARTS.size() == 5, "PARTS unchanged (5, no patch)")
	GameState.reset_new_game()
	_ok(not GameState.flag(FirstHour.PATCH_FLAG) and not CampaignData.planet_in_range("zorp"), "reset_new_game clears first_patch")
	# An old save: from_dict with no campaign keys -> campaign_active false, story_done true.
	GameState.from_dict({})
	print("  old save: %s" % _ranges())
	_ok(not CampaignData.gates_on() and CampaignData.planet_in_range("zorp") and CampaignData.planet_in_range("bolt")
		and CampaignData.planet_in_range("vela"), "old save: gates off, every world open")
	_ok(not FirstHour.chain_active() and not FirstHour.handles("mayor_orbit") and not FirstHour.handles("pip"),
		"old save: first hour inert")
	# A finished campaign.
	GameState.reset_new_game()
	GameState.story_done = true
	_ok(CampaignData.planet_in_range("zorp") and CampaignData.planet_in_range("vela"), "finished story: every world open")
	# A campaign save from before this feature that already reached Zorp or Bolt.
	for legacy: Dictionary in [{"met_zorp": true}, {"met_bolt": true}]:
		GameState.reset_new_game()
		for k: String in legacy:
			GameState.set_flag(k)
		_ok(CampaignData.planet_in_range("zorp") and CampaignData.planet_in_range("bolt"), "pre-feature campaign save %s: open" % str(legacy))
	GameState.reset_new_game()
	GameState.projects["zorp"] = {"step": 1, "asked": false, "found": [], "markers": {}, "days": [], "done": false}
	_ok(CampaignData.planet_in_range("bolt"), "pre-feature campaign save with Zorp's project: open")
	GameState.reset_new_game()
	GameState.rocket_parts = ["part_zorp"]
	_ok(CampaignData.planet_in_range("zorp"), "pre-feature campaign save with a part: open")
	GameState.reset_new_game()
	GameState.set_flag("met_mayor_orbit")
	GameState.set_flag("met_pip")
	_ok(not CampaignData.planet_in_range("zorp"), "a save that only met the Commons crowd is still gated")


# ----------------------------------------------------------------------------------------- handles
func _check_handles() -> void:
	print("[5] talk gates and the photo task")
	GameState.reset_new_game()
	_ok(FirstHour.handles("mayor_orbit"), "new game: the Professor's talk is the first hour")
	_ok(not FirstHour.handles("pip") and not FirstHour.handles("pop") and not FirstHour.handles("stella"),
		"before he sends you: the residents talk as normal")
	_ok(not FirstHour.handles("dj_nova") and not FirstHour.handles("zorp"), "nobody else is taken over")
	# The scratch copy's old radio call still opens the task: the first hour must win anyway.
	ProfessorAsk.open_task()
	ProfessorAsk.open_task()
	_ok(ProfessorAsk.is_open() and not GameState.flag(ProfessorAsk.DONE_FLAG), "open_task twice: open once, not paid")
	_ok(FirstHour.handles("mayor_orbit") and ProfessorAsk.handles("mayor_orbit"),
		"task already open: first hour still claims him (hooked first in conversation.gd)")
	GameState.set_flag(FirstHour.STARTED_FLAG)
	_ok(FirstHour.handles("pip") and FirstHour.handles("pop") and FirstHour.handles("stella"), "after he sends you: the residents' talks are the errands")
	for id: String in FirstHour.RESIDENTS:
		GameState.set_flag("fh_%s_bit" % id)
	_ok(FirstHour.bits() == 3, "three bits counted")
	GameState.set_flag(FirstHour.PATCH_FLAG)
	GameState.set_flag(FirstHour.PARCEL_FLAG)
	_ok(not FirstHour.handles("pip") and FirstHour.handles("mayor_orbit") and FirstHour.parcel_for("zorp")
		and not FirstHour.parcel_for("bolt"), "after the patch: residents free, Professor reminds of the parcel, Zorp takes it")
	GameState.set_flag(FirstHour.PARCEL_DONE_FLAG)
	_ok(not FirstHour.handles("mayor_orbit") and not FirstHour.parcel_for("zorp") and ProfessorAsk.handles("mayor_orbit"),
		"after the parcel: his photo task takes his talks again")
	GameState.set_flag(ProfessorAsk.DONE_FLAG)
	GameState.set_flag(ProfessorAsk.OPEN_FLAG, false)
	ProfessorAsk.open_task()
	_ok(not ProfessorAsk.is_open(), "open_task after he has paid: stays closed")
	var lines := ProfessorAsk.first_meeting_lines(false)
	_ok(lines.size() == 5 and str(lines[0]) == "That crackly voice on the radio? That was me!",
		"first-meeting lines intact (5 boxes, radio reveal first)")
	# Polish 2026-10-18: a blank or all-space name falls back to "Astro" (no "Now then, .").
	var keep_name: Variant = GameState.player_style.get("name", "Astro")
	GameState.player_style["name"] = ""
	var blank_ok := FirstHour._player_name() == "Astro"
	GameState.player_style["name"] = "   "
	var spaces_ok := FirstHour._player_name() == "Astro"
	GameState.player_style["name"] = keep_name
	_ok(blank_ok and spaces_ok, "blank and all-space names read 'Astro'")
	# STORY_FIT_REVIEW B2: the first hour's meeting greets by name instead; the meteor lines follow as before.
	var named := ProfessorAsk.first_meeting_lines(false, "Sprout")
	_ok(named.size() == 5 and str(named[0]) == "There you are, Sprout! Professor Comet, in person."
		and str(named[1]) == str(lines[1]), "first-hour meeting greets by name (5 boxes, name line first)")


# ----------------------------------------------------------------------------------------- callers
func _check_callers() -> void:
	print("[6-7] other planet_in_range callers")
	GameState.reset_new_game()
	_ok(not FavorSystem.planet_reachable("zorp") and FavorSystem.planet_reachable("hub"), "favours: zorp unreachable, hub reachable during the gate")
	var ns: Variant = load("res://src/campaign/norm_system.gd")
	var worlds: PackedStringArray = ns.call("candidate_worlds")
	_ok(not worlds.has("zorp") and not worlds.has("bolt"), "Norm's candidate worlds during the gate: %s" % str(worlds))
	GameState.set_flag(FirstHour.PATCH_FLAG)
	_ok(FavorSystem.planet_reachable("zorp") and FavorSystem.planet_reachable("bolt"), "favours: zorp, bolt reachable after the patch")
	GameState.reset_new_game()
	# 7. favor_system._templates_for (lead-approved fix, 2026-10-18): no favour may need a closed world.
	_check_favour_rolls("gate closed", false)
	GameState.set_flag(FirstHour.PATCH_FLAG)
	_check_favour_rolls("patch fitted", true)
	GameState.reset_new_game()


const COMMONS := ["pip", "pop", "stella", "mayor_orbit", "dj_nova"]
const ROLLS := 300


## ROLLS offers per Commons neighbour through the REAL make_offer (a FavorSystem not in the tree, so
## no play favours; nothing is accepted). Every "bring" material must grow on a reachable world and
## every "deliver" must go to a reachable neighbour. `want_bring`: whether "bring" must appear at all.
func _check_favour_rolls(tag: String, want_bring: bool) -> void:
	var fs := FavorSystem.new()
	var kinds := {}
	var bad := 0
	var offers := 0
	for id: String in COMMONS:
		var tmpl: Array = fs.call("_templates_for", id)
		_ok(tmpl.has("bring") == want_bring, "%s: %s templates %s" % [tag, id, str(tmpl)])
		for i in ROLLS:
			var f: Dictionary = fs.make_offer(id)
			if f.is_empty():
				continue
			offers += 1
			var k := str(f["type"])
			kinds[k] = int(kinds.get(k, 0)) + 1
			if k == "bring" and not bool(fs.call("_material_reachable", str(f["target_item"]))):
				bad += 1
				print("  bad bring: %s asks for %s" % [id, f["target_item"]])
			elif k == "deliver" and not FavorSystem.npc_reachable(str(f["deliver_to"])):
				bad += 1
				print("  bad deliver: %s -> %s" % [id, f["deliver_to"]])
	print("  %s: %d offers over %d Commons neighbours x %d rolls, by type %s" % [tag, offers, COMMONS.size(), ROLLS, str(kinds)])
	_ok(bad == 0 and offers == COMMONS.size() * ROLLS, "%s: %d offers, %d need a closed world" % [tag, offers, bad])
	_ok(kinds.has("bring") == want_bring, "%s: 'bring' offered=%s" % [tag, str(kinds.has("bring"))])
	fs.free()
