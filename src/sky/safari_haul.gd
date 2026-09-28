class_name SafariHaul
extends Node
## SPIKE (2026-09-21, scratch only, label "wire"). WHAT HAPPENS TO THE PHOTOS WHEN YOU LAND.
##
## THE BUG THIS FILE IS. safari_run.gd ended a flight with `run_finished.emit(_haul)` and NOTHING
## IN THE PROJECT WAS CONNECTED TO IT. The reviewer found it and wrote it down: the haul is thrown
## away. A player flew 56 seconds, waited out a driftling's moment, gave up the ice to get it — and
## then landed, and the five photographs did not exist. No journal page, no print in the satchel,
## no coin, no neighbour reaction. The card on the screen was the only place they were ever real,
## and it is destroyed with the scene.
##
## So this is the landing. One node, connected to one signal, and the haul becomes the same three
## things a telescope print has always become:
##
##   A PRINT      SkyPrint.make(...), the real object, with a real rendered preview (below).
##   A PAGE       SkyJournal.take_print(print, page_subject) — best-shot-per-sight, exactly like a
##                tripod print. A better shot of the same sight replaces the old one and says so.
##   A COIN       PrintBag.take_sky_print(print) — into the satchel, onto Gloop's table, sold for
##                8 + 46*rarity + 30*sharpness with no new rule and no new number.
##
## WHY IT IS ITS OWN FILE AND NOT SIX LINES IN safari_run.gd. safari_run.gd is the flight: the lane,
## the glass, the thumb. Whether a photograph is worth money is a different subject that four other
## files already argue about, and the seam between them is where every wiring bug in this spike has
## been. One file, one seam, and `attach()` is the whole interface.
##
## THE PREVIEW IS REAL, NOT A SWATCH. A journal page whose image is null draws the silhouette with a
## "?" on it — the empty-page art — which would make five caught sights look uncaught. So the catch
## is re-rendered offscreen through safari_eyepiece.gdshader itself, 256x256, at the blur the player
## actually held and with the moment open if they caught one. A soft catch makes a soft print, the
## same promise sky_watch.gd's `_render_preview` makes for the tripod. Nothing is painted by hand.
##
## TWO KIND SPACES, MAPPED HERE ONCE. SafariCast's kinds (comet/pod/ice/derelict/moon rim/limb, 0-5)
## are shapes the flight shader can draw. SkyEvents' kinds (aurora/comet/ring, 0-2) are shapes the
## journal's PageArt can draw. They are different alphabets that both start at 0, and mixing them up
## silently draws aurora curtains on a comet's page. `_page_kind` is the only place in the project
## that knows both, and it is a lookup, not a coincidence.
##
## SAY WHAT IS SYNTHETIC: nothing here has been on a phone. It has been flown headless by autopilot
## and by showcase/safari_wire_probe.gd, which is code driving the same scoring a thumb drives.

const EYE_SHADER := preload("res://src/sky/safari_eyepiece.gdshader")

## The offscreen print size, the same 256 sky_watch.gd uses, so a safari page and a tripod page put
## the same number of pixels on the same square.
const PREVIEW_PX := 256

signal landed(prints: Array, paid: int)

var _run: Node = null
var _vp: SubViewport
var _rect: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	name = "SafariHaul"
	_build_preview_rig()


## THE WHOLE INTERFACE. Hand it the run; it connects itself and gets out of the way.
func attach(run: Node) -> void:
	if run == null or not is_instance_valid(run):
		return
	_run = run
	if run.has_signal("run_finished") and not run.is_connected("run_finished", _on_run_finished):
		run.connect("run_finished", _on_run_finished)


# ------------------------------------------------------------------ the landing
func _on_run_finished(haul: Array) -> void:
	if haul.is_empty():
		# A skipped flight lands with nothing, and that is a real answer, not a failure. Say it once
		# so a silent landing is never confused with a landing that silently dropped the photos.
		print("SAFARI LANDED: empty haul, nothing to file")
		landed.emit([], 0)
		return
	var journal := _find_journal()
	# BOOK round: SAY IT OUT LOUD WHEN THERE IS NO BOOK. Before this round there never WAS one on
	# the real pad route, and the only sign was a line that did not get printed. A missing journal
	# is still not fatal (a showcase that only wants the flight works) but it is now loud.
	if journal == null:
		push_warning("SafariHaul: no SkyJournal in the tree - this haul gets coins but no pages.")
	var day: int = GameState.day_count
	var hour: float = float(_run.hour) if _run != null and "hour" in _run else 12.0
	var made: Array = []
	var paged := 0
	var paid := 0
	for rec in haul:
		var p := await _print_from(rec, day, hour)
		if p == null:
			continue
		made.append(p)
		if journal != null:
			var jr: Dictionary = journal.take_print(p, _page_subject(rec), false)
			if not jr.is_empty():
				paged += 1
		var coin: Dictionary = PrintBag.take_sky_print(p)
		paid += PrintBag.pay_for(coin)
		# The neighbour who told you about it now has something to say. The reaction itself is said
		# next time you talk to them (SafariHeard.line_for, through SkyHints.maybe_hint_line, which
		# conversation.gd already calls); this only has to make the journal PAGE exist, which
		# `take_print` above just did - and `is_caught` reads that page, so a landing with no
		# journal used to leave the neighbour with nothing to react to.
		if SafariCatalog.by_id(str(p.event_id)).get("needs_hint", false):
			var caught := journal != null and bool(journal.call("has_shot", str(p.event_id)))
			print("  hinted rare caught: %s - %s can react now (page=%s)" % [
				p.event_id, str(SafariCatalog.by_id(str(p.event_id)).get("hint_npc", "")),
				str(caught)])
	if journal != null:
		journal.save_to_flags()
	# ONE toast for the batch. Five separate "First shot of ..." toasts on one landing is the kind of
	# thing that reads as a bug even when it is working.
	EventBus.toast_requested.emit(_landing_line(made.size(), paid), "star")
	print("SAFARI LANDED: %d prints filed, %d journal pages, satchel=%d, worth %d dust" % [
		made.size(), paged, PrintBag.bag_count(), paid])
	for p in made:
		print("  filed %-26s %s %3d%%  moment=\"%s\"" % [
			p.event_id, p.grade, int(round(p.sharpness * 100.0)), p.moment])
	landed.emit(made, paid)


## Player words, and the 60-character budget is a hard one this round.
func _landing_line(n: int, paid: int) -> String:
	if n == 1:
		return "One print in the bag. Gloop will pay %d." % paid
	return "%d prints in the bag. Gloop will pay %d." % [n, paid]


# ------------------------------------------------------------------ a catch becomes a print
func _print_from(rec: Dictionary, day: int, hour: float) -> SkyPrint:
	var subj: Dictionary = _page_subject(rec)
	var sharp: float = clampf(float(rec.get("sharpness", 0.0)), 0.0, 1.0)
	var mult: float = maxf(float(rec.get("mult", 1.0)), 1.0)
	# `on_world` TRUE, always, and the reason is the rule itself. SkyPrint's OFF_WORLD_CAP exists so
	# that Fine and Gallery are things you can only bring back from a TRIP (its header: "travel is in
	# the sharpness, not a bonus"). A safari IS the trip — you are between two worlds at the time —
	# so capping it at 0.58 would mean the one activity built entirely out of travelling could never
	# produce a good print. No new parameter: the existing rule, applied the way it reads.
	var p := SkyPrint.make(subj, sharp, true, day, hour, 1.0, 0.0)
	p.moment = str(rec.get("moment", ""))
	# WIRE round: THE GRADE IS SafariScoring'S, not SkyPrint's. SkyPrint grades on sharpness alone,
	# so a shot taken in the best moment in the game graded the same as one taken while the thing
	# drifted - the moment did nothing. SafariScoring.grade_for folds the two 50/50, and its
	# `quality_of` is the number Gloop prices on. A tripod print still uses SkyPrint's own grade:
	# it has no moment, and nothing here touches that path.
	p.grade = SafariScoring.grade_for(sharp, mult)
	p.quality = SafariScoring.quality_of(p.rarity, sharp, mult)
	p.moment_mult = mult
	p.from_safari = true
	p.preview = await _render_preview(rec, sharp)
	return p


## The journal's page for this catch: the SIGHT, in the journal's own vocabulary. `world` is where
## you were GOING, because that is what the lane is named after and what a player will look for.
## WIRE round: ONE PAGE SHAPE, SafariHeard's, so the page a hint opened ("heard about, not seen")
## and the page a catch fills are THE SAME PAGE. They used to be built in two places out of two
## vocabularies, which meant catching a hinted rare opened a SECOND page beside the one the
## neighbour's hint had already made.
func _page_subject(rec: Dictionary) -> Dictionary:
	var e: Dictionary = rec.get("subject", {})
	var to_id := str(_run.to_id) if _run != null and "to_id" in _run else ""
	var lane_name := "the lane"
	if _run != null and _run.has_method("lane"):
		lane_name = str((_run.call("lane") as Dictionary).get("name", "the lane"))
	var cat := SafariCatalog.by_id(str(rec.get("id", "")))
	if not cat.is_empty():
		return SafariHeard.journal_subject(cat, to_id, "on %s" % lane_name)
	# A WORLD'S LIMB. SafariLanes builds it from the world's own .tres, so it is not a catalog
	# sight - but it IS on every single run, which makes it the most producible thing in the game.
	# BOOK round: it gets a REAL page off SkyEvents.limb_subject, whose id collapses `_behind` and
	# `_ahead` onto one page per world face. Before this, the page was built here out of the cast
	# entry with the run's own id, which meant it existed for the session and was dropped by the
	# next load - a page a player filled and then lost. Rarity 1, so nothing about money moves.
	var limb_id := SkyEvents.limb_page_id(str(rec.get("id", "")))
	var limb := SkyEvents.limb_subject(limb_id) if limb_id != "" else {}
	if not limb.is_empty():
		limb["where"] = "on %s" % lane_name
		return limb
	return {
		"id": str(rec.get("id", "")),
		"title": str(rec.get("title", "A sight")),
		"kind": SkyEvents.KIND_AURORA,
		"kind_label": "A sight",
		"rarity": clampi(int(rec.get("rarity", 1)), 1, 4),
		"world": to_id,
		"where": "on %s" % lane_name,
		"blurb": str(e.get("blurb", "")),
		"silhouette": "",
		"tint_a": str(e.get("tint_a", "#ffffff")),
		"tint_b": str(e.get("tint_b", "#ffffff")),
	}


# ------------------------------------------------------------------ the offscreen print
func _build_preview_rig() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(PREVIEW_PX, PREVIEW_PX)
	_vp.transparent_bg = true
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mat = ShaderMaterial.new()
	_mat.shader = EYE_SHADER
	_rect.material = _mat
	_vp.add_child(_rect)


## One subject, dead centre, at the blur the player held. `run`/`look` are left at the run's own t so
## the star field behind it is the field that was behind it, not a different random one.
func _render_preview(rec: Dictionary, sharp: float) -> Image:
	# HEADLESS HAS NO RENDERER. `get_texture().get_image()` on a dummy driver returns nothing and the
	# frame_post_draw await can never arrive, so a headless landing files the numbers and skips the
	# picture. SAY WHAT IS SYNTHETIC: every headless proof in the report has null previews; the
	# pictures were checked in a windowed run.
	if DisplayServer.get_name() == "headless":
		return null
	var e: Dictionary = rec.get("subject", {})
	var t: float = float(rec.get("t", 0.0))
	_mat.set_shader_parameter("n_subj", 1)
	_mat.set_shader_parameter("t", t)
	_mat.set_shader_parameter("run", t)
	_mat.set_shader_parameter("look", Vector2.ZERO)
	_mat.set_shader_parameter("sky_light", 0.0)
	_mat.set_shader_parameter("swim", 0.0)
	_mat.set_shader_parameter("warm", clampf(sharp, 0.0, 1.0))
	_mat.set_shader_parameter("flash", 0.0)
	# BOOK round: THE PRINT IS SafariShapes' PICTURE, not the bare six-branch one.
	# This function used to set s0_kind/scale/tints by hand and leave s0_f1/f2/f3 at zero — which
	# is EXACTLY the bug the shapes round found in safari_run.gd and fixed there and not here. So
	# the flight drew 51 distinct sights and then filed a photograph of one of six. `apply` sends
	# the same twelve knobs, the same rotation and the sight's OWN seed, so the picture in the book
	# is the picture that was in the glass.
	# The moment is OPEN in the print if the shutter caught one: the driftling is turning to look
	# at you on the page, because that is the photograph you took.
	var cat := SafariCatalog.by_id(str(rec.get("id", "")))
	var moment_open: float = 1.0 if str(rec.get("moment", "")) != "" else 0.0
	if not cat.is_empty():
		SafariShapes.apply(_mat, 0, cat, Vector2.ZERO, clampf(1.0 - sharp, 0.0, 1.0), moment_open)
	else:
		# A world's limb is not a catalog sight, so it has no SafariShapes row. Same hand-set path
		# as before, for that one case only.
		_mat.set_shader_parameter("s0_kind", int(rec.get("kind", 0)))
		_mat.set_shader_parameter("s0_pos", Vector2.ZERO)
		_mat.set_shader_parameter("s0_blur", clampf(1.0 - sharp, 0.0, 1.0))
		_mat.set_shader_parameter("s0_scale", float(e.get("scale", 1.0)))
		_mat.set_shader_parameter("s0_moment", moment_open)
		_mat.set_shader_parameter("s0_seed", 1.0 + float(t))
		_mat.set_shader_parameter("s0_a", Color(str(e.get("tint_a", "#ffffff"))))
		_mat.set_shader_parameter("s0_b", Color(str(e.get("tint_b", "#ffffff"))))
	for i in [1, 2]:
		_mat.set_shader_parameter("s%d_pos" % i, Vector2(9.0, 9.0))
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	return _vp.get_texture().get_image()


# ------------------------------------------------------------------ finding the book
## Same defensive pattern SkyJournal itself uses to find SkyWatch: by node name, anywhere, and a
## missing journal is not an error — a showcase scene that only wants the flight still works, the
## prints just go to the satchel alone.
func _find_journal() -> Node:
	var n := get_node_or_null("/root/SkyJournal")
	if n != null:
		return n
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.find_child("SkyJournal", true, false)
