class_name SafariPhotoScorer
extends RefCounted
## THE PLANET PHOTO'S NUMBERS (docs/PLANET_SAFARI_SPEC.md 5.4 and 11.1; builders P3, R3). Pure maths
## on a camera and the safari's subject list: no node of its own, no state, nothing drawn. `PlanetSafari` calls
## `score_frame` at the instant the shutter fires; SafariScoring's own functions turn the numbers
## into a grade and a price (see CRAFT).
##
## Every subject is a SPHERE: a world point (its Node3D's origin plus a local offset) and a radius in
## metres. That is the whole contract a subject gives the scorer (see planet_safari.gd's API).
##
## CENTRED  10 * (1 - d), d = the subject centre's distance from the frame centre on screen, divided by
##          HALF THE SCREEN HEIGHT (the spec's own unit). Dead centre 10; touching the top or bottom
##          edge 0. On a wide phone the left and right thirds are past d = 1 and score 0 too, which
##          is what "centred" means.
## SIZE     the subject's projected diameter as a fraction of the frame height, against its BEST BAND
##          (lo, hi): inside the band 10; outside it, x = how many STOPS (doublings) it is outside the
##          band - log2(lo / size) below, log2(size / hi) above - and the score is 10 / (1 + x^2)
##          (R3, spec 11.1, 2026-09-24: "falls off smoothly outside a subject's best band"). Half the
##          band's low end or double its top is 5 (the anchor the old rule already stated), a quarter
##          or four times is 2, an eighth 1. The curve leaves the band with ZERO slope, so there is no
##          cliff at the band's edge, and a stop or more outside it is within half a point of the old
##          10 * size / lo. The old rule was linear in size with a kink at the band's edge. No
##          constant here but the subject's own band: the band is the lever (R4 sets each so that 45 degrees at a creature's usual distance scores 6 or less,
##          which on this curve means lo >= 1.76 x that size).
##          Then times the fraction of the subject's on-screen box that is inside the frame (cut off
##          at the edge) and times the fraction of its sight rays that reach it (half hidden behind a
##          rock).
## FOCUS    10 * (1 - |log2(focus distance / subject distance)|): focused exactly on it 10, focused at
##          1.41x or 0.71x its distance 5, at double or half its distance 0. The one rule is stated,
##          not fitted: a lens focused at twice or half the distance has lost the subject.
## HIDDEN   RAYS_PER_SUBJECT physics rays from the lens to the subject's centre and four points on its
##          rim (the camera's own right and up axes). A ray that reaches the subject's sphere before
##          hitting anything counts. None reaching it = hidden by the planet or a prop = the subject
##          is not in the photo at all.
##
## FACING   (R3, spec 11.1) only for a subject that carries "front": a Callable returning the world-space
##          unit vector its face points along. (dot(front, direction from the subject to the lens) + 1)
##          * 5: looking at you 10, side-on 5, its back 0 - the lead's fixed formula. A subject with no
##          front (a shower, a geyser) has NO facing score: the entry's "facing" is -1 and the grade is
##          made from the other three exactly as before. The direction is the full 3D one, so a
##          subject whose front is level tops out at (cos(elevation) + 1) * 5 when the lens looks
##          down (or up) at it: measured 9.98 for a 0.3 m-high stub 3.2 m away on Bolt (5.5 degrees),
##          lower the closer and steeper you stand over a small creature.
##
## CRAFT    (spec 13.1) SafariScoring.planet_craft: the GEOMETRIC mean of the craft scores the subject
##          has - centred, size, focus, and facing when it has a front - each counted as at least 1 of
##          10 inside the mean, so one bad score hurts but never makes the photo worthless (a perfectly
##          framed back is a Fair).
## GRADE    (spec 13.1) SafariScoring.planet_grade: craft below 0.35 Smudge, below 0.70 Fair, then Fine;
##          a caught moment lifts it one grade (Gallery = a well-made photo mid-moment). The PRICE is the
##          flight's own price_of fed that craft. The flight's own grades are not touched.
##
## THE BEST SUBJECT names the photo (spec 17.1 rule 6): CLASS decides first - a counted subject (its
## category is not in SafariWorld.UNCOUNTED_CATEGORIES: a creature, event or neighbour) beats a "sight",
## and a "sight" beats a "bonus" page. Only inside one class do GRADE and PRICE decide: the highest GRADE
## (spec 13.1's planet scale), then, among equal grades, the highest SafariScoring price (rarity and the
## moment count, so a well-framed rare beats a well-framed common of the same grade), then the higher
## craft. Grade before price within a class because price still weights the moment heavily and the grade
## does not: by price alone an all-zero photo that caught a 2.4 moment (Fair, 26) would beat a perfect
## photo with no moment (Fine, 24). PAY comes from the named subject only (`photo_numbers`' price on
## every OTHER subject in the frame is left as scored - a caller that pays only the named subject, as
## `planet_safari.gd` does, never adds it in).

## Rim points sit this far out from the centre, as a fraction of the radius: inside the sphere, so a
## ray to them still ends on the subject and not past its silhouette. Half-way out is the stated pick.
const RIM_FRAC := 0.5
const RAYS_PER_SUBJECT := 5
## Everything a sight ray may be stopped by: every physics layer. Areas are ignored (triggers are not
## solid); the player's own body is excluded by the caller.
const RAY_MASK := 0xFFFFFFFF


## Scores every subject in the frame. `subjects` is an Array of the registry's Dictionaries (see
## planet_safari.gd). Returns {"best": Dictionary (empty when nothing counted), "all": Array of the
## same shape, best first}. Each entry:
##   key, name, rarity, centred, size, focus (floats 0..10), facing (0..10, or -1 = the subject has
##   no front), has_facing, dist, size_frac, inside_frac, seen_frac,
##   moment_mult, moment_line, plus SafariScoring.planet_photo's fields (craft, skill, grade, price,
##   rarity10, rarity_dust), and (spec 15.5) category (SafariWorld.subject_category) and pays (false
##   for a "bonus" subject, whose price is then 0: a collector's page).
static func score_frame(cam: Camera3D, frame: Vector2, subjects: Array, focus_m: float,
		space: PhysicsDirectSpaceState3D, exclude: Array[RID], t: float) -> Dictionary:
	var out: Array = []
	for s: Dictionary in subjects:
		var e := score_subject(cam, frame, s, focus_m, space, exclude, t)
		if not e.is_empty():
			out.append(e)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca := class_rank(str(a["category"]))
		var cb := class_rank(str(b["category"]))
		if ca != cb:
			return ca > cb
		if int(a["grade_idx"]) != int(b["grade_idx"]):
			return int(a["grade_idx"]) > int(b["grade_idx"])
		if int(a["price"]) != int(b["price"]):
			return int(a["price"]) > int(b["price"])
		return float(a["craft"]) > float(b["craft"]))
	return {"best": out[0] if not out.is_empty() else {}, "all": out}


## Public: the naming CLASS of a scrapbook category (spec 17.1 rule 6) - higher wins the name. A counted
## subject (its category is not one of SafariWorld.UNCOUNTED_CATEGORIES: "creature", "event" or
## "neighbour") is 2; "sight" is 1; "bonus" (SafariWorld.UNPAID_CATEGORIES) is 0. An unknown or empty
## category counts as a counted subject (2) - the safe default for a world that predates categories.
static func class_rank(category: String) -> int:
	if not SafariWorld.UNCOUNTED_CATEGORIES.has(category):
		return 2
	if SafariWorld.UNPAID_CATEGORIES.has(category):
		return 0
	return 1


## One subject, or {} when it is not in the photo (behind the lens, entirely off the frame, or hidden).
static func score_subject(cam: Camera3D, frame: Vector2, s: Dictionary, focus_m: float,
		space: PhysicsDirectSpaceState3D, exclude: Array[RID], t: float) -> Dictionary:
	var p := subject_point(s)
	var r := float(s.get("radius", 0.5))
	var lens := cam.global_position
	var dist := lens.distance_to(p)
	if dist < 0.05 or cam.is_position_behind(p):
		return {}
	var half_h := frame.y * 0.5
	var sp := cam.unproject_position(p)
	# Projected radius, exact for a sphere: the half-angle it subtends is asin(r / dist).
	var half_ang := asin(clampf(r / dist, 0.0, 1.0))
	var tan_half_fov := tan(deg_to_rad(cam.fov) * 0.5)
	var r_px := tan(half_ang) / tan_half_fov * half_h
	var inside := inside_fraction(sp, r_px, frame)
	if inside <= 0.0:
		return {}
	var seen := seen_fraction(cam, p, r, space, exclude)
	if seen <= 0.0:
		return {}
	var d := sp.distance_to(frame * 0.5) / half_h
	var centred := 10.0 * clampf(1.0 - d, 0.0, 1.0)
	var size_frac := 2.0 * r_px / frame.y
	var band: Vector2 = s.get("band", Vector2(0.2, 0.6))
	var size := band_score(size_frac, band) * inside * seen
	var focus := focus_score(focus_m, dist)
	var mm := 1.0
	var line := ""
	var moment: Variant = s.get("moment", Callable())
	if moment is Callable and (moment as Callable).is_valid():
		var m: Variant = (moment as Callable).call(t)
		if m is Dictionary:
			mm = float((m as Dictionary).get("mult", 1.0))
			line = str((m as Dictionary).get("line", ""))
		elif m is float or m is int:
			mm = float(m)
	var facing := facing_score(s, p, lens)
	var rarity := int(s.get("rarity", 1))
	var e := photo_numbers(centred, size, focus, facing, rarity, mm)
	# THE SCRAPBOOK'S CATEGORY (spec 15.5, safari_world.gd CATEGORY): a "bonus" subject is a collector's
	# page and pays nothing - price 0, whatever its grade. Its grade, craft and bars are scored as usual.
	var category := SafariWorld.subject_category(s)
	var pays := SafariWorld.category_pays(category)
	if not pays:
		e["price"] = 0
	e.merge({
		"category": category,
		"pays": pays,
		"key": str(s.get("key", "")),
		"id": str(s.get("id", "")),
		"name": str(s.get("name", "")),
		"kind": str(s.get("kind", "")),
		"rarity": rarity,
		"centred": centred,
		"size": size,
		"focus": focus,
		"facing": facing,
		"has_facing": facing >= 0.0,
		"dist": dist,
		"size_frac": size_frac,
		"inside_frac": inside,
		"seen_frac": seen,
		"screen": sp,
		"moment_line": line,
	})
	return e


## FACING out of 10, or -1 when the subject has no "front" (or it returns nothing usable).
## (dot(front, subject -> lens) + 1) * 5, the lead's fixed formula (spec 11.1).
static func facing_score(s: Dictionary, p: Vector3, lens: Vector3) -> float:
	var fr: Variant = s.get("front", Callable())
	if not (fr is Callable) or not (fr as Callable).is_valid():
		return -1.0
	var v: Variant = (fr as Callable).call()
	if not (v is Vector3):
		return -1.0
	var f := (v as Vector3)
	var to_cam := lens - p
	if f.length_squared() < 1e-8 or to_cam.length_squared() < 1e-8:
		return -1.0
	return clampf((f.normalized().dot(to_cam.normalized()) + 1.0) * 5.0, 0.0, 10.0)


## The grade and price of one subject in one photo: SafariScoring.planet_photo, the planet scale of spec
## 13.1 (see CRAFT and GRADE in the header). `facing` < 0 = the subject has no front.
static func photo_numbers(centred: float, size: float, focus: float, facing: float, rarity: int,
		moment_mult: float) -> Dictionary:
	return SafariScoring.planet_photo(centred, size, focus, rarity, moment_mult, facing)


## The subject's scoring point in world space: its node's origin plus the local offset.
static func subject_point(s: Dictionary) -> Vector3:
	var n: Variant = s.get("node")
	if not (n is Node3D) or not is_instance_valid(n):
		return Vector3.ZERO
	var node := n as Node3D
	var off: Vector3 = s.get("offset", Vector3.ZERO)
	return node.global_transform * off


## Fraction of the subject's on-screen box [c - r, c + r] that lies inside the frame (0..1).
static func inside_fraction(c: Vector2, r_px: float, frame: Vector2) -> float:
	if r_px <= 0.0001:
		return 1.0 if Rect2(Vector2.ZERO, frame).has_point(c) else 0.0
	var ox := maxf(0.0, minf(c.x + r_px, frame.x) - maxf(c.x - r_px, 0.0))
	var oy := maxf(0.0, minf(c.y + r_px, frame.y) - maxf(c.y - r_px, 0.0))
	return clampf((ox * oy) / (4.0 * r_px * r_px), 0.0, 1.0)


## 10 inside the band; outside it 10 / (1 + x^2), x = stops outside the band (see SIZE in the header).
static func band_score(size_frac: float, band: Vector2) -> float:
	var lo := maxf(band.x, 0.0001)
	var hi := maxf(band.y, lo)
	if size_frac <= 0.0:
		return 0.0
	var x := 0.0
	if size_frac < lo:
		x = log(lo / size_frac) / log(2.0)
	elif size_frac > hi:
		x = log(size_frac / hi) / log(2.0)
	return 10.0 / (1.0 + x * x)


## Stops (log2) the subject is SMALLER than its band's low end: > 0 = too small, 0 = big enough.
static func stops_too_small(size_frac: float, band: Vector2) -> float:
	var lo := maxf(band.x, 0.0001)
	if size_frac <= 0.0:
		return INF
	return maxf(0.0, log(lo / size_frac) / log(2.0))


## WHAT THE VIEWFINDER IS ON (for the zoom nudge and the test players): of every awake subject that is
## in front of the lens, with its centre inside the frame and at least one sight ray reaching it, the
## one whose centre is nearest the frame centre. {} when there is none. Returns
## {key, name, size_frac, band, d (centre offset in half frame heights), dist, seen}.
static func aim_subject(cam: Camera3D, frame: Vector2, subjects: Array, space: PhysicsDirectSpaceState3D,
		exclude: Array[RID]) -> Dictionary:
	var half_h := frame.y * 0.5
	var tan_half_fov := tan(deg_to_rad(cam.fov) * 0.5)
	var lens := cam.global_position
	var cands: Array = []
	for s: Dictionary in subjects:
		var p := subject_point(s)
		var dist := lens.distance_to(p)
		if dist < 0.05 or cam.is_position_behind(p):
			continue
		var sp := cam.unproject_position(p)
		if not Rect2(Vector2.ZERO, frame).has_point(sp):
			continue
		var r := float(s.get("radius", 0.5))
		var r_px := tan(asin(clampf(r / dist, 0.0, 1.0))) / tan_half_fov * half_h
		cands.append({"s": s, "p": p, "d": sp.distance_to(frame * 0.5) / half_h, "dist": dist,
			"size_frac": 2.0 * r_px / frame.y, "r": r})
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	for c: Dictionary in cands:
		var seen := seen_fraction(cam, c["p"], float(c["r"]), space, exclude)
		if seen <= 0.0:
			continue
		var s: Dictionary = c["s"]
		return {"key": str(s.get("key", "")), "name": str(s.get("name", "")), "size_frac": c["size_frac"],
			"band": s.get("band", Vector2(0.2, 0.6)), "d": c["d"], "dist": c["dist"], "seen": seen}
	return {}


## 10 * (1 - |log2(focus / dist)|), clamped to 0..10.
static func focus_score(focus_m: float, dist: float) -> float:
	if focus_m <= 0.0 or dist <= 0.0:
		return 0.0
	return 10.0 * clampf(1.0 - absf(log(focus_m / dist) / log(2.0)), 0.0, 1.0)


## Fraction of RAYS_PER_SUBJECT sight rays that reach the subject's sphere (0..1).
static func seen_fraction(cam: Camera3D, p: Vector3, r: float, space: PhysicsDirectSpaceState3D,
		exclude: Array[RID]) -> float:
	if space == null:
		return 1.0
	var lens := cam.global_position
	var b := cam.global_transform.basis
	var right := b.x.normalized() * r * RIM_FRAC
	var up := b.y.normalized() * r * RIM_FRAC
	var pts := [p, p + right, p - right, p + up, p - up]
	var hit_n := 0
	for q: Vector3 in pts:
		if ray_reaches(space, lens, q, p, r, exclude):
			hit_n += 1
	return float(hit_n) / float(pts.size())


## True when a ray from `from` toward `to` meets nothing before it enters the sphere (centre, r).
static func ray_reaches(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, centre: Vector3,
		r: float, exclude: Array[RID]) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, RAY_MASK, exclude)
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	# The ray stopped on something. It still "reached" the subject if that something is inside the
	# subject's own sphere (its own collision shape, or a prop it is standing in).
	return (hit["position"] as Vector3).distance_to(centre) <= r


## WHAT THE FOCUS LOCKS ON (spec 8.2, Q3 2026-09-24): the first thing inside the viewfinder's focus
## ring - the physics world under the centre ray, or any awake, unhidden subject whose projected disc
## touches the ring (`af_r_px`, the radius SafariLayer DRAWS the ring at, in the same viewport pixels
## `frame` is in: what you see in the ring is what focuses). The ring, not a bare ray, because a
## small moving subject that is well centred (a nut-crab, 86 px across at the low end of its band)
## slips off a one-pixel ray between frames, and the old ray then focused on the sky and scored 0.
## Returns:
##   "hit"    false when the ring covers nothing within `far_m` (the sky) - the caller KEEPS its last
##            lock then, it does not jump to the far distance;
##   "near"   the distance a TAP focuses at, at once: the first surface the lens meets - the physics
##            hit, or the subject sphere's near side (its centre distance minus its radius);
##   "dist"   the distance a HELD shutter settles on: the subject's CENTRE, the distance FOCUS is
##            scored against (so holding on a subject always reaches a 10, and a tap on it scores
##            10 * (1 - log2(d / (d - r))): 8.5 for a nut-crab at 3 m, 9.1 at 5 m); the hit
##            distance itself for plain ground or a prop;
##   "key"    the subject's key, or "".
static func centre_ray_focus(cam: Camera3D, frame: Vector2, subjects: Array, space: PhysicsDirectSpaceState3D,
		exclude: Array[RID], far_m: float, af_r_px: float) -> Dictionary:
	var from := cam.global_position
	var dir := -cam.global_transform.basis.z.normalized()
	var phys := INF
	var hit_pos := Vector3.INF
	if space != null:
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * far_m, RAY_MASK, exclude)
		q.collide_with_areas = false
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			hit_pos = hit["position"] as Vector3
			phys = from.distance_to(hit_pos)
	var best_near := phys
	var best_dist := phys
	var best_key := ""
	var centre := frame * 0.5
	var half_h := frame.y * 0.5
	var tan_half_fov := tan(deg_to_rad(cam.fov) * 0.5)
	for s: Dictionary in subjects:
		var c := subject_point(s)
		var r := float(s.get("radius", 0.5))
		var d := from.distance_to(c)
		if d < 0.05 or cam.is_position_behind(c):
			continue
		var r_px := tan(asin(clampf(r / d, 0.0, 1.0))) / tan_half_fov * half_h
		if cam.unproject_position(c).distance_to(centre) > r_px + af_r_px:
			continue
		# The near side: where the centre ray enters the sphere, or the sphere's nearest point.
		var t := ray_sphere(from, dir, c, r)
		var near := t if t > 0.0 else maxf(d - r, 0.05)
		# The centre ray stopped on the subject's own body (a solid inside its sphere).
		if hit_pos != Vector3.INF and hit_pos.distance_to(c) <= r:
			near = minf(near, phys)
		# Something nearer - a prop, the ground, another subject - is what the lens meets first.
		if near > best_near:
			continue
		if seen_fraction(cam, c, r, space, exclude) <= 0.0:
			continue
		best_near = near
		best_dist = d
		best_key = str(s.get("key", ""))
	if best_key == "" and phys == INF:
		return {"hit": false, "near": far_m, "dist": far_m, "key": ""}
	return {"hit": true, "near": best_near, "dist": best_dist, "key": best_key}


## Nearest positive distance along a unit ray to a sphere, or -1.
static func ray_sphere(o: Vector3, d: Vector3, c: Vector3, r: float) -> float:
	var oc := o - c
	var b := oc.dot(d)
	var cc := oc.dot(oc) - r * r
	var disc := b * b - cc
	if disc < 0.0:
		return -1.0
	var sq := sqrt(disc)
	var t0 := -b - sq
	if t0 > 0.0:
		return t0
	var t1 := -b + sq
	return t1 if t1 > 0.0 else -1.0
