extends "res://tools/ps_careless_player.gd"
## THE CAREFUL TEST PLAYER (builder R3, docs/PLANET_SAFARI_SPEC.md 11.1 calibration gate: "a careful one
## - gets close or zooms, waits for the subject to face it, centres it - reaches Fine on most photos and
## Gallery on some"). It wanders and notices exactly like the careless player (ps_careless_player.gd,
## whose header says how to run both and what is synthetic), preferring a subject it has no photo of
## yet. Then it works the shot: it wants the subject to fill the MIDDLE of its best band (the geometric
## middle of lo..hi); if even full zoom (12 degrees) could not get there from where it stands it WALKS
## CLOSER, and if it is too close for the wide lens it backs off (at most APPROACH_MAX s); it raises the
## camera, zooms to exactly that size with the zoom control's own entry point, keeps the subject dead
## centre every frame (things move), waits up to FACING_WAIT s for a subject with a front to face the
## lens (Facing FACING_OK or more) and for all of it to be in view (every sight ray reaches it) - after
## that it shoots anyway if all of it is in view, and gives up without spending film if not - then
## HOLDS the shutter until the focus has settled on that subject (at most 1.5 s) and lets go. It does not
## wait for a subject's special moment: whatever moment happens while it works is what it gets.
## THE VARIETY REPORT (spec 13.2, SYS): its PS_RESULT line carries `per_subject` (photos per subject id),
## `share` (each one's fraction of its photos) and `top_share` / `top_id` - the pacing director's rule is
## that no single subject is more than 30% of a careful player's photos.
## SIGHTS AND BONUS SUBJECTS ARE LEFT OUT OF IT (spec 15.5): the shares are of `photos_counted`, the photos
## of counted subjects only, and it does not go for them unless --ps-collect (ps_careless_player.gd). Works on any planet
## (world.tscn -- --planet=<id>); see ps_careless_player.gd's header for how to run it.

## Good enough facing: 8 of 10 (its face within 66 degrees of the lens).
const FACING_OK := 8.0
const FACING_WAIT := 8.0
const APPROACH_MAX := 25.0
## Zoom headroom kept when deciding whether to walk, so a subject drifting away mid-shot can still be
## followed with the zoom.
const FOV_MARGIN := 2.0
const LOST_SEC := 2.0


func _init() -> void:
	who = "careful"


## A subject it has no photo of yet first, then the nearest.
func spot() -> Dictionary:
	var vis := visible_subjects()
	for v: Dictionary in vis:
		var key := str(v["s"]["key"])
		if _may_shoot(key) and not _shot_at.has(key):
			return v
	for v: Dictionary in vis:
		if _may_shoot(str(v["s"]["key"])):
			return v
	return {}


## The lens (vertical fov, degrees) that makes `e` fill the middle of its band from where the lens is.
func want_fov(e: Dictionary) -> float:
	var s: Dictionary = e["s"]
	var band: Vector2 = s.get("band", Vector2(0.2, 0.6))
	var target := sqrt(maxf(band.x, 0.0001) * maxf(band.y, band.x))
	var r := float(s.get("radius", 0.5))
	return rad_to_deg(2.0 * atan(tan(asin(clampf(r / maxf(float(e["dist"]), 0.01), 0.0, 1.0))) / target))


func _take(target: Dictionary) -> void:
	var s: Dictionary = target["s"]
	# 1. get to where the zoom can make it the right size
	var t := 0.0
	while awake() and t < APPROACH_MAX:
		var e := refresh(s)
		if e.is_empty():
			release_all()
			return
		var need := want_fov(e)
		if need >= CameraRig.FP_FOV_MIN + FOV_MARGIN and need <= CameraRig.FP_FOV_DEFAULT:
			break
		aim_at(e["p"], 0.5)
		var closer := need < CameraRig.FP_FOV_MIN + FOV_MARGIN
		hold_action("move_forward", closer)
		hold_action("move_back", not closer)
		await F(1)
		t += get_process_delta_time()
	release_all()
	if not awake():
		return
	# 2. camera up, zoom, centre, wait for its face and all of it in view
	safari.set_camera_up(true)
	await F(2)
	var waited := 0.0
	var lost := 0.0
	var seen := 0.0
	var ready := false
	while awake() and waited < FACING_WAIT:
		var e := refresh(s)
		if e.is_empty():
			L("gave up: %s went to sleep" % str(s["key"]))
			return
		safari.set_zoom_fov(clampf(want_fov(e), CameraRig.FP_FOV_MIN, CameraRig.FP_FOV_DEFAULT))
		var err := aim_at(e["p"])
		await F(1)
		waited += get_process_delta_time()
		seen = SafariPhotoScorer.seen_fraction(cam(), SafariPhotoScorer.subject_point(s),
			float(s.get("radius", 0.5)), _space(), _exclude())
		if seen <= 0.0:
			lost += get_process_delta_time()
			if lost >= LOST_SEC:
				L("gave up: lost sight of %s" % str(s["key"]))
				return
			continue
		lost = 0.0
		var fa := facing_now(s)
		if waited > 0.1 and seen >= 1.0 and absf(err.x) < 0.3 and absf(err.y) < 0.3 and (fa < 0.0 or fa >= FACING_OK):
			ready = true
			break
	# Waited long enough for its face: a careful player still takes it if all of it is in view, and does
	# not spend film on a frame it is half out of (a crab ducking into its vent, Bolt behind a post).
	if not ready and seen < 1.0:
		L("gave up: %s not fully in view after %.1f s" % [str(s["key"]), waited])
		return
	# 3. hold for focus, tracking it
	if awake():
		await shoot(true, s, 1.5, str(s["key"]))
