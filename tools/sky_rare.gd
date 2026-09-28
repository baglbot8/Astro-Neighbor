extends SceneTree
## REVIEWER probe (safari4-review). When a run's RAREST sight is up, can you actually take it?
## For every directed pair x 20 days, with all ten hints heard, find the highest-rarity sight in the
## cast and ask: is its window long enough for its own hold, and does another sight's window overlap
## it so far apart that you cannot swing back in time (SLEW 55 deg/s, the run's own number)?
const SLEW := 55.0
func _init() -> void:
	var ids := ["home", "zorp", "bolt", "hub", "fen", "grig", "vela"]
	var heard := []
	for e in SafariCatalog.SIGHTS:
		if bool(e.get("needs_hint", false)):
			heard.append(str(e["id"]))
	var runs := 0
	var with_r4 := 0
	var contested := 0
	var too_short := 0
	var rare_sum := 0.0
	for a in ids:
		for b in ids:
			if a == b:
				continue
			for day in range(1, 21):
				var cast: Array = SafariLanes.draw_cast(a, b, {"hour": 3.2, "day": day, "parts": 5, "heard": heard})
				if cast.is_empty():
					continue
				runs += 1
				var best: Dictionary = {}
				for e in cast:
					if best.is_empty() or int(e["rarity"]) > int(best["rarity"]):
						best = e
				rare_sum += float(int(best["rarity"]))
				if int(best["rarity"]) < 4:
					continue
				with_r4 += 1
				var w := float(best["t_end"]) - float(best["t_start"])
				if w < float(best["hold_sec"]):
					too_short += 1
					continue
				for o in cast:
					if str(o["id"]) == str(best["id"]):
						continue
					var lo: float = maxf(float(o["t_start"]), float(best["t_start"]))
					var hi: float = minf(float(o["t_end"]), float(best["t_end"]))
					if hi - lo <= 0.5:
						continue
					var sep: float = absf(float(o["az0"]) - float(best["az0"]))
					if sep > 180.0:
						sep = 360.0 - sep
					var swing: float = sep / SLEW
					if swing + float(best["hold_sec"]) + float(o["hold_sec"]) > (hi - lo) + 1.5:
						contested += 1
						break
	print("RARE  runs=%d  mean top rarity=%.2f" % [runs, rare_sum / runs])
	print("  runs whose top sight is rarity 4      : %d (%.1f%%)" % [with_r4, 100.0 * with_r4 / runs])
	print("  of those, window shorter than its hold: %d" % too_short)
	print("  of those, contested by an overlapper  : %d (%.1f%% of the r4 runs)" % [
		contested, 100.0 * contested / maxi(1, with_r4)])
	quit()
