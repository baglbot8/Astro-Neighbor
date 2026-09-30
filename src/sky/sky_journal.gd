class_name SkyJournal
extends CanvasLayer
## BOOK round (2026-09-21, scratch only). THE BOOK, AND IT IS NOW REACHABLE FROM THE FLIGHT.
##
## THE BUG THIS ROUND FIXES, in the reviewer's words: "SkyJournal is not an autoload and is not in
## safari_flight.tscn, so on the real route the journal is never written - no page, no best shot,
## and the neighbour's reaction to a hinted rare is built on a page that was never made."
##
## Measured before the fix, in this scratch copy: the only two places in the whole project that
## ever built a SkyJournal were `showcase/journal_spike.gd` and `showcase/sky_spike.gd`.
## `safari_haul.gd::_find_journal` searched the tree, found nothing on the real pad route, and
## quietly filed the flight's photographs into the satchel only. Five catches, no pages.
##
## AUTOLOAD, NOT A NODE IN THE FLIGHT SCENE. Both were on the table; the autoload wins on three
## counts, and none of them is taste:
##   1. THE LANDING OUTLIVES THE FLIGHT SCENE. `safari_haul` files the haul and then
##      `safari_flight.gd` calls `SceneRouter.go_to_planet(dest)`. A journal parented to
##      safari_flight.tscn is freed in that same transition, so its pages would exist for the few
##      frames between the landing and the fade. The book has to be older than the scene.
##   2. THREE DOORS, ONE BOOK. A page is written from the flight (safari_haul), from the tripod
##      (sky_watch), and opened by a neighbour's hint during a CONVERSATION on any planet
##      (safari_heard.mark_heard -> register_hint). Those are three different scenes. Both
##      `SafariHeard._find_journal` and `SkyHints._find_journal` already looked for
##      `/root/SkyJournal` first - the autoload is the node they were written for and never found.
##   3. IT IS THE ONLY PLACE THE PLAYER CAN OPEN IT. A book that only exists during a 63-second
##      flight is not a book.
## The cost is one line in `project.godot`'s `[autoload]` block, the only file outside this round's
## five that changed. The button it puts on screen is gated: see `_in_world()`.
##
## ONE SKY. The book is no longer this file's own reading of SkyEvents' nine hand-made events. It
## is `SkyEvents.producible_sights()` - SafariCatalog's 51, minus anything the safari cannot
## produce for this save (an unheard hint, an unreached story gate). That is the whole of the
## reviewer's "the player's book must never again list a sight the safari cannot produce", and
## `debug_sweep()` re-measures it rather than asserting it.
##
## ONE PAGE PER SIGHT, whichever way you caught it, and THE PAGE SAYS WHICH:
##   from the ship    "From the ship, day 4, 22:14, on the Lantern Lane"
##   from the ground  "Standing on Vela, day 4, 22:14"
## `best_from` ("ship" / "ground") and `best_where` are stored with the rest of the record, so a
## reload still knows. A BETTER shot replaces the old one and says so, from either door; a worse
## one only bumps the count.
##
## WHAT IS SAVED, into `GameState.flags["sky_journal"]`:
##   records   best sharpness, grade, day, hour, world, where, from, moment, times, per sight id
##   heard     who told you about what, so a "heard about, not seen" page survives the night
## NOT SAVED: the page list (rebuilt from the catalog every load, which is what makes the catalog
## the one table), and the preview IMAGE. The image is a rendered 256x256 with no file behind it;
## a reloaded page keeps its numbers and falls back to the silhouette art. SAY WHAT IS SYNTHETIC:
## that is still a real, visible gap, and this round did not close it.
##
## PUBLIC API
##   has_shot(id) -> bool                   true once any print of that sight has been taken
##   record_for(id) -> Dictionary           {} if empty, else the record + its page under "event"
##   record(p) / take_print(p, subject, announce) -> Dictionary   file a print
##   best_image(id) -> Image
##   filled_count() / page_ids()
##   register_hint(subject, hint)           a neighbour opened a "heard about, not seen" page
##   open_to(id) / debug_sweep()
##   top_grade(id) -> String                the highest grade ever filed for that sight, "" if none
##   has_grade_at_least(id, grade) -> bool  the story's photo step asks this (STORY_SPINE_SPEC 2.4)
##   signal page_filed(id, grade)           after every filing, so a live ProjectSystem re-checks
##
## TOP GRADE, NOT BEST GRADE (STORY_SPINE_SPEC 2.4). `best_grade` is the grade of the SHARPEST
## shot, because the page keeps the sharpest picture. But a grade mixes sharpness with the caught
## moment (SafariScoring.grade_for), so a less sharp shot that caught the moment can earn a HIGHER
## grade than the one on the page. `top_grade` is the highest grade ever filed, raised on every
## filing and never lowered; an old save without it falls back to its `best_grade`.

## Emitted after every print is filed (first, better or worse). ProjectSystem listens while a world
## is up; a print filed during a flight is seen by the next world's ProjectSystem when it loads.
signal page_filed(event_id: String, grade: String)

## The grade ladder, lowest first. SafariScoring.GRADES by value (safari_scoring.gd:35) - written
## out so this autoload's parse does not pull in the scoring class. `grade_rank` is the one place
## that orders grades; unknown or empty is -1.
const GRADE_ORDER: Array[String] = ["Smudge", "Fair", "Fine", "Gallery"]

## THE LAST PHOTO's own page key (finale_gift.gd PAGE_PLANET/PAGE_KEY, kept in sync by name only -
## this file does not load that one to read it, the usual rule for an autoload naming another
## builder's class). See planet_roster().
const HOME_PAGE_PLANET := "hub"
const HOME_PAGE_KEY := "hub:home"

## How long a fresh "NEW BEST" flash stays on the open page, in seconds.
const FLASH_SEC := 3.5
## The world scene. The journal button only shows while the player is standing on a planet.
const WORLD_SCENE := "res://src/world/world.tscn"
## SkyWatch.St.WATCH, by value. Written out rather than referenced so this file's parse does not
## resolve the whole telescope class - see the palette note below.
const WATCH_STATE := 3

## The palette, LOCAL. It used to read SkyWatch.C_*, which made this file's parse resolve the whole
## telescope class and its eyepiece shader. Harmless when the journal was built by a showcase; not
## harmless in an autoload, which every scene in the game now loads (SceneRouter's own header
## carries the same warning about an autoload naming a class it does not always need).
const C_CREAM := Color("#e9eaf1")
const C_TEXT := Color("#2c2f42")
const C_SOFT := Color("#6d7288")
const C_NAVY := Color("#1b1f33")
const C_GOOD := Color("#6fc47f")

var _watch: Node = null
var gift: Node = null  # PrintGift, built on first use - see `_ensure_gift`

var _catalog: Array = []          # Array[Dictionary], page subjects, catalog order
var _records: Dictionary = {}     # sight id -> record Dictionary, see _blank_record()
## event_id -> {"npc_id","line","day"} for a sight a neighbour has mentioned. Kept even after the
## page fills, so a caught hint still shows who told you first.
var _heard: Dictionary = {}
var _page := 0
var _flash_id := ""
var _flash_t := 0.0
## The last print filed. The journal is reachable two ways (a `print_made` signal a showcase
## connects, and the direct `record()` call sky_watch makes), and one print arriving down both
## would double a sight's `times`. Identity, not a flag: cheap and impossible to get wrong.
var _last_filed: SkyPrint = null
var _vis_t := 0.0

var _root: Control
var _toggle_btn: Button
var _panel: PanelContainer
var _art: PageArt
var _title_lbl: Label
var _meta_lbl: Label
var _stat_lbl: Label
var _whenwhere_lbl: Label
var _hint_lbl: Label
var _page_lbl: Label
var _give_btn: Button
var _foot: HBoxContainer

# ---- PLANET SAFARI JOURNAL UI (builder P5, 2026-09-23), additive to everything above ----
var _planet_btn: Button
var _planet_panel: PanelContainer
var _planet_body: VBoxContainer


func _ready() -> void:
	layer = 42  # above SkyWatch's 40, so the journal draws over the idle bar/clock
	name = "SkyJournal"
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_from_flags()
	load_planet_from_flags()
	_build_ui()
	set_process(true)
	if not EventBus.game_loaded.is_connected(_on_game_loaded):
		EventBus.game_loaded.connect(_on_game_loaded)
	if not EventBus.planet_loaded.is_connected(_on_planet_loaded_pay):
		EventBus.planet_loaded.connect(_on_planet_loaded_pay)
	_try_attach_watch()
	_apply_visibility()


func _on_game_loaded() -> void:
	_records.clear()
	_heard.clear()
	load_from_flags()
	load_planet_from_flags()
	_page = 0
	if _panel != null and _panel.visible:
		_refresh_page()
	_update_planet_button()
	# A review interrupted by a reload left its payout PENDING in the save: pay it now, once.
	_pay_notice += planet_pay_settle_all()


func _process(delta: float) -> void:
	if _flash_id != "":
		_flash_t -= delta
		if _flash_t <= 0.0:
			_flash_id = ""
			if _panel.visible:
				_refresh_page()
	# THE PILL IS DECIDED EVERY FRAME, not four times a second. There is no signal for "the current
	# scene changed", and the first version polled at 0.25 s - which the probe caught leaving the
	# pill on screen for up to a quarter of a second INTO the safari flight, over the porthole.
	# `_in_world` is one node read and one string compare; the expensive half is the SkyWatch
	# lookup, and that is the only thing still throttled.
	_vis_t -= delta
	if _vis_t <= 0.0:
		_vis_t = 0.25
		if not is_instance_valid(_watch):
			_watch = null
			_try_attach_watch()
	_apply_visibility()


# ---------------------------------------------------------------- where the button is allowed
## THE BUTTON ONLY EXISTS ON A PLANET. An autoload draws on every scene, including the title, the
## rocket cruise and the safari flight, and a "Journal" pill over the title screen or over the
## porthole is exactly the kind of thing that reads as a bug. During a watch at the eyepiece it
## hides too, so it never sits over the glass.
func _in_world() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var cs := tree.current_scene
	if cs == null:
		return false
	if cs.scene_file_path != WORLD_SCENE:
		return false
	# PLANET SAFARI GATE (docs/PLANET_SAFARI_SPEC.md 5.3/6.2, builder P5, 2026-09-23): the photo
	# journal's own button and J key hide while a safari is running (PhotoMode.active - the same
	# gate the HUD pills, compass pips and mini-game pill already read) and while the rocket flies
	# its climb or descent. THE ESTABLISHED IDIOM for "the rocket is mid-flight", copied verbatim
	# from replay_board.gd / norm_system.gd / visitor_system.gd rather than invented here: rocket_pad.gd
	# is not this builder's file to edit and has no single flag that spans the whole climb (only
	# `rocket_arriving` for the descent), but every one of those three callers already treats
	# `GameState.flag("rocket_arriving") or EventBus.modal_counts().has("cutscene")` as "in flight",
	# because rocket_pad.gd's `_begin_cutscene`/`_end_cutscene` wraps the boarding-to-climb and the
	# landing-to-descent the same way. Before this the button sat on screen through the whole climb
	# (the scene is still world.tscn until the seam cut), which is the bug the user reported
	# 2026-09-23 for the safari case and is the same shape of bug here.
	if PhotoMode.active:
		return false
	# ...and through the fade back and the review that follow it (P5b: the pill showed beside the
	# review card, inside the phone's notch margin). The PlanetSafari node lives until the review
	# ends. Found BY PATH, not through the PlanetSafari class: naming that class in this autoload
	# loads the whole safari script graph at boot and measured 465 leaked objects at exit
	# (tools/check.sh, showcase/characters_lineup.tscn, P5b 2026-09-24).
	if cs.get_node_or_null("PlanetSafari") != null or EventBus.modal_counts().has("planet_safari_review"):
		return false
	if GameState.flag("rocket_arriving") or EventBus.modal_counts().has("cutscene"):
		return false
	return not _watching()


func _watching() -> bool:
	return is_instance_valid(_watch) and _watch.has_method("debug_state") \
		and int(_watch.call("debug_state")) == WATCH_STATE


func _apply_visibility() -> void:
	if _root == null:
		return
	var want := _in_world()
	# the pill steps aside while the full-screen scrapbook is up (it sat over the panel's left edge on the
	# phone); the scrapbook has its own Close, and J / Escape close it too
	_toggle_btn.visible = want and not (_planet_panel != null and _planet_panel.visible)
	if not want and _panel.visible:
		_close()
	if not want and _planet_panel != null and _planet_panel.visible:
		_close_planet_panel()


## RETRIED, not once. The autoload boots before any world exists, so the one-shot call in `_ready`
## always found nothing and `_watch` stayed null forever - which left the Journal pill sitting over
## the eyepiece during a watch (caught in this round's first windowed capture). The scope is a node
## someone adds to a world later, so the lookup has to happen later too; `_process` re-runs it four
## times a second while there is no valid watch.
func _try_attach_watch() -> void:
	if is_instance_valid(_watch):
		return
	var tree := get_tree()
	if tree == null:
		return
	var w := tree.root.find_child("SkyWatch", true, false)
	if w != null:
		attach_watch(w)


## Public: hook up to a SkyWatch found (or created) after this journal already exists. The watch
## also calls `record()` directly; `_last_filed` makes the overlap harmless.
func attach_watch(w: Node) -> void:
	if is_instance_valid(_watch) or w == null:
		return
	_watch = w
	if w.has_signal("print_made") and not w.is_connected("print_made", _on_print_made):
		w.connect("print_made", _on_print_made)


# ------------------------------------------------------------------ the pages
## THE BOOK IS THE CATALOG. Every sight the safari can produce for this save gets a page, in the
## catalog's own order (everyday, then weekly, then rare, then the hinted ones a neighbour has told
## you about). A sight you have ALREADY caught keeps its page even if its gate somehow closes
## again, because deleting a page a player filled would be worse than any rule.
func rebuild_catalog() -> void:
	var out: Array = []
	for e in SafariCatalog.SIGHTS:
		var id := str(e["id"])
		if SkyEvents.producible(e) or _records.has(id):
			out.append(SafariHeard.journal_subject(e))
	# ...AND THE WORLDS THEMSELVES. Every run casts the world you left and the world you are
	# arriving at, so they are producible by definition; see SkyEvents' "the fifteenth kind".
	# Two faces per world, 14 pages, appended after the catalog's own order.
	for lid in SkyEvents.limb_page_ids():
		var sub := SkyEvents.limb_subject(str(lid))
		if not sub.is_empty():
			out.append(sub)
	_catalog = out
	if _page >= _catalog.size():
		_page = 0


func _catalog_entry(event_id: String) -> Dictionary:
	for ev in _catalog:
		if str(ev.get("id", "")) == event_id:
			return ev
	return {}


## Public. Every sight id the book currently holds a page for. `debug_sweep` and the critic's
## checklist item 4 read this.
func page_ids() -> Array:
	var out: Array = []
	for ev in _catalog:
		out.append(str(ev.get("id", "")))
	return out


# ------------------------------------------------------------------ records
func _blank_record() -> Dictionary:
	return {
		"times": 0,
		"best_sharpness": -1.0,
		"best_quality": 0.0,
		"best_grade": "",
		## The HIGHEST grade ever filed for this sight - see the header. Never lowered.
		"top_grade": "",
		"best_day": -1,
		"best_hour": 0.0,
		"best_world": "",
		## HOW THE PAGE RECORDS WHICH DOOR IT CAME IN BY. "ship" for a safari catch, "ground" for a
		## tripod print. `best_where` is the lane's name for a ship shot ("on the Lantern Lane")
		## and stays empty for a ground one, where `best_world` is already the whole answer.
		"best_from": "",
		"best_where": "",
		## The sight caught DOING something ("one turns and looks back at you"). Empty for a plain
		## shot and for every tripod print - only a safari catch has one.
		"best_moment": "",
		"preview": null,   # Image, in-memory only this session
	}


func _on_print_made(p: SkyPrint) -> void:
	take_print(p)


## THE SEAM sky_watch.gd's `_record()` calls (it looks for a `record` method on /root/SkyJournal).
## Same body as the signal path; `_last_filed` stops a print arriving down both counting twice.
func record(p: SkyPrint) -> Dictionary:
	return take_print(p)


## THE PUBLIC DOOR. A print becomes a page.
##   `subject`   the sight's own dictionary, for a caller that brings its own page. A safari catch
##               passes one (it is where `best_where` comes from); the tripod does not need to,
##               because every catalog sight already has a page. If a page for that id exists it is
##               LEFT ALONE, so one sight keeps one page no matter which way you caught it.
##   `announce`  false for a batch, so landing with five prints is one toast and not five.
## Returns {"is_best", "best", "seen", "total"} - the shape sky_watch.gd's card expects.
func take_print(p: SkyPrint, subject: Dictionary = {}, announce: bool = true) -> Dictionary:
	if p == null or p == _last_filed:
		return {}
	_last_filed = p
	var id := p.event_id
	if id == "":
		return {}
	if _catalog_entry(id).is_empty():
		var cat := SafariCatalog.by_id(id)
		if not cat.is_empty():
			_catalog.append(SafariHeard.journal_subject(cat))
		elif not subject.is_empty():
			_catalog.append(_page_subject(id, subject))
		else:
			# A print of something the catalog does not know. It cannot get a page (ONE SKY), and
			# saying so out loud is better than filing it into a book that will not show it.
			push_warning("SkyJournal: no catalog sight for print id '%s'; not filed." % id)
			return {}
	var rec: Dictionary = _records.get(id, _blank_record())
	var prev_sharp: float = float(rec["best_sharpness"])
	var is_first := prev_sharp < 0.0
	var is_better := is_first or p.sharpness > prev_sharp
	rec["times"] = int(rec["times"]) + 1
	if grade_rank(p.grade) > grade_rank(str(rec.get("top_grade", ""))):
		rec["top_grade"] = p.grade
	if is_better:
		rec["best_sharpness"] = p.sharpness
		rec["best_quality"] = p.quality
		rec["best_grade"] = p.grade
		rec["best_day"] = p.day
		rec["best_hour"] = p.hour
		# WHERE IT WAS TAKEN. A tripod print is taken standing somewhere, so the planet you are on
		# is the honest answer. A SAFARI print is taken between two worlds, where
		# `current_planet_id` is still the world you left - so the caller says where instead.
		rec["best_from"] = "ship" if p.from_safari else "ground"
		rec["best_world"] = p.world if p.from_safari and p.world != "" else GameState.current_planet_id
		rec["best_where"] = str(subject.get("where", "")) if p.from_safari else ""
		rec["best_moment"] = p.moment
		rec["preview"] = p.preview
	_records[id] = rec
	save_to_flags()
	page_filed.emit(id, p.grade)

	if is_better and not is_first:
		if announce:
			EventBus.toast_requested.emit(
				"New best %s! %d%%  (was %d%%)" % [p.title, int(round(p.sharpness * 100.0)),
					int(round(prev_sharp * 100.0))], "star")
		_flash_id = id
		_flash_t = FLASH_SEC
	elif is_first and announce:
		EventBus.toast_requested.emit("First shot of %s - in the journal" % p.title, "star")

	if _panel != null and _panel.visible:
		_refresh_page()
	return {"is_best": is_better, "best": float(rec["best_sharpness"]),
		"seen": filled_count(), "total": _catalog.size()}


## Public. true once ANY print of this sight exists.
func has_shot(event_id: String) -> bool:
	return _records.has(event_id) and float(_records[event_id]["best_sharpness"]) >= 0.0


## Public. The highest grade ever filed for this sight, or "" when it was never shot.
func top_grade(event_id: String) -> String:
	if not has_shot(event_id):
		return ""
	var r: Dictionary = _records[event_id]
	var t := str(r.get("top_grade", ""))
	return t if grade_rank(t) >= grade_rank(str(r.get("best_grade", ""))) else str(r.get("best_grade", ""))


## Public. True when the book holds this sight at `grade` or better (STORY_SPINE_SPEC 2.4: the
## story's photo step is met by this, never by a carried print). An unknown `grade` is never met.
func has_grade_at_least(event_id: String, grade: String) -> bool:
	var need := grade_rank(grade)
	return need >= 0 and grade_rank(top_grade(event_id)) >= need


## The same question read straight from the saved flag, for a caller with no journal node in the
## tree (the autoload is always there in the game; this is for a bare probe). Same rule, same ladder.
static func saved_grade_at_least(event_id: String, grade: String) -> bool:
	var need := grade_rank(grade)
	if need < 0:
		return false
	return grade_rank(saved_top_grade(event_id)) >= need


static func saved_top_grade(event_id: String) -> String:
	var blob: Variant = GameState.flags.get(F_JOURNAL, {})
	if not (blob is Dictionary):
		return ""
	var recs: Variant = (blob as Dictionary).get("records", {})
	if not (recs is Dictionary) or not (recs as Dictionary).has(event_id):
		return ""
	var r: Variant = (recs as Dictionary)[event_id]
	if not (r is Dictionary) or float((r as Dictionary).get("best_sharpness", -1.0)) < 0.0:
		return ""
	var t := str((r as Dictionary).get("top_grade", ""))
	var b := str((r as Dictionary).get("best_grade", ""))
	return t if grade_rank(t) >= grade_rank(b) else b


static func grade_rank(grade: String) -> int:
	return GRADE_ORDER.find(grade)


## Public. {} if never shot; otherwise the record dict PLUS the page entry under "event".
func record_for(event_id: String) -> Dictionary:
	if not has_shot(event_id):
		return {}
	var rec: Dictionary = _records[event_id].duplicate()
	rec["event"] = _catalog_entry(event_id)
	rec["event_id"] = event_id
	return rec


func best_image(event_id: String) -> Image:
	if not has_shot(event_id):
		return null
	return _records[event_id]["preview"]


func filled_count() -> int:
	var n := 0
	for id in _records.keys():
		if float(_records[id]["best_sharpness"]) >= 0.0:
			n += 1
	return n


# --------------------------------------------------------------- a page for a non-catalog subject
## Only reached by a caller that brings a subject for an id the catalog does not hold. With ONE SKY
## that should never happen in the game; it is kept so a showcase can still push a made-up page.
func _page_subject(id: String, subject: Dictionary) -> Dictionary:
	var e := subject.duplicate(true)
	e["id"] = id
	e["title"] = str(e.get("title", "A sight"))
	e["kind"] = int(e.get("kind", 0))
	e["kind_label"] = str(e.get("kind_label", ""))
	e["rarity"] = clampi(int(e.get("rarity", 1)), 1, 4)
	e["world"] = str(e.get("world", ""))
	e["where"] = str(e.get("where", ""))
	e["blurb"] = str(e.get("blurb", ""))
	e["silhouette"] = str(e.get("silhouette", ""))
	e["tint_a"] = str(e.get("tint_a", "#ffffff"))
	e["tint_b"] = str(e.get("tint_b", "#ffffff"))
	return e


# ------------------------------------------------------------------ the book survives a reload
const F_JOURNAL := "sky_journal"


func save_to_flags() -> void:
	var recs: Dictionary = {}
	for id in _records.keys():
		var r: Dictionary = (_records[id] as Dictionary).duplicate()
		r.erase("preview")
		recs[id] = r
	GameState.flags[F_JOURNAL] = {"records": recs, "heard": _heard.duplicate(true)}


func load_from_flags() -> void:
	var blob: Variant = GameState.flags.get(F_JOURNAL, {})
	if blob is Dictionary:
		var d: Dictionary = blob
		var recs: Variant = d.get("records", {})
		if recs is Dictionary:
			for id in (recs as Dictionary):
				# ONE SKY, APPLIED TO AN OLD SAVE. A record for a sight the catalog does not hold
				# is a leftover of the nine retired SkyEvents events; it is dropped rather than
				# carried into a book that has no page for it.
				if SafariCatalog.by_id(str(id)).is_empty() and not SkyEvents.is_limb_page(str(id)):
					continue
				var r: Dictionary = _blank_record()
				for k in ((recs as Dictionary)[id] as Dictionary):
					r[k] = ((recs as Dictionary)[id] as Dictionary)[k]
				# JSON HAS NO INTS. A saved `times` / `best_day` comes back as 1.0, and a page that
				# printed it raw would read "taken 1.0 times". Coerced here, once.
				r["times"] = int(r["times"])
				r["best_day"] = int(r["best_day"])
				# AN OLD SAVE HAS NO top_grade: its best_grade is the best it can honestly claim.
				if grade_rank(str(r.get("top_grade", ""))) < grade_rank(str(r.get("best_grade", ""))):
					r["top_grade"] = str(r.get("best_grade", ""))
				r["preview"] = null
				_records[str(id)] = r
		var hd: Variant = d.get("heard", {})
		if hd is Dictionary:
			for id in (hd as Dictionary):
				if SafariCatalog.by_id(str(id)).is_empty():
					continue
				_heard[str(id)] = (hd as Dictionary)[id]
	rebuild_catalog()


# ------------------------------------------------------------------ hints
## Public. Called by SafariHeard.mark_heard (and by SkyHints, for its own retired five) once a
## neighbour's hint has actually been said out loud. Records who told you and in what words.
##
## BOOK round: A SUBJECT THE CATALOG DOES NOT HOLD IS REFUSED. sky_hints.gd still carries five
## hand-written hints of its own whose sights ("hint_bolt_moon") no lane can ever produce. Their
## mouth is already gone - `SkyHints.maybe_hint_line` hands every world neighbour to SafariHeard
## first and returns "" - but `debug_force_heard` can still call this, and a page for a sight the
## safari cannot show is exactly what the reviewer said must never happen again. The door is shut
## here, in a file this round owns, rather than in sky_hints.gd, which it does not.
func register_hint(subject: Dictionary, hint: Dictionary) -> void:
	var id := str(subject.get("id", ""))
	if id == "":
		return
	if SafariCatalog.by_id(id).is_empty():
		push_warning("SkyJournal: refused a hint page for '%s' - the safari cannot produce it." % id)
		return
	_heard[id] = hint.duplicate()
	rebuild_catalog()
	save_to_flags()
	if _panel != null and _panel.visible and _page < _catalog.size() \
			and str(_catalog[_page].get("id", "")) == id:
		_refresh_page()


# ------------------------------------------------------------------ UI build
func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIStyle.theme()
	add_child(_root)

	# CENTRE-LEFT, and that is not decoration. Top-left is the stardust pill and, on mobile, the
	# jet pill; top-right is the clock and the desktop toasts; bottom-left and bottom-right are the
	# thumbstick and the buttons. The middle of the left edge is the one strip of a phone screen
	# this game does not already use.
	var wrap := MarginContainer.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	wrap.grow_vertical = Control.GROW_DIRECTION_BOTH
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override("margin_left", 20)
	_root.add_child(wrap)

	# No keyboard hint on a phone. The user plays with two thumbs; "[J]" there is noise.
	_toggle_btn = _mk_button("Journal" if Platform.is_mobile() else "Journal  [J]", _toggle)
	_toggle_btn.visible = false
	wrap.add_child(_toggle_btn)
	if not Platform.mode_changed.is_connected(_on_ui_mode_changed):
		Platform.mode_changed.connect(_on_ui_mode_changed)

	_panel = PanelContainer.new()
	_panel.name = "JournalPanel"
	_panel.visible = false
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_CREAM, 26))
	_root.add_child(_panel)

	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 26)
	_panel.add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(820, 0)
	m.add_child(col)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 12)
	col.add_child(head_row)
	var head := Label.new()
	head.text = "Journal"
	head.add_theme_font_override("font", UIStyle.ui_font())
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", C_TEXT)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(head)
	_page_lbl = _small("")
	head_row.add_child(_page_lbl)
	# THE SCRAPBOOK'S DOOR from the sky pages (spec 15.5). Only reachable while the space safari is
	# switched on (spec 15.1); with it off the Journal pill opens the scrapbook itself (`_open`).
	_planet_btn = _mk_button("Scrapbook", _open_planet_panel)
	_planet_btn.visible = false
	head_row.add_child(_planet_btn)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	col.add_child(body)

	_art = PageArt.new()
	_art.custom_minimum_size = Vector2(232, 232)
	body.add_child(_art)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(info)
	_title_lbl = _body_label("")
	info.add_child(_title_lbl)
	_meta_lbl = _small("")
	info.add_child(_meta_lbl)
	_stat_lbl = _small("")
	info.add_child(_stat_lbl)
	_whenwhere_lbl = _small("")
	_whenwhere_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(_whenwhere_lbl)
	_hint_lbl = _small("")
	_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(_hint_lbl)

	_foot = HBoxContainer.new()
	_foot.add_theme_constant_override("separation", 12)
	col.add_child(_foot)
	_foot.add_child(_mk_button("< Prev", func(): _turn(-1)))
	_foot.add_child(_mk_button("Next >", func(): _turn(1)))
	_give_btn = _mk_button("Give a print", _on_give_pressed)
	_foot.add_child(_give_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_foot.add_child(spacer)
	_foot.add_child(_mk_button("Close", _close))

	_build_planet_panel()
	_update_planet_button()


func _on_ui_mode_changed(mobile: bool) -> void:
	if _toggle_btn != null:
		_toggle_btn.text = "Journal" if mobile else "Journal  [J]"


func _mk_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_override("font", UIStyle.ui_font())
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", C_TEXT)
	b.add_theme_color_override("font_pressed_color", C_TEXT)
	b.add_theme_stylebox_override("normal", UIStyle.make_pill_style(C_CREAM))
	b.add_theme_stylebox_override("hover", UIStyle.make_pill_style(Color("#f6f7fb")))
	b.add_theme_stylebox_override("pressed", UIStyle.make_pill_style(Color("#d5d8e4")))
	b.pressed.connect(cb)
	return b


func _body_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", C_TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	return l


func _small(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", C_SOFT)
	return l


# ------------------------------------------------------------------ open / navigate
func _toggle() -> void:
	if _panel.visible or (_planet_panel != null and _planet_panel.visible):
		_close()
		_close_planet_panel()
	else:
		_open()


## THE JOURNAL OPENS ON THE SCRAPBOOK while the space safari is switched off (spec 15.1: "the journal
## hides the sky-sight pages while the switch is off"); the sky pages open only while it is on.
func _open() -> void:
	# Do not fight the eyepiece for the same screen: refuse to open mid-watch.
	if _watching():
		return
	if not space_safari_on():
		_open_planet_panel()
		return
	_panel.visible = true
	_refresh_page()


## SafariTransit.SPACE_SAFARI (spec 15.1), read BY PATH each time it is wanted - this autoload never
## names the flight classes (see WATCH_STATE's note), and the switch is a dev-menu toggle that may change
## while the game runs. A build without the switch reads as OFF: the spec's value.
static func space_safari_on() -> bool:
	if not ResourceLoader.exists(SAFARI_TRANSIT_SCRIPT):
		return false
	var scr: Variant = load(SAFARI_TRANSIT_SCRIPT)
	if not (scr is Script):
		return false
	var v: Variant = (scr as Script).get("SPACE_SAFARI")
	return v is bool and bool(v)


func _close() -> void:
	_panel.visible = false


func _turn(d: int) -> void:
	if _catalog.is_empty():
		return
	_page = posmod(_page + d, _catalog.size())
	_refresh_page()


## Public: jump straight to a sight's page (the scrapbook instead while the space safari is off).
func open_to(event_id: String) -> void:
	if not space_safari_on():
		_open()
		return
	for i in _catalog.size():
		if str(_catalog[i].get("id", "")) == event_id:
			_page = i
			break
	_open()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var k := (event as InputEventKey).keycode
	if _planet_panel != null and _planet_panel.visible:
		if k == KEY_ESCAPE or k == KEY_J:
			_close_planet_panel()
		elif k == KEY_RIGHT or k == KEY_LEFT:
			var i := SCRAPBOOK_SECTIONS.find(_scrap_section)
			_show_scrap_section(SCRAPBOOK_SECTIONS[posmod(i + (1 if k == KEY_RIGHT else -1), SCRAPBOOK_SECTIONS.size())])
	elif k == KEY_J and not _panel.visible:
		if _in_world():
			_open()
	elif _panel.visible:
		if k == KEY_ESCAPE:
			_close()
		elif k == KEY_RIGHT:
			_turn(1)
		elif k == KEY_LEFT:
			_turn(-1)


# ------------------------------------------------------------------ page fill
func _refresh_page() -> void:
	if _catalog.is_empty():
		_page_lbl.text = "0 / 0"
		_title_lbl.text = "Nothing in the book yet."
		_meta_lbl.text = ""
		_stat_lbl.text = ""
		_whenwhere_lbl.text = ""
		_hint_lbl.text = ""
		_give_btn.disabled = true
		return
	_page = clampi(_page, 0, _catalog.size() - 1)
	var ev: Dictionary = _catalog[_page]
	var id := str(ev.get("id", ""))
	_page_lbl.text = "%d / %d   -   %d of %d sights seen" % [
		_page + 1, _catalog.size(), filled_count(), _catalog.size()]

	var filled := has_shot(id)
	_art.filled = filled
	_art.kind = int(ev.get("kind", 0))
	_art.draw_id = str(ev.get("draw", ""))
	_art.tint_a = Color(str(ev.get("tint_a", "#ffffff")))
	_art.tint_b = Color(str(ev.get("tint_b", "#ffffff")))
	_art.image = best_image(id) if filled else null
	_art.flashing = (id == _flash_id)
	_art.queue_redraw()

	_title_lbl.text = str(ev.get("title", "A sight"))
	_meta_lbl.text = "%s  -  %s" % [
		SkyEvents.kind_label(ev), SkyEvents.rarity_name(int(ev.get("rarity", 1)))]

	var heard: Dictionary = _heard.get(id, {})
	if filled:
		var rec := record_for(id)
		var sharp_pct := int(round(float(rec["best_sharpness"]) * 100.0))
		var moment := str(rec.get("best_moment", ""))
		_stat_lbl.text = "Best shot: %d%% sharp  -  %s  (taken %d time%s)" % [
			sharp_pct, str(rec["best_grade"]), int(rec["times"]),
			"" if int(rec["times"]) == 1 else "s"]
		_whenwhere_lbl.text = _taken_line(rec)
		if _art.flashing:
			_hint_lbl.text = "New BEST!"
			_hint_lbl.add_theme_color_override("font_color", C_GOOD)
		elif PhotoAsks.has(id) and not has_grade_at_least(id, "Fair"):
			# THE ROUTE MUST NOT DISAPPEAR (STORY_SPINE_SPEC.md 6.4): `filled` is true the moment
			# ANY print of this sight exists, including a Smudge below the grade someone asked for -
			# and the ask stays open until a Fair-or-better one is filed (ProjectSystem._complete
			# only calls PhotoAsks.remove then). CHECKED BEFORE moment/heard, not after: a Smudge can
			# carry a moment (SafariScoring.grade_for grades on sharpness+moment together, so a low
			# hold with a moment still lands below Fair), and the moment branch below used to win the
			# elif chain and hide the route on exactly the flights a beginner is most likely to fly
			# (2026-09-23 critic, measured with a real SkyPrint built the way safari_haul builds one,
			# not debug_file_grade). Gated on the grade, not just "ask open", so a player who has
			# already filed Fair-or-better but has not yet walked back to hand it in sees their
			# moment/heard line instead of a stale route reminder.
			#
			# S6 round (STORY_SPINE_SPEC.md 7.1): the PROFESSOR's own ask (STORY_SPINE_SPEC 2.5 -
			# "he takes it in person... any grade counts") is the one exception to "keep telling
			# them where to catch it": once the journal already holds a print, telling the player to
			# go catch it on a trip is wrong - there is nothing left to catch, they only need to
			# walk over and hand it in. Every other asker's line (nobody else accepts below Fair
			# today) is unchanged.
			if str(PhotoAsks.get_ask(id).get("by", "")) == "professor":
				_hint_lbl.text = "%s asked for this - take it to him at %s, he'll take any grade." % [
					asker_name("professor"), place_word("hub")]
			else:
				_hint_lbl.text = ask_line(id)
			_hint_lbl.add_theme_color_override("font_color", C_TEXT)
		elif moment != "":
			_hint_lbl.text = "Caught the moment: %s." % moment
			_hint_lbl.add_theme_color_override("font_color", C_SOFT)
		elif not heard.is_empty():
			_hint_lbl.text = "%s told you about this first." % _npc_display_name(
				str(heard.get("npc_id", "")))
			_hint_lbl.add_theme_color_override("font_color", C_SOFT)
		else:
			_hint_lbl.text = str(ev.get("blurb", ""))
			_hint_lbl.add_theme_color_override("font_color", C_SOFT)
		_give_btn.disabled = false
	elif PhotoAsks.has(id):
		# ASKED FOR, NOT SEEN (STORY_SPINE_SPEC 2.6). Someone wants this picture: say who, and the
		# trip and hours that are GUARANTEED to carry it while the ask is open (spec 2.3).
		_stat_lbl.text = "Not seen yet."
		_whenwhere_lbl.text = str(ev.get("silhouette", ""))
		_hint_lbl.text = ask_line(id)
		_hint_lbl.add_theme_color_override("font_color", C_TEXT)
		_give_btn.disabled = true
	elif not heard.is_empty():
		# HEARD ABOUT, NOT SEEN. A neighbour made this page exist; show what you were told and who
		# told you, not a countdown - a hint is a direction, never a time.
		_stat_lbl.text = "Heard about it. Not seen yet."
		_whenwhere_lbl.text = "%s, day %d" % [
			_npc_display_name(str(heard.get("npc_id", ""))),
			int(heard.get("day", GameState.day_count))]
		_hint_lbl.text = "\"%s\"" % str(heard.get("line", ""))
		_hint_lbl.add_theme_color_override("font_color", C_SOFT)
		_give_btn.disabled = true
	else:
		# THE SILHOUETTE LINE. The catalog wrote one for every one of its 51 sights and nothing in
		# the game had ever shown one: "Five round shapes, keeping pace with something."
		_stat_lbl.text = "Not seen yet."
		_whenwhere_lbl.text = str(ev.get("silhouette", ""))
		# NO FORECAST LINE (STORY_SPINE_SPEC 2.6). It used to read "Forecast tonight ... over Zorp",
		# which pointed at a ground telescope that does not exist in real play. The lanes the
		# catalog flies it on are the honest answer.
		_hint_lbl.text = _where_it_flies(id)
		_hint_lbl.add_theme_color_override("font_color", C_SOFT)
		_give_btn.disabled = true


## NOT IN THE FORECAST, SO SAY WHERE IT FLIES INSTEAD. With 51 sights and three forecast rows a
## night, most of the book is not on tonight's list, and "not forecast" on its own is a dead end.
## The catalog already knows which of the eight lanes can show a sight, and SafariLanes knows what
## those lanes are called, so the empty page can point at a TRIP: "Out on the Lantern Lane, the
## Long Way Home." Player words, capped at 60 characters, measured here rather than trusted.
func _where_it_flies(sight_id: String) -> String:
	var e := SafariCatalog.by_id(sight_id)
	if e.is_empty():
		return "Nobody has seen this one on a lane yet."
	var names: Array[String] = []
	for lane_id in Array(e.get("lanes", [])):
		if SafariLanes.LANES.has(str(lane_id)):
			names.append(str((SafariLanes.LANES[str(lane_id)] as Dictionary).get("name", "")))
	if names.is_empty():
		return "Nobody has seen this one on a lane yet."
	var line := "Out on %s." % names[0]
	if names.size() > 1 and ("Out on %s and %s." % [names[0], names[1]]).length() <= 60:
		line = "Out on %s and %s." % [names[0], names[1]]
	if names.size() > 2:
		var more := "Out on %s and %d other lanes." % [names[0], names.size() - 1]
		if more.length() <= 60:
			line = more
	return line


## THE ASK, IN WORDS A PLAYER CAN ACT ON (STORY_SPINE_SPEC 2.6):
##   "Zorp asked for this - fly the Lantern Lane between home and Zorp, any time."
##   "Bolt asked for this - fly the Lantern Lane between home and Bolt, leaving 16:00-07:00."
## The Professor's own example is dead (docs/STORY_HOME_SPEC.md 5, cleanup): his task moved off the
## sky entirely (PLANET_SAFARI_SPEC.md 15.3) and he never appears as a `by` in a PhotoAsks entry any
## more, so this line never fires for him now.
## "" when nobody asked for this sight. Read through PhotoAsks only.
static func ask_line(sight_id: String) -> String:
	var e := PhotoAsks.get_ask(sight_id)
	if e.is_empty():
		return ""
	return "%s asked for this - %s, %s." % [asker_name(str(e.get("by", ""))), ask_route(e),
		ask_hours(e.get("hours", [0, 24]))]


## "fly the Lantern Lane between home and Zorp" / "catch it on any trip to the Commons". Shared
## with ProjectSystem's status line, so the journal and the neighbour name the trip the same way.
static func ask_route(e: Dictionary) -> String:
	var lane_id := str(e.get("lane", ""))
	var f := str(e.get("from", ""))
	var t := str(e.get("to", ""))
	var lane_name := ""
	if lane_id != "" and SafariLanes.LANES.has(lane_id):
		lane_name = str((SafariLanes.LANES[lane_id] as Dictionary).get("name", ""))
	if lane_name != "" and f != "" and t != "":
		return "fly %s between %s and %s" % [lane_name, place_word(f), place_word(t)]
	if lane_name != "":
		return "fly %s" % lane_name
	if t != "" and f == "":
		return "catch it on any trip to %s" % place_word(t)
	if f != "" and t != "":
		return "fly between %s and %s" % [place_word(f), place_word(t)]
	return "catch it on any photo trip"


## "any time" for a whole day, else "leaving 16:00-07:00" (the ask counts the DEPARTURE hour).
static func ask_hours(hours: Variant) -> String:
	if not (hours is Array) or (hours as Array).size() < 2:
		return "any time"
	var a := float(hours[0])
	var b := float(hours[1])
	if b - a >= 24.0 or is_equal_approx(fposmod(a, 24.0), fposmod(b, 24.0)):
		return "any time"
	return "leaving %02d:00-%02d:00" % [int(fposmod(a, 24.0)), int(fposmod(b, 24.0))]


## "home", "the Commons", "Zorp" - the words the spec's ask lines use.
static func place_word(world_id: String) -> String:
	match world_id:
		"home":
			return "home"
		"hub":
			return "the Commons"
		"":
			return "anywhere"
	return world_id.capitalize()


static func asker_name(by: String) -> String:
	var npc_id := "mayor_orbit" if by == "professor" else by
	var n := str(NpcData.get_data(npc_id).get("display_name", ""))
	if n != "":
		return n
	return "The Professor" if by == "professor" else ("Someone" if by == "" else by.capitalize())


## THE PAGE SAYS WHICH DOOR THE SHOT CAME IN BY.
func _taken_line(rec: Dictionary) -> String:
	var when_txt := "day %d, %s" % [
		int(rec["best_day"]), SkyEvents.clock_text(float(rec["best_hour"]))]
	if str(rec.get("best_from", "")) == "ship":
		var where_txt := str(rec.get("best_where", ""))
		if where_txt == "":
			where_txt = "out between the worlds"
		return "From the ship, %s, %s" % [when_txt, where_txt]
	return "Standing on %s, %s" % [str(rec["best_world"]).capitalize(), when_txt]


func _npc_display_name(npc_id: String) -> String:
	if npc_id == "":
		return "Someone"
	return str(NpcData.get_data(npc_id).get("display_name", npc_id.capitalize()))


## PrintGift is built ON FIRST USE, not in `_ready`. It is a CanvasLayer that pulls in the
## telescope's palette and its shader; an autoload must not pay for that on the title screen.
func _ensure_gift() -> Node:
	if is_instance_valid(gift):
		return gift
	var scr: Variant = load("res://src/sky/print_gift.gd")
	if scr == null:
		return null
	gift = (scr as Script).new()
	add_child(gift)
	if "journal" in gift:
		gift.set("journal", self)
	return gift


func _on_give_pressed() -> void:
	if _catalog.is_empty():
		return
	var ev: Dictionary = _catalog[_page]
	var id := str(ev.get("id", ""))
	if not has_shot(id):
		return
	var g := _ensure_gift()
	if g != null and g.has_method("open_picker"):
		g.call("open_picker", record_for(id))


# ------------------------------------------------------------------ debug hooks (captures)
## THE SWEEP, checklist item 4. Every page id the safari cannot produce; empty is the pass.
func debug_sweep() -> Array:
	return SkyEvents.unproducible_among(page_ids())


## SYNTHETIC - pushes a fabricated print straight into the store, bypassing the eyepiece and the
## flight entirely. Only for repeatable captures of empty/full/replace pages.
func debug_fake_print(event_id: String, sharpness: float, from_ship: bool = false,
		day_n: int = -1, hour_n: float = 22.0) -> void:
	var cat := SafariCatalog.by_id(event_id)
	if cat.is_empty():
		return
	var subj := SafariHeard.journal_subject(cat, GameState.current_planet_id,
		"on the Lantern Lane" if from_ship else "")
	var p := SkyPrint.make(subj, sharpness, true,
		day_n if day_n >= 0 else GameState.day_count, hour_n)
	p.from_safari = from_ship
	take_print(p, subj if from_ship else {}, false)


## SYNTHETIC - files a print of `event_id` graded EXACTLY `grade`, bypassing the flight. For the
## dev menu's "Meet this step" on a photo step and for probes. The grade is forced, not earned:
## sharpness is set to the floor of that grade on the tripod's scale so the page reads sensibly.
func debug_file_grade(event_id: String, grade: String, from_ship: bool = true) -> bool:
	var cat := SafariCatalog.by_id(event_id)
	if cat.is_empty() or grade_rank(grade) < 0:
		return false
	var floors := {"Smudge": 0.20, "Fair": 0.40, "Fine": 0.65, "Gallery": 0.90}
	var subj := SafariHeard.journal_subject(cat, GameState.current_planet_id,
		"on the Lantern Lane" if from_ship else "")
	var p := SkyPrint.make(subj, float(floors.get(grade, 0.4)), true, GameState.day_count,
		GameState.time_of_day)
	p.from_safari = from_ship
	p.grade = grade
	return not take_print(p, subj if from_ship else {}, false).is_empty()


## SYNTHETIC - the unseen-page hint line a player would read for this sight, without a screenshot.
func debug_unseen_hint(event_id: String) -> String:
	for i in _catalog.size():
		if str(_catalog[i].get("id", "")) == event_id:
			var keep := _page
			_page = i
			_refresh_page()
			var t := _hint_lbl.text
			_page = keep
			return t
	return ""


## SYNTHETIC - is the Journal pill on screen right now, and what scene are we in? The gate is
## `_in_world`, and a probe has to be able to measure it rather than reason about it.
func debug_button_visible() -> bool:
	return _toggle_btn != null and _toggle_btn.visible


func debug_open() -> void:
	_open()


func debug_page() -> int:
	return _page


func debug_filled_count() -> int:
	return filled_count()


## SYNTHETIC - the page entry at an index, so a probe can walk the book without a UI.
func debug_page_at(i: int) -> Dictionary:
	if i < 0 or i >= _catalog.size():
		return {}
	return _catalog[i]


func debug_has_page(event_id: String) -> bool:
	return not _catalog_entry(event_id).is_empty()


func debug_catalog_size() -> int:
	return _catalog.size()


## SYNTHETIC - the stored record, preview stripped, for a probe checking a reload.
func debug_record(event_id: String) -> Dictionary:
	if not _records.has(event_id):
		return {}
	var r: Dictionary = (_records[event_id] as Dictionary).duplicate()
	r["has_preview"] = r.get("preview", null) != null
	r.erase("preview")
	return r


## SYNTHETIC - the page text a player would read, without a screenshot. For a headless probe.
func debug_page_text(event_id: String) -> String:
	if not has_shot(event_id):
		return ""
	return _taken_line(record_for(event_id))


# ============================================================================================
# PLANET SAFARI JOURNAL (docs/PLANET_SAFARI_SPEC.md 5.4, 5.6, 6; builder P5, 2026-09-23)
# ============================================================================================
## A SECOND, INDEPENDENT BOOK inside the same autoload. Everything above this line is the flight's
## book (`_records`, `_catalog`, `F_JOURNAL`, `rebuild_catalog`) and NOTHING below touches it -
## deliverable 5 is "flight photos must keep working exactly as in merge4", and the safest way to
## keep that true is to never read or write a single variable the flight code owns. A planet
## subject's key ("<planet>:<id>", PlanetSafari.add_subject's own key) can never collide with a
## flight sight id (SafariCatalog's ids have no colon), so even sharing a dictionary would have
## been safe, but a separate one makes it provably so instead of merely likely so.
##
## THE BUG THIS FIXES (spec deliverable 5): today the loader deletes any record whose id is not a
## flight sight (line ~500, "SafariCatalog.by_id(str(id)).is_empty() ... continue") and the pages
## are rebuilt only from SkyEvents' producible sights (`rebuild_catalog`). A planet safari's photos
## never went through either path before this round, so there was nothing here TO delete yet - this
## section is new, not a fix to old planet data (there was none).
##
## WHAT IS KEPT, and how, for each subject key:
##   _planet_woke      key -> true. Set the moment a subject is OFFERED to the journal (i.e. the
##                     player photographed it at least once) AND the moment a session reports it
##                     WOKE without being shot (`planet_mark_woke`). This is the SECRETS roster
##                     (spec 6.1): a key here with no record below is a "????" row - seen to exist,
##                     never identified. A subject that has never woken in any session this player
##                     has run doesn't have a row at all; see "WHAT THIS DOES NOT DO" below.
##   _planet_records   key -> the KEPT photo (spec 5.6 "keep new or old"): name, rarity, kind, day,
##                     hour, the four scores, grade, price, moment line, and a small WebP thumbnail,
##                     base64 in the save file itself. UNLIKE the flight's own `preview` (this
##                     file's header: "NOT SAVED... a reloaded page keeps its numbers and falls back
##                     to the silhouette"), spec 5.6 explicitly asks for these to survive a reload,
##                     so they are re-encoded small enough (PLANET_THUMB_W wide, WebP) to live
##                     inside GameState.flags -> the JSON save, with no second file to keep in sync.
##   _friend_records   npc_id -> the same shape, for spec 5.6's "Friends" section: your CHOSEN
##                     favourite photo of each neighbour (a subject whose `kind` is "neighbour").
##
## THE ROSTER (spec 8.2, "the secrets page lists EVERY subject of the planet, including ones that
## have never woken, as ????"). The live world registers some subjects only on some days (Bolt's
## Great Magnet on a rare day, the Spark-moths at night - worlds/bolt.gd `build`), so the live
## registry of one safari cannot list them all. The full id list per planet is its world's MANIFEST
## roster (spec 12.5; `const MANIFEST` in worlds/<planet>.gd, read through PlanetSafari.manifest, which
## falls back to the old table for a world that has none yet - see `_planet_manifest`); the review also
## teaches the journal every key the live world registered (`planet_learn_roster`), so a subject a
## world registers that its roster does not list still gets its row the first time a safari registers
## it. Names are NEVER shown from the roster: a row shows its name only once a photo of it is kept.
##
## PAYMENT (spec 8.2, "photos pay"). `planet_pay_begin` writes the session's total into
## GameState.flags[F_PAY] as pending when the review opens; `planet_pay_settle` adds it to stardust
## and erases the pending entry in the same frame. A save taken at any moment therefore holds one of
## "pending, unpaid" or "paid, not pending" - and a load settles any pending entry (a reload during
## the review), so the payment lands exactly once.
##
## THE SCRAPBOOK (spec 15.5, builder B3 2026-09-26; it replaces the "Planet Log" panel). FIVE SECTIONS -
## Sights, Events, Neighbours, Creatures, Bonus (SCRAPBOOK_SECTIONS) - one at a time behind a row of tabs,
## each GROUPED BY PLANET (SCRAPBOOK_PLANETS, the story's order; any other planet with data after them).
## EVERY ENTRY HAS ITS PAGE FROM THE START: every roster entry of every planet that has a safari manifest,
## whether you have been there or not, blank and titled "???" until a photo of it is kept. A roster entry's
## section is its manifest "category" (safari_world.gd CATEGORY; an entry without one gets it from its tier,
## `SafariWorld.category_from`, loaded by path). NEIGHBOURS IS THE FRIENDS PAGE: a neighbour's page shows
## your chosen favourite (`_friend_records`), else the kept subject photo. A bonus page says it is a
## collector's page. The tab row counts what is filled ("Sights 3/10").
## THE SKY PAGES ARE HIDDEN while SafariTransit.SPACE_SAFARI is off (spec 15.1, `space_safari_on`): the
## Journal pill, the J key and `open_to` all open the scrapbook, and the sky book cannot be reached. With
## the switch on, the pill opens the sky pages as before, with a "Scrapbook" button in their header and a
## "Sky pages" button back from the scrapbook. The flight's records are kept either way; only the UI hides.
##
## FOR THE STORY (spec 15.2, 15.3): `planet_top_grade(key)` is the highest grade ever photographed of a
## subject (raised on every photo the review offers, kept or not - the flight's TOP GRADE rule, so choosing
## the old photo for taste never loses a story step), `planet_has_grade_at_least(key, grade)`, and
## `planet_has_neighbour_photo()`; the same from the save with no node: `saved_planet_top_grade`,
## `saved_planet_grade_at_least`, `saved_planet_neighbour_photo`. Every planet photo offered emits
## `page_filed("<planet>:<id>", grade)` (a colon key can never be a sky sight id), so a live ProjectSystem
## re-checks at once. THE BEST SESSION TOTAL: `planet_pay_settle` raises
## GameState.flags[F_BEST_TOTAL][<planet>] to the paid total when it is the best yet (`note_best_total`)
## and emits `best_total_changed(planet, total)`.
##
## PUBLIC API (called by src/planet_safari/review/safari_review.gd; nothing else needs it today):
##   planet_has_photo(key) -> bool
##   planet_record_for(key) -> Dictionary                 {} if never kept
##   planet_offer_photo(photo, planet_id) -> Dictionary    {"key", "old"} - "old" is {} for a first
##       shot (nothing to compare - the review should just call planet_keep_new itself); otherwise
##       the review shows both images and calls keep_new or keep_old for the player's choice.
##   planet_keep_new(photo, planet_id) -> void
##   planet_keep_old(key) -> void                          explicit no-op; see the doc comment on it
##   planet_restore_record(key, record) -> void            11.3's swap-back: write a RECORD (the same
##       shape `planet_record_for`/an "old" dict already has, never a raw photo) back as the kept one
##   planet_mark_woke(planet_id, woke_ids) -> void          the SECRETS roster; call once per session
##   planet_page_ids(planet_id) -> Array                    discovery order, for a SECRETS page
##   planet_friend_offer(npc_id) -> Dictionary              same shape as planet_offer_photo
##   planet_keep_friend_new(npc_id, photo, planet_id) -> void
##   planet_keep_friend_old(npc_id) -> void
##   friend_record_for(npc_id) -> Dictionary
##   friend_ids() -> Array
##   planet_learn_roster(planet_id, keys) -> void            every key a live world registered
##   planet_roster(planet_id) -> Array                       every subject key, fixed order
##   planet_pay_begin(planet_id, total) -> String            pending payout id ("" for 0)
##   planet_pay_settle(id) -> int                            pays it once; 0 if already paid; notes the best total
##   planet_top_grade(key) / planet_has_grade_at_least(key, grade) / planet_has_neighbour_photo()
##   static saved_planet_top_grade / saved_planet_grade_at_least / saved_planet_neighbour_photo / note_best_total
##   static best_total(planet_id) -> int                     the best paid session on that planet (0 if none)
##   scrapbook_entries(section) -> Array                     [{planet, key, filled}] in the order shown

const F_PLANET := "planet_journal"
## RAISED FROM 160 TO 256 (critic round 2, 2026-09-24): at 160 the ROW thumbnail (a landscape photo,
## the game's own viewport aspect - roughly 2.17:1, `PlanetSafari.PHOTO_W`) let down and letterboxed
## inside its box measured about 73x31 native phone px - too small to see, and the display box could
## never grow past a blurry 160-wide source anyway. 256 is P3's own report's other measured point
## (~3 KB a WebP q0.8, same report the old 160 comment cited); re-measured below in
## `debug_planet_thumb_bytes` rather than assumed, both here and by the round-2 critic.
const PLANET_THUMB_W := 384
const PLANET_THUMB_LOSSY := true
const PLANET_THUMB_QUALITY := 0.8
## RAISED AGAIN TO 384 (P5b, 2026-09-24): the Planet Log's rows are now sized from the screen (about
## 330-420 logical px wide on a phone, 540-690 device px), and the review compares a kept photo side
## by side with a fresh 512-wide one; a 256 source was upscaled 2x in both. Measured size: see the
## report (`debug_planet_thumb_bytes`).
##
## THE PLANET LOG'S LAYOUT is derived from the screen when it opens (`_layout_planet_panel`): the
## panel fills the screen inside the safe area, rows sit in two columns when there is room, and each
## row's photo takes this share of its cell's width.
const PLANET_ROW_THUMB_SHARE := 0.58
const PLANET_ROW_THUMB_MIN_W := 216.0
## The row box's height for a subject with no photo ("????"): the shape of a phone photo.
const PLANET_ROW_ASPECT := 2.17
## The tap-to-enlarge dialog: this share of the screen, both ways, whichever binds first.
const PLANET_ENLARGE_SHARE := Vector2(0.84, 0.66)
## THE ROSTER AND THE HOST COME FROM EACH WORLD'S MANIFEST (spec 12.5, 13.3; they were hard-coded here
## as PLANET_ROSTER / PLANET_HOST, and the spring-hopper was missing). This autoload must never NAME the
## safari classes (a class name here loads the whole safari script graph at boot and leaked 465 objects
## in characters_lineup.tscn - spec 9.1), so the reader is loaded BY PATH, lazily, the first time a
## roster or a host is wanted (the Planet Log opening, the review) and never at boot.
const PLANET_SAFARI_SCRIPT := "res://src/planet_safari/planet_safari.gd"
const F_PAY := "planet_safari_pending_pay"
## Spec 15.2's shared flag: planet id -> the best session total paid on that planet.
const F_BEST_TOTAL := "planet_safari_best_total"
## Loaded BY PATH, lazily, for the same reason as PLANET_SAFARI_SCRIPT: the scrapbook's categories
## (SafariWorld.category_from) and the space-safari switch (SafariTransit.SPACE_SAFARI).
const SAFARI_WORLD_SCRIPT := "res://src/planet_safari/safari_world.gd"
const SAFARI_TRANSIT_SCRIPT := "res://src/sky/safari_transit.gd"
## The scrapbook's sections, in order (SafariWorld.CATEGORIES), and their titles.
## "home" (builder HOMEALBUM, docs/STORY_HOME_SPEC.md 8.1) is not a subject category like the other
## five - it is HomeAlbumStore's own freeform, up-to-25 album, never auto-replaced. `_refresh_scrap_tabs`
## and `_refresh_planet_panel` special-case it rather than routing it through `scrapbook_entries`.
## "cave" (builder CAVE, docs/STORY_HOME_SPEC.md 9.3) is special-cased the same way: CaveStore's own
## pages (src/cave/cave_store.gd), shown only once the story is over (CaveStore.unlocked).
const SCRAPBOOK_SECTIONS: Array[String] = ["sight", "event", "neighbour", "creature", "bonus", "home", "cave"]
const SCRAPBOOK_TITLES := {
	"sight": "Sights", "event": "Events", "neighbour": "Neighbours", "creature": "Creatures", "bonus": "Bonus",
	"home": "Home", "cave": "Cave",
}
## The planets the scrapbook lists, in the story's order (planet_score.gd TRUST_NPCS; written out so this
## autoload names no other class). Only those with a safari manifest are shown.
## "jungle" (The Tangle, JWIRE 2026-09-29, docs/JUNGLE_PLANET_SPEC.md) is not part of that story order -
## it is a locked side world, so `scrapbook_planets()` also gates it on GameState.flags["jungle_open"]
## (the same flag the rocket pad and space map lock it behind) rather than showing its "???" pages before
## the player has ever been able to go there.
const SCRAPBOOK_PLANETS: Array[String] = ["zorp", "bolt", "fen", "grig", "vela", "jungle"]

## Emitted when a paid session raises a planet's best total (spec 15.2's "one safari worth N").
signal best_total_changed(planet_id: String, total: int)

var _planet_records: Dictionary = {}   # "<planet>:<id>" -> record (see header)
var _planet_woke: Dictionary = {}      # "<planet>:<id>" -> true
var _friend_records: Dictionary = {}   # npc_id -> record
var _learned_roster: Dictionary = {}   # planet_id -> Array of keys the live worlds registered
var _pay_notice := 0                   # stardust settled at load, announced on the next planet
var _planet_grids: Array = []          # the scrapbook's GridContainers (for a re-layout)
var _planet_top: Dictionary = {}       # "<planet>:<id>" -> the highest grade ever photographed (story)
var _scrap_section := "sight"          # the scrapbook's open section (in memory)
var _scrap_tabs: Dictionary = {}       # section -> its tab Button
var _scrap_sky_btn: Button             # "Sky pages", only while the space safari is on
var _home_selection: Dictionary = {}   # HomeAlbumStore id -> true; the Home section's own bulk pick


func planet_has_photo(key: String) -> bool:
	return _planet_records.has(key)


func planet_record_for(key: String) -> Dictionary:
	if not _planet_records.has(key):
		return {}
	return (_planet_records[key] as Dictionary).duplicate(true)


## Called once per photo that names a subject (`photo.subject_key != ""`), BEFORE anything is
## committed. Registers the subject as discovered (SECRETS) either way, and hands back whatever is
## already kept for it so the caller can decide whether a choice is even needed.
func planet_offer_photo(photo: Dictionary, planet_id: String) -> Dictionary:
	var key := str(photo.get("subject_key", ""))
	if key == "":
		return {"key": "", "old": {}}
	_planet_woke[key] = true
	var grade := str(photo.get("grade", ""))
	if grade_rank(grade) > grade_rank(str(_planet_top.get(key, ""))):
		_planet_top[key] = grade
		save_planet_to_flags()
	page_filed.emit(key, grade)
	return {"key": key, "old": planet_record_for(key)}


## Commits `photo` as the kept record for its subject - overwrites whatever was there. The caller
## (the review) calls this straight away for a first shot, or after the player picks "keep new".
func planet_keep_new(photo: Dictionary, planet_id: String) -> void:
	var key := str(photo.get("subject_key", ""))
	if key == "":
		return
	_planet_woke[key] = true
	_planet_records[key] = _planet_record_from_photo(photo, planet_id)
	save_planet_to_flags()
	_update_planet_button()
	if _planet_panel != null and _planet_panel.visible:
		_refresh_planet_panel()


## Explicit no-op: "keep old" changes nothing on disk. Kept as its own function (rather than the
## review simply not calling anything) so the choice always has two real, named paths to test, and
## so a future rule ("keep old" still bumps a times-seen counter, say) has one place to land.
func planet_keep_old(_key: String) -> void:
	pass


## 11.3's swap-back: the reveal's "swap" tap on the SUBJECT's own choice (never Friends - that one
## has no nudge) needs to put the OLD record back after `planet_keep_new` already overwrote it.
## `record` is a record already in this shape (what `planet_offer_photo`'s "old" and
## `planet_record_for` both hand back) - never a raw photo, so it is written as-is, not re-derived.
## A no-op for an empty record (nothing to restore) or an empty key, same guard as `planet_keep_new`.
func planet_restore_record(key: String, record: Dictionary) -> void:
	if key == "" or record.is_empty():
		return
	_planet_records[key] = record.duplicate(true)
	save_planet_to_flags()
	_update_planet_button()
	if _planet_panel != null and _planet_panel.visible:
		_refresh_planet_panel()


func _planet_record_from_photo(photo: Dictionary, planet_id: String) -> Dictionary:
	var scores: Dictionary = photo.get("scores", {})
	var raw: Dictionary = photo.get("raw", {})
	var rec_scores := {
		"centred": int(scores.get("centred", 0)),
		"size": int(scores.get("size", 0)),
		"focus": int(scores.get("focus", 0)),
		"rarity": int(scores.get("rarity", 0)),
	}
	# FACING (11.1) is a new score only some subjects carry (those with a "front"); a subject with
	# none never puts "facing" into `photo.scores`, so the KEPT record leaves it out too rather than
	# storing a fake 0 - the review's bar stays hidden for it after a reload exactly as it was live.
	if scores.has("facing"):
		rec_scores["facing"] = int(scores.get("facing", 0))
	return {
		"planet_id": planet_id,
		"name": str(photo.get("subject_name", "")),
		"rarity": int(photo.get("rarity", 0)),
		"kind": str(raw.get("kind", "")),
		"category": str(raw.get("category", "")),
		"day": GameState.day_count,
		"hour": GameState.time_of_day,
		"scores": rec_scores,
		"grade": str(photo.get("grade", "")),
		"price": int(photo.get("price", 0)),
		"moment_line": str(photo.get("moment_line", "")),
		"thumb_b64": _encode_planet_thumb(photo.get("image")),
	}


## Image -> a small WebP, base64, so it can live inside GameState.flags (JSON has no bytes). ""
## when there is no image to encode (a synthetic test photo, or a decode/encode failure).
func _encode_planet_thumb(img_v: Variant) -> String:
	if not (img_v is Image):
		return ""
	var img := (img_v as Image).duplicate() as Image
	if img.is_empty():
		return ""
	if img.get_width() > PLANET_THUMB_W:
		var h := maxi(1, int(round(float(img.get_height()) * PLANET_THUMB_W / float(maxi(img.get_width(), 1)))))
		img.resize(PLANET_THUMB_W, h, Image.INTERPOLATE_BILINEAR)
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	var bytes := img.save_webp_to_buffer(PLANET_THUMB_LOSSY, PLANET_THUMB_QUALITY)
	if bytes.is_empty():
		return ""
	return Marshalls.raw_to_base64(bytes)


func _decode_planet_thumb(b64: String) -> Image:
	if b64 == "":
		return null
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.is_empty():
		return null
	var img := Image.new()
	var err := img.load_webp_from_buffer(bytes)
	return img if err == OK and not img.is_empty() else null


## Public. Every subject the player has DISCOVERED on `planet_id` (woke or photographed), oldest
## first - the SECRETS page's roster (spec 6.1). See the header for what this does not (yet) do.
func planet_page_ids(planet_id: String) -> Array:
	var prefix := planet_id + ":"
	var out: Array = planet_roster(planet_id)
	for k in _planet_woke.keys():
		if str(k).begins_with(prefix) and not out.has(str(k)):
			out.append(str(k))
	for k in _planet_records.keys():
		if str(k).begins_with(prefix) and not out.has(str(k)):
			out.append(str(k))
	return out


## Public. Every subject key of `planet_id` the journal knows exists - the fixed roster first, then
## any key a live world registered that the roster does not list. Discovered or not.
func planet_roster(planet_id: String) -> Array:
	var out: Array = []
	for e: Variant in _planet_manifest(planet_id).get("roster", []):
		if e is Dictionary:
			out.append("%s:%s" % [planet_id, str((e as Dictionary).get("id", ""))])
	# THE LAST PHOTO (finale_gift.gd, docs/STORY_HOME_SPEC.md ruling 11). The Commons has no safari
	# MANIFEST, so without this "hub:home" always fell to _learned_roster the first time the finale
	# filed it - which prints "SkyJournal: hub registered subjects the roster does not list" every
	# time, forever, since a safari roster gap is meant to be a standing warning. The one page the
	# finale itself fires belongs in the fixed roster, not in that "somebody forgot to add this"
	# bucket - added here rather than at the finale's own call site, since this is the file that owns
	# the roster's shape.
	if planet_id == HOME_PAGE_PLANET and not out.has(HOME_PAGE_KEY):
		out.append(HOME_PAGE_KEY)
	for k: String in _learned_roster.get(planet_id, []):
		if not out.has(k):
			out.append(k)
	return out


## The planet's safari MANIFEST (PlanetSafari.manifest: the world script's `const MANIFEST`, or the
## fallback table), loaded by path on first use - see PLANET_SAFARI_SCRIPT. {} for a planet with none.
func _planet_manifest(planet_id: String) -> Dictionary:
	if planet_id == "" or not ResourceLoader.exists(PLANET_SAFARI_SCRIPT):
		return {}
	var scr: Variant = load(PLANET_SAFARI_SCRIPT)
	if not (scr is Script):
		return {}
	var m: Variant = (scr as Script).call("manifest", planet_id)
	return m if m is Dictionary else {}


## The npc id whose world `planet_id` is (its manifest's host), "" when unknown.
func _planet_host(planet_id: String) -> String:
	return str(_planet_manifest(planet_id).get("host", ""))


## Public. Called by the review with every key the live world registered this session (woken or
## not). A key the fixed roster does not list is remembered (and saved) so its "????" row appears.
func planet_learn_roster(planet_id: String, keys: Array) -> void:
	if planet_id == "":
		return
	var known := planet_roster(planet_id)
	var learned: Array = (_learned_roster.get(planet_id, []) as Array).duplicate()
	var changed := false
	for raw in keys:
		var k := str(raw)
		if k == "":
			continue
		if not k.begins_with(planet_id + ":"):
			k = "%s:%s" % [planet_id, k]
		if not known.has(k):
			learned.append(k)
			known.append(k)
			changed = true
	if changed:
		push_warning("SkyJournal: %s registered subjects the roster does not list: %s - add them to its MANIFEST roster" % [
			planet_id, str(learned)])
		_learned_roster[planet_id] = learned
		save_planet_to_flags()


## Public. Every planet id that has at least one discovered subject, in first-discovered order.
func planet_ids_with_data() -> Array:
	var out: Array = []
	for k in _planet_woke.keys() + _planet_records.keys():
		var pid := str(k).get_slice(":", 0)
		if pid != "" and not out.has(pid):
			out.append(pid)
	return out


## Public. Registers every subject id that WOKE this session (photographed or not) so the SECRETS
## page can show a "????" row for the ones that were never shot. Call once, after a session ends
## (`session.woke`, planet_safari.gd's own field - never the names, only the ids).
func planet_mark_woke(planet_id: String, woke_ids: Array) -> void:
	var changed := false
	for raw_id in woke_ids:
		var key := str(raw_id)
		if key == "":
			continue
		if not key.begins_with(planet_id + ":"):
			key = "%s:%s" % [planet_id, key]
		if not _planet_woke.has(key):
			_planet_woke[key] = true
			changed = true
	if changed:
		save_planet_to_flags()
		_update_planet_button()
		if _planet_panel != null and _planet_panel.visible:
			_refresh_planet_panel()


# ---------------------------------------------------------------------------------- friends
## Same two-step shape as `planet_offer_photo`/`planet_keep_new`, for a photo whose subject `kind`
## is "neighbour" (planet_safari.gd's API, `safari_photo_scorer.gd` carries it through into
## `photo.raw.kind`). `npc_id` names WHICH neighbour - today that is always the safari's own host
## (PlanetSafari.PLANETS[planet_id].host: Bolt is the only one), because no subject dictionary
## carries an npc id of its own yet (flagged in needs_from_others).
func planet_friend_offer(npc_id: String) -> Dictionary:
	if npc_id == "":
		return {"old": {}}
	return {"old": friend_record_for(npc_id)}


func planet_keep_friend_new(npc_id: String, photo: Dictionary, planet_id: String) -> void:
	if npc_id == "":
		return
	var rec := _planet_record_from_photo(photo, planet_id)
	rec["npc_id"] = npc_id
	_friend_records[npc_id] = rec
	save_planet_to_flags()
	_update_planet_button()
	if _planet_panel != null and _planet_panel.visible:
		_refresh_planet_panel()


func planet_keep_friend_old(_npc_id: String) -> void:
	pass


func friend_record_for(npc_id: String) -> Dictionary:
	if not _friend_records.has(npc_id):
		return {}
	return (_friend_records[npc_id] as Dictionary).duplicate(true)


## Public. Every npc id with a favourite photo kept, in the order it was first set.
func friend_ids() -> Array:
	return _friend_records.keys()


# ---------------------------------------------------------------------------------- persistence
func save_planet_to_flags() -> void:
	GameState.flags[F_PLANET] = {
		"records": _planet_records.duplicate(true),
		"woke": _planet_woke.duplicate(true),
		"friends": _friend_records.duplicate(true),
		"roster": _learned_roster.duplicate(true),
		"top": _planet_top.duplicate(true),
	}


func load_planet_from_flags() -> void:
	_planet_records.clear()
	_planet_woke.clear()
	_friend_records.clear()
	_learned_roster.clear()
	_planet_top.clear()
	var blob: Variant = GameState.flags.get(F_PLANET, {})
	if not (blob is Dictionary):
		return
	var d: Dictionary = blob
	var recs: Variant = d.get("records", {})
	if recs is Dictionary:
		for k in (recs as Dictionary):
			var v: Variant = (recs as Dictionary)[k]
			if v is Dictionary:
				_planet_records[str(k)] = (v as Dictionary).duplicate(true)
	var woke: Variant = d.get("woke", {})
	if woke is Dictionary:
		for k in (woke as Dictionary):
			_planet_woke[str(k)] = true
	var friends: Variant = d.get("friends", {})
	if friends is Dictionary:
		for k in (friends as Dictionary):
			var v2: Variant = (friends as Dictionary)[k]
			if v2 is Dictionary:
				_friend_records[str(k)] = (v2 as Dictionary).duplicate(true)
	var roster: Variant = d.get("roster", {})
	if roster is Dictionary:
		for k in (roster as Dictionary):
			var v3: Variant = (roster as Dictionary)[k]
			if v3 is Array:
				_learned_roster[str(k)] = (v3 as Array).map(func(x: Variant) -> String: return str(x))
	var top: Variant = d.get("top", {})
	if top is Dictionary:
		for k in (top as Dictionary):
			_planet_top[str(k)] = str((top as Dictionary)[k])
	# A SAVE FROM BEFORE THE TOP GRADE: every kept photo's grade is the best it can honestly claim.
	for k: String in _planet_records:
		var g := str((_planet_records[k] as Dictionary).get("grade", ""))
		if grade_rank(g) > grade_rank(str(_planet_top.get(k, ""))):
			_planet_top[k] = g


# ---------------------------------------------------------------------------------- for the story
## Public. The highest grade ever photographed of subject `key` ("<planet>:<id>"), "" if never (spec 15.2).
func planet_top_grade(key: String) -> String:
	return str(_planet_top.get(key, ""))


## Public. True when subject `key` was photographed at `grade` or better (an unknown grade is never met).
func planet_has_grade_at_least(key: String, grade: String) -> bool:
	var need := grade_rank(grade)
	return need >= 0 and grade_rank(planet_top_grade(key)) >= need


## Public. True once the journal holds any photo of a neighbour (spec 15.3, the Professor's first task):
## a Friends favourite, or a photographed subject whose category or kind is "neighbour".
func planet_has_neighbour_photo() -> bool:
	if not _friend_records.is_empty():
		return true
	for k: String in _planet_records:
		var r: Dictionary = _planet_records[k]
		if str(r.get("category", "")) == "neighbour" or str(r.get("kind", "")) == "neighbour":
			return true
	return false


## The same three, read straight from the saved flag (a caller with no journal node, a bare probe).
static func saved_planet_top_grade(key: String) -> String:
	var blob: Variant = GameState.flags.get(F_PLANET, {})
	if not (blob is Dictionary):
		return ""
	var best := ""
	var top: Variant = (blob as Dictionary).get("top", {})
	if top is Dictionary:
		best = str((top as Dictionary).get(key, ""))
	var recs: Variant = (blob as Dictionary).get("records", {})
	if recs is Dictionary and (recs as Dictionary).get(key) is Dictionary:
		var g := str(((recs as Dictionary)[key] as Dictionary).get("grade", ""))
		if grade_rank(g) > grade_rank(best):
			best = g
	return best


static func saved_planet_grade_at_least(key: String, grade: String) -> bool:
	var need := grade_rank(grade)
	return need >= 0 and grade_rank(saved_planet_top_grade(key)) >= need


static func saved_planet_neighbour_photo() -> bool:
	var blob: Variant = GameState.flags.get(F_PLANET, {})
	if not (blob is Dictionary):
		return false
	var friends: Variant = (blob as Dictionary).get("friends", {})
	if friends is Dictionary and not (friends as Dictionary).is_empty():
		return true
	var recs: Variant = (blob as Dictionary).get("records", {})
	if recs is Dictionary:
		for k in (recs as Dictionary):
			var r: Variant = (recs as Dictionary)[k]
			if r is Dictionary and (str((r as Dictionary).get("category", "")) == "neighbour" \
					or str((r as Dictionary).get("kind", "")) == "neighbour"):
				return true
	return false


## Spec 15.2's shared flag: raises GameState.flags[F_BEST_TOTAL][planet_id] to `total` when it beats the
## best so far. Returns true when it did. Called when a session is PAID (planet_pay_settle), so once per
## session; the review calls it itself only in its no-journal fallback.
static func note_best_total(planet_id: String, total: int) -> bool:
	if planet_id == "" or total <= 0:
		return false
	var v: Variant = GameState.flags.get(F_BEST_TOTAL, {})
	var d: Dictionary = (v as Dictionary).duplicate() if v is Dictionary else {}
	if total <= int(d.get(planet_id, 0)):
		return false
	d[planet_id] = total
	GameState.flags[F_BEST_TOTAL] = d
	return true


## The best paid session total on `planet_id` (0 when none has paid yet).
static func best_total(planet_id: String) -> int:
	var v: Variant = GameState.flags.get(F_BEST_TOTAL, {})
	return int((v as Dictionary).get(planet_id, 0)) if v is Dictionary else 0


# ---------------------------------------------------------------------------------- payment
## Public. Records `total` stardust as PENDING for the review that just opened and saves; returns
## the id `planet_pay_settle` pays. "" (nothing recorded) for a total of 0.
func planet_pay_begin(planet_id: String, total: int) -> String:
	if total <= 0:
		return ""
	var id := "%s_d%d_%d" % [planet_id, GameState.day_count, Time.get_ticks_usec()]
	var pend: Dictionary = _pending_pay().duplicate(true)
	pend[id] = {"planet_id": planet_id, "amount": total, "day": GameState.day_count}
	GameState.flags[F_PAY] = pend
	_save_soon("safari_pay_pending")
	return id


## Public. Pays the pending entry `id` and erases it IN THE SAME FRAME, then saves. Returns what it
## paid - 0 when `id` is unknown or already paid, so calling it twice can never pay twice.
func planet_pay_settle(id: String) -> int:
	var pend: Dictionary = _pending_pay().duplicate(true)
	if id == "" or not pend.has(id):
		return 0
	var entry: Variant = pend[id]
	var amount := maxi(0, int((entry as Dictionary).get("amount", 0))) if entry is Dictionary else 0
	var pid := str((entry as Dictionary).get("planet_id", "")) if entry is Dictionary else ""
	pend.erase(id)
	if pend.is_empty():
		GameState.flags.erase(F_PAY)
	else:
		GameState.flags[F_PAY] = pend
	if amount > 0:
		GameState.add_stardust(amount)
	# THE BEST SESSION TOTAL (spec 15.2), in the same frame as the payment: a session is paid once, so
	# the flag is written once for it - from the review, or from the load that settles an interrupted one.
	var raised := note_best_total(pid, amount)
	_save_soon("safari_paid")
	if raised:
		best_total_changed.emit(pid, amount)
	return amount


## Public. Pays every pending entry (a review a reload interrupted). Returns the total paid.
func planet_pay_settle_all() -> int:
	var paid := 0
	for id: String in _pending_pay().keys():
		paid += planet_pay_settle(id)
	return paid


func planet_pay_pending_total() -> int:
	var t := 0
	for e: Variant in _pending_pay().values():
		if e is Dictionary:
			t += int((e as Dictionary).get("amount", 0))
	return t


func _pending_pay() -> Dictionary:
	var v: Variant = GameState.flags.get(F_PAY, {})
	return v if v is Dictionary else {}


## Write the save now (SaveManager.save_now: still gated by autosave_allowed, so a test run never
## writes). It drops a write inside 0.5 s of the last one, so retry once just after that window.
func _save_soon(reason: String) -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or not bool(sm.call("autosave_allowed")):
		return
	if bool(sm.call("save_now", reason)):
		return
	get_tree().create_timer(0.6, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(sm) and bool(sm.call("autosave_allowed")):
			sm.call("save_now", reason))


func _on_planet_loaded_pay(_planet_id: String) -> void:
	if _pay_notice <= 0:
		return
	var n := _pay_notice
	_pay_notice = 0
	EventBus.toast_requested.emit("+%d stardust for your safari photos" % n, "star")
	_save_soon("safari_paid_on_load")


# ---------------------------------------------------------------------------------- UI: the panel
## THE SCRAPBOOK PANEL (spec 15.5; the Planet Log's panel, rebuilt). A SEPARATE panel from `_panel` (the
## sky book), a sibling under `_root`. Opening it hides the sky panel and vice versa; nothing about the sky
## panel's own nodes or draw path is touched here. Row 1: the title, "Sky pages" (only while the space
## safari is on) and Close. Row 2: the five section tabs, each as wide as the others. Then the section,
## scrolled.
func _build_planet_panel() -> void:
	_planet_panel = PanelContainer.new()
	_planet_panel.name = "PlanetJournalPanel"
	_planet_panel.visible = false
	_planet_panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_CREAM, 26))
	_root.add_child(_planet_panel)

	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 8)
	_planet_panel.add_child(m)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	m.add_child(outer)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 12)
	outer.add_child(head_row)
	var head := Label.new()
	head.text = "Scrapbook"
	head.add_theme_font_override("font", UIStyle.ui_font())
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", C_TEXT)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(head)
	_scrap_sky_btn = _mk_button("Sky pages", _open_sky_from_scrapbook)
	head_row.add_child(_scrap_sky_btn)
	head_row.add_child(_mk_button("Close", _close_planet_panel))

	var tabs := HBoxContainer.new()
	tabs.name = "ScrapbookTabs"
	tabs.add_theme_constant_override("separation", 8)
	outer.add_child(tabs)
	_scrap_tabs.clear()
	for sec: String in SCRAPBOOK_SECTIONS:
		var sec_id := sec
		var b := _mk_button(str(SCRAPBOOK_TITLES[sec]), func(): _show_scrap_section(sec_id))
		b.name = "Tab_" + sec
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_stretch_ratio = 1.0
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 50)
		tabs.add_child(b)
		_scrap_tabs[sec] = b

	var scroll := ScrollContainer.new()
	scroll.name = "PlanetScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_planet_body = VBoxContainer.new()
	_planet_body.add_theme_constant_override("separation", 14)
	_planet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_planet_body)


func _open_sky_from_scrapbook() -> void:
	_close_planet_panel()
	if space_safari_on():
		_panel.visible = true
		_refresh_page()


## Switches the scrapbook to `section` (one of SCRAPBOOK_SECTIONS) and redraws it, back at the top.
func _show_scrap_section(section: String) -> void:
	if not SCRAPBOOK_SECTIONS.has(section):
		return
	_scrap_section = section
	_home_selection.clear()   # a fresh tab switch always starts with nothing picked
	if _planet_panel != null:
		var sc := _planet_panel.find_child("PlanetScroll", true, false) as ScrollContainer
		if sc != null:
			sc.scroll_vertical = 0
	_refresh_planet_panel()

## The Planet Log fills the screen inside the safe area (a notch) - on a phone every row photo needs
## the width - and is centred with a ceiling on a wide desktop window. Re-done on every open, so a
## rotation or a UI-mode change is picked up.
func _layout_planet_panel() -> void:
	var vp := get_viewport().get_visible_rect().size
	var safe := MobileUI.safe_area()
	var edge := 14.0
	var w := minf(vp.x - safe.x - safe.z - 2.0 * edge, 1320.0)
	var h := vp.y - safe.y - safe.w - 2.0 * edge
	var left := safe.x + edge + (vp.x - safe.x - safe.z - 2.0 * edge - w) * 0.5
	_planet_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_planet_panel.position = Vector2(left, safe.y + edge)
	_planet_panel.size = Vector2(w, h)
	_planet_panel.custom_minimum_size = Vector2(w, h)


## The width a row's cell gets, and how many columns: two whenever a row photo can still be at least
## PLANET_ROW_THUMB_MIN_W wide in half the panel.
func _planet_columns() -> int:
	var inner := _planet_inner_w()
	return 2 if (inner - 14.0) * 0.5 * PLANET_ROW_THUMB_SHARE >= 300.0 else 1


func _planet_inner_w() -> float:
	# panel style margin 20 + MarginContainer 8, both sides, and room for a scroll bar
	return _planet_panel.size.x - 2.0 * (20.0 + 8.0) - 16.0


func _planet_thumb_w() -> float:
	var cols := _planet_columns()
	var cell := (_planet_inner_w() - 14.0 * float(cols - 1)) / float(cols)
	return maxf(PLANET_ROW_THUMB_MIN_W, cell * PLANET_ROW_THUMB_SHARE)


## The sky pages' "Scrapbook" button: always there while the space safari is on - every scrapbook page
## exists from the start (spec 15.5), so there is always something to open it for.
func _update_planet_button() -> void:
	if _planet_btn == null:
		return
	_planet_btn.visible = true


func _open_planet_panel() -> void:
	_panel.visible = false
	_planet_panel.visible = true
	if _scrap_sky_btn != null:
		_scrap_sky_btn.visible = space_safari_on()
	_layout_planet_panel()
	_refresh_planet_panel()


func _close_planet_panel() -> void:
	if _planet_panel != null:
		_planet_panel.visible = false
	_close_enlarged()


# ---------------------------------------------------------------------------------- the scrapbook
## The planets the scrapbook shows: SCRAPBOOK_PLANETS that have a safari manifest, then any other planet
## the journal holds data for.
func scrapbook_planets() -> Array:
	var out: Array = []
	for pid: String in SCRAPBOOK_PLANETS:
		# The Tangle is locked (JUNGLE_PLANET_SPEC.md 2, "a new rocket destination... locked by
		# GameState.flags['jungle_open']"): its pages stay out of the scrapbook until that flag is set,
		# same as the rocket pad and space map hide the world itself until then.
		if pid == "jungle" and not GameState.flag("jungle_open"):
			continue
		if not _planet_manifest(pid).is_empty():
			out.append(pid)
	for pid: String in planet_ids_with_data():
		if not out.has(pid):
			out.append(pid)
	return out


## The scrapbook category of subject `key`: its roster entry's (SafariWorld.category_from, loaded by
## path), else the kept photo's own, else "event".
func scrap_category(key: String) -> String:
	var pid := key.get_slice(":", 0)
	var id := key.get_slice(":", 1)
	for e: Variant in _planet_manifest(pid).get("roster", []):
		if e is Dictionary and str((e as Dictionary).get("id", "")) == id:
			return _category_from(e as Dictionary)
	var rec: Dictionary = _planet_records.get(key, {})
	if not rec.is_empty():
		return _category_from(rec)
	return "event"


func _category_from(entry: Dictionary) -> String:
	if ResourceLoader.exists(SAFARI_WORLD_SCRIPT):
		var scr: Variant = load(SAFARI_WORLD_SCRIPT)
		if scr is Script:
			var c: Variant = (scr as Script).call("category_from", entry)
			if c is String and SCRAPBOOK_SECTIONS.has(c):
				return c
	return "event"


## Public. Every page of `section`, in the order the scrapbook shows them: [{planet, key, filled}].
## A neighbour's page is filled by a Friends favourite or a kept photo of them.
func scrapbook_entries(section: String) -> Array:
	var out: Array = []
	for pid: String in scrapbook_planets():
		for key: String in planet_roster(pid):
			if scrap_category(key) != section:
				continue
			out.append({"planet": pid, "key": key, "filled": not _scrap_record(key).is_empty()})
	return out


## The photo a page shows: a neighbour's Friends favourite first (Neighbours IS the Friends page), else
## the kept photo of that subject. {} for a blank page.
func _scrap_record(key: String) -> Dictionary:
	var id := key.get_slice(":", 1)
	if scrap_category(key) == "neighbour":
		var f := friend_record_for(id)
		if f.is_empty():
			var host := _planet_host(key.get_slice(":", 0))
			if host != "" and _neighbour_ids(key.get_slice(":", 0)).size() == 1:
				f = friend_record_for(host)
		if not f.is_empty():
			if str(f.get("name", "")) == "":
				f["name"] = _npc_display_name(str(f.get("npc_id", id)))
			return f
	return planet_record_for(key)


func _neighbour_ids(pid: String) -> Array:
	var out: Array = []
	for key: String in planet_roster(pid):
		if scrap_category(key) == "neighbour":
			out.append(key.get_slice(":", 1))
	return out


## HUDJ (2026-09-28): the "neighbour" tab's "X/Y" used to count only `rows` (the roster's own
## neighbour entries), while `_refresh_planet_panel` ALSO appends an "Other friends" group for any
## favourited npc the roster does not list (an old save, or a neighbour from a world without a
## manifest - see that function). The tab's total silently fell out of sync with the page whenever
## that group was non-empty. Shared here so both call sites read the exact same set and can never
## drift apart again: every friend id in `rows` (keyed by npc_id, the same key `_scrap_record`
## resolves a neighbour row through) is "shown"; everything `friend_ids()` holds beyond that is extra.
func _neighbour_extra_ids(rows: Array) -> Array:
	var shown: Dictionary = {}
	for r: Dictionary in rows:
		var rec := _scrap_record(str(r["key"]))
		shown[str(rec.get("npc_id", str(r["key"]).get_slice(":", 1)))] = true
	return friend_ids().filter(func(n: Variant) -> bool: return not shown.has(str(n)))


func _refresh_scrap_tabs() -> void:
	for sec: String in SCRAPBOOK_SECTIONS:
		var b: Button = _scrap_tabs.get(sec)
		if b == null:
			continue
		var filled := 0
		var total := 0
		if sec == "home":
			# HomeAlbumStore's own count, not a subject roster (see the SCRAPBOOK_SECTIONS comment).
			filled = HomeAlbumStore.count()
			total = HomeAlbumStore.MAX_PHOTOS
		elif sec == "cave":
			# CaveStore's own pages (builder CAVE); the tab only exists after the story.
			b.visible = CaveStore.unlocked()
			b.size_flags_stretch_ratio = 0.7   # "Cave 3/9" is short: leave the longer tabs the room
			filled = CaveStore.filled_count()
			total = CaveStore.ROSTER.size()
		else:
			var rows := scrapbook_entries(sec)
			filled = rows.filter(func(r: Dictionary) -> bool: return bool(r["filled"])).size()
			total = rows.size()
			if sec == "neighbour":
				# See _neighbour_extra_ids: the page's "Other friends" group, counted in so the tab
				# can never show a smaller total than the page actually lists. Every extra is a kept
				# favourite by definition (that is the only way an npc_id lands in friend_ids()), so
				# it adds to `filled` too.
				var extra := _neighbour_extra_ids(rows).size()
				filled += extra
				total += extra
		b.text = "%s %d/%d" % [str(SCRAPBOOK_TITLES[sec]), filled, total]
		var on := sec == _scrap_section
		var style := UIStyle.make_pill_style(C_NAVY if on else C_CREAM)
		b.add_theme_stylebox_override("normal", style)
		b.add_theme_stylebox_override("hover", UIStyle.make_pill_style(C_NAVY if on else Color("#f6f7fb")))
		b.add_theme_color_override("font_color", C_CREAM if on else C_TEXT)
		b.add_theme_color_override("font_hover_color", C_CREAM if on else C_TEXT)
		# HUDJ (2026-09-28): `clip_text = true` (see _build_planet_panel) silently cut the last digit
		# off "Neighbours"/"Creatures"/"Cave" once their total reached two digits - the fixed
		# `custom_minimum_size(0, 50)` from build time left no floor for the text, and the pill
		# stylebox's own 24px-a-side content margin (UIStyle.make_pill_style) ate the rest of the
		# slack a long name or a two-digit total needed. Measured in probe captures (button rect vs.
		# the font's own get_string_size), not guessed: the tab's minimum width is set to EXACTLY what
		# its current text needs at the real margins, so an HBoxContainer with SIZE_EXPAND_FILL can
		# never compress it smaller (that only ever shrinks a child below its own minimum on genuine
		# overflow, which the whole row has room to avoid - see the comment on this loop's call site).
		var text_w := b.get_theme_font("font").get_string_size(
			b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		b.custom_minimum_size.x = text_w + style.content_margin_left + style.content_margin_right


## Rebuilds the open section: one group per planet (its host's name and how many of its pages are
## filled), then that planet's pages - every roster entry of the section, "???" until photographed.
func _refresh_planet_panel() -> void:
	if _planet_body == null:
		return
	for c in _planet_body.get_children():
		_planet_body.remove_child(c)
		c.queue_free()
	_planet_grids.clear()
	_refresh_scrap_tabs()
	if _scrap_section == "home":
		_refresh_home_section()
		return
	if _scrap_section == "cave":
		_refresh_cave_section()
		return
	var rows := scrapbook_entries(_scrap_section)
	var pid_now := ""
	var grid: GridContainer = null
	for r: Dictionary in rows:
		var pid := str(r["planet"])
		if pid != pid_now:
			pid_now = pid
			var mine := rows.filter(func(x: Dictionary) -> bool: return str(x["planet"]) == pid)
			var got := mine.filter(func(x: Dictionary) -> bool: return bool(x["filled"])).size()
			var host := _planet_host(pid)
			# The Tangle's heading names the WORLD, not Moss (JUNGLE_PLANET_SPEC.md 3: Moss hosts the
			# safari but is "not a neighbour" - "Moss's world" would wrongly read like a neighbour's).
			var heading := "The Tangle" if pid == "jungle" else (
				_npc_display_name(host) + "'s world" if host != "" else pid.capitalize() + "'s world")
			_planet_body.add_child(_planet_section_header("%s - %d of %d" % [heading, got, mine.size()]))
			grid = _planet_grid()
		grid.add_child(_planet_subject_row(str(r["key"])))
	# A Friends favourite no roster lists (an old save, a neighbour from a world without a manifest).
	# Uses _neighbour_extra_ids (shared with _refresh_scrap_tabs) so the tab's total can never
	# disagree with how many rows actually show up here (HUDJ, 2026-09-28).
	if _scrap_section == "neighbour":
		var extra := _neighbour_extra_ids(rows)
		if not extra.is_empty():
			_planet_body.add_child(_planet_section_header("Other friends"))
			var fgrid := _planet_grid()
			for npc_id: Variant in extra:
				fgrid.add_child(_friend_row(str(npc_id)))
	if _planet_body.get_child_count() == 0:
		_planet_body.add_child(_body_label("No %s pages yet." % str(SCRAPBOOK_TITLES[_scrap_section]).to_lower()))


# ---------------------------------------------------------------------------------- the cave (CAVE)
## Builder CAVE (docs/STORY_HOME_SPEC.md 9.3). Reads CaveStore (src/cave/) directly - the pages are
## CaveStore's, this is only their view: one header, then every page in roster order, "???" until a
## photo of it is kept (the same row as a planet's page, `_planet_thumb_rect`, tap to enlarge).
func _refresh_cave_section() -> void:
	_planet_body.add_child(_planet_section_header("The cave under your home - %d of %d" % [
		CaveStore.filled_count(), CaveStore.ROSTER.size()]))
	var grid := _planet_grid()
	for e: Dictionary in CaveStore.ROSTER:
		var rec := CaveStore.record_for(str(e["id"]))
		var row := HBoxContainer.new()
		row.name = "Page"
		row.add_theme_constant_override("separation", 12)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(_planet_thumb_rect(str(rec.get("thumb_b64", "")), str(rec.get("name", ""))))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(info)
		if rec.is_empty():
			info.add_child(_body_label("???"))
			info.add_child(_small_wrap("Not photographed yet."))
		else:
			info.add_child(_body_label(str(rec.get("name", "???"))))
			info.add_child(_small_wrap("%s - day %d, %s" % [str(rec.get("grade", "")), int(rec.get("day", 0)),
				SkyEvents.clock_text(float(rec.get("hour", 0.0)))]))
		grid.add_child(row)


# ---------------------------------------------------------------------------------- home album (HOMEALBUM)
## Builder HOMEALBUM (docs/STORY_HOME_SPEC.md 8.1). Reads HomeAlbumStore (src/home_album/) directly -
## this section owns none of that data, only the view of it and the bulk-clear controls. Row 1: the
## count and the two bulk actions, each behind its own confirm (`_confirm_popup`); then a grid of
## every photo, oldest first, each with its own "Throw away" (one at a time was already possible
## nowhere before this - both paths are new) and a Select box for the bulk ones.
func _refresh_home_section() -> void:
	var recs := HomeAlbumStore.list()
	# Selections for photos that got thrown away elsewhere (or an old save with fewer photos than
	# were once selected) never linger past a redraw.
	var kept_ids: Dictionary = {}
	for r: Dictionary in recs:
		kept_ids[str(r.get("id", ""))] = true
	for sel_id in _home_selection.keys().duplicate():
		if not kept_ids.has(str(sel_id)):
			_home_selection.erase(sel_id)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 12)
	_planet_body.add_child(head_row)
	head_row.add_child(_small("%d / %d photos" % [recs.size(), HomeAlbumStore.MAX_PHOTOS]))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(spacer)

	var sel_n := _home_selection.size()
	var del_btn := _mk_button("Delete selected (%d)" % sel_n, func():
		if _home_selection.is_empty():
			return
		var n := _home_selection.size()
		_confirm_popup("Throw away %d photo%s? This can't be undone." % [n, "" if n == 1 else "s"],
			"Throw away", _home_delete_selected))
	del_btn.disabled = sel_n == 0
	head_row.add_child(del_btn)

	var clear_btn := _mk_button("Clear album", func():
		if recs.is_empty():
			return
		_confirm_popup("Throw away all %d home photos? This can't be undone." % recs.size(),
			"Clear album", _home_clear_all))
	clear_btn.disabled = recs.is_empty()
	head_row.add_child(clear_btn)

	if recs.is_empty():
		_planet_body.add_child(_body_label("No home photos yet."))
		_planet_body.add_child(_small_wrap("Look for the Camera button on your own home planet - any time."))
		return

	var grid := _planet_grid()
	for rec: Dictionary in recs:
		grid.add_child(_home_photo_cell(rec))


func _home_photo_cell(rec: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "HomePhoto"
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var id := str(rec.get("id", ""))
	var b64 := str(rec.get("thumb_b64", ""))
	var thumb := _planet_thumb_rect(b64, "Home photo")
	row.add_child(thumb)
	# FILTERS (builder HOMECAM, docs/JUNGLE_PLANET_SPEC.md 6.1): the stored photo is never changed; its
	# look is drawn on top (HomeAlbumFilters), here and in the enlarged view. The thumb's own
	# tap-to-enlarge is re-pointed so the big view shows the same look.
	var fid := HomeAlbumStore.get_filter(rec)
	HomeAlbumFilters.apply_to(thumb, fid)
	for n in thumb.find_children("*", "Button", true, false):
		var tap := n as Button
		for c: Dictionary in tap.pressed.get_connections():
			tap.pressed.disconnect(c["callable"])
		tap.pressed.connect(func(): _home_show_enlarged(b64, fid))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	var when := "Day %d, %s" % [int(rec.get("day", 0)), SkyEvents.clock_text(float(rec.get("hour", 0.0)))]
	info.add_child(_small_wrap(when))

	var cb := CheckBox.new()
	cb.text = "Select"
	cb.focus_mode = Control.FOCUS_NONE
	cb.add_theme_font_override("font", UIStyle.ui_font())
	cb.add_theme_font_size_override("font_size", 17)
	cb.add_theme_color_override("font_color", C_TEXT)
	cb.button_pressed = _home_selection.has(id)
	cb.toggled.connect(func(on: bool): _home_toggle_select(id, on))
	info.add_child(cb)

	if not HomeAlbumFilters.owned().is_empty() or fid != "":
		var fb := _mk_button("Filter: %s" % HomeAlbumFilters.display_name(fid), func(): _home_cycle_filter(id, fid))
		fb.name = "HomeFilterButton"
		info.add_child(fb)

	info.add_child(_mk_button("Throw away", func():
		_confirm_popup("Throw away this photo?", "Throw away", func(): _home_delete_one(id))))
	return row


## One tap moves a photo to the next owned filter, then back to None (HomeAlbumFilters.next_after).
func _home_cycle_filter(id: String, current: String) -> void:
	HomeAlbumStore.set_filter(id, HomeAlbumFilters.next_after(current))
	_refresh_planet_panel()


func _home_show_enlarged(b64: String, fid: String) -> void:
	var title := "Home photo" if fid == "" else "Home photo - %s" % HomeAlbumFilters.display_name(fid)
	_show_enlarged(b64, title)
	if is_instance_valid(_enlarge_panel):
		HomeAlbumFilters.apply_to(_enlarge_panel, fid)


## SYNTHETIC - opens the enlarged view of home photo number `i` (oldest first) with its filter.
func debug_open_home_enlarge(i: int) -> bool:
	var recs := HomeAlbumStore.list()
	if i < 0 or i >= recs.size():
		return false
	_home_show_enlarged(str(recs[i].get("thumb_b64", "")), HomeAlbumStore.get_filter(recs[i]))
	return _enlarge_overlay != null


## SYNTHETIC - the tap handler of photo `i`'s "Filter" button, without a finger.
func debug_home_cycle_filter(i: int) -> void:
	var recs := HomeAlbumStore.list()
	if i >= 0 and i < recs.size():
		_home_cycle_filter(str(recs[i].get("id", "")), HomeAlbumStore.get_filter(recs[i]))


func _home_toggle_select(id: String, on: bool) -> void:
	if on:
		_home_selection[id] = true
	else:
		_home_selection.erase(id)
	_refresh_planet_panel()


func _home_delete_one(id: String) -> void:
	if HomeAlbumStore.delete_photo(id):
		_home_selection.erase(id)
		EventBus.toast_requested.emit("Threw away a home photo.", "check")
	_refresh_planet_panel()


func _home_delete_selected() -> void:
	var ids := _home_selection.keys()
	var n := HomeAlbumStore.delete_many(ids)
	_home_selection.clear()
	EventBus.toast_requested.emit("Threw away %d photo%s." % [n, "" if n == 1 else "s"], "check")
	_refresh_planet_panel()


func _home_clear_all() -> void:
	var n := HomeAlbumStore.clear_all()
	_home_selection.clear()
	EventBus.toast_requested.emit("Cleared the home album (%d photo%s)." % [n, "" if n == 1 else "s"], "check")
	_refresh_planet_panel()


## A small yes/cancel popup above everything else in this autoload's canvas (`_root`), for the two
## bulk actions above and the per-photo "Throw away". Freed on either answer.
func _confirm_popup(text: String, yes_text: String, on_yes: Callable) -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "HomeConfirmBackdrop"
	backdrop.color = Color(0.05, 0.06, 0.12, 0.55)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_CREAM, 22))
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	backdrop.add_child(panel)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(380, 0)
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)
	col.add_child(_body_label(text))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	row.add_child(_mk_button("Cancel", func(): backdrop.queue_free()))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_mk_button(yes_text, func():
		backdrop.queue_free()
		on_yes.call()))


func _planet_grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = _planet_columns()
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_planet_body.add_child(g)
	_planet_grids.append(g)
	return g


func _planet_section_header(text: String) -> Label:
	var l := _body_label(text)
	l.add_theme_font_size_override("font_size", 24)
	return l


## One page. BLANK AND TITLED "???" until a photo of it is kept (spec 15.5; the secrets rule of 6.1: a
## name is never shown from the roster).
func _planet_subject_row(key: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "Page"
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rec := _scrap_record(key)
	var b64 := str(rec.get("thumb_b64", "")) if not rec.is_empty() else ""
	var thumb := _planet_thumb_rect(b64, str(rec.get("name", "")) if not rec.is_empty() else "")
	row.add_child(thumb)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	if rec.is_empty():
		info.add_child(_body_label("???"))
		info.add_child(_small_wrap("Not photographed yet."))
	else:
		var cat := scrap_category(key)
		info.add_child(_body_label(str(rec.get("name", "???"))))
		var when := "%s - day %d, %s" % [str(rec.get("grade", "")), int(rec.get("day", 0)),
			SkyEvents.clock_text(float(rec.get("hour", 0.0)))]
		if cat == "neighbour" and rec.has("npc_id"):
			when = "Favourite photo - " + when
		info.add_child(_small_wrap(when))
		if cat == "bonus":
			var col := _small_wrap("A collector's page!")
			col.add_theme_color_override("font_color", Color("#8a5a14"))
			info.add_child(col)
	return row


func _friend_row(npc_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rec := friend_record_for(npc_id)
	row.add_child(_planet_thumb_rect(str(rec.get("thumb_b64", "")), _npc_display_name(npc_id)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	info.add_child(_body_label(_npc_display_name(npc_id)))
	info.add_child(_small_wrap("Favourite photo - %s" % str(rec.get("grade", ""))))
	return row


func _small_wrap(t: String) -> Label:
	var l := _small(t)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	return l


## A thumbnail slot sized from the panel (`_planet_thumb_w`), its height from the photo's own
## aspect: the decoded WebP if there is one, else a plain "?" card (SECRETS - no silhouette art for a
## planet subject: the flight's doodles are keyed to SafariCatalog's shape words, which a planet
## subject has none of). `title` names the enlarge dialog; "" when there is no photo to enlarge.
func _planet_thumb_rect(b64: String, title: String = "") -> Control:
	var box := PanelContainer.new()
	box.name = "PlanetThumb"
	box.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_NAVY, 12, C_NAVY, 0, 0, 0.0))
	var w := _planet_thumb_w()
	var img := _decode_planet_thumb(b64)
	var aspect := PLANET_ROW_ASPECT
	if img != null:
		aspect = float(img.get_width()) / float(maxi(img.get_height(), 1))
	box.custom_minimum_size = Vector2(w, w / aspect)
	if img != null:
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tr)
		# TAP TO ENLARGE: the same stored photo, as big as the screen allows.
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(func(): _show_enlarged(b64, title))
		box.add_child(btn)
	else:
		var q := Label.new()
		q.text = "?"
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_font_override("font", UIStyle.ui_font())
		q.add_theme_font_size_override("font_size", 40)
		q.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
		box.add_child(q)
	return box


## THE ENLARGE DIALOG (critic round 2). A second overlay, sibling to `_panel`/`_planet_panel` under
## `_root` so it draws above the Planet Log panel that opened it; only ever one at a time
## (`_close_enlarged` first, same as `_planet_thumb_rect`'s box replaced each refresh).
var _enlarge_overlay: Control = null
var _enlarge_panel: Control = null


func _show_enlarged(b64: String, title: String) -> void:
	var img := _decode_planet_thumb(b64)
	if img == null:
		return
	_close_enlarged()
	var overlay := Control.new()
	overlay.name = "PlanetPhotoEnlarge"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(overlay)
	_enlarge_overlay = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_CREAM, 20))
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# GROWS BOTH WAYS FROM CENTRE (bug found in this round's own self-test, not the critic's four -
	# see the report): PRESET_CENTER sizes the offsets from whatever the panel's size is AT THAT
	# CALL, which is (0,0) before its children (title/image/button) are added, and the default grow
	# direction (END) then only grows right and down as content is added - so the dialog measured
	# correctly (fits the screen) but rendered pinned to the lower-right of centre, not centred. Same
	# fix `_panel`/`_planet_panel` already use.
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.add_child(panel)
	_enlarge_panel = panel
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)
	if title != "":
		col.add_child(_body_label(title))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	# SIZED TO FIT THE SCREEN, both ways: a phone is 720 logical px tall (tooling traps, "1560x720
	# phone"), so capping only the width is how a card overflows the bottom (the safari review
	# card's own bug, this round). Whichever dimension binds first sets the other from the image's
	# own aspect ratio, so nothing is ever cropped or stretched.
	var vp := get_viewport().get_visible_rect().size
	var safe := MobileUI.safe_area()
	var usable := vp - Vector2(safe.x + safe.z, safe.y + safe.w)
	var ratio: float = float(img.get_width()) / float(maxi(img.get_height(), 1))
	var max_w: float = usable.x * PLANET_ENLARGE_SHARE.x
	var max_h: float = usable.y * PLANET_ENLARGE_SHARE.y
	var w := max_w
	var h := w / ratio
	if h > max_h:
		h = max_h
		w = h * ratio
	tr.custom_minimum_size = Vector2(w, h)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	col.add_child(tr)
	var close_btn := _mk_button("Close", _close_enlarged)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(close_btn)


func _close_enlarged() -> void:
	if is_instance_valid(_enlarge_overlay):
		_enlarge_overlay.queue_free()
	_enlarge_overlay = null
	_enlarge_panel = null


# ---------------------------------------------------------------------------------- debug hooks
## SYNTHETIC - lets a probe drive the whole keep-new-or-old flow without a real safari. Never used
## by the game itself.
func debug_planet_offer(photo: Dictionary, planet_id: String) -> Dictionary:
	return planet_offer_photo(photo, planet_id)


func debug_planet_woke(planet_id: String) -> Array:
	return planet_page_ids(planet_id)


func debug_planet_button_visible() -> bool:
	return _planet_btn != null and _planet_btn.visible


func debug_open_planet_panel() -> void:
	_open_planet_panel()


func debug_planet_panel_rows() -> int:
	return _planet_body.get_child_count() if _planet_body != null else 0


## SYNTHETIC - what the Journal pill's own callback does (`_toggle`), without a tap.
func debug_toggle() -> void:
	_toggle()


## SYNTHETIC - the scrapbook's tab callback, without a tap.
func debug_show_scrap_section(section: String) -> void:
	_show_scrap_section(section)


## Which panel is up: {"sky": the sky pages, "scrapbook": the scrapbook, "sky_btn": its "Sky pages"
## button, "tabs": each tab's text}.
func debug_panels() -> Dictionary:
	var tabs := {}
	for sec: String in _scrap_tabs:
		tabs[sec] = (_scrap_tabs[sec] as Button).text
	return {"sky": _panel != null and _panel.visible,
		"scrapbook": _planet_panel != null and _planet_panel.visible,
		"sky_btn": _scrap_sky_btn != null and _scrap_sky_btn.visible, "tabs": tabs}


## SYNTHETIC - the exact byte count of the thumbnail a given Image would be saved as, so a probe
## can re-measure "how big is a kept planet photo" instead of trusting a number in a comment.
func debug_planet_thumb_bytes(img: Image) -> int:
	var b64 := _encode_planet_thumb(img)
	return Marshalls.base64_to_raw(b64).size() if b64 != "" else 0


## SYNTHETIC - the row box's own logical size, so a probe can compute the actual displayed photo
## rect (STRETCH_KEEP_ASPECT_CENTERED fitted inside this) instead of assuming the box is square.
func debug_planet_row_thumb_size() -> Vector2:
	var w := _planet_thumb_w() if _planet_panel != null else PLANET_ROW_THUMB_MIN_W
	return Vector2(w, w / PLANET_ROW_ASPECT)


## SYNTHETIC - opens the tap-to-enlarge dialog for a subject's kept photo without a real tap, same
## shape as `_planet_thumb_rect`'s own button callback. false when the subject has no kept photo.
func debug_open_enlarge(key: String) -> bool:
	var rec := planet_record_for(key)
	if rec.is_empty():
		return false
	_show_enlarged(str(rec.get("thumb_b64", "")), str(rec.get("name", "")))
	return _enlarge_overlay != null


## SYNTHETIC - same, for a Friends favourite photo.
func debug_open_friend_enlarge(npc_id: String) -> bool:
	var rec := friend_record_for(npc_id)
	if rec.is_empty():
		return false
	_show_enlarged(str(rec.get("thumb_b64", "")), _npc_display_name(npc_id))
	return _enlarge_overlay != null


## SYNTHETIC - is the enlarge dialog open right now, and at what size, so a probe can check it fits
## the screen without a screenshot.
func debug_enlarge_open() -> bool:
	return is_instance_valid(_enlarge_overlay)


func debug_enlarge_size() -> Vector2:
	return _enlarge_panel.size if is_instance_valid(_enlarge_panel) else Vector2.ZERO


func debug_close_enlarge() -> void:
	_close_enlarged()


# ------------------------------------------------------------------ the page art
## Either the real best-shot image, or - for an untaken sight - a tinted silhouette, so an empty
## page looks like SOMETHING is waiting there. The doodles are deliberately simple (STYLE_GUIDE:
## rough models are fine, the sky is not), and they follow the CATALOG's shape word now, so a
## creature gets a school of dots and a wreck gets a hull instead of every one of them getting
## aurora curtains.
class PageArt extends Control:
	var filled := false
	var kind := 0
	var draw_id := ""
	var tint_a := Color.WHITE
	var tint_b := Color.WHITE
	var image: Image
	var flashing := false
	var _tex: ImageTexture

	const A_NAVY := Color("#1b1f33")
	const A_GOOD := Color("#6fc47f")

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, A_NAVY, true)
		if filled and image != null:
			_tex = ImageTexture.create_from_image(image)
			draw_texture_rect(_tex, r, false)
			if flashing:
				draw_rect(r, Color(A_GOOD.r, A_GOOD.g, A_GOOD.b, 0.16), true)
			draw_rect(r, Color(1, 1, 1, 0.22), false, 3.0)
			return
		# --- empty page (or a reloaded one whose picture is gone): silhouette
		var c := r.get_center()
		var rad: float = minf(size.x, size.y) * 0.5
		draw_circle(c, rad * 0.92, Color(tint_a.r, tint_a.g, tint_a.b, 0.14))
		draw_arc(c, rad * 0.92, 0.0, TAU, 48, Color(tint_b.r, tint_b.g, tint_b.b, 0.35), 2.0, true)
		var ca := Color(tint_a.r, tint_a.g, tint_a.b, 0.32)
		var cb := Color(tint_b.r, tint_b.g, tint_b.b, 0.55)
		match draw_id:
			"comet":
				var head := c + Vector2(-rad * 0.28, -rad * 0.10)
				draw_circle(head, 8.0, cb)
				draw_line(head, head + Vector2(rad * 0.75, rad * 0.42), ca, 5.0, true)
				draw_line(head, head + Vector2(rad * 0.62, rad * 0.20), ca, 3.0, true)
			"pod":
				for i in 5:
					var a: float = TAU * float(i) / 5.0 + 0.4
					draw_circle(c + Vector2(cos(a), sin(a) * 0.55) * rad * 0.48,
						9.0 - float(i), cb)
			"ice":
				for i in 4:
					var a2: float = TAU * float(i) / 4.0 + 0.8
					var p := c + Vector2(cos(a2), sin(a2)) * rad * 0.46
					draw_polyline(PackedVector2Array([p + Vector2(-11, 6), p + Vector2(0, -13),
						p + Vector2(12, 4), p + Vector2(3, 12), p + Vector2(-11, 6)]),
						cb, 2.0, true)
			"derelict":
				var w: float = rad * 0.62
				draw_line(c + Vector2(-w, rad * 0.10), c + Vector2(w, -rad * 0.06), ca, 12.0, true)
				draw_line(c + Vector2(-w * 0.4, rad * 0.10), c + Vector2(-w * 0.2, -rad * 0.42),
					cb, 3.0, true)
			"moonrim":
				draw_arc(c + Vector2(0, rad * 0.18), rad * 0.62, PI, TAU, 40, cb, 4.0, true)
			_:
				# limb, and anything else: soft vertical bands, the old aurora doodle
				for i in 4:
					var x: float = r.position.x + r.size.x * (0.24 + 0.17 * float(i))
					var pl := PackedVector2Array()
					for j in 9:
						var yy: float = r.position.y + r.size.y * float(j) / 8.0
						pl.append(Vector2(x + sin(yy * 0.05 + float(i) * 1.7) * 14.0, yy))
					draw_polyline(pl, ca, 3.0, true)
		var font: Font = UIStyle.ui_font()
		draw_string(font, c - Vector2(9, -8), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 30,
			Color(1, 1, 1, 0.30))
		draw_rect(r, Color(1, 1, 1, 0.14), false, 2.0)
