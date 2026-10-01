extends Node
## STAMP CARD PROBE (docs/DAILY_STAMPS_SPEC.md 2). Headless, no world: drives stamp_card.gd through
## simulated real days and stamp_system.gd through the EventBus signals it listens to.
## SYNTHETIC: the dates are set by hand, the signals are emitted by this probe (not by play), and
## the mini-game / safari handlers are called directly. Run:
##   godot --headless --path . res://tests/stamps_probe.tscn --quit-after 600 -- --no-autosave
const StampCard := preload("res://src/stamps/stamp_card.gd")
const StampSystem := preload("res://src/stamps/stamp_system.gd")
const NormLines := preload("res://src/campaign/norm_lines.gd")

var fails: Array = []
var checks := 0


func ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails.append(what)
		print("  FAIL " + what)


func _ready() -> void:
	print("PROBE user dir: " + OS.get_user_data_dir())
	if not OS.get_user_data_dir().contains("AN STAMPS"):
		print("STAMPSPROBE ABORT: not the scratch save folder")
		get_tree().quit(2)
		return
	# ---- TEST items, only when the furniture builder's are not in this copy yet.
	var real := StampCard.prize_list().size()
	if real == 0:
		Catalog.register({"id": "TEST_stamp_deco_a", "name": "TEST Stamp Deco A", "kind": "decoration", "category": "fun",
			"rarity": "common", "price": 0, "source": "stamps", "desc": "TEST", "footprint": 0.5, "icon_color": "#c08a5c",
			"scene": "res://src/decorations/items/meteor_rock.tscn"})
		Catalog.register({"id": "TEST_stamp_deco_b", "name": "TEST Stamp Deco B", "kind": "decoration", "category": "fun",
			"rarity": "common", "price": 0, "source": "stamps", "desc": "TEST", "footprint": 0.5, "icon_color": "#9a968f",
			"scene": "res://src/decorations/items/meteor_rock.tscn"})
		Catalog.register({"id": "TEST_stamp_suit", "name": "TEST Stamp Suit", "kind": "clothing", "category": "suit",
			"rarity": "common", "price": 0, "source": "stamps", "desc": "TEST", "icon_color": "#c8d1de",
			"style": {"suit_color": "#c8d1de", "accent_color": "#e0642f", "visor_tint": "#a8e0ff"}})
	var prizes := StampCard.prize_list()
	print("PROBE prizes (%s): %s" % ["catalog" if real > 0 else "TEST items", str(prizes)])

	_dates()
	_reachable()
	_week()
	_signals()
	_lines()
	print("STAMPSPROBE %s checks=%d fails=%d %s" % ["PASS" if fails.is_empty() else "FAIL", checks, fails.size(), str(fails)])
	get_tree().quit(0 if fails.is_empty() else 1)


func _dates() -> void:
	print("== dates")
	ok(StampCard.weekday("2026-10-05") == 0, "2026-10-05 is a Monday")
	ok(StampCard.weekday("2026-10-11") == 6, "2026-10-11 is a Sunday")
	ok(StampCard.weekday("2026-10-01") == 3, "2026-10-01 is a Thursday")
	ok(StampCard.week_start("2026-10-11") == "2026-10-05", "Sunday belongs to the Monday before")
	ok(StampCard.week_start("2026-10-12") == "2026-10-12", "Monday starts a week")
	ok(StampCard.week_start("2027-01-01") == "2026-12-28", "a week across New Year")
	ok(StampCard.date_of(StampCard.day_number("2028-02-29")) == "2028-02-29", "leap day round trip")
	ok(StampCard.debug_set_date("nonsense").begins_with("Not a date"), "a bad date is refused")
	StampCard.debug_set_date("")
	ok(StampCard.today() == Time.get_date_string_from_system(), "no override = the device's local date")


func _reachable() -> void:
	print("== reachable")
	GameState.reset_new_game()
	var fresh: Array = []
	for id: String in StampCard.TASKS:
		if StampCard.reachable(id):
			fresh.append(id)
	print("  new game reachable: " + str(fresh))
	for id: String in ["safari", "fine_photo", "new_photo", "minigame", "favour", "prints", "quiz", "tidy", "outfit"]:
		ok(not fresh.has(id), "new game must not offer " + id)
	StampCard.debug_set_date("2026-10-05")
	for i in 60:
		var card := StampCard.pick_tasks(StampCard.date_of(StampCard.day_number("2026-10-05") + i))
		ok(card.size() == 5, "new game day %d has 5 tasks (got %d)" % [i, card.size()])
		var seen := {}
		for t: Dictionary in card:
			ok(fresh.has(t["id"]), "new game day %d offered unreachable %s" % [i, t["id"]])
			ok(not seen.has(t["id"]), "day %d repeats %s" % [i, t["id"]])
			seen[t["id"]] = true
	# A finished story with everyone met, two suits, prints in the bag, junk at home.
	GameState.story_done = true
	GameState.campaign_active = false
	for n: String in ["zorp", "bolt", "fen", "grig", "vela", "mayor_orbit", "moss"]:
		GameState.set_flag("met_" + n)
	GameState.wardrobe = ["suit_white", "suit_comet"]
	GameState.flags["spike_prints"] = [{"id": "x", "name": "x"}]
	GameState.trash_home = [{"id": "a"}, {"id": "b"}, {"id": "c"}]
	var late: Array = []
	for id: String in StampCard.TASKS:
		if StampCard.reachable(id):
			late.append(id)
	print("  finished-story reachable: " + str(late))
	print("  safari worlds: " + str(StampCard.safari_worlds()))
	for id: String in ["safari", "fine_photo", "new_photo", "favour", "prints", "tidy", "outfit"]:
		ok(late.has(id), "finished story should offer " + id)
	var used := {}
	var same_as_yesterday := 0
	var prev := ""
	for i in 60:
		var card := StampCard.pick_tasks(StampCard.date_of(StampCard.day_number("2026-10-05") + i))
		var ids: Array = []
		var photo := 0
		for t: Dictionary in card:
			ids.append(t["id"])
			used[t["id"]] = int(used.get(t["id"], 0)) + 1
			ok(late.has(t["id"]), "late day %d offered unreachable %s" % [i, t["id"]])
			if t["id"] in ["fine_photo", "new_photo"]:
				photo += 1
		ok(card.size() == 5 and photo <= 1, "late day %d: 5 tasks, at most one photo-grade task" % i)
		ids.sort()
		if str(ids) == prev:
			same_as_yesterday += 1
		prev = str(ids)
	print("  60 days of cards used: " + str(used) + "  same-as-yesterday=%d" % same_as_yesterday)
	ok(same_as_yesterday <= 2, "cards rotate (same five two days running: %d of 60)" % same_as_yesterday)
	ok(StampCard.pick_tasks("2026-10-05") == StampCard.pick_tasks("2026-10-05"), "one date = one card")


func _do(n: int) -> Dictionary:
	return StampCard.debug_tick(n)


func _week() -> void:
	print("== a week, a save, a rollover")
	var prizes := StampCard.prize_list()
	StampCard.debug_reset()
	StampCard.debug_set_date("2026-10-05")   # Monday
	ok(StampCard.progress("deco").is_empty() and not StampCard.is_on(), "nothing counts before Norm hands over the card")
	ok(not GameState.flags.has("stamps"), "and nothing is written to the save before that")
	StampCard.start()
	ok(StampCard.tasks().size() == 5, "day 1 card has 5 tasks")
	var r := _do(2)
	ok(not r.has("stamp") and StampCard.done_count() == 2 and not StampCard.stamped_today(), "2 tasks: no stamp")
	r = _do(1)
	ok(r.has("stamp") and StampCard.stamped_today() and StampCard.week_stamps().size() == 1, "3 tasks: the stamp")
	r = _do(2)
	ok(not r.has("stamp") and StampCard.week_stamps().size() == 1, "tasks 4 and 5 add nothing")
	print("  " + StampCard.debug_line())
	var card1 := str(StampCard.tasks())
	# Tuesday: a new card, yesterday's ticks gone, the stamp kept.
	StampCard.debug_advance(1)
	ok(StampCard.roll(), "Tuesday deals a new card")
	ok(StampCard.done_count() == 0 and not StampCard.stamped_today() and StampCard.week_stamps().size() == 1, "new card is blank, Monday's stamp kept")
	ok(not StampCard.roll(), "a second roll the same day deals nothing")
	_do(3)
	# Wednesday: only two tasks. No stamp, no penalty.
	StampCard.debug_advance(1)
	StampCard.roll()
	_do(2)
	ok(StampCard.week_stamps().size() == 2 and not StampCard.stamped_today(), "Wednesday with 2 tasks: still 2 stamps")
	# ---- save and reload mid-week, mid-card
	var before := StampCard.debug_line()
	ok(SaveManager.save_game(), "save written")
	GameState.reset_new_game()
	ok(not StampCard.is_on(), "a new game has no card")
	ok(SaveManager.load_game(), "save loaded")
	StampCard.roll()
	var after := StampCard.debug_line()
	print("  before: " + before + "\n  after:  " + after)
	ok(before == after, "the card is the same after a save and a reload")
	ok(StampCard.peek().get("owed") is int and (StampCard.tasks()[0] as Dictionary).get("n") is int, "whole numbers come back as ints")
	_do(1)
	ok(StampCard.stamped_today() and StampCard.week_stamps().size() == 3, "the third task after the reload earns Wednesday's stamp")
	# Thursday missed entirely. Friday, Saturday: stamps 4 and 5.
	StampCard.debug_advance(2)
	StampCard.roll()
	r = _do(3)
	ok(StampCard.week_stamps().size() == 4 and not r.has("prize") and StampCard.owed() == 0, "Friday: 4 stamps, no prize yet")
	StampCard.debug_advance(1)
	StampCard.roll()
	var shown := StampCard.week_prize()
	r = _do(3)
	ok(r.has("prize") and StampCard.owed() == 1 and StampCard.week_stamps().size() == 5, "Saturday: the 5th stamp owes a prize")
	ok(shown == prizes[0] and StampCard.week_prize() == prizes[0], "the silhouette is the first prize, before and after the 5th stamp")
	# Sunday: a 6th stamp does nothing more.
	StampCard.debug_advance(1)
	StampCard.roll()
	r = _do(3)
	ok(StampCard.week_stamps().size() == 6 and StampCard.owed() == 1 and not r.has("prize"), "Sunday: a 6th stamp, still one prize")
	print("  " + StampCard.debug_line())
	# ---- week rollover with the prize unclaimed: it waits.
	StampCard.debug_advance(1)
	ok(StampCard.today() == "2026-10-12" and StampCard.roll(), "next Monday deals a card")
	ok(StampCard.week_stamps().is_empty() and StampCard.owed() == 1, "new week: stamps cleared, the unclaimed prize waits")
	ok(StampCard.week_prize() == prizes[1], "this week's silhouette is the NEXT prize (the first is spoken for)")
	var had := GameState.item_count(prizes[0])
	var got := StampCard.claim()
	ok(got == prizes[0] and GameState.item_count(prizes[0]) == had + 1 and StampCard.owed() == 0, "claim: %s is in the inventory" % prizes[0])
	ok(StampCard.claim() == "", "nothing more to claim")
	ok(StampCard.week_prize() == prizes[1], "the silhouette still shows the next prize")
	# A missed week loses nothing but that week's prize: 4 stamps, then two weeks away.
	for i in 4:
		_do(3)
		StampCard.debug_advance(1)
		StampCard.roll()
	ok(StampCard.week_stamps().size() == 4 and StampCard.owed() == 0, "4 stamps: no prize")
	StampCard.debug_advance(17)
	StampCard.roll()
	ok(StampCard.week_stamps().is_empty() and StampCard.owed() == 0 and StampCard.given().size() == 1, "after weeks away: clean week, nothing lost, no penalty")
	# ---- every prize in order (decorations, then outfits), then a repeat by choice.
	var order: Array = [prizes[0]]
	var guard := 0
	while StampCard.next_prize() != "" and guard < 40:
		guard += 1
		StampCard.debug_set_date(StampCard.date_of(StampCard.day_number(StampCard.week_start(StampCard.today())) + 7))
		for i in 5:
			StampCard.roll()
			_do(3)
			StampCard.debug_advance(1)
		ok(StampCard.owed() == 1, "week %d owes one prize" % guard)
		order.append(StampCard.claim())
	ok(order == Array(prizes), "prizes come in catalog order, decorations then outfits: " + str(order))
	for id: String in prizes:
		if str(Catalog.get_item(id).get("kind", "")) == "clothing":
			ok(GameState.wardrobe.has(id) and GameState.item_count(id) == 1, "outfit %s is in the wardrobe and the bag" % id)
		else:
			ok(GameState.item_count(id) >= 1, "decoration %s is in the bag" % id)
	StampCard.debug_set_date(StampCard.date_of(StampCard.day_number(StampCard.week_start(StampCard.today())) + 7))
	for i in 5:
		StampCard.roll()
		_do(3)
		StampCard.debug_advance(1)
	ok(StampCard.owed() == 1 and StampCard.next_prize() == "" and StampCard.week_prize() == "", "list run out: a prize is owed, as a choice")
	ok(StampCard.claim() == "" and StampCard.owed() == 1, "no choice made: nothing given, still owed")
	var rep := StampCard.repeat_choices()
	ok(not rep.is_empty() and str(Catalog.get_item(rep[0]).get("kind")) == "decoration", "the choice is stamp decorations")
	var n0 := GameState.item_count(rep[0])
	ok(StampCard.claim(rep[0]) == rep[0] and GameState.item_count(rep[0]) == n0 + 1 and StampCard.owed() == 0, "a second copy by choice")
	ok(StampCard.claim("deco_moon_lamp") == "", "a non-stamp item can never be claimed")
	ok(card1 != "", "card recorded")


func _signals() -> void:
	print("== signals -> ticks (emitted by the probe)")
	GameState.reset_new_game()
	StampCard.debug_reset()
	StampCard.debug_set_date("2026-11-02")
	var world := Node.new()
	world.name = "ProbeWorld"
	add_child(world)
	var sys: Node = StampSystem.attach(world)
	StampCard.start()
	# A card holding EVERY task, so each signal has something to tick.
	var all: Array = []
	for id: String in StampCard.TASKS:
		all.append({"id": id, "n": 0})
	(StampCard._s())["tasks"] = all
	var t := func(id: String) -> int:
		for x: Dictionary in StampCard.tasks():
			if x["id"] == id:
				return int(x["n"])
		return -1
	EventBus.decoration_placed.emit("home", "i1", "deco_moon_lamp")
	ok(t.call("deco") == 1, "decoration_placed ticks deco")
	(StampCard.tasks()[0] as Dictionary)["n"] = 0 if StampCard.tasks()[0]["id"] == "deco" else StampCard.tasks()[0]["n"]
	GameState.stardust = 1000
	GameState.spend_stardust(240)
	GameState.add_item("deco_meteor_rock", 1)
	ok(t.call("deco") == 1, "a stardust spend + a decoration in the bag ticks deco")
	GameState.add_item("moon_flower", 1)
	for who: String in ["zorp", "zorp", "pip", ""]:
		EventBus.dialogue_finished.emit(who)
	ok(t.call("talk3") == 2, "talk3 counts different speakers only (zorp twice, narration: 2)")
	EventBus.dialogue_finished.emit("norm")
	ok(t.call("talk3") == 3, "third neighbour ticks talk3")
	EventBus.planet_loaded.emit("home")
	ok(t.call("visit2") == 0, "a world loading without a flight is not a visit")
	EventBus.travel_started.emit("home", "hub")
	EventBus.planet_loaded.emit("hub")
	EventBus.travel_started.emit("hub", "hub")
	EventBus.planet_loaded.emit("hub")
	ok(t.call("visit2") == 1, "the same world twice is one visit")
	EventBus.travel_started.emit("hub", "home")
	EventBus.planet_loaded.emit("home")
	ok(t.call("visit2") == 2, "two flights tick visit2")
	EventBus.player_style_changed.emit()
	ok(t.call("outfit") == 1, "player_style_changed ticks outfit")
	GameState.add_scrap(4)
	GameState.spend_scrap(2)
	GameState.add_scrap(6)
	ok(t.call("scrap") == 10, "scrap gains add up to 10, a spend does not count")
	for k: String in ["moon_flower", "scrap", "stardust_pickup", "gear_bit", "crystal_chunk", "moon_flower", "gear_bit"]:
		EventBus.collectible_picked.emit(k, Vector3.ZERO)
	ok(t.call("materials") == 5, "five materials (scrap and stardust pickups are not materials)")
	EventBus.favor_completed.emit("f", "", 0)
	ok(t.call("favour") == 1, "favor_completed ticks favour")
	GameState.trash_home = []
	for i in 4:
		GameState.add_trash("t%d" % i, Vector3.UP, "can")
	ok(t.call("tidy") == 0, "junk landing is not tidying")
	for i in 3:
		GameState.remove_trash("t%d" % i)
	ok(t.call("tidy") == 3, "three pieces cleaned ticks tidy")
	# The polled three.
	GameState.flags["home_album_seq"] = int(GameState.flags.get("home_album_seq", 0)) + 1
	GameState.flags["gloop_table"] = [{"id": "p"}]
	GameState.flags["norm_wins"] = int(GameState.flags.get("norm_wins", 0)) + 1
	sys._poll_t = 99.0
	sys._process(0.0)
	ok(t.call("album") == 1 and t.call("prints") == 1 and t.call("quiz") == 1, "album, prints and quiz tick from their save flags")
	# Called directly (SYNTHETIC: no real safari or mini-game ran).
	sys._on_photo({"grade_idx": 1, "subject_key": ""})
	ok(t.call("fine_photo") == 0 and t.call("new_photo") == 0, "a Fair photo of nothing ticks neither")
	sys._on_photo({"grade_idx": 2, "subject_key": "probe_new_thing"})
	ok(t.call("fine_photo") == 1 and t.call("new_photo") == 1, "a Fine photo of a new subject ticks both")
	sys._on_minigame_finished("catch", false, {})
	ok(t.call("minigame") == 0, "a mini-game left early does not count")
	sys._on_minigame_finished("catch", true, {})
	ok(t.call("minigame") == 1, "a finished mini-game ticks")
	ok(StampCard.stamped_today(), "and the day is stamped")
	# A load under the node must not read the new save's numbers as play.
	(StampCard._s())["tasks"] = [{"id": "album", "n": 0}, {"id": "quiz", "n": 0}, {"id": "tidy", "n": 0}]
	GameState.flags["home_album_seq"] = 50
	GameState.flags["norm_wins"] = 9
	GameState.trash_home = []
	EventBus.campaign_changed.emit()
	sys._poll_t = 99.0
	sys._process(0.0)
	ok(StampCard.done_count() == 0, "a state swap (load / new game) ticks nothing")
	world.queue_free()


func _lines() -> void:
	print("== Norm's lines")
	var m: Dictionary = (NormLines as GDScript).get_script_constant_map()
	var n := 0
	for k: String in m:
		if not k.begins_with("STAMP_"):
			continue
		var v: Variant = m[k]
		var list: Array = v if v is Array else [v]
		for s: Variant in list:
			n += 1
			var txt := str(s).replace("%d", "5")
			if k != "STAMP_VIEW_OFF":
				ok(txt.length() <= 60, "%s over 60: %s" % [k, txt])
	var week := {}
	var d0 := StampCard.day_number("2026-10-05")
	for i in NormLines.STAMP_DAILY.size():
		week[NormLines.stamp_daily(d0 + i)] = true
	ok(week.size() == NormLines.STAMP_DAILY.size(), "the line of the day does not repeat for %d days" % NormLines.STAMP_DAILY.size())
	print("  %d stamp lines, %d daily; this week: " % [n, NormLines.STAMP_DAILY.size()])
	for i in 7:
		print("    %s  %s" % [StampCard.date_of(d0 + i), NormLines.stamp_daily(d0 + i)])
