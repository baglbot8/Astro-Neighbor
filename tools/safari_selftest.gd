extends SceneTree
## THE SAFARI'S ONE SELF-TEST (2026-09-21, merge round). One command, pass or fail per item:
##
##     godot --headless --path <project> --script res://tools/safari_selftest.gd
##
## It measures the six things the merge was graded on. Everything it prints is computed here and
## now off SafariLanes / SafariCatalog / SafariScoring - no number is typed into this file except
## the thresholds the brief set (6-7 sights, 3 on the glass, 1.5 s, 60-100, 150-200).
##
## SAY WHAT IS SYNTHETIC: all of it. This is a model of the flight, not the flight. It never opens
## a window, never renders a frame, never sends an input event, and the two "trips" in item 4 are
## two hand-written models of a player. Nothing here proves the eyepiece draws any of it.
##
## Exit code 1 if any item fails, so it can go in a build gate.

const RUNS := 1200          ## drawn runs for items 1, 2, 3 and 5. The brief asks for 300+.
const TRIPS := 600          ## simulated trips for the payout band in item 4.

## The player models in item 4, stated so they can be argued with. Round 2 shipped ONE steady
## model and the critic showed that other, equally defensible readings of "steady" paid up to a
## third more, so the band held for the model it had been solved from and for nothing else. There
## is now a FAMILY, and the band has to hold for every member marked steady.
##   name, sharpness mean, how the moment lands, limb sights shot too, counts as steady
const STEADY_MODELS := [
	["S1 shutter at random 0.55",   0.55, "shutter", false, true],
	["S2 moment 1 plate in 4 0.55", 0.55, "every4",  false, true],
	["S3 S2 with limbs shot too",   0.55, "every4",  true,  true],
	["S4 shutter at random 0.45",   0.45, "shutter", false, true],
	["S5 shutter at random 0.65",   0.65, "shutter", false, true],
	["S6 no moment ever 0.55",      0.55, "never",   false, true],
	["S7 moment-hunter 0.55",       0.55, "always",  false, false],
	["S8 moment 1 in 3, 0.60",      0.60, "every3",  false, true],
]
## S7 is printed but NOT gated: a player who lands each sight's best moment on all four plates is
## timing every moment, which is the great player's defining skill. That is a moment-hunter with
## shaky hands, not a steady player, and no scale puts it under 100 while great still clears 150.
##   GREAT holds almost perfectly, catches each sight's best moment, and spends its plates on the
##   sights worth the most rather than on whatever came up first.
const GREAT_SHARP := 0.95
const STEADY_SPREAD := 0.12   ## sd of the per-catch sharpness draw. A steady player is not a robot.
const GREAT_SPREAD := 0.03

var _fails: int = 0
var _lines: Array = []


func _initialize() -> void:
	print("== safari self-test ==")
	print("catalog %d sights, %d lanes, film %d plates" % [SafariCatalog.SIGHTS.size(),
		SafariLanes.LANES.size(), SafariScoring.FILM_BASE])
	print("")
	var runs := _sweep()
	_item1(runs)
	_item2(runs)
	_item3(runs)
	_item4()
	_item5()
	_sample()
	print("")
	print("== %s ==" % ("SAFARI SELFTEST PASSED" if _fails == 0 else
		"SAFARI SELFTEST FAILED (%d items)" % _fails))
	quit(0 if _fails == 0 else 1)


func _ok(item: String, good: bool, detail: String) -> void:
	if not good:
		_fails += 1
	print("%s  %-46s %s" % ["PASS" if good else "FAIL", item, detail])


# ---------------------------------------------------------------- the sweep everything reads
## One pile of drawn runs, so items 1, 2, 3 and 5 all measure THE SAME draws.
func _sweep() -> Array:
	var out: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260921
	var worlds: Array = SafariLanes.DEPTH.keys()
	var hinted: Array = SafariCatalog.hinted_ids()
	while out.size() < RUNS:
		var a := str(worlds[rng.randi() % worlds.size()])
		var b := str(worlds[rng.randi() % worlds.size()])
		if a == b:
			continue
		# half the runs have heard every hint, half have heard none, so item 5 has both halves.
		var told: bool = out.size() % 2 == 0
		var ctx := SafariLanes.make_ctx(rng.randf() * 24.0, rng.randi() % 30, rng.randi() % 6,
			hinted if told else [])
		out.append({"from": a, "to": b, "told": told, "ctx": ctx,
			"lane": SafariLanes.lane_id_for(a, b),
			"cast": SafariLanes.draw_cast(a, b, ctx)})
	return out


# ---------------------------------------------------------------- 1. one system
func _item1(runs: Array) -> void:
	var problems: Array = SafariLanes.check()
	problems.append_array(SafariCatalog.problems())

	# all 42 directed trips resolve to a lane and to a legal run
	var directed := 0
	var sizes := {}
	var dupes := 0
	var worlds: Array = SafariLanes.DEPTH.keys()
	for a in worlds:
		for b in worlds:
			if a == b:
				continue
			directed += 1
			if SafariLanes.lane_id_for(str(a), str(b)) == "":
				problems.append("%s->%s has no lane" % [a, b])
	# ids, and also WORDS: two entries in one run with the same title or the same blurb is the
	# same picture twice, which is what caught the home limb and home_aurora sharing a blurb.
	var echoes := 0
	for r in runs:
		var cast: Array = r["cast"]
		sizes[cast.size()] = int(sizes.get(cast.size(), 0)) + 1
		var seen := {}
		var said := {}
		for e in cast:
			if seen.has(e["id"]):
				dupes += 1
			seen[e["id"]] = true
			for k in ["title", "blurb"]:
				if said.has(str(e[k])):
					echoes += 1
				said[str(e[k])] = true
	var bad_size := 0
	for k in sizes:
		if int(k) < 6 or int(k) > 7:
			bad_size += int(sizes[k])
	_ok("1 one system: data, ids, signatures", problems.is_empty(),
		"%d problems%s" % [problems.size(), "" if problems.is_empty() else ": " + str(problems)])
	_ok("1 all 21 pairs / 42 directed trips resolve", directed == 42,
		"%d directed trips, %d pairs" % [directed, SafariLanes.pairs_covered().size()])
	_ok("1 every run is 6 or 7 sights, no duplicates", bad_size == 0 and dupes == 0,
		"sizes %s, duplicate ids %d, over %d runs" % [str(sizes), dupes, runs.size()])
	_ok("1 no run says the same thing twice", echoes == 0,
		"%d repeated titles or blurbs over %d runs" % [echoes, runs.size()])

	# how often the seventh sight - the conditions slot - actually turns up, told and untold
	var seven := {"told": 0, "untold": 0}
	var tot := {"told": 0, "untold": 0}
	var sig_hits := {}
	var sig_runs := {}
	for r2 in runs:
		var key: String = "told" if bool(r2["told"]) else "untold"
		tot[key] = int(tot[key]) + 1
		if (r2["cast"] as Array).size() == 7:
			seven[key] = int(seven[key]) + 1
		var lid := str(r2["lane"])
		sig_runs[lid] = int(sig_runs.get(lid, 0)) + 1
		for e2 in r2["cast"]:
			if (SafariLanes.LANES[lid]["signatures"] as Array).has(str(e2["id"])):
				sig_hits[lid] = int(sig_hits.get(lid, 0)) + 1
				break
	print("    a seventh sight: %.0f%% of trips once you have heard the hints, %.0f%% before" %
		[100.0 * float(seven["told"]) / maxf(float(tot["told"]), 1.0),
		100.0 * float(seven["untold"]) / maxf(float(tot["untold"]), 1.0)])
	var sig := ""
	for lid2 in SafariLanes.LANES:
		sig += "%s %.0f%%  " % [lid2,
			100.0 * float(sig_hits.get(lid2, 0)) / maxf(float(sig_runs.get(lid2, 1)), 1.0)]
	print("    a lane shows one of its own two signatures: " + sig)


# ---------------------------------------------------------------- 2. shapes and the glass
func _item2(runs: Array) -> void:
	var bad: Array = []
	var by_shape := {}
	for e in SafariCatalog.SIGHTS:
		var d := str(e.get("draw", ""))
		if not SafariCatalog.DRAW.has(d):
			bad.append(str(e["id"]) + " draws " + d)
		by_shape[d] = int(by_shape.get(d, 0)) + 1
	_ok("2 every sight is one of the six shader shapes", bad.is_empty(),
		"%s" % str(by_shape))

	var worst := 0
	for r in runs:
		var cast: Array = r["cast"]
		for e in cast:
			var n := 0
			for f in cast:
				if float(f["t_start"]) < float(e["t_end"]) \
						and float(f["t_end"]) > float(e["t_start"]):
					n += 1
			worst = maxi(worst, n)
	_ok("2 never more than 3 on the glass at once", worst <= SafariCatalog.MAX_ON_GLASS,
		"worst was %d over %d runs (eyepiece holds %d)" %
		[worst, runs.size(), SafariCatalog.MAX_ON_GLASS])

	# what a run is actually made of, shape by shape, so nobody has to take the table on trust
	# The two world limbs are free and always there, so they are counted separately: what matters
	# for variety is the mix of the four or five sights the lane actually DREW.
	var drawn := {}
	var n_sights := 0
	for r in runs:
		for e in r["cast"]:
			if str(e["slot"]) in ["behind", "ahead"]:
				continue
			var k := int(e["kind"])
			drawn[k] = int(drawn.get(k, 0)) + 1
			n_sights += 1
	var mix := ""
	for name in SafariCatalog.DRAW:
		var k2: int = int(SafariCatalog.DRAW[name])
		mix += "%s %.0f%%  " % [name, 100.0 * float(drawn.get(k2, 0)) / float(n_sights)]
	# nothing is ever placed where the scope cannot be pointed
	var out_of_reach := 0
	var el_lo := 999.0
	var el_hi := -999.0
	for r2 in runs:
		for e2 in r2["cast"]:
			for k3 in ["el0", "el1"]:
				var v := float(e2[k3])
				el_lo = minf(el_lo, v)
				el_hi = maxf(el_hi, v)
				if v < SafariLanes.EL_MIN or v > SafariLanes.EL_MAX:
					out_of_reach += 1
	_ok("2 every sight is inside the scope's elevation", out_of_reach == 0,
		"el %.1f..%.1f, limits %.0f..%.0f" %
		[el_lo, el_hi, SafariLanes.EL_MIN, SafariLanes.EL_MAX])

	print("    the DRAWN sights, by shape (the 2 world limbs are free and not counted): " + mix)


# ---------------------------------------------------------------- 3. the clash
## THE CRITIC'S TEST, both ways round. You enter the first window the instant it opens, hold, swing
## at the real slew speed, and hold again. "Spare" is how much of the second window is left when
## you would be done: NEGATIVE means you missed it, which is what is wanted.
func _item3(runs: Array) -> void:
	var best_spare := -999.0          # the luckiest run in the whole sweep
	var best_where := ""
	var counted := 0
	var per_lane := {}
	for r in runs:
		var cast: Array = r["cast"]
		var a := {}
		var b := {}
		for e in cast:
			if str(e["slot"]) == "clash_a":
				a = e
			elif str(e["slot"]) == "clash_b":
				b = e
		if a.is_empty() or b.is_empty():
			continue
		counted += 1
		var lid := str(r["lane"])
		var cross := SafariLanes.swing_sec(str(a["side"]), str(b["side"]))
		# both orders: take A first then swing to B, and take B first then swing to A.
		for pair in [[a, b], [b, a]]:
			var first: Dictionary = pair[0]
			var second: Dictionary = pair[1]
			var finish: float = float(first["t_start"]) + float(first["hold_sec"]) + cross \
				+ float(second["hold_sec"])
			var spare: float = float(second["t_end"]) - finish
			if spare > best_spare:
				best_spare = spare
				best_where = "%s %s then %s" % [lid, first["id"], second["id"]]
			if not per_lane.has(lid) or spare > float(per_lane[lid]):
				per_lane[lid] = spare
	_ok("3 the clash misses by >= 1.5 s, real drawn holds", best_spare <= -1.5,
		"best spare anywhere was %+.2f s (%s), %d clashes" % [best_spare, best_where, counted])

	# and the same test at the lane's MAXIMUM hold, which is how the critic wrote it
	var worst_max := -999.0
	for lid in SafariLanes.LANES:
		var miss := SafariLanes.clash_miss_sec(lid, SafariLanes.max_hold_on(lid))
		worst_max = maxf(worst_max, -miss)
	_ok("3 same at the lane's maximum hold", worst_max <= -1.5,
		"best spare %+.2f s over the eight lanes" % worst_max)

	var per := ""
	for lid in per_lane:
		per += "%s %+.2f  " % [lid, per_lane[lid]]
	_lines.append("    per lane, best spare: " + per)
	print("    per lane, best spare: " + per)


# ---------------------------------------------------------------- 4. scoring and the economy
func _item4() -> void:
	# rarity 4 pays more than rarity 3, at every skill
	var r4_beats := true
	for sm in [0.0, 0.25, 0.5, 0.75, 1.0]:
		if SafariScoring.quality_of(4, sm, 1.0) <= SafariScoring.quality_of(3, sm, 1.0):
			r4_beats = false
	_ok("4 rarity 4 pays more than rarity 3", r4_beats,
		"perfect shot: rare %d, hardly ever %d" %
		[SafariScoring.price_of(3, 1.0, SafariScoring.MOMENT_CEILING),
		SafariScoring.price_of(4, 1.0, SafariScoring.MOMENT_CEILING)])

	# nothing authored is clamped
	var authored := SafariCatalog.max_authored_moment()
	var clamped: Array = []
	for e in SafariCatalog.SIGHTS:
		for m in e.get("moments", []):
			if float(m["mult"]) > SafariScoring.MOMENT_CEILING + 0.0001:
				clamped.append(str(e["id"]))
	_ok("4 no authored moment is clamped",
		clamped.is_empty() and is_equal_approx(authored, SafariScoring.MOMENT_CEILING),
		"highest authored %.1f, ceiling %.1f, clamped %d" %
		[authored, SafariScoring.MOMENT_CEILING, clamped.size()])

	# skill plus moment still outweighs rarity
	var skill_swing := SafariScoring.PAY_SKILL_MOMENT
	var rarity_swing := SafariScoring.PAY_RARITY
	_ok("4 skill+moment outweighs rarity", skill_swing > rarity_swing * 2.0,
		"skill %.1f vs rarity %.1f (%.2fx)" %
		[skill_swing, rarity_swing, skill_swing / rarity_swing])

	print("    payout table (stardust per print):")
	print("      %-9s %8s %8s %8s %12s" % ["shot", "common", "uncommon", "rare", "hardly ever"])
	var best_bad := 0
	var worst_avg := 99999
	for row in SafariScoring.example_payout_table():
		print("      %-9s %8d %8d %8d %12d" % [row["shot"], row["common"], row["uncommon"],
			row["rare"], row["hardly_ever"]])
		for key in ["common", "uncommon", "rare", "hardly_ever"]:
			if str(row["shot"]) == "bad":
				best_bad = maxi(best_bad, int(row[key]))
			elif str(row["shot"]) == "average":
				worst_avg = mini(worst_avg, int(row[key]))
	# the film price is a RULE read off that table, not a typed number: strictly above every bad
	# catch and strictly below every average one, so a bought plate is always a real bet.
	_ok("4 film price still sits between bad and average",
		SafariScoring.FILM_BUY_PRICE > best_bad and SafariScoring.FILM_BUY_PRICE < worst_avg,
		"best bad %d < plate %d < worst average %d" %
		[best_bad, SafariScoring.FILM_BUY_PRICE, worst_avg])

	# ---- the trip bands, over a FAMILY of players rather than one model.
	# Round 2 failed here: the scale had been solved from two player models, so it held for those
	# two and missed by 3-11 for every other reading of "steady". Every model below is run over
	# the real draw; the band must hold for ALL of the ones marked steady.
	print("    a trip: %d plates, no purchases, no upgrades, %d drawn trips per model." %
		[SafariScoring.FILM_BASE, TRIPS])
	print("    %-30s %7s %7s %7s  %s" % ["player model", "mean", "lo", "hi", "verdict"])
	var worst := 1e9
	var best := -1e9
	var all_in := true
	var names_out: Array = []
	for m in STEADY_MODELS:
		var r := _trip_model(float(m[1]), str(m[2]), bool(m[3]), false)
		var counts: bool = bool(m[4])
		var inside: bool = r["mean"] >= 60.0 and r["mean"] <= 100.0
		if counts:
			worst = minf(worst, float(r["mean"]))
			best = maxf(best, float(r["mean"]))
			if not inside:
				all_in = false
				names_out.append(str(m[0]))
		print("    %-30s %7.1f %7d %7d  %s" % [str(m[0]), r["mean"], r["lo"], r["hi"],
			("in band" if inside else "OUT") if counts else "not counted as steady"])
	_ok("4 every steady model pays 60-100 stardust", all_in,
		"%d models counted, spread %.1f-%.1f%s" % [_steady_counted(), worst, best,
		"" if all_in else ", out: " + ", ".join(PackedStringArray(names_out))])

	var great := _trip_model(GREAT_SHARP, "best", false, true)
	_ok("4 a great trip pays 150-200 stardust",
		great["mean"] >= 150.0 and great["mean"] <= 200.0,
		"mean %.1f, range %d-%d over %d trips" % [great["mean"], great["lo"], great["hi"], TRIPS])

	# The band that binds the scale from each side, so the next reader can re-derive PAY_SCALE.
	print("    scale window at these models: k >= %.3f (great floor), k <= %.3f (sharpest steady)"
		% [150.0 / (great["mean"] / SafariScoring.PAY_SCALE),
		100.0 / (best / SafariScoring.PAY_SCALE)])
	print("    cheapest decoration is 120: %.1f-%.1f steady trips, %.1f great ones" %
		[120.0 / best, 120.0 / worst, 120.0 / great["mean"]])
	print("    NOT TWO TRIPS, and said plainly: the brief wanted 120 to be about two ordinary")
	print("      trips. It is %.1f-%.1f. Two trips needs the middle steady near 60, which is" %
		[120.0 / best, 120.0 / worst])
	print("      scale %.2f, and the great trip would then pay %.0f - under its own 150 floor."
		% [SafariScoring.PAY_SCALE * 60.0 / _mid_steady(), great["mean"] * 60.0 / _mid_steady()])


func _steady_counted() -> int:
	var n := 0
	for m in STEADY_MODELS:
		if bool(m[4]):
			n += 1
	return n


## The middle steady model (S1, a random shutter at 0.55) - the one number the sentences above use
## when they say "an ordinary trip".
func _mid_steady() -> float:
	return float(_trip_model(0.55, "shutter", false, false)["mean"])


## ONE simulated trip model. FILM_BASE plates, no purchases, no upgrades, a real drawn cast.
##   mode "shutter" the shutter falls at a uniformly random instant inside the sight's own window,
##                  so whether a moment is live is decided by the CATALOG's moment windows and not
##                  by a rate this file made up. This is the critic's model and the fairest one.
##   mode "every4" / "every3"  the player deliberately lands the best moment on one plate in four
##                  / in three.
##   mode "always"  the best moment on every plate. Counted as NOT steady - see safari_scoring.gd.
##   mode "never"   no moment ever lands.
##   mode "best"    the great player: best moment every plate, and the plates spent on the sights
##                  worth the most rather than on whatever came up first.
func _trip_model(mu: float, mode: String, include_limbs: bool, great: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242 if great else 131313
	var worlds: Array = SafariLanes.DEPTH.keys()
	var hinted: Array = SafariCatalog.hinted_ids()
	var total := 0.0
	var lo := 99999
	var hi := 0
	var n := 0
	while n < TRIPS:
		var a := str(worlds[rng.randi() % worlds.size()])
		var b := str(worlds[rng.randi() % worlds.size()])
		if a == b:
			continue
		n += 1
		var ctx := SafariLanes.make_ctx(rng.randf() * 24.0, rng.randi() % 30,
			5 if great else rng.randi() % 6, hinted if great else [])
		var cast: Array = SafariLanes.draw_cast(a, b, ctx)
		var order: Array = []
		for e in cast:
			if include_limbs or not str(e["id"]).begins_with("limb_"):
				order.append(e)
		if great:
			order.sort_custom(func(x, y): return _best_price(x) > _best_price(y))
		var paid := 0
		for i in mini(SafariScoring.FILM_BASE, order.size()):
			var e: Dictionary = order[i]
			var mult := 1.0
			match mode:
				"shutter":
					var ts := rng.randf_range(float(e["t_start"]), float(e["t_end"]))
					for m in e.get("moments", []):
						if ts >= float(m["t0"]) and ts <= float(m["t1"]):
							mult = maxf(mult, float(m["mult"]))
				"every4":
					if i % 4 == 0:
						mult = _best_mult(e)
				"every3":
					if i % 3 == 0:
						mult = _best_mult(e)
				"always", "best":
					mult = _best_mult(e)
			var sharp := clampf(rng.randfn(mu, GREAT_SPREAD if great else STEADY_SPREAD), 0.0, 1.0)
			paid += SafariScoring.price_of(int(e["rarity"]), sharp, mult)
		total += float(paid)
		lo = mini(lo, paid)
		hi = maxi(hi, paid)
	return {"mean": total / float(n), "lo": lo, "hi": hi}


func _best_mult(e: Dictionary) -> float:
	var best := 1.0
	for m in e.get("moments", []):
		best = maxf(best, float(m["mult"]))
	return best


# ---------------------------------------------------------------- 5. hints
func _item5() -> void:
	var bad: Array = []
	var hinted: Array = SafariCatalog.hinted_ids()
	for sid in hinted:
		var h := SafariCatalog.hint_for(str(sid))
		if str(h.get("npc", "")) == "":
			bad.append(str(sid) + ": no npc")
		if str(h.get("line", "")) == "":
			bad.append(str(sid) + ": no line")
		elif str(h["line"]).length() > SafariLanes.MAX_CHARS:
			bad.append("%s: line is %d chars" % [sid, str(h["line"]).length()])
	_ok("5 every hinted sight has an npc and a line", bad.is_empty(),
		"%d hinted sights, longest line %d chars%s" %
		[hinted.size(), _longest_hint(), "" if bad.is_empty() else ": " + str(bad)])

	# THE GATE. A big sweep with nobody having heard anything: a hinted sight must never appear.
	var leaks := 0
	var told_hits := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 909090
	var worlds: Array = SafariLanes.DEPTH.keys()
	var n := 0
	while n < RUNS * 3:
		var a := str(worlds[rng.randi() % worlds.size()])
		var b := str(worlds[rng.randi() % worlds.size()])
		if a == b:
			continue
		n += 1
		var hour := rng.randf() * 24.0
		var day := rng.randi() % 60
		for e in SafariLanes.draw_cast(a, b, SafariLanes.make_ctx(hour, day, 5, [])):
			if hinted.has(str(e["id"])):
				leaks += 1
		for e2 in SafariLanes.draw_cast(a, b, SafariLanes.make_ctx(hour, day, 5, hinted)):
			if hinted.has(str(e2["id"])):
				told_hits += 1
	_ok("5 the hint gate holds", leaks == 0,
		"%d appearances untold, %d told, over %d trips each" % [leaks, told_hits, n])
	for sid2 in hinted:
		var h2 := SafariCatalog.hint_for(str(sid2))
		print("      %-16s %-12s \"%s\"" % [sid2, h2["npc"], h2["line"]])


## What a plate on this sight is worth to a player who holds it perfectly and catches its best
## moment. The "great" trip model spends its film in this order.
func _best_price(e: Dictionary) -> int:
	var best := 1.0
	for m in e.get("moments", []):
		best = maxf(best, float(m["mult"]))
	return SafariScoring.price_of(int(e["rarity"]), GREAT_SHARP, best)


## One run printed in full, so a reader can see what the numbers are describing.
func _sample() -> void:
	var hinted: Array = SafariCatalog.hinted_ids()
	var ctx := SafariLanes.make_ctx(3.2, 4, 3, hinted)
	print("")
	print("    a sample run: home -> vela, 03:12, day 4, 3 parts, every hint heard")
	var lm := SafariLanes.landmarks("home", "vela", 3.2)
	print("      %s - %s" % [lm["lane"], lm["mood"]])
	for e in SafariLanes.draw_cast("home", "vela", ctx):
		print("      %5.1f-%5.1f  %-9s az %6.1f el %5.1f  hold %.1f  r%d  %-7s  %s" %
			[e["t_start"], e["t_end"], e["slot"], e["az0"], e["el0"], e["hold_sec"],
			e["rarity"], _shape_name(int(e["kind"])), e["title"]])


func _shape_name(k: int) -> String:
	for name in SafariCatalog.DRAW:
		if int(SafariCatalog.DRAW[name]) == k:
			return str(name)
	return "?"


func _longest_hint() -> int:
	var m := 0
	for sid in SafariCatalog.hinted_ids():
		m = maxi(m, str(SafariCatalog.hint_for(str(sid)).get("line", "")).length())
	return m
