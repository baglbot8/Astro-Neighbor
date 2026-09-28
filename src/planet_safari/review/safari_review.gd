class_name SafariReview
extends RefCounted
## THE REVIEW (docs/PLANET_SAFARI_SPEC.md 5.4, 5.6, 6, 8; builder P5, rebuilt by P5b "Q5" 2026-09-24).
##
## THE SEAM planet_safari.gd calls: `load(REVIEW_SCRIPT).call("present", world, session)`, awaited.
##
## WHAT IT SHOWS, one photo at a time (session.photos, in the order taken - three shots of one
## nut-crab are three cards, because "keep new or old" compares against whatever the JOURNAL holds,
## which can change between one card and the next):
##   * the picture, BIG (the left of the card), its numbers as bars (right) - Centred, Size, Facing
##     (11.1, only when the photo's scores carry one - a subject with no "front" never gets the bar),
##     Focus, Rarity boost - what it is worth, and one line in the host's own voice (never about the
##     player's aim - VOICE_LINES)
##   * the moment, as a caption built from the world's own phrase: "Nut-crab, came out to see you."
##     Every phrase in worlds/bolt.gd is a finished fragment ("mid-spout!", "riding a gear"), so the
##     caption never glues it into a sentence template (round 2's "mid-mid-spout!" came from that)
##   * KEEP NEW OR OLD (5.6): when the journal already holds a photo of the subject, the card becomes
##     the two photos SIDE BY SIDE across its whole width, the same size, each labelled with its grade
##     and with its own button under it; the info column comes back once the choice is made
##   * THE REVEAL, OPTION 2 (11.3, docs/PLANET_SAFARI_SPEC.md): the choice above stays BLIND - only the
##     coarse grade word is on screen, never the numeric bars, so the player has to look at the photo
##     itself. The instant a choice commits, `_reveal_scores` shows the SAME two photos again with
##     every bar now visible (Facing included when the photo has one, 11.1). If the one just kept
##     scored lower in stardust than the one let go, one line offers a one-tap swap BACK IN EITHER
##     DIRECTION ("Your old one scored higher - swap back?" / "Your new one scored higher..."); tapping
##     it replays the persistence call the other choice would have made
##     (`SkyJournal.planet_keep_new` / the new `planet_restore_record`), so the journal ends up exactly
##     as if that had been the original pick - nothing extra to keep in sync on a reload. The Friends
##     favourite (below) gets the same reveal but never the nudge - 5.6 calls it "a pure choice of
##     taste".
##   * a "neighbour" subject (photo.raw.kind) is also offered to the Friends page, as a second
##     question on the same card once the first is answered
## Then a summary card (photos taken, how many things you missed - never their names, 6.1 - and the
## stardust the photos pay) and Done.
##
## THE LAYOUT RULE (8.1 re-diagnosis). Round 2's card lived in a ScrollContainer whose child never
## expanded sideways (700 px of content in a 1363 px view), so everything sat in the left half and
## the photos were shrunk to 260 px to fit. Now every size is DERIVED from the card's own rect, not
## tuned: the info column takes a fixed share of the width, the photo takes the rest, and after the
## first layout pass `_fit_pictures` measures how much the card's content overflows its box and
## takes exactly that many pixels off the picture height (an inversion, no free constant). The info
## column never holds a picture, so its height does not depend on the fit; a ScrollContainer stays
## round the card only as the backstop for a line nobody has written yet.
##
## 8.2 RE-DIAGNOSIS - the same bug found a new place. `_score_col` (the reveal, 11.3) stacked its
## 5-6 bar rows ONE AT A TIME under the picture and left the column at its own SHRINK width, so
## `_fit_pictures`'s height fit had to cut the picture down to fit the whole stack, and the two
## columns together never reached even half the card - the right 45-55% sat empty. Two changes,
## each fixing one half of it: the column is now EXPAND_FILL (as 8.1's info column already was), so
## the row's two halves fill the card width; and the bars wrap TWO AT A TIME in a GridContainer
## instead of one under another, roughly halving the height they add, so the picture keeps the same
## full half-card width the blind choice already gives it (`_pic_w_cap` in `_reveal_scores`) rather
## than giving up width to sit beside them - bars beside the picture was tried first and measured to
## fail: a Facing bar's row can only shrink so far before its label clips, so on a narrower phone
## (`--safe-area=108,0,108,38`) the picture dropped to 0.54x the blind one, short of the 0.6x gate.
##
## THE SCRAPBOOK (15.5). A photo's scrapbook category rides in `photo.raw.category` (SafariPhotoScorer,
## SafariWorld.CATEGORY). A "bonus" subject pays nothing: its card, and its column in the reveal, say
## "A collector's page!" where a price would be (`worth_text`), and the summary counts collector's pages
## apart from the stardust. A "neighbour" category is a neighbour photo exactly like a "neighbour" kind
## (the Friends question). The summary's "N things woke up that you never saw" counts only what the
## density band counts: sights (always there) and bonus subjects (hidden secrets) are left out of it
## (`missed_count`), so the end never hints at a collector's page.
##
## WHO A PHOTO IS NAMED AFTER (17.1 rule 6). `SafariPhotoScorer.score_frame` already picks `best` by
## CLASS first (a counted subject beats a sight, a sight beats a bonus page) and grade/price only inside
## one class (`SafariPhotoScorer.class_rank`) - this file never re-decides it. Pay comes from the named
## subject only: `SafariReview.session_total` sums `photo.price` (the NAMED subject's price) over
## `session.photos`, never anything in a photo's `others`.
##
## SECONDARY PAGES (17.1 rule 6, `_file_secondary_pages`). Every subject in `photo.others` that is a
## "sight" or a "bonus" already PASSED THE SCORER'S OWN VISIBILITY TEST to be in `others` at all (in
## front of the lens, some of its disc inside the frame, a sight ray reaching it - `score_subject`'s own
## gate, the same one that puts a subject in the photo in the first place): it is filed as ITS OWN
## scrapbook page from the SAME image, no second player choice - the card has room for one line per page,
## not a second blind-reveal screen. WHAT "the scrapbook's keep-new-or-old rule" MEANS HERE (the spec asks
## for it, not a UI, for a page that is never shown to the player to choose): the SAME comparison the
## reveal's swap nudge uses (`SafariReview.is_better` - higher grade wins, price only breaks a tie) decides
## automatically, so a weak incidental glimpse of something you already have a good page for never
## overwrites it, and a first sighting - or a better one - is filed at once. The card shows one line per
## sight or bonus subject the photo also caught, whether or not it changed the kept page - "Also: <name>
## - a collector's page!" for a bonus item, "Also: <name>" for a sight (`_file_secondary_pages`).
##
## THE BEST SESSION TOTAL (15.2). When the review pays, SkyJournal.planet_pay_settle also raises
## GameState.flags["planet_safari_best_total"][<planet>] to this session's total if it is the best yet -
## the one shared flag the story's "one safari worth N stardust" step reads. Written in the same frame as
## the payment, so a reload mid-review (paid on load) writes it too, and a session is paid - and written
## - once.
##
## PAYMENT (8.2 "Photos pay"). The session's total is written into the save as PENDING when the
## review opens (SkyJournal.planet_pay_begin), and added to GameState.stardust in the same frame the
## pending entry is erased (planet_pay_settle) when the review closes. Any save snapshot therefore
## holds either "pending, not yet paid" or "paid, not pending", never both - a reload mid-review pays
## the pending entry on load (SkyJournal._on_game_loaded), exactly once.

const C_TEXT := Color("#2c2f42")
const C_SOFT := Color("#6d7288")
const C_NAVY := Color("#1b1f33")
const C_GOOD := Color("#3f8f52")
const C_MOMENT := Color("#8a5a14")
const C_BAR_BG := Color("#d5d8e4")
const C_BAR_CENTRED := Color("#6fb8c4")
const C_BAR_SIZE := Color("#e0a83a")
const C_BAR_FOCUS := Color("#e8646f")
const C_BAR_RARITY := Color("#8a6fc4")
const C_BAR_FACING := Color("#4f9e6e")

## The info column's share of the card's inner width, and its floor/ceiling in logical px. The floor
## is what a "Rarity boost 10/10" label plus a readable bar needs at phone type size.
const INFO_SHARE := 0.34
const INFO_MIN_W := 380.0
const INFO_MAX_W := 520.0
## Gap between the picture area and the info column, and between the two compared photos.
const GAP := 22.0
## Space left between the card and the screen edge (inside the safe area).
const EDGE := 14.0

## VOICE, IN THE HOST'S OWN WORDS (spec 5.6). Bolt counts things and speaks like a maintenance log
## (planet_safari.gd). Dry about the SUBJECT, warm to the player, never about the player's aim: a
## soft photo is "soft", not "bad", and it "still counts". `%s` is the subject's name, always right
## after "Logged:"/"On file:" so a name with "The" in front ("The Sky Whale") or a plural
## ("Spark-moths") reads correctly in every line. The moment is NOT put into these lines - it is the
## caption's job (see the header).
const VOICE_LINES := {
	"bolt": {
		"no_subject": [
			"Logged: the yard itself. Nothing woke in this frame, but it's a fine view.",
			"Entry: scenery. Every archive needs a few of these.",
		],
		"Smudge": [
			"Logged: %s. A soft one, but it's on the record.",
			"On file: %s. Faint entry - it still counts.",
		],
		"Fair": [
			"Logged: %s. Clear enough for the archive.",
			"On file: %s. A good, honest entry.",
		],
		"Fine": [
			"Logged: %s. Crisp. The yard approves.",
			"On file: %s. That one goes in the good drawer.",
		],
		"Gallery": [
			"Logged: %s. Flawless. Filing it under \"keep forever\".",
			"On file: %s. Best plate this yard has seen.",
		],
		"moment": " Good timing, too.",
	},
	"_default": {
		"no_subject": ["Just the view in this one. It's a nice view."],
		"Smudge": ["A soft shot of %s, but it's on file."],
		"Fair": ["A clear shot of %s."],
		"Fine": ["A fine shot of %s."],
		"Gallery": ["A gallery shot of %s!"],
		"moment": " Good timing, too.",
	},
}
## The neighbour's own line about THEIR OWN photo - warm whatever the grade.
const FRIEND_LINES := {
	"low": "That's me, alright. Good to have one on file.",
	"mid": "Good likeness. You can keep that one.",
	"high": "Now THAT's a keeper. Frame it.",
}


static func present(host: Node, session: Dictionary) -> void:
	var view := _View.new()
	host.add_child(view)
	await view.run(session)
	if is_instance_valid(view):
		view.queue_free()


## The host from the planet's MANIFEST (spec 12.5; PlanetSafari.manifest, which falls back to the old
## PLANETS table for a world that has none yet).
static func _host_of(planet_id: String) -> String:
	return str(PlanetSafari.manifest(planet_id).get("host", ""))


## The host's lines about a photo: the manifest's optional "review" block (same shape as VOICE_LINES'
## entries; any key it leaves out comes from the host's entry here, then "_default"), else VOICE_LINES.
static func _voice_for(planet_id: String) -> Dictionary:
	var base: Dictionary = (VOICE_LINES.get(_host_of(planet_id), VOICE_LINES["_default"]) as Dictionary).duplicate()
	var own: Variant = PlanetSafari.manifest(planet_id).get("review", {})
	if own is Dictionary:
		for k: Variant in (own as Dictionary):
			base[k] = (own as Dictionary)[k]
	return base


static func _pick(lines: Variant, seed_i: int) -> String:
	if not (lines is Array) or (lines as Array).is_empty():
		return ""
	var arr: Array = lines
	return str(arr[seed_i % arr.size()])


## Public: the host's line for one photo (a "neighbour" photo uses `friend_line` instead).
static func line_for(photo: Dictionary, planet_id: String) -> String:
	var voice := _voice_for(planet_id)
	var idx := int(photo.get("index", 0))
	if str(photo.get("subject_key", "")) == "":
		return _pick(voice.get("no_subject", []), idx)
	var grade := str(photo.get("grade", "Smudge"))
	var line := _pick(voice.get(grade, voice.get("Smudge", [])), idx)
	line = line.replace("%s", str(photo.get("subject_name", "")))
	if str(photo.get("moment_line", "")) != "":
		line += str(voice.get("moment", ""))
	return line


## Public: the caption under the name. "" when the photo caught no moment. The phrase is appended
## as written; a full stop is added only when the phrase has no end mark of its own.
static func moment_caption(photo: Dictionary) -> String:
	var m := str(photo.get("moment_line", "")).strip_edges()
	if m == "":
		return ""
	var subject := str(photo.get("subject_name", ""))
	var text := ("%s, %s" % [subject, m]) if subject != "" else m.capitalize()
	if not (text.ends_with("!") or text.ends_with(".") or text.ends_with("?")):
		text += "."
	return text


## Public: a subject's name for the middle of a sentence - "The Sky Whale" becomes "the Sky Whale"
## ("a photo of the Sky Whale"); every other name is kept as written.
static func mid(subject_name: String) -> String:
	return ("the " + subject_name.substr(4)) if subject_name.begins_with("The ") else subject_name


## Public: the host npc id a "neighbour"-kind photo on `planet_id` belongs to ("" if none).
static func host_of(planet_id: String) -> String:
	return _host_of(planet_id)


static func friend_line(grade: String) -> String:
	match grade:
		"Gallery", "Fine":
			return FRIEND_LINES["high"]
		"Fair":
			return FRIEND_LINES["mid"]
		_:
			return FRIEND_LINES["low"]


## Public: the scrapbook category of a photo (spec 15.5): `photo.raw.category` when the scorer put one
## there, else from the subject key's roster entry (SafariWorld.key_category); "" for a photo of nothing.
static func category_of(photo: Dictionary) -> String:
	var key := str(photo.get("subject_key", ""))
	if key == "":
		return ""
	var c := str((photo.get("raw", {}) as Dictionary).get("category", ""))
	if SafariWorld.CATEGORIES.has(c):
		return c
	return SafariWorld.key_category(key)


## Public: true for a collector's page - a photo whose category pays nothing ("bonus").
static func is_collectors(photo: Dictionary) -> bool:
	var c := category_of(photo)
	return c != "" and not SafariWorld.category_pays(c)


## Public: what a card says where the price goes - "Fine - worth 12 stardust", or for a collector's page
## (spec 15.5) "Fine - A collector's page!".
static func worth_text(grade: String, price: int, collectors: bool) -> String:
	if collectors:
		return "%s - A collector's page!" % grade
	return "%s - worth %d stardust" % [grade, price]


## Public: how many subjects woke this session that no photo named, leaving out sights and bonus subjects
## (spec 15.5: they do not count toward the density band, and the end never hints at a secret). Falls
## back to the session's own `missed_count` when it carries no `woke` list.
static func missed_count(session: Dictionary) -> int:
	if not session.has("woke"):
		return int(session.get("missed_count", 0))
	var named: Dictionary = {}
	for p: Variant in session.get("photos", []):
		if p is Dictionary:
			named[str((p as Dictionary).get("subject_key", ""))] = true
	var live: PlanetSafari = PlanetSafari.current if is_instance_valid(PlanetSafari.current) else null
	var n := 0
	for raw: Variant in session.get("woke", []):
		var k := str(raw)
		if k == "" or named.has(k):
			continue
		var cat := SafariWorld.key_category(k, live.subject(k) if live != null else {})
		if SafariWorld.UNCOUNTED_CATEGORIES.has(cat):
			continue
		n += 1
	return n


## Public: the collector's pages in this session (photos of "bonus" subjects).
static func collectors_count(session: Dictionary) -> int:
	var n := 0
	for p: Variant in session.get("photos", []):
		if p is Dictionary and is_collectors(p as Dictionary):
			n += 1
	return n


## Public (17.1 rule 6): a "photo"-shaped Dictionary for a SECONDARY subject `e` (one entry of
## `photo.others`, always a "sight" or "bonus" category), built from the same captured image, so
## SkyJournal's `planet_offer_photo` / `planet_keep_new` can file it exactly as they would the named
## subject's own photo. `e` already carries every field `SafariScoring.planet_photo` puts on a scored
## subject (grade, grade_idx, price, rarity10, craft) - see SafariPhotoScorer.score_subject.
static func secondary_photo(photo: Dictionary, e: Dictionary) -> Dictionary:
	var scores := {
		"centred": int(round(float(e.get("centred", 0.0)))),
		"size": int(round(float(e.get("size", 0.0)))),
		"focus": int(round(float(e.get("focus", 0.0)))),
		"rarity": int(e.get("rarity10", 0)),
	}
	if bool(e.get("has_facing", false)):
		scores["facing"] = int(round(float(e.get("facing", 0.0))))
	return {
		"image": photo.get("image"),
		"subject_key": str(e.get("key", "")),
		"subject_name": str(e.get("name", "")),
		"rarity": int(e.get("rarity", 0)),
		"scores": scores,
		"has_facing": bool(e.get("has_facing", false)),
		"raw": {"kind": str(e.get("kind", "")), "category": str(e.get("category", ""))},
		"grade": str(e.get("grade", SafariScoring.GRADES[0])),
		"grade_idx": int(e.get("grade_idx", 0)),
		"price": int(e.get("price", 0)),
		"moment_line": str(e.get("moment_line", "")),
	}


## Public: what the whole session pays - the sum of every photo's price.
static func session_total(session: Dictionary) -> int:
	var total := 0
	for p: Variant in session.get("photos", []):
		if p is Dictionary:
			total += maxi(0, int((p as Dictionary).get("price", 0)))
	return total


# ================================================================================================
## A fresh one per keep-new-or-old choice. GDScript lambdas capture locals BY VALUE, so a bool
## flipped inside a button's lambda never reaches the awaiting loop; a RefCounted's signal does.
## True when photo A beats photo B: the higher grade index (SafariScoring.GRADES) wins; on the same
## grade the higher price wins; equal on both is NOT better (no nudge between equals). The reveal's
## swap-back nudge uses it; SafariPhotoScorer.score_frame picks the best subject by the same order.
static func is_better(a_grade_idx: int, a_price: int, b_grade_idx: int, b_price: int) -> bool:
	if a_grade_idx != b_grade_idx:
		return a_grade_idx > b_grade_idx
	return a_price > b_price


class _Choice extends RefCounted:
	signal made(is_new: bool)


## A fresh one per reveal (11.3): "continue" or "swap". Same RefCounted-signal reason as `_Choice`.
class _Pick extends RefCounted:
	signal chosen(action: String)


class _View extends CanvasLayer:
	var _journal: SkyJournal
	var _root: Control
	var _card_host: Control
	var _session: Dictionary = {}
	var _pay_id := ""
	var _paid := false
	## The current card's pieces the fit pass needs.
	var _scroll: ScrollContainer
	var _col: VBoxContainer
	var _pics: Array = []          # TextureRect/placeholder boxes of the current picture area
	var _pic_aspect: Array = []    # width/height of each
	var _pic_w_cap := 0.0          # the width budget of ONE picture right now
	var _panel: PanelContainer

	func run(session: Dictionary) -> void:
		layer = 60  # above SafariLayer's chrome and SkyJournal's 42
		name = "SafariReview"
		process_mode = Node.PROCESS_MODE_ALWAYS
		_session = session
		var planet_id := str(session.get("planet_id", ""))
		_journal = get_tree().root.get_node_or_null("/root/SkyJournal") as SkyJournal
		if _journal == null:
			push_warning("SafariReview: no SkyJournal in the tree - photos are shown but nothing is kept.")
		else:
			# SECRETS (6.1, 8.2): every subject that woke this session joins the planet's page, and
			# every subject the live world REGISTERED (woken or not) teaches the journal's roster.
			_journal.planet_mark_woke(planet_id, session.get("woke", []))
			_journal.planet_learn_roster(planet_id, _live_subject_keys())
			_pay_id = _journal.planet_pay_begin(planet_id, SafariReview.session_total(session))
		_build_shell()
		EventBus.ui_modal_opened.emit("planet_safari_review")
		var photos: Array = session.get("photos", [])
		for i in photos.size():
			await _show_photo(photos[i] as Dictionary, i, photos.size())
		await _show_summary()
		_settle_pay()
		_give_gloop_print()
		EventBus.ui_modal_closed.emit("planet_safari_review")

	## GLOOP'S HOOK (STORY_HOME_SPEC ruling 13, 5.8; owned by the UIG builder - the rest of this file is
	## not). The one best photo of the safari (highest PrintBag.pay_for) becomes a print in the satchel;
	## the photo also stays in the scrapbook via the journal calls above, so it is a COPY, never a move.
	## Never a bonus/collector's page (is_collectors), never an empty frame (no subject_key) - a
	## bonus-only or empty safari gives no print at all.
	func _give_gloop_print() -> void:
		var planet_id := str(_session.get("planet_id", ""))
		var is_night := bool(_session.get("is_night", false))
		var best: Dictionary = {}
		var best_pay := -1
		for raw: Variant in _session.get("photos", []):
			if not (raw is Dictionary):
				continue
			var photo := raw as Dictionary
			if str(photo.get("subject_key", "")) == "" or SafariReview.is_collectors(photo):
				continue
			var pay := PrintBag.pay_for(PrintBag.from_planet_photo(photo, planet_id, is_night))
			if pay > best_pay:
				best_pay = pay
				best = photo
		if best.is_empty():
			return
		PrintBag.add(PrintBag.from_planet_photo(best, planet_id, is_night))
		EventBus.toast_requested.emit("A copy for Gloop's table.", "star")

	## Torn down before Done (a scene change mid-review): pay now rather than leave the pending
	## entry waiting for the next load. Settling is idempotent, so this can never pay twice.
	func _exit_tree() -> void:
		_settle_pay()

	func _settle_pay() -> void:
		if _paid:
			return
		_paid = true
		var total := SafariReview.session_total(_session)
		if _journal != null and is_instance_valid(_journal):
			var paid := _journal.planet_pay_settle(_pay_id)
			if paid > 0:
				EventBus.toast_requested.emit("+%d stardust for your safari photos" % paid, "star")
		elif total > 0:
			GameState.add_stardust(total)
			SkyJournal.note_best_total(str(_session.get("planet_id", "")), total)

	func _live_subject_keys() -> Array:
		var s: PlanetSafari = PlanetSafari.current
		if s == null or not is_instance_valid(s):
			return []
		var order: Variant = s.get("_subject_order")
		return (order as Array).duplicate() if order is Array else []

	func _build_shell() -> void:
		_root = Control.new()
		_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_root.mouse_filter = Control.MOUSE_FILTER_STOP
		_root.theme = UIStyle.theme()
		add_child(_root)
		MobileUI.apply_theme(_root)
		var dim := ColorRect.new()
		dim.color = UIStyle.BACKDROP
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_root.add_child(dim)
		_card_host = Control.new()
		_card_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_root.add_child(_card_host)

	# ---------------------------------------------------------------------------- the card frame
	## The card's rect: the whole screen minus the safe area (a notch) minus a small edge.
	func _card_rect() -> Rect2:
		var vp := get_viewport().get_visible_rect().size
		var safe := MobileUI.safe_area()  # left, top, right, bottom
		var tl := Vector2(safe.x + EDGE, safe.y + EDGE)
		var br := Vector2(safe.z + EDGE, safe.w + EDGE)
		return Rect2(tl, vp - tl - br)

	func _fs(size: int) -> int:
		return int(round(float(size) * (MobileUI.FONT_SCALE if MobileUI.is_mobile() else 1.0)))

	## A fresh card; returns the VBox its content goes in. The VBox is EXPAND_FILL both ways inside
	## the ScrollContainer, so it spans the card's full width (the 8.1 bug was its default SHRINK).
	func _panel_frame(compact := false) -> VBoxContainer:
		for c in _card_host.get_children():
			c.queue_free()
		_pics.clear()
		_pic_aspect.clear()
		var r := _card_rect()
		if compact:
			# the summary: a card in the middle, as tall as its content (`_shrink_to_content`)
			var w := minf(r.size.x, 820.0)
			r = Rect2(Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y), Vector2(w, r.size.y))
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(UIStyle.CREAM, 22,
			UIStyle.CREAM_EDGE, 3, 10, 18.0))
		panel.position = r.position
		panel.size = r.size
		_card_host.add_child(panel)
		_panel = panel
		_scroll = ScrollContainer.new()
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		panel.add_child(_scroll)
		_col = VBoxContainer.new()
		_col.add_theme_constant_override("separation", 10)
		_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_scroll.add_child(_col)
		return _col

	## The card's usable inner size (inside the panel's 18 px content margin).
	func _inner() -> Vector2:
		return _card_rect().size - Vector2(36.0, 36.0)

	func _info_w() -> float:
		return clampf(_inner().x * INFO_SHARE, INFO_MIN_W, INFO_MAX_W)

	## SECONDARY PAGES (17.1 rule 6; see the header comment). Files every "sight"/"bonus" entry of
	## `photo.others` under its OWN key, from the same image, keeping whichever of the new or the
	## already-filed record is better (`SafariReview.is_better` - grade first, price only breaks a
	## tie); returns one "Also: <name>" line per such subject, whether or not its page changed.
	func _file_secondary_pages(photo: Dictionary, planet_id: String) -> Array[String]:
		var lines: Array[String] = []
		if _journal == null:
			return lines
		for raw: Variant in photo.get("others", []):
			if not (raw is Dictionary):
				continue
			var e := raw as Dictionary
			var cat := str(e.get("category", ""))
			if cat != "sight" and cat != "bonus":
				continue
			var sub_name := str(e.get("name", ""))
			if str(e.get("key", "")) == "" or sub_name == "":
				continue
			var sub_photo := SafariReview.secondary_photo(photo, e)
			var old: Dictionary = _journal.planet_offer_photo(sub_photo, planet_id).get("old", {})
			var old_gi := SafariScoring.GRADES.find(str(old.get("grade", "")))
			if old.is_empty() or SafariReview.is_better(int(sub_photo.get("grade_idx", 0)),
					int(sub_photo.get("price", 0)), old_gi, int(old.get("price", 0))):
				_journal.planet_keep_new(sub_photo, planet_id)
			lines.append(("Also: %s - a collector's page!" % sub_name) if cat == "bonus" else ("Also: %s" % sub_name))
		return lines

	# ------------------------------------------------------------------------------- one photo
	func _show_photo(photo: Dictionary, index: int, total: int) -> void:
		var planet_id := str(_session.get("planet_id", ""))
		var col := _panel_frame()
		var subject_name := str(photo.get("subject_name", ""))
		var grade := str(photo.get("grade", "Smudge"))
		var kind := str((photo.get("raw", {}) as Dictionary).get("kind", ""))
		var collectors := SafariReview.is_collectors(photo)
		# a neighbour by its kind or by its scrapbook category (spec 15.5): either one is a Friends photo
		if SafariReview.category_of(photo) == "neighbour":
			kind = "neighbour"
		var key := str(photo.get("subject_key", ""))
		var host_id := SafariReview.host_of(planet_id)
		# SECONDARY PAGES (17.1 rule 6): every sight/bonus subject the scorer also saw in this photo
		# gets its own page filed now (see the header comment), so the "Also:" lines below are ready
		# before the info column is built.
		var also_lines := _file_secondary_pages(photo, planet_id)

		var body := HBoxContainer.new()
		body.add_theme_constant_override("separation", int(GAP))
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(body)

		# LEFT: the picture area (one big photo, or the two compared ones).
		var pic_area := VBoxContainer.new()
		pic_area.add_theme_constant_override("separation", 8)
		pic_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(pic_area)
		var status := VBoxContainer.new()   # "Filed in the journal." lines, under the photo
		status.add_theme_constant_override("separation", 2)

		# RIGHT: the numbers, the line, and the Next button - fixed width, never holds a picture.
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 6)
		info.custom_minimum_size = Vector2(_info_w(), 0)
		body.add_child(info)
		info.add_child(_label("Photo %d of %d" % [index + 1, total], UIStyle.SIZE_SMALL, C_SOFT))
		var title := _label(subject_name if subject_name != "" else "Just the yard", UIStyle.SIZE_HEADER, C_TEXT)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD
		info.add_child(title)
		var cap := SafariReview.moment_caption(photo)
		if cap != "":
			var cap_l := _label(cap, UIStyle.SIZE_SMALL, C_MOMENT)
			cap_l.autowrap_mode = TextServer.AUTOWRAP_WORD
			info.add_child(cap_l)
		var scores: Dictionary = photo.get("scores", {})
		info.add_child(_bar_row("Centred", int(scores.get("centred", 0)), C_BAR_CENTRED))
		info.add_child(_bar_row("Size", int(scores.get("size", 0)), C_BAR_SIZE))
		# FACING (11.1): a new score, out of 10, only for a subject registered with a "front". No
		# such subject puts "facing" into `photo.scores` at all (never a fake 0), so the bar's
		# presence here is read straight off the dictionary, same rule the reveal (`_score_col`) uses.
		if scores.has("facing"):
			info.add_child(_bar_row("Facing", int(scores.get("facing", 0)), C_BAR_FACING))
		info.add_child(_bar_row("Focus", int(scores.get("focus", 0)), C_BAR_FOCUS))
		info.add_child(_bar_row("Rarity boost", int(scores.get("rarity", 0)), C_BAR_RARITY))
		info.add_child(_label(SafariReview.worth_text(grade, int(photo.get("price", 0)), collectors),
			UIStyle.SIZE_BODY, C_MOMENT if collectors else C_TEXT))
		# THE SECOND LINE(S) (17.1 rule 6): one "Also: <name>" per sight/bonus subject also in this
		# photo - never a price (pay comes from the named subject only).
		for also_l: String in also_lines:
			var also_lbl := _label(also_l, UIStyle.SIZE_SMALL, C_MOMENT)
			also_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			info.add_child(also_lbl)
		# A neighbour's photo gets the neighbour's own first-person line, never the specimen log.
		var voice := SafariReview.friend_line(grade) if kind == "neighbour" \
			else SafariReview.line_for(photo, planet_id)
		var voice_l := _label(voice, UIStyle.SIZE_SMALL, C_SOFT)
		voice_l.autowrap_mode = TextServer.AUTOWRAP_WORD
		info.add_child(voice_l)
		var push := Control.new()
		push.size_flags_vertical = Control.SIZE_EXPAND_FILL
		info.add_child(push)
		var next_row := HBoxContainer.new()
		info.add_child(next_row)
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		next_row.add_child(sp)

		var img: Variant = photo.get("image")
		var counter := "Photo %d of %d" % [index + 1, total]
		# 1. THE SUBJECT: keep new-or-old (5.6), or filed straight away on a first shot.
		if key != "" and _journal != null:
			var old: Dictionary = (_journal.planet_offer_photo(photo, planet_id)).get("old", {})
			if old.is_empty():
				_journal.planet_keep_new(photo, planet_id)
				status.add_child(_status("First photo of %s - filed in the journal." % SafariReview.mid(subject_name)))
			else:
				var kept_new := await _ask_keep(pic_area, info, counter,
					"You already have a photo of %s. Keep which one?" % SafariReview.mid(subject_name),
					img, "This safari - %s" % grade, str(old.get("thumb_b64", "")),
					"In your journal - %s" % str(old.get("grade", "")))
				if kept_new:
					_journal.planet_keep_new(photo, planet_id)
				else:
					_journal.planet_keep_old(key)
				var journal := _journal
				var final_new := await _reveal_scores(pic_area, info, counter, photo, old, kept_new, true,
					func() -> void: journal.planet_keep_new(photo, planet_id),
					func() -> void: journal.planet_restore_record(key, old))
				if final_new:
					status.add_child(_status("Kept the new photo of %s." % SafariReview.mid(subject_name)))
				else:
					status.add_child(_status("Kept your old photo of %s." % SafariReview.mid(subject_name)))

		# 2. FRIENDS (5.6): a neighbour's photo also competes for their favourite-photo slot.
		if key != "" and kind == "neighbour" and host_id != "" and _journal != null:
			var fold: Dictionary = (_journal.planet_friend_offer(host_id)).get("old", {})
			var fname := str(NpcData.get_data(host_id).get("display_name", host_id.capitalize()))
			if fold.is_empty():
				_journal.planet_keep_friend_new(host_id, photo, planet_id)
				status.add_child(_status("Set as your favourite photo of %s in Friends." % fname))
			else:
				var fav_new := await _ask_keep(pic_area, info, counter,
					"Your favourite photo of %s, for Friends - which one?" % fname,
					img, "This safari - %s" % grade, str(fold.get("thumb_b64", "")),
					"Favourite now - %s" % str(fold.get("grade", "")))
				if fav_new:
					_journal.planet_keep_friend_new(host_id, photo, planet_id)
				else:
					_journal.planet_keep_friend_old(host_id)
				# A PURE CHOICE OF TASTE (5.6): the reveal still shows both photos' scores (11.3), but
				# `allow_swap = false` - no nudge ever offered here, whichever one scored higher.
				var final_fav := await _reveal_scores(pic_area, info, counter, photo, fold, fav_new, false,
					Callable(), Callable())
				if final_fav:
					status.add_child(_status("New favourite photo of %s." % fname))
				else:
					status.add_child(_status("Kept your favourite photo of %s." % fname))

		# The card at rest: the one big photo, the status lines, and Next.
		_clear(pic_area)
		info.visible = true
		pic_area.alignment = BoxContainer.ALIGNMENT_BEGIN
		var big := _image_rect(img)
		pic_area.add_child(big)
		pic_area.add_child(status)
		var next_btn := UIStyle.make_button("Next" if index + 1 < total else "Continue", "PillPrimary", 180.0)
		next_row.add_child(next_btn)
		_pics.clear()
		_pic_aspect.clear()
		_register_pic(big, img)
		_pic_w_cap = maxf(1.0, _inner().x - _info_w() - GAP)
		await _fit_pictures()
		await next_btn.pressed

	## The two photos side by side across the WHOLE card (the info column steps aside while the
	## question is open), same size, each with its grade and its own button. Returns true for new.
	func _ask_keep(pic_area: VBoxContainer, info: Control, counter: String, prompt: String,
			new_img: Variant, new_caption: String, old_b64: String, old_caption: String) -> bool:
		_clear(pic_area)
		info.visible = false
		pic_area.alignment = BoxContainer.ALIGNMENT_CENTER
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 16)
		pic_area.add_child(head)
		var p := _label(prompt, UIStyle.SIZE_BODY, C_TEXT)
		p.autowrap_mode = TextServer.AUTOWRAP_WORD
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(p)
		head.add_child(_label(counter, UIStyle.SIZE_SMALL, C_SOFT))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(GAP))
		pic_area.add_child(row)
		var old_img := _decode_thumb(old_b64)
		var new_col := _choice_col(new_caption, new_img, "Keep new")
		var old_col := _choice_col(old_caption, old_img, "Keep old")
		row.add_child(new_col[0])
		row.add_child(old_col[0])
		_pics.clear()
		_pic_aspect.clear()
		_register_pic(new_col[1], new_img)
		_register_pic(old_col[1], old_img)
		_pic_w_cap = maxf(1.0, (_inner().x - GAP) * 0.5)
		await _fit_pictures()
		var choice := _Choice.new()
		(new_col[2] as Button).pressed.connect(func(): choice.made.emit(true))
		(old_col[2] as Button).pressed.connect(func(): choice.made.emit(false))
		var picked_new: bool = await choice.made
		return picked_new

	## [the column, its picture box, its button]
	func _choice_col(caption: String, img: Variant, btn_text: String) -> Array:
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 6)
		c.add_child(_label(caption, UIStyle.SIZE_SMALL, C_SOFT))
		var pic := _image_rect(img)
		c.add_child(pic)
		var b := UIStyle.make_button(btn_text, "Pill", 0.0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.add_child(b)
		return [c, pic, b]

	## THE REVEAL (11.3, "blind, with a safety net"). Called right after a keep-new-or-old choice
	## commits. Shows the SAME two photos again, side by side, now with every bar (11.1's Facing
	## included when the photo has one - hidden, not zeroed, when it does not). `allow_swap` is true
	## only for the subject's own choice; the Friends favourite (5.6, a pure choice of taste) passes
	## false and two empty Callables, so no nudge is ever built for it. The comparison is GRADE first,
	## price only to break a tie (SafariReview.is_better): the nudge must never push the player toward
	## the photo with the worse grade shown beside it. Price alone did (critic, round 1): it still weights
	## the moment heavily, so a perfect no-moment Fine (24) lost to an all-zero Fair that caught a 2.4
	## moment (26). Never a fitted combination of the bars. Loops so a swap (or a
	## swap back) redraws with the tag flipped and the nudge re-evaluated from the new state; returns
	## whichever is kept when the player finally continues.
	func _reveal_scores(pic_area: VBoxContainer, info: Control, counter: String, photo: Dictionary,
			old: Dictionary, kept_new_start: bool, allow_swap: bool, commit_new: Callable,
			restore_old: Callable) -> bool:
		var new_img: Variant = photo.get("image")
		var old_img := _decode_thumb(str(old.get("thumb_b64", "")))
		var new_scores: Dictionary = photo.get("scores", {})
		var old_scores: Dictionary = old.get("scores", {})
		var new_grade := str(photo.get("grade", "Smudge"))
		var old_grade := str(old.get("grade", "Smudge"))
		var new_price := int(photo.get("price", 0))
		var old_price := int(old.get("price", 0))
		# both photos are of the one subject, so a collector's page is one on both sides (15.5)
		var collectors := SafariReview.is_collectors(photo)
		# The grade as a number, from the grade NAME (a journal photo saved before grade_idx existed
		# still carries its name); -1 for an unknown name, so it never outranks a real grade.
		var new_gi := SafariScoring.GRADES.find(new_grade)
		var old_gi := SafariScoring.GRADES.find(old_grade)
		var kept_new := kept_new_start
		while true:
			_clear(pic_area)
			info.visible = false
			pic_area.alignment = BoxContainer.ALIGNMENT_CENTER
			var head := HBoxContainer.new()
			head.add_theme_constant_override("separation", 16)
			pic_area.add_child(head)
			var p := _label("Here's how they scored.", UIStyle.SIZE_BODY, C_TEXT)
			p.autowrap_mode = TextServer.AUTOWRAP_WORD
			p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			head.add_child(p)
			head.add_child(_label(counter, UIStyle.SIZE_SMALL, C_SOFT))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", int(GAP))
			pic_area.add_child(row)
			_pics.clear()
			_pic_aspect.clear()
			var new_col := _score_col(new_img, new_scores, new_grade, new_price, kept_new, "This safari", collectors)
			var old_col := _score_col(old_img, old_scores, old_grade, old_price, not kept_new, "In your journal",
				collectors)
			row.add_child(new_col[0])
			row.add_child(old_col[0])
			_register_pic(new_col[1], new_img)
			_register_pic(old_col[1], old_img)
			# THE PICTURE GETS THE SAME HALF-CARD BUDGET THE BLIND CHOICE GIVES IT (8.2 re-diagnosis,
			# "squeezed into the left half") - the bars no longer compete with it for WIDTH (they sit
			# in a two-across grid UNDER it, `_score_col` below), only for height, and `_fit_pictures`
			# already inverts a height overflow into exactly the shrink needed - never a fraction
			# borrowed from the single-photo info column, which is far wider than this half-card
			# column can spare.
			_pic_w_cap = maxf(1.0, (_inner().x - GAP) * 0.5)

			# THE BUTTON ROW MUST EXIST BEFORE `_fit_pictures()` RUNS (same order `_ask_keep` uses) -
			# it measures the card's OWN overflow to decide how much to shrink the pictures, so
			# anything added after that pass (a nudge line, Swap) would sit unmeasured and could be
			# pushed off the bottom of the card instead of shrinking the pictures to make room for it.
			var kept_price := new_price if kept_new else old_price
			var other_price := old_price if kept_new else new_price
			var kept_gi := new_gi if kept_new else old_gi
			var other_gi := old_gi if kept_new else new_gi
			var offer_swap := allow_swap and SafariReview.is_better(other_gi, other_price, kept_gi, kept_price)
			var pick := _Pick.new()
			if offer_swap:
				var which := "old" if kept_new else "new"
				var line := _label("Your %s one scored higher - swap back?" % which,
					UIStyle.SIZE_SMALL, C_TEXT)
				pic_area.add_child(_centred(line))
			var btn_row := HBoxContainer.new()
			btn_row.add_theme_constant_override("separation", 12)
			btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
			btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if offer_swap:
				var swap_btn := UIStyle.make_button("Swap", "Pill", 160.0)
				swap_btn.pressed.connect(func(): pick.chosen.emit("swap"))
				btn_row.add_child(swap_btn)
			var cont_btn := UIStyle.make_button("Continue", "PillPrimary", 180.0)
			cont_btn.pressed.connect(func(): pick.chosen.emit("continue"))
			btn_row.add_child(cont_btn)
			pic_area.add_child(btn_row)

			await _fit_pictures()

			var action: String = await pick.chosen
			if action != "swap":
				break
			if kept_new and restore_old.is_valid():
				restore_old.call()
			elif not kept_new and commit_new.is_valid():
				commit_new.call()
			kept_new = not kept_new
		return kept_new

	## One photo's full numbers for the reveal - a tag (highlighted when this one is the one
	## currently kept), the picture at the SAME width the blind choice gave it, then its bars in a
	## two-across grid underneath (8.2 re-diagnosis: see THE LAYOUT RULE at the top of the file).
	## Facing (11.1) only appears when `scores` actually carries one; a subject with no `front` never
	## gets a Facing score, so the bar is left out rather than drawn at zero. Returns [column,
	## picture box] - the caller registers the picture with `_fit_pictures` same as everywhere else.
	func _score_col(img: Variant, scores: Dictionary, grade: String, price: int, is_kept: bool,
			tag: String, collectors: bool = false) -> Array:
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 6)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tag_l := _label(("%s - kept" % tag) if is_kept else tag,
			UIStyle.SIZE_SMALL, C_GOOD if is_kept else C_SOFT)
		tag_l.autowrap_mode = TextServer.AUTOWRAP_WORD
		c.add_child(tag_l)
		var pic := _image_rect(img)
		# CENTRED IN ITS HALF (spec 13.3): when `_fit_pictures` shrinks the picture for height it no
		# longer fills its half-card column; it sits in the middle of it, not against its left edge.
		pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		c.add_child(pic)
		var worth := _label(SafariReview.worth_text(grade, price, collectors), UIStyle.SIZE_BODY,
			C_MOMENT if collectors else C_TEXT)
		worth.autowrap_mode = TextServer.AUTOWRAP_WORD
		c.add_child(worth)
		# THE BARS SIT TWO-ACROSS, NOT ONE-UNDER-ANOTHER (8.2 re-diagnosis, "squeezed into the left
		# half"). Six rows stacked one at a time is what pushed the card's content past its own
		# height and forced `_fit_pictures` to shrink the picture to make room; a GridContainer
		# wraps them at 2 pairs per line instead, roughly HALVING that height, while the picture
		# keeps the same full half-card width the blind choice already gave it (`_pic_w_cap` in
		# `_reveal_scores`) - no share of that width goes to the bars at all, so neither photo ever
		# has to give ground for its own numbers.
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 4)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.add_child(grid)
		_bar_cells(grid, "Centred", int(scores.get("centred", 0)), C_BAR_CENTRED)
		_bar_cells(grid, "Size", int(scores.get("size", 0)), C_BAR_SIZE)
		if scores.has("facing"):
			_bar_cells(grid, "Facing", int(scores.get("facing", 0)), C_BAR_FACING)
		_bar_cells(grid, "Focus", int(scores.get("focus", 0)), C_BAR_FOCUS)
		_bar_cells(grid, "Rarity boost", int(scores.get("rarity", 0)), C_BAR_RARITY)
		return [c, pic]

	func _register_pic(box: Control, img: Variant) -> void:
		var a := 2.0
		if img is Image and not (img as Image).is_empty():
			a = float((img as Image).get_width()) / float(maxi((img as Image).get_height(), 1))
		_pics.append(box)
		_pic_aspect.append(a)

	## Sizes the current pictures: as wide as their width budget allows, then, after a layout pass,
	## exactly as much shorter as the card overflows its box. Two passes, because a shorter picture
	## can let a wrapped label re-flow; the second pass measures what the first left.
	func _fit_pictures() -> void:
		if _pics.is_empty():
			return
		var aspect := 1.0
		for a: float in _pic_aspect:
			aspect = maxf(aspect, a)  # the widest one binds the shared height
		var h := _pic_w_cap / aspect
		_size_pics(h)
		for pass_i in 2:
			await get_tree().process_frame
			await get_tree().process_frame
			if not is_instance_valid(_col):
				return
			var over := _col.get_combined_minimum_size().y - _inner().y
			if over <= 0.5:
				break
			h = maxf(60.0, h - over - 1.0)
			_size_pics(h)
		await get_tree().process_frame

	func _size_pics(h: float) -> void:
		for i in _pics.size():
			var box := _pics[i] as Control
			if not is_instance_valid(box):
				continue
			var w := minf(_pic_w_cap, h * float(_pic_aspect[i]))
			box.custom_minimum_size = Vector2(w, h)

	func _clear(n: Node) -> void:
		for c in n.get_children():
			n.remove_child(c)
			c.queue_free()

	func _decode_thumb(b64: String) -> Image:
		if b64 == "":
			return null
		var bytes := Marshalls.base64_to_raw(b64)
		if bytes.is_empty():
			return null
		var img := Image.new()
		var err := img.load_webp_from_buffer(bytes)
		return img if err == OK and not img.is_empty() else null

	# ----------------------------------------------------------------------------- the summary
	func _show_summary() -> void:
		var col := _panel_frame(true)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var photos: Array = _session.get("photos", [])
		col.add_child(_centred(_label("Safari complete", UIStyle.SIZE_TITLE, C_TEXT)))
		col.add_child(_centred(_label("%d photo%s taken." % [photos.size(), "" if photos.size() == 1 else "s"],
			UIStyle.SIZE_BODY, C_TEXT)))
		# THE END NEVER NAMES A SUBJECT YOU DID NOT PHOTOGRAPH (6.1) - only the count.
		var missed := SafariReview.missed_count(_session)
		if missed > 0:
			var word := "thing" if missed == 1 else "things"
			col.add_child(_centred(_label("%d %s woke up that you never saw." % [missed, word],
				UIStyle.SIZE_BODY, C_SOFT)))
		var total := SafariReview.session_total(_session)
		var pay_text := ("Your photos earned %d stardust." % total) if total > 0 \
			else "No stardust this time - photograph a creature or an event to earn some."
		col.add_child(_centred(_label(pay_text, UIStyle.SIZE_HEADER, C_GOOD if total > 0 else C_SOFT)))
		# COLLECTOR'S PAGES (15.5): counted apart - they pay nothing, and the line says so kindly.
		var pages := SafariReview.collectors_count(_session)
		if pages > 0:
			col.add_child(_centred(_label("Plus %d collector's page%s for your scrapbook - just for keeps." % [
				pages, "" if pages == 1 else "s"], UIStyle.SIZE_BODY, C_MOMENT)))
		var done_btn := UIStyle.make_button("Done", "PillPrimary", 200.0)
		done_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(done_btn)
		await _shrink_to_content()
		await done_btn.pressed

	## Measured, not guessed: after a layout pass, the card becomes as tall as its content (never
	## taller than the full card rect) and is centred vertically.
	func _shrink_to_content() -> void:
		await get_tree().process_frame
		await get_tree().process_frame
		if not is_instance_valid(_panel) or not is_instance_valid(_col):
			return
		var full := _card_rect()
		var h := minf(full.size.y, _col.get_combined_minimum_size().y + 36.0 + 24.0)
		_panel.size.y = h
		_panel.position.y = full.position.y + (full.size.y - h) * 0.5

	# ------------------------------------------------------------------------- small UI helpers
	func _label(text: String, size: int, color: Color) -> Label:
		var l := Label.new()
		l.text = text
		l.add_theme_font_override("font", UIStyle.ui_font())
		l.add_theme_font_size_override("font_size", _fs(size))
		l.add_theme_color_override("font_color", color)
		return l

	func _centred(l: Label) -> Label:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		return l

	func _status(text: String) -> Label:
		var l := _label(text, UIStyle.SIZE_SMALL, C_GOOD)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		return l

	## A picture box; its size is set by `_size_pics`. The image keeps its aspect inside it.
	func _image_rect(img_v: Variant) -> Control:
		var box := PanelContainer.new()
		var sb := UIStyle.make_panel_style(C_NAVY, 12, C_NAVY, 0, 0, 0.0)
		box.add_theme_stylebox_override("panel", sb)
		box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if img_v is Image and not (img_v as Image).is_empty():
			var tr := TextureRect.new()
			tr.name = "Photo"
			tr.texture = ImageTexture.create_from_image(img_v as Image)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			box.add_child(tr)
		else:
			var q := Label.new()
			q.text = "?"
			q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			q.add_theme_font_override("font", UIStyle.ui_font())
			q.add_theme_font_size_override("font_size", 30)
			q.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
			box.add_child(q)
		return box

	## A labelled bar out of 10 - Centred / Size / Focus / the rarity boost (5.4). The bar takes
	## whatever width the info column has left after its label.
	func _bar_row(label_text: String, value10: int, fill: Color) -> Control:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl := _label("%s %d/10" % [label_text, clampi(value10, 0, 10)], UIStyle.SIZE_SMALL, C_TEXT)
		lbl.custom_minimum_size = Vector2(_fs(17) * 9.5, 0)
		row.add_child(lbl)
		var bar := _Bar.new()
		bar.frac = clampf(float(value10) / 10.0, 0.0, 1.0)
		bar.fill = fill
		bar.custom_minimum_size = Vector2(80, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		return row

	## The reveal's two-across bar grid (8.2 re-diagnosis): a label cell then a bar cell, added
	## straight into `grid` rather than returned as one control - a GridContainer aligns every
	## column to its OWN widest cell, so the label is never padded out to the single-photo info
	## column's width (`_bar_row`'s fixed 9.5-character floor), which is far wider than two bars
	## side by side can spare.
	func _bar_cells(grid: GridContainer, label_text: String, value10: int, fill: Color) -> void:
		var lbl := _label("%s %d/10" % [label_text, clampi(value10, 0, 10)], UIStyle.SIZE_SMALL, C_TEXT)
		grid.add_child(lbl)
		var bar := _Bar.new()
		bar.frac = clampf(float(value10) / 10.0, 0.0, 1.0)
		bar.fill = fill
		bar.custom_minimum_size = Vector2(50, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(bar)


class _Bar extends Control:
	var frac := 0.0
	var fill := Color.WHITE

	func _draw() -> void:
		var bg := StyleBoxFlat.new()
		bg.bg_color = SafariReview.C_BAR_BG
		bg.set_corner_radius_all(int(size.y * 0.5))
		draw_style_box(bg, Rect2(Vector2.ZERO, size))
		if frac > 0.0:
			var fg := StyleBoxFlat.new()
			fg.bg_color = fill
			fg.set_corner_radius_all(int(size.y * 0.5))
			draw_style_box(fg, Rect2(Vector2.ZERO, Vector2(maxf(size.y, size.x * frac), size.y)))
