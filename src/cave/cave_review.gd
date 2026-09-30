class_name CaveReview
extends RefCounted
## THE CAVE'S PHOTO REVIEW (docs/JUNGLE_PLANET_SPEC.md 6, the user 2026-09-30: "in the cave there was no
## review of photos"; lead ruling: "the photo review must run at the end of every cave visit, like the
## safaris"). Builder PERFCAVE.
##
## THE SAFARIS' OWN REVIEW SCREEN, not a look-alike: `_CaveView` extends SafariReview._View
## (src/planet_safari/review/safari_review.gd, read-only for this builder) and keeps every piece of its
## layout - the big photo, the bars, the blind KEEP NEW OR OLD side by side, the scored reveal with its
## one-tap swap back, the fit-to-card pass, the summary card. What it changes is only where a photo is
## FILED and what the words say:
##   * pages are CaveStore's (the scrapbook's Cave tab), not SkyJournal's planet pages - so `run` never
##     touches the journal, and `_journal` stays null for the whole review
##   * no stardust: the cave never paid (STORY_HOME_SPEC 9.3). No pay entry is opened (`_paid` is true
##     from the start, so the parent's `_exit_tree` settles nothing), no price is ever shown, and no
##     print goes to Gloop's table
##   * "better" is CaveStore's rule - grade first, then craft - so the reveal's swap nudge is fed the
##     craft as its tie-break in place of a price (`_nudge_copy`)
## Called by CaveVisit._go_to_sleep for every ending: time up, Leave, or out of film.

const LINES := {
	"Smudge": "A soft one - the cave doesn't mind.",
	"Fair": "Clear enough for your Cave pages.",
	"Fine": "Crisp! The crystals would be proud.",
	"Gallery": "A gallery shot, deep underground!",
}


static func present(host: Node, session: Dictionary) -> void:
	var view := _CaveView.new()
	host.add_child(view)
	await view.run(session)
	if is_instance_valid(view):
		view.queue_free()


class _CaveView extends SafariReview._View:
	## Pages this review filed for the first time (the summary line).
	var _new_pages := 0

	func run(session: Dictionary) -> void:
		layer = 60
		name = "CaveReview"
		process_mode = Node.PROCESS_MODE_ALWAYS
		_session = session
		_journal = null
		_paid = true   # nothing to pay: the parent's _exit_tree -> _settle_pay returns at once
		_build_shell()
		EventBus.ui_modal_opened.emit("planet_safari_review")
		var photos: Array = session.get("photos", [])
		for i in photos.size():
			await _show_photo(photos[i] as Dictionary, i, photos.size())
		await _show_summary()
		EventBus.ui_modal_closed.emit("planet_safari_review")
		print("[CaveReview] done: photos=%d new_pages=%d filled=%d/%d" % [photos.size(), _new_pages,
			CaveStore.filled_count(), CaveStore.ROSTER.size()])

	## The parent's card, word for word in layout, with the cave's store and the cave's words.
	func _show_photo(photo: Dictionary, index: int, total: int) -> void:
		var col := _panel_frame()
		var subject_name := str(photo.get("subject_name", ""))
		var grade := str(photo.get("grade", "Smudge"))
		var id := CaveStore.page_id(photo)

		var body := HBoxContainer.new()
		body.add_theme_constant_override("separation", int(SafariReview.GAP))
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(body)
		var pic_area := VBoxContainer.new()
		pic_area.add_theme_constant_override("separation", 8)
		pic_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(pic_area)
		var status := VBoxContainer.new()
		status.add_theme_constant_override("separation", 2)

		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 6)
		info.custom_minimum_size = Vector2(_info_w(), 0)
		body.add_child(info)
		info.add_child(_label("Photo %d of %d" % [index + 1, total], UIStyle.SIZE_SMALL, SafariReview.C_SOFT))
		var title := _label(subject_name if subject_name != "" else "The cave", UIStyle.SIZE_HEADER, SafariReview.C_TEXT)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD
		info.add_child(title)
		var cap := SafariReview.moment_caption(photo)
		if cap != "":
			var cap_l := _label(cap, UIStyle.SIZE_SMALL, SafariReview.C_MOMENT)
			cap_l.autowrap_mode = TextServer.AUTOWRAP_WORD
			info.add_child(cap_l)
		var scores: Dictionary = photo.get("scores", {})
		info.add_child(_bar_row("Centred", int(scores.get("centred", 0)), SafariReview.C_BAR_CENTRED))
		info.add_child(_bar_row("Size", int(scores.get("size", 0)), SafariReview.C_BAR_SIZE))
		if scores.has("facing"):
			info.add_child(_bar_row("Facing", int(scores.get("facing", 0)), SafariReview.C_BAR_FACING))
		info.add_child(_bar_row("Focus", int(scores.get("focus", 0)), SafariReview.C_BAR_FOCUS))
		info.add_child(_bar_row("Rarity boost", int(scores.get("rarity", 0)), SafariReview.C_BAR_RARITY))
		info.add_child(_label(grade, UIStyle.SIZE_BODY, SafariReview.C_TEXT))
		var voice_l := _label(str(CaveReview.LINES.get(grade, CaveReview.LINES["Smudge"])), UIStyle.SIZE_SMALL, SafariReview.C_SOFT)
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
		# KEEP NEW OR OLD against the page as it is NOW (an earlier card this review may have changed it).
		if id != "":
			var old := CaveStore.record_for(id)
			var nm := SafariReview.mid(subject_name)
			if old.is_empty():
				CaveStore.keep_new(photo)
				_new_pages += 1
				status.add_child(_status("First photo of %s - a new Cave page!" % nm))
			else:
				var kept_new := await _ask_keep(pic_area, info, counter,
					"Your Cave page already has %s. Keep which one?" % nm,
					img, "This visit - %s" % grade, str(old.get("thumb_b64", "")),
					"On your page - %s" % str(old.get("grade", "")))
				if kept_new:
					CaveStore.keep_new(photo)
				var final_new := await _reveal_scores(pic_area, info, counter, _nudge_copy(photo),
					_nudge_copy(old), kept_new, true,
					func() -> void: CaveStore.keep_new(photo),
					func() -> void: CaveStore.restore_record(id, old))
				if final_new:
					status.add_child(_status("Kept the new photo of %s." % nm))
				else:
					status.add_child(_status("Kept your old photo of %s." % nm))

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
		_pic_w_cap = maxf(1.0, _inner().x - _info_w() - SafariReview.GAP)
		await _fit_pictures()
		await next_btn.pressed

	## The reveal's swap nudge ranks by grade, then "price". The cave ranks by grade, then craft
	## (CaveStore.offer_photo), so the copy the reveal reads carries the craft in the price slot. Never shown:
	## `_score_col` below prints no price.
	func _nudge_copy(p: Dictionary) -> Dictionary:
		var c := p.duplicate()
		c["price"] = int(round(float(p.get("craft", 0.0)) * 1000.0))
		return c

	## The parent's reveal column with the cave's tags and no price line.
	func _score_col(img: Variant, scores: Dictionary, grade: String, _price: int, is_kept: bool,
			tag: String, _collectors: bool = false) -> Array:
		var t := "This visit" if tag == "This safari" else ("On your page" if tag == "In your journal" else tag)
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 6)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tag_l := _label(("%s - kept" % t) if is_kept else t,
			UIStyle.SIZE_SMALL, SafariReview.C_GOOD if is_kept else SafariReview.C_SOFT)
		tag_l.autowrap_mode = TextServer.AUTOWRAP_WORD
		c.add_child(tag_l)
		var pic := _image_rect(img)
		pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		c.add_child(pic)
		c.add_child(_label(grade, UIStyle.SIZE_BODY, SafariReview.C_TEXT))
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 4)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.add_child(grid)
		_bar_cells(grid, "Centred", int(scores.get("centred", 0)), SafariReview.C_BAR_CENTRED)
		_bar_cells(grid, "Size", int(scores.get("size", 0)), SafariReview.C_BAR_SIZE)
		if scores.has("facing"):
			_bar_cells(grid, "Facing", int(scores.get("facing", 0)), SafariReview.C_BAR_FACING)
		_bar_cells(grid, "Focus", int(scores.get("focus", 0)), SafariReview.C_BAR_FOCUS)
		_bar_cells(grid, "Rarity boost", int(scores.get("rarity", 0)), SafariReview.C_BAR_RARITY)
		return [c, pic]

	func _show_summary() -> void:
		var col := _panel_frame(true)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var photos: Array = _session.get("photos", [])
		col.add_child(_centred(_label("Back from the cave", UIStyle.SIZE_TITLE, SafariReview.C_TEXT)))
		col.add_child(_centred(_label("%d photo%s taken." % [photos.size(), "" if photos.size() == 1 else "s"],
			UIStyle.SIZE_BODY, SafariReview.C_TEXT)))
		if _new_pages > 0:
			col.add_child(_centred(_label("%d new Cave page%s!" % [_new_pages, "" if _new_pages == 1 else "s"],
				UIStyle.SIZE_HEADER, SafariReview.C_GOOD)))
		col.add_child(_centred(_label("Cave pages: %d of %d filled." % [CaveStore.filled_count(), CaveStore.ROSTER.size()],
			UIStyle.SIZE_BODY, SafariReview.C_MOMENT)))
		var done_btn := UIStyle.make_button("Done", "PillPrimary", 200.0)
		done_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(done_btn)
		await _shrink_to_content()
		await done_btn.pressed
