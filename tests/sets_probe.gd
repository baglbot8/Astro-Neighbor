extends Node
## FURNITURE SETS SYSTEMS PROBE (docs/SETS_SPEC.md 4-6, "Systems" gates). Headless, no world.
## SYNTHETIC: favours are built by hand and paid through the REAL FavorSystem.complete(); shop buys and orders
## go through the REAL ShopPanel.buy_now() (the charge-and-give step of _try_buy, minus the confirm dialog);
## save/reload goes through the REAL SaveManager.save_game()/load_game() in the scratch user folder.
## Set pieces with no scene in this copy are registered as TEST defs (same ids, a stand-in scene) and said so.
## Run (scratch copy only - it aborts unless config/name is a scratch name):
##   godot --headless --path . res://tests/sets_probe.tscn --quit-after 900 -- --no-autosave
const DecoSets := preload("res://src/decorations/deco_sets.gd")
const STAND_IN := "res://src/decorations/items/meteor_rock.tscn"

var fails: Array = []
var checks := 0
var toasts: Array = []


func ok(cond: bool, what: String) -> void:
	checks += 1
	print(("  PASS " if cond else "  FAIL ") + what)
	if not cond:
		fails.append(what)


func gate(name: String, before: int) -> void:
	print("%s %s" % ["PASS" if fails.size() == before else "FAIL", name])


func _ready() -> void:
	var udir := OS.get_user_data_dir()
	print("PROBE user dir: " + udir)
	if not udir.contains("AstroScratch"):
		print("SETSPROBE ABORT: not a scratch save folder")
		get_tree().quit(2)
		return
	EventBus.toast_requested.connect(func(t: String, _i: String) -> void: toasts.append(t))
	_register_stand_ins()
	await _run()
	print("SETSPROBE checks=%d fail=%d" % [checks, fails.size()])
	for f in fails:
		print("  failed: " + str(f))
	get_tree().quit(1 if fails.size() > 0 else 0)


## Registers a TEST def for every set piece / bonus / outfit id that has no Catalog entry in this copy (the
## art builders' scenes are not here yet). Same keys decoration_catalog.gd gives a real one.
func _register_stand_ins() -> void:
	var n := 0
	for st: Dictionary in DecoSets.all_sets():
		if bool(st["display_only"]):
			continue
		var sid := str(st["id"])
		for pid: String in (st["pieces"] as Array) + [str(st["bonus"])]:
			if Catalog.has_item(pid):
				continue
			var bonus := pid == str(st["bonus"])
			var price := 0
			var path := str(st["id"])
			var s: Variant = load("res://src/decorations/sets/set_%s.gd" % path)
			for r: Array in s.PIECES:
				if "deco_" + str(r[0]) == pid:
					price = int(r[4])
			var def := {"id": pid, "name": str(st["names"][pid]), "kind": "decoration", "category": "fun",
				"rarity": "legendary" if bonus else "common", "price": 0 if bonus else price, "footprint": 0.5,
				"icon_color": "#c08a5c", "desc": "TEST", "scene": STAND_IN, "set": sid}
			if bonus:
				def["source"] = "set"
			Catalog.register(def)
			n += 1
		for cid: String in st["outfit"]:
			if not Catalog.has_item(cid):
				Catalog.register({"id": cid, "name": "TEST " + cid, "kind": "clothing",
					"category": "hat" if cid.begins_with("hat_") else "suit", "rarity": "common", "price": 900,
					"desc": "TEST", "icon_color": "#c8d1de", "set": sid, "style": {}})
				n += 1
	print("TEST stand-in defs registered: %d (no scene in this copy yet)" % n)


func _fresh() -> void:
	GameState.reset_new_game()
	GameState.stardust = 100000
	toasts.clear()


func _pay(fs: FavorSystem, npc: String) -> Dictionary:
	GameState.add_item("gear_bit", 1)
	var f := {"id": "probe_%d" % randi(), "npc": npc, "type": "fetch", "target_item": "gear_bit", "count": 1,
		"progress": 1, "state": "active", "reward_stardust": 100, "deliver_to": ""}
	GameState.favors[f["id"]] = f
	return fs.complete(f)


func _count_toasts(sub: String) -> int:
	var n := 0
	for t: String in toasts:
		if t.contains(sub):
			n += 1
	return n


func _run() -> void:
	var fs := FavorSystem.get_or_create()
	await get_tree().process_frame
	var tinker := DecoSets.get_set("tinker")
	var tinker_ids: Array = (tinker["pieces"] as Array) + (tinker["outfit"] as Array)

	# ---------------------------------------------------------------- G1 Bolt pays Tinker, then falls back
	var b := fails.size()
	_fresh()
	GameState.npc_data("bolt")["friendship"] = 0
	var seen: Dictionary = {}
	var stardust_ok := true
	var sig_count := 0
	for i in tinker_ids.size():
		var trust := int(GameState.npc_data("bolt").get("friendship", 0))
		var before_sd := GameState.stardust
		var r := _pay(fs, "bolt")
		var id := str(r.get("item_id", ""))
		ok(tinker_ids.has(id) and not seen.has(id), "favour %d from Bolt paid an uncollected Tinker item: %s" % [i + 1, id])
		seen[id] = true
		var mult := 1.4 if trust >= FavorSystem.TRUST_BEST_FRIEND else (1.2 if trust >= FavorSystem.TRUST_PAL else 1.0)
		var expect := int(round(100 * mult))
		if GameState.stardust - before_sd != expect or int(r.get("stardust", 0)) != expect:
			stardust_ok = false
	await get_tree().process_frame
	ok(stardust_ok, "stardust reward + trust bonus unchanged on every set gift")
	ok(_count_toasts("(Tinker Workshop ") >= 6, "piece toasts name the set: e.g. '%s'" % _first_toast("(Tinker Workshop"))
	var fallback_ok := true
	for i in 8:
		var r2 := _pay(fs, "bolt")
		var id2 := str(r2.get("item_id", ""))
		var d2 := Catalog.get_item(id2)
		if id2 == "" or str(d2.get("kind", "")) != "decoration" or str(d2.get("source", "")) != "" or str(d2.get("project", "")) != "":
			fallback_ok = false
		if tinker_ids.has(id2) and DecoSets.gift_pool("bolt").size() > 0:
			fallback_ok = false
	ok(DecoSets.gift_pool("bolt").is_empty() and fallback_ok, "all Tinker collected: Bolt falls back to the old random roll (8 draws)")
	# signature gift: trust crossed 30 during these 16 favours (2 each)
	ok(GameState.flag("signature_unlocked_bolt") and GameState.item_count("deco_robot_dog") >= 1,
		"signature legendary still granted at best-friend trust")
	gate("G1 bolt-gifts-tinker+fallback+rewards-unchanged", b)

	# ---------------------------------------------------------------- G2 Commons crowd gives Cozy
	b = fails.size()
	_fresh()
	var cozy: Array = DecoSets.get_set("cozy")["pieces"]
	var cozy_ok := true
	for npc in ["pip", "pop", "stella", "mayor_orbit", "dj_nova"]:
		for k in 2:
			var r3 := _pay(fs, npc)
			if not cozy.has(str(r3.get("item_id", ""))):
				cozy_ok = false
				print("    %s paid %s (not cozy)" % [npc, str(r3.get("item_id", ""))])
	ok(cozy_ok, "10 Commons favours (Pip, Pop, Stella, Mayor Orbit, DJ Nova) all paid Cozy Home pieces")
	ok(DecoSets.collected_count("cozy") == 10, "cozy collected = 10 distinct (got %d)" % DecoSets.collected_count("cozy"))
	gate("G2 commons-gives-cozy", b)

	# ---------------------------------------------------------------- G3 bonus once: by favour, survives save+reload
	b = fails.size()
	_fresh()
	GameState.npc_data("bolt")["friendship"] = 0
	for i in 8:
		_pay(fs, "bolt")
	await get_tree().process_frame
	ok(DecoSets.bonus_earned("tinker") and GameState.item_count("deco_tinker_helper_arm") == 1, "6th Tinker piece by FAVOUR gave the Helper Arm once")
	ok(_count_toasts("Tinker Workshop complete! Bolt sent a Helper Arm") == 1, "bonus toast once: '%s'" % _first_toast("complete!"))
	ok(SaveManager.save_game(), "saved")
	GameState.reset_new_game()
	ok(SaveManager.load_game(), "reloaded")
	toasts.clear()
	GameState.add_item("deco_tinker_cog_clock", 1)      # another piece after reload
	GameState.add_item("deco_tinker_gear_stool", 1)
	await get_tree().process_frame
	ok(GameState.item_count("deco_tinker_helper_arm") == 1 and _count_toasts("complete!") == 0,
		"after save+reload, more Tinker pieces do NOT give a 2nd bonus (have %d)" % GameState.item_count("deco_tinker_helper_arm"))
	gate("G3 bonus-once-by-favour-and-after-reload", b)

	# ---------------------------------------------------------------- G4 bonus by SHOP BUY
	b = fails.size()
	_fresh()
	var glow: Array = DecoSets.get_set("glowshroom")["pieces"]
	for i in 5:
		GameState.add_item(str(glow[i]), 1)
	ok(not DecoSets.bonus_earned("glowshroom"), "5/6 Glowshroom: no bonus yet")
	var price := int(Catalog.get_item(str(glow[5])).get("price", 0))
	var sd := GameState.stardust
	ok(ShopPanel.buy_now(str(glow[5]), price), "shop buy of the 6th piece went through")
	await get_tree().process_frame
	ok(GameState.stardust == sd - price, "shop buy charged %d" % price)
	ok(GameState.item_count("deco_glowshroom_daybed") == 1 and _count_toasts("Glowshroom Hollow complete! Zorp sent") == 1,
		"6th piece by SHOP BUY gave the Glowshroom Daybed once")
	gate("G4 bonus-by-shop-buy", b)

	# ---------------------------------------------------------------- G5 order book
	b = fails.size()
	_fresh()
	var book0 := DecoSets.order_book()
	var dusk: Array = DecoSets.get_set("long_dusk")["pieces"]
	ok(_book_has_set(book0, "long_dusk") == 0, "order book before any Long Dusk piece: no Long Dusk entries")
	GameState.add_item(str(dusk[0]), 1)
	var book := DecoSets.order_book()
	ok(_book_has_set(book, "long_dusk") == 6, "after 1 Long Dusk piece: all 6 orderable (%d)" % _book_has_set(book, "long_dusk"))
	var clean := true
	for d: Dictionary in book:
		var sid := str(d.get("set", ""))
		if str(d.get("source", "")) != "" or int(d.get("price", 0)) <= 0 or sid in ["tangle", "normal", ""] \
				or str(d["id"]).ends_with(str(DecoSets.get_set(sid).get("bonus", "#")).trim_prefix("deco_")):
			clean = false
			print("    bad order entry " + str(d["id"]))
	# start the other display sets too, then re-check: still never Moss / Norm goods, never a bonus
	GameState.add_item("deco_spiral_fern", 1)
	GameState.add_item("deco_normal_sofa", 1)
	GameState.add_item("deco_picket_fence", 1)
	for d: Dictionary in DecoSets.order_book():
		if str(d.get("source", "")) != "" or str(d.get("set", "")) in ["tangle", "normal"]:
			clean = false
			print("    bad order entry " + str(d["id"]))
	ok(clean, "order book never lists a bonus, Moss's or Norm's goods, or a price-0 item")
	ok(_book_has_set(DecoSets.order_book(), "cozy") == 12, "Cozy Home started -> its 12 pieces orderable")
	# refuses when short
	var piece := str(dusk[5])
	var p5 := int(Catalog.get_item(piece).get("price", 0))
	GameState.stardust = p5 - 1
	ok(not ShopPanel.buy_now(piece, p5) and GameState.stardust == p5 - 1 and GameState.item_count(piece) == 0,
		"order refused when 1 stardust short; nothing charged, nothing given")
	GameState.stardust = p5 + 7
	ok(ShopPanel.buy_now(piece, p5) and GameState.stardust == 7 and GameState.item_count(piece) == 1, "order charges exactly %d" % p5)
	# 6th by ORDER gives the bonus
	GameState.stardust = 100000
	toasts.clear()
	for i in range(1, 5):
		GameState.add_item(str(dusk[i]), 1)
	ok(DecoSets.bonus_earned("long_dusk") and GameState.item_count("deco_long_dusk_sundial") == 1, "6th Long Dusk piece by ORDER gave the Sundial")
	# the real panel in order mode
	var sp := ShopPanel.new()
	add_child(sp)
	await get_tree().process_frame
	sp.open(DecoSets.order_book(), "order", "Cosmo Depot", "Pip & Pop")
	var entries: Array = sp._hook_entries("")
	ok(entries.size() == DecoSets.order_book().size() and entries.size() > 0, "ShopPanel order mode shows the book (%d entries)" % entries.size())
	ok(str((sp._hook_actions(entries[0]) as Array)[0]["label"]) == "Order", "ShopPanel order button reads 'Order'")
	sp.queue_free()
	gate("G5 order-book", b)

	# ---------------------------------------------------------------- G6 place / sell keeps collected
	b = fails.size()
	_fresh()
	var ft: Array = DecoSets.get_set("frost_cabin")["pieces"]
	GameState.add_item(str(ft[0]), 1)
	GameState.add_item(str(ft[1]), 1)
	GameState.remove_item(str(ft[0]), 1)                                  # place it
	GameState.add_placed_decoration("home", "probe_inst", str(ft[0]), Vector3.UP, Basis.IDENTITY)
	GameState.remove_item(str(ft[1]), 1)                                  # sell it
	GameState.add_stardust(30)
	ok(GameState.is_collected(str(ft[0])) and GameState.is_collected(str(ft[1])) and DecoSets.collected_count("frost_cabin") == 2,
		"placed + sold pieces still collected (2/6)")
	SaveManager.save_game()
	GameState.reset_new_game()
	SaveManager.load_game()
	ok(DecoSets.collected_count("frost_cabin") == 2, "…and still 2/6 after save+reload")
	gate("G6 place-sell-keeps-collected", b)

	# ---------------------------------------------------------------- G7 old save fills the record
	b = fails.size()
	_fresh()
	var d := GameState.to_dict()
	d.erase("collected")
	d["inventory"] = {"deco_tinker_gear_stool": 1, "gear_bit": 3}
	d["placed_decorations"]["zorp"] = [{"id": "x1", "item": "deco_glowshroom_puff_pouf", "pos": [0, 1, 0], "basis": [1, 0, 0, 0, 1, 0, 0, 0, 1]}]
	d["placed_decorations"]["vela"] = [{"id": "x2", "item": "deco_tea_table", "pos": [0, 1, 0], "basis": [1, 0, 0, 0, 1, 0, 0, 0, 1]}]
	d["wardrobe"] = ["suit_white", "suit_gearworks"]
	var json := JSON.stringify(d)
	GameState.from_dict(JSON.parse_string(json))
	ok(GameState.collected.has("deco_tinker_gear_stool"), "old save: bag piece filled into the record")
	ok(GameState.collected.has("deco_glowshroom_puff_pouf") and GameState.collected.has("deco_tea_table"), "old save: placed pieces on zorp + vela filled")
	ok(GameState.collected.has("suit_gearworks"), "old save: wardrobe filled")
	ok(not GameState.collected.has("gear_bit") and not GameState.collected.has("deco_tinker_cog_clock"), "old save: materials and never-owned pieces NOT in the record")
	ok(DecoSets.collected_count("tinker") == 1 and DecoSets.collected_count("cozy") == 1, "old save: Sets counts right (tinker 1, cozy 1)")
	gate("G7 old-save-fill", b)

	# ---------------------------------------------------------------- ADV sell then re-buy after the bonus
	b = fails.size()
	_fresh()
	var ch: Array = DecoSets.get_set("chalk_terrace")["pieces"]
	for id: String in ch:
		GameState.add_item(id, 1)
	await get_tree().process_frame
	GameState.remove_item(str(ch[2]), 1)
	GameState.remove_item("deco_chalk_terrace_arch", 1)      # even sells/places the bonus away
	toasts.clear()
	ShopPanel.buy_now(str(ch[2]), int(Catalog.get_item(str(ch[2])).get("price", 0)))
	await get_tree().process_frame
	ok(GameState.item_count("deco_chalk_terrace_arch") == 0 and _count_toasts("complete!") == 0, "sell a piece + the bonus, re-buy the piece: no 2nd bonus")
	gate("ADV sell-then-rebuy", b)

	# ---------------------------------------------------------------- ADV reload mid-set
	b = fails.size()
	_fresh()
	var fr: Array = DecoSets.get_set("frost_cabin")["pieces"]
	for i in 3:
		GameState.add_item(str(fr[i]), 1)
	GameState.remove_item(str(fr[0]), 1)   # sold before saving
	SaveManager.save_game()
	GameState.reset_new_game()
	SaveManager.load_game()
	ok(DecoSets.collected_count("frost_cabin") == 3 and not DecoSets.bonus_earned("frost_cabin"), "reload mid-set: 3/6, no bonus")
	toasts.clear()
	for i in range(3, 6):
		GameState.add_item(str(fr[i]), 1)
	await get_tree().process_frame
	ok(GameState.item_count("deco_frost_cabin_aurora_lamp") == 1 and _count_toasts("Frost Cabin complete! Vela sent") == 1,
		"…3 more after reload: the Aurora Lamp once")
	SaveManager.save_game()
	GameState.reset_new_game()
	SaveManager.load_game()
	GameState.add_item(str(fr[0]), 1)
	ok(GameState.item_count("deco_frost_cabin_aurora_lamp") == 1, "…and a second reload + re-buy gives nothing more")
	gate("ADV reload-mid-set", b)

	# ---------------------------------------------------------------- G8 Sets page after save+reload
	b = fails.size()
	var jp := JournalPanel.new()
	add_child(jp)
	await get_tree().process_frame
	jp.page = JournalPanel.PAGE_SETS
	jp.open(false)
	await get_tree().process_frame
	var texts := _label_texts(jp)
	ok(texts.has("Frost Cabin") and texts.has("6/6"), "Sets page shows Frost Cabin 6/6 after reload")
	ok(texts.has("Bonus: Aurora Lamp"), "Sets page names the earned bonus")
	ok(texts.has("Bonus: ???"), "Sets page hides unearned bonuses as ???")
	ok(texts.has("Pip & Pop · Vela's favours") and texts.has("Norm's stamp card"), "Sets page says where pieces come from")
	ok(texts.has("0/5") and texts.has("0/8") and texts.has("0/12"), "display sets listed: tangle 0/5, normal 0/8, cozy 0/12")
	jp.close()
	gate("G8 sets-page-after-reload", b)


func _first_toast(sub: String) -> String:
	for t: String in toasts:
		if t.contains(sub):
			return t
	return "(none)"


func _book_has_set(book: Array, sid: String) -> int:
	var n := 0
	for d: Dictionary in book:
		if str(d.get("set", "")) == sid:
			n += 1
	return n


func _label_texts(n: Node) -> PackedStringArray:
	var out: PackedStringArray = []
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		out.append_array(_label_texts(c))
	return out
