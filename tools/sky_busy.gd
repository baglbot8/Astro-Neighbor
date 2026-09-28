extends SceneTree
## REVIEWER probe (safari4-review, 2026-09-21). How much of a run has anything in the sky, and how
## much of it can a player with 4 plates actually spend holding a subject?
func _init() -> void:
	var ids := ["home", "zorp", "bolt", "hub", "fen", "grig", "vela"]
	var cov_sum := 0.0
	var hold_sum := 0.0
	var runs := 0
	var sec_sum := 0.0
	var cast_sum := 0.0
	var pairs_photo := 0
	var pairs_all := 0
	for a in ids:
		for b in ids:
			if a == b:
				continue
			pairs_all += 1
			if b != "hub":
				pairs_photo += 1
			for day in range(1, 21):
				var ctx := {"hour": 21.0, "day": day, "parts": 2, "heard": []}
				var cast: Array = SafariLanes.draw_cast(a, b, ctx)
				if cast.is_empty():
					continue
				var lane: Dictionary = SafariLanes.lane_for(a, b)
				var secs := float(lane["seconds"])
				var spans: Array = []
				var holds := 0.0
				for e in cast:
					spans.append([float(e["t_start"]), float(e["t_end"])])
					holds += float(e["hold_sec"])
				spans.sort_custom(func(x, y): return x[0] < y[0])
				var union := 0.0
				var cur0: float = spans[0][0]
				var cur1: float = spans[0][1]
				for i in range(1, spans.size()):
					if spans[i][0] <= cur1:
						cur1 = maxf(cur1, spans[i][1])
					else:
						union += cur1 - cur0
						cur0 = spans[i][0]
						cur1 = spans[i][1]
				union += cur1 - cur0
				# what 4 plates can actually consume: the four longest holds in the cast
				var hs: Array = []
				for e in cast:
					hs.append(float(e["hold_sec"]))
				hs.sort()
				hs.reverse()
				var payable := 0.0
				for i in range(mini(4, hs.size())):
					payable += hs[i]
				cov_sum += union / secs
				hold_sum += payable / secs
				sec_sum += secs
				cast_sum += float(cast.size())
				runs += 1
	print("BUSY  runs=%d  mean run=%.1f s  mean cast=%.2f sights" % [runs, sec_sum / runs, cast_sum / runs])
	print("  something in the sky      : %.1f%% of the run" % (100.0 * cov_sum / runs))
	print("  time the 4 plates can use : %.1f%% of the run (sum of the 4 longest holds)" % (100.0 * hold_sum / runs))
	print("  directed pairs with a lane and not to the Commons: %d of %d" % [pairs_photo, pairs_all])
	quit()
