extends SceneTree
# REVIEWER's own draw probe. Independent of the RARE builder's (deleted) rare_probe.gd.
# Draws N uniform trips and counts, per run: any rarity-4 present; rarity-4 takeable
# (= present in a slot that is NOT one of the two clash roles); rarity>=3 takeable.
const PAIRS := ["home","zorp","bolt","hub","fen","grig","vela"]

func _count(heard: Array, n: int, parts: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 987654321
	var appear4 := 0; var take4 := 0; var clash4 := 0
	var appear3 := 0; var take3 := 0
	for i in n:
		var a: String = PAIRS[rng.randi_range(0, PAIRS.size() - 1)]
		var b: String = PAIRS[rng.randi_range(0, PAIRS.size() - 1)]
		while b == a:
			b = PAIRS[rng.randi_range(0, PAIRS.size() - 1)]
		var hour: float = rng.randf_range(0.0, 24.0)
		var day: int = rng.randi_range(1, 60)
		var ctx := SafariLanes.make_ctx(hour, day, parts, heard)
		var cast: Array = SafariLanes.draw_cast(a, b, ctx)
		var has4 := false; var t4 := false; var c4 := false
		var has3 := false; var t3 := false
		for e in cast:
			var r: int = int(e.get("rarity", 1))
			var role: String = str(e.get("role", ""))
			var in_clash: bool = role.begins_with("clash")
			if r >= 4:
				has4 = true
				if in_clash: c4 = true
				else: t4 = true
			if r >= 3:
				has3 = true
				if not in_clash: t3 = true
		if has4: appear4 += 1
		if t4: take4 += 1
		if c4 and not t4: clash4 += 1
		if has3: appear3 += 1
		if t3: take3 += 1
	return {"n": n, "appear4": appear4, "take4": take4, "clashonly4": clash4,
		"appear3": appear3, "take3": take3}

func _init() -> void:
	var all_hinted := []
	for e in SafariCatalog.all():
		if bool(e.get("needs_hint", false)):
			all_hinted.append(str(e["id"]))
	print("REV hinted ids (%d): %s" % [all_hinted.size(), str(all_hinted)])
	var n := 6000
	for label in ["told"]:
		var heard: Array = all_hinted if label == "told" else []
		for parts in [0, 1, 2, 3, 4, 5]:
			var r := _count(heard, n, parts)
			print("REV %-6s parts=%d n=%d  r4 appear=%.2f%%  r4 TAKEABLE=%.2f%%  r4 clash-locked-only=%.2f%%  r3+ takeable=%.2f%%" % [
				label, parts, r["n"],
				100.0 * float(r["appear4"]) / float(r["n"]),
				100.0 * float(r["take4"]) / float(r["n"]),
				100.0 * float(r["clashonly4"]) / float(r["n"]),
				100.0 * float(r["take3"]) / float(r["n"])])
	quit()
