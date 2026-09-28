extends SceneTree
## SELF-TEST FOR THE SHAPE TABLE (2026-09-21, shapes round, spike, scratch only).
##
## What it proves, headless, in under a second:
##  1. Every one of SafariCatalog's 51 sights has a row in SafariShapes.ROWS and nothing else does.
##  2. The two files agree on every sight's `draw`, so the catalog is not lying about how a sight
##     is drawn. (The three recasts of this round were written into BOTH files.)
##  3. Every `draw` names one of the six branches the shader actually has.
##  4. No two sights share the same (branch, knobs) fingerprint - the failure this whole round
##     exists to fix. Tints and scale are deliberately NOT part of the fingerprint: two sights
##     that differ only in colour count as the same picture here, which is the strict reading.
##  5. Every knob vector has four finite numbers in a sane range, and the counts the shader loops
##     over (nuclei, bodies, chunks, pebbles, sheets, curtains/lamps) are inside their loop bounds,
##     so nothing is silently clipped.
##
## WHAT THIS DOES NOT PROVE: that any of it LOOKS right. That is the contact sheet's job
## (showcase/safari_sheet.gd) and a person's eyes. This test would pass on 51 different-looking
## piles of garbage.
##
## Run: godot --headless --path <copy> --script res://tools/safari_shapes_selftest.gd

## The shader's fixed loop bounds, and the uniform's own hint_range on n_subj.
const LOOP_CAP := {"comet": 3, "pod": 6, "ice": 4, "derelict": 4, "moonrim": 3, "limb": 5}

var _fail := 0


func _init() -> void:
	var cat_ids := {}
	for e in SafariCatalog.SIGHTS:
		cat_ids[str(e["id"])] = str(e["draw"])
	print("SHAPES SELFTEST  catalog=%d sights  rows=%d" % [cat_ids.size(), SafariShapes.ROWS.size()])

	# 1 + 2: one row per sight, and the two files agree on the branch
	for id in cat_ids:
		if not SafariShapes.ROWS.has(id):
			_bad("no shape row for catalog sight '%s'" % id)
			continue
		var rd: String = str(SafariShapes.ROWS[id]["draw"])
		if rd != cat_ids[id]:
			_bad("'%s' draw disagrees: catalog '%s' vs shapes '%s'" % [id, cat_ids[id], rd])
	for id in SafariShapes.ROWS:
		if not cat_ids.has(id):
			_bad("shape row '%s' is not a catalog sight" % id)

	# 3: every branch exists in the shader
	for id in SafariShapes.ROWS:
		var d: String = str(SafariShapes.ROWS[id]["draw"])
		if not SafariShapes.DRAW.has(d):
			_bad("'%s' names branch '%s', which the shader does not have" % [id, d])
		if SafariCatalog.DRAW.has(d) and int(SafariCatalog.DRAW[d]) != int(SafariShapes.DRAW[d]):
			_bad("branch '%s' has a different number in the two files" % d)

	# 4: no two sights are the same picture
	var seen := {}
	var clashes := 0
	for id in SafariShapes.ROWS:
		var r: Dictionary = SafariShapes.ROWS[id]
		var fp := "%s|%s|%s|%s" % [str(r["draw"]), str(r["f1"]), str(r["f2"]), str(r["f3"])]
		if seen.has(fp):
			_bad("'%s' and '%s' are the SAME PICTURE (same branch, same twelve knobs)"
				% [id, seen[fp]])
			clashes += 1
		seen[fp] = id
	print("  distinct (branch + knobs) fingerprints: %d of %d  [%d clashes]"
		% [seen.size(), SafariShapes.ROWS.size(), clashes])

	# 5: knobs finite, in range, and counts inside the shader's loop bounds
	var count_knob := {"comet": ["f1", 3], "pod": ["f1", 0], "ice": ["f1", 0],
		"moonrim": ["f1", 2], "derelict": ["f2", 1], "limb": ["f1", 2]}
	for id in SafariShapes.ROWS:
		var r: Dictionary = SafariShapes.ROWS[id]
		var d: String = str(r["draw"])
		for key in ["f1", "f2", "f3"]:
			var v: Array = r[key]
			if v.size() != 4:
				_bad("'%s' %s has %d numbers, not 4" % [id, key, v.size()])
				continue
			for x in v:
				if not is_finite(float(x)) or absf(float(x)) > 64.0:
					_bad("'%s' %s has a bad number %s" % [id, key, str(x)])
		if count_knob.has(d):
			var which: Array = count_knob[d]
			var n: float = float((r[str(which[0])] as Array)[int(which[1])])
			var cap: int = int(LOOP_CAP[d])
			# On the limb branch f1.z is "how many things along the limb" and it feeds TWO loops:
			# the curtains (5) and the lamps (6). Which cap applies depends on whether this sight
			# has curtains at all, so the test asks the same question the shader does.
			if d == "limb" and float((r["f1"] as Array)[0]) <= 0.002:
				cap = 6
			if n > float(cap) + 0.001:
				_bad("'%s' asks for %.1f of a thing the shader loops over %d times"
					% [id, n, cap])
		if float(r.get("scale", 1.0)) <= 0.05:
			_bad("'%s' scale %.3f divides by ~zero in the shader" % [id, r.get("scale", 1.0)])

	# branch spread, printed so a regression is visible
	var per := {}
	for id in SafariShapes.ROWS:
		var d: String = str(SafariShapes.ROWS[id]["draw"])
		per[d] = int(per.get(d, 0)) + 1
	var line := ""
	for d in per:
		line += "%s=%d " % [d, per[d]]
	print("  per branch: %s" % line)

	if _fail == 0:
		print("SHAPES SELFTEST PASSED")
	else:
		print("SHAPES SELFTEST FAILED (%d problems)" % _fail)
	quit(0 if _fail == 0 else 1)


func _bad(msg: String) -> void:
	_fail += 1
	print("  FAIL: " + msg)
