class_name PadModePicker
extends CanvasLayer
## MODE round (2026-09-21, scratch only). "Before you go..." — a second, small choice right after
## the destination card closes and before anything boards: "Just travelling" or "Photo time!" (the
## user's own words, point 2).
##
## WHY A SEPARATE CARD, NOT A THIRD OPTION BOLTED ONTO THE DESTINATION CARD: the destination card is
## "where", already a wide row of up to six tiles; cramming "how" into the same screen would mean
## asking two unrelated questions with one arm-timer, one confirm, one layout. Two small cards in a
## row costs one extra tap and keeps each one honest about what it is asking. `rocket_pad.gd` opens
## this immediately after `_on_destination_chosen`, so the cutscene modal the picker already raised
## never comes down in between - no hotkey can sneak in on the seam.
##
## Same shape as `pad_destination_picker.gd` on purpose (armed timer so the E that opened the
## destination card cannot also fire this one, click-to-confirm, Esc / mobile "Stay here" always
## cancels the WHOLE boarding rather than stepping back to the destination card - one extra state
## machine to go "back" a screen was not worth it for a two-tile choice).
##
## ROUND 2, BLOCKING FIX. `_make_tile` used to build the whole tile AS a PanelContainer, with the
## inner text box and the corner badge as two direct children. A PanelContainer is a Container: it
## lays out EVERY direct child full-rect inside its content margins and ignores any anchor/position
## you set on them (Godot's Container contract, not a bug) - so `ClosedBadge`'s 26x26 minimum size
## and `TOP_RIGHT` position were silently thrown away and the badge was stretched over the whole
## tile, its ring-and-slash drawn at the tile's own centre and radius. On the real 2556x1179
## --ui=mobile frame that put a ~180px ring right across "Photo time!" and its reason line - the
## exact thing the critic's frame showed and the code comment did not.
##
## THE FIX: the tile itself is a plain `Control`, not a `Container`, so its children keep whatever
## anchors/position they are given. `bg` (a PanelContainer, unchanged) still holds and lays out the
## label column the same way it always did; the badge is a SIBLING of `bg`, not its child, so its
## `TOP_RIGHT` preset is honoured and it sits in an honest corner.
##
## "Photo time!" is disabled, with the reason shown in place of its blurb, when:
##   * `SafariTransit.is_flyable(origin, dest)` is false - no cast route exists for this pair yet.
##     WIRE round: SafariLanes covers every pair, so this is now only a defensive branch - see
##     SafariTransit.photo_possible / photo_blocked_reason.
##   * S6 round (STORY_SPINE_SPEC.md 7.1 "A gated trip is silent"): the Professor's own gate is open
##     and this trip is not the Commons run. `rocket_pad.gd` used to check `photo_possible` BEFORE
##     opening this card at all and fall straight through to a one-tap launch when it was false - so
##     a trip that carried a neighbour's own ask (e.g. Zorp's, on home<->zorp) opened silently, with
##     no card and no reason, while the Professor's ask was open. `rocket_pad.gd` now ALSO opens this
##     card - disabled, exactly through this same branch - whenever such a trip carries an open ask
##     (`PhotoAsks.for_trip`), even though `photo_possible` is false, so `setup`'s call to
##     `SafariTransit.photo_blocked_reason` ("fly to the Commons for the Professor first") is the
##     normal case for that trip now, not a defensive one. A trip with no ask at all still never
##     reaches this file - `rocket_pad.gd` launches it straight through, unchanged.
## FILM builder pass: film is no longer a reason to disable this tile. The magazine is loaded PER
## TRIP now (`GameState.film_capacity()`), always full at the pad - it can run out mid-flight, never
## before one starts, so there is nothing left here to gate on `film_stock`.
## "Just travelling" is never disabled: it is exactly today's launch, unchanged, for every route.

signal chosen(mode: String)   # "travel" | "photo"
signal cancelled()

const EDGE := 22.0
const ARM_SECONDS := 0.4
const SCRIM := Color(0.06, 0.05, 0.16, 0.46)
const TILE_SIZE := Vector2(212.0, 156.0)
## PAD CARD builder pass, finding 5. A cool, flat grey - deliberately NOT any of the warm cream/white
## every choosable tile gets, so "unavailable" reads as a different KIND of panel, not just a dimmer
## one. Paired with a muted brick-red for the reason line and the ClosedBadge glyph.
## ROUND 2 (critic finding: "the disabled panel colour does nothing" - CREAM_INSET, what an
## enabled-unselected tile already uses, is #d5d8e4, itself a cool blue-grey, so the old
## DISABLED_FILL #c6c8d3 measured only 8-11/255 away from it in a real frame - not a colour a
## player reads as "off" at a glance. This is deliberately much darker and flatter, not just a
## different shade of the same cool grey: RGB delta from CREAM_INSET is ~50/255 on every channel.
const DISABLED_FILL := Color("#a3a6b5")
const DISABLED_EDGE := Color("#787c8d")
const DISABLED_REASON := Color("#a85c4e")

var _photo_ok := false
var _photo_reason := ""
## S4 round (docs/STORY_SPINE_SPEC.md 2.5, item 3): "the Photo tile says who wants what" whenever
## `PhotoAsks.for_trip` carries something on this exact trip; "" (the shipped "Fly the safari
## lane." sub-line) when it does not. Computed once in `setup`, same as `_photo_ok`/`_photo_reason`.
var _photo_ask_sub := ""
var _index := 0
## The whole tile hit-region (plain Control, NOT a Container - see `_make_tile`'s header comment
## for why a PanelContainer could not hold a freely-positioned corner badge).
var _tiles: Array[Control] = []
## The panel background each tile's style is set on (`_refresh`) - a separate node from `_tiles`
## on purpose, see `_make_tile`.
var _tile_bgs: Array[PanelContainer] = []
var _hatches: Array[Control] = []
var _titles: Array[Label] = []
var _subs: Array[Label] = []
var _card: PanelContainer
var _scrim: ColorRect
var _stay_btn: Button
var _armed := false
var _arm_timer := 0.0
var _closing := false


## `origin_id` / `dest_id` decide whether "Photo time!" can be picked at all — see the file header.
## WIRE round: rocket_pad.gd only OPENS this card when `SafariTransit.photo_possible` is true, so
## the disabled branch below is now belt-and-braces for any other caller rather than the normal
## case it used to be. The reason line is the transit file's, so there is one copy of it.
func setup(origin_id: String, dest_id: String) -> void:
	_photo_reason = SafariTransit.photo_blocked_reason(origin_id, dest_id)
	_photo_ok = _photo_reason == ""
	_photo_ask_sub = _ask_sub_line(origin_id, dest_id)


## S4 round: one line per open ask this trip carries ("<who> wants: <sight>"), joined with "\n" when
## more than one is open on the same trip (rare today - only the Professor's exists - but
## `PhotoAsks.for_trip` is already sorted, so this stays deterministic once neighbours add their
## own). "" when the trip carries nothing, which leaves the shipped "Fly the safari lane." line up.
func _ask_sub_line(origin_id: String, dest_id: String) -> String:
	var hour := GameState.time_of_day
	var ids := PhotoAsks.for_trip(SafariTransit.route_id_for(origin_id, dest_id), origin_id, dest_id, hour)
	if ids.is_empty():
		return ""
	var lines: Array[String] = []
	for sid in ids:
		var ask := PhotoAsks.get_ask(sid)
		lines.append("%s wants: %s" % [_asker_label(str(ask.get("by", ""))), _sight_short_name(sid)])
	return "\n".join(lines)


## "professor" is not an NPC id (`PhotoAsks` entries use it for the Professor's own ask, which is
## not tied to any single project neighbour) - everything else is, and gets its usual display name.
static func _asker_label(by: String) -> String:
	if by == "professor":
		return "The Professor"
	return Journal.npc_name(by)


## The catalog's "name" field is a whole sentence ("Lantern-fish, drifting between worlds",
## safari_catalog.gd :167) - too long for a two-tile card. Nothing else in the codebase shortens
## one yet, so this takes the plain-English convention its own commas already invite: the bit
## before the first comma is the sight's own name, the rest is what's notable about it.
static func _sight_short_name(sight_id: String) -> String:
	var full := str(SafariCatalog.by_id(sight_id).get("name", sight_id))
	var comma := full.find(",")
	return full.substr(0, comma) if comma >= 0 else full


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_arm_timer = ARM_SECONDS

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	add_child(root)

	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = SCRIM
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim.modulate.a = 0.0
	root.add_child(_scrim)
	var fade := _scrim.create_tween()
	fade.tween_property(_scrim, "modulate:a", 1.0, 0.22)

	var mobile := MobileUI.is_mobile()
	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 12)
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	column.offset_top = -460.0 if mobile else -400.0
	column.offset_bottom = -EDGE
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)

	_card = PanelContainer.new()
	_card.name = "ModeCard"
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_card.add_theme_stylebox_override("panel",
		UIStyle.make_panel_style(UIStyle.CREAM, UIStyle.RADIUS, UIStyle.CREAM_EDGE, 3, 16, 22.0))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(box)

	box.add_child(UIStyle.make_label("Before you go...", "Header", HORIZONTAL_ALIGNMENT_CENTER))

	var row := HBoxContainer.new()
	row.name = "Tiles"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	row.add_child(_make_tile(0, "Just travelling", "Straight there — blast off and go.", true, ""))
	var photo_sub := _photo_ask_sub if _photo_ask_sub != "" else "Fly the safari lane."
	row.add_child(_make_tile(1, "Photo time!", photo_sub, _photo_ok, _photo_reason))

	var hint := PanelContainer.new()
	hint.name = "Hint"
	hint.theme_type_variation = "HudPillSoft"
	hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_child(UIStyle.make_label(
		"tap to choose" if mobile else "◀ ▶ choose  ·  E confirm  ·  Esc stay here",
		"Hint", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(hint)

	# Built in both modes, hidden on desktop — same rule pad_destination_picker.gd's own exit
	# button follows (no Esc key on a phone).
	_stay_btn = UIStyle.make_button("Stay here", "Pill")
	_stay_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stay_btn.pressed.connect(_cancel)
	_stay_btn.visible = mobile
	_stay_btn.custom_minimum_size = Vector2(MobileUI.MIN_TOUCH * 2.4, MobileUI.MIN_TOUCH) if mobile else Vector2.ZERO
	column.add_child(_stay_btn)

	_refresh()
	UIStyle.pop_in(_card, 0.32)


## PAD CARD builder pass, finding 5, round 2. The last review measured the two tiles as looking
## near-identical when "Photo time!" is unavailable - "only a small sub-line differs" - and this
## round's critic then measured the FIRST fix as not actually landing (badge stretched over the
## whole tile; colour only 8-11/255 off CREAM_INSET). Four things now mark a disabled tile, each
## one measured on its own, not asserted:
##   1. FILL, clearly darker (`DISABLED_FILL`, ~50/255 off the enabled-unselected colour) - `bg`.
##   2. A HATCH - diagonal "out of service" stripes drawn under the text (`HatchOverlay` below), a
##      texture cue that survives even if a display or a colourblind eye reads (1) as "close enough".
##   3. A "not open" ring-and-slash badge in a REAL top-right corner (`ClosedBadge`, positioned on
##      `tile` itself, not inside the `bg` PanelContainer - see the file-level comment above for why
##      that split exists) - the same brass-ring language the haul card's chips use.
##   4. The reason line in a dedicated muted-red tone instead of the soft grey an enabled subtitle
##      uses.
func _make_tile(index: int, title: String, sub: String, enabled: bool, reason: String) -> Control:
	var tile := Control.new()
	tile.name = "Tile_%d" % index
	tile.custom_minimum_size = TILE_SIZE
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_select(index, true)
			_confirm())

	var bg := PanelContainer.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(bg)
	_tile_bgs.append(bg)

	var hatch := HatchOverlay.new()
	hatch.name = "Hatch"
	hatch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hatch.visible = not enabled
	bg.add_child(hatch)   # first child of `bg`: drawn before `inner`, so text stays on top of it
	_hatches.append(hatch)

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(inner)

	var t := UIStyle.make_label(title, "", HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_font_size_override("font_size", 21)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(TILE_SIZE.x - 26.0, 46.0)
	inner.add_child(t)
	_titles.append(t)

	var s := UIStyle.make_label(sub if enabled else reason, "Soft", HORIZONTAL_ALIGNMENT_CENTER)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size = Vector2(TILE_SIZE.x - 26.0, 40.0)
	if not enabled:
		s.add_theme_color_override("font_color", DISABLED_REASON)
	inner.add_child(s)
	_subs.append(s)

	if not enabled:
		# A CHILD OF `tile`, NOT OF `bg`: `bg` is a PanelContainer and would stretch this full-rect
		# the same way the old bug did. `tile` is a plain Control, so this anchor preset + offset is
		# honoured and the badge lands in the corner it names.
		var badge := ClosedBadge.new()
		badge.name = "ClosedBadge"
		badge.custom_minimum_size = Vector2(26.0, 26.0)
		badge.size = Vector2(26.0, 26.0)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# NOT `set_anchors_preset` (round 2 regression caught in review, before this fix ever
		# shipped): calling it before `tile.add_child(badge)` computes the TOP_RIGHT offset against
		# a parent size of 0 (badge is not in the tree yet), so at real layout time - once `tile`
		# actually has its 212x156 size - the anchor math puts the badge off past the tile's right
		# edge entirely, invisible. `TILE_SIZE` is a fixed constant, not something the tile is
		# resized to later, so a plain top-left `position` (the default anchor, 0/0/0/0) is both
		# simpler and correct: no anchor conversion, no parent-size dependency.
		badge.position = Vector2(TILE_SIZE.x - 34.0, 8.0)
		tile.add_child(badge)

	_tiles.append(tile)
	return tile


## A closed ring with a slash through it - "not open", same drawn-not-imported language as every
## other icon in the safari (the haul card's Chip, the cockpit's aperture blades). `size` is fixed
## at `custom_minimum_size` above (26x26): unlike the old bug, nothing here stretches it.
class ClosedBadge extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r: float = minf(size.x, size.y) * 0.42
		draw_arc(c, r, 0.0, TAU, 24, PadModePicker.DISABLED_REASON, 2.5, true)
		var d := Vector2(0.72, -0.72).normalized() * r * 0.82
		draw_line(c - d, c + d, PadModePicker.DISABLED_REASON, 2.5, true)


## ROUND 2, the disabled tile's second cue (finding 3): faint diagonal stripes, an "out of service"
## texture that reads even where the flat-colour difference from `_refresh` does not. Inset from the
## tile's own edge so the lines stay inside `bg`'s rounded corners (`UIStyle.RADIUS_CARD`) rather
## than poking square corners past the curve.
class HatchOverlay extends Control:
	func _draw() -> void:
		var inset := 3.0
		var r := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			return
		var col := Color(PadModePicker.DISABLED_EDGE, 0.30)
		var step := 13.0
		var n := int(ceil((r.size.x + r.size.y) / step))
		# Every stripe runs bottom-left to top-right at slope -1: point(t) = (x0+d+t, y1-t). Clipping
		# a 45-degree line to an axis-aligned rect is just intersecting two 1-D ranges of `t`.
		for i in n:
			var d: float = -r.size.y + float(i) * step
			var t0: float = maxf(0.0, -d)
			var t1: float = minf(r.size.y, r.size.x - d)
			if t1 <= t0:
				continue
			var a := Vector2(r.position.x + d + t0, r.end.y - t0)
			var b := Vector2(r.position.x + d + t1, r.end.y - t1)
			draw_line(a, b, col, 2.0, true)


func _process(delta: float) -> void:
	if _closing:
		return
	if not _armed:
		_arm_timer -= delta
		if _arm_timer <= 0.0:
			_armed = true
	if Input.is_action_just_pressed("cancel"):
		_cancel()
		return
	if Input.is_action_just_pressed("interact"):
		_confirm()
		return
	var step := 0
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("camera_right"):
		step = 1
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("camera_left"):
		step = -1
	if step != 0:
		_select(wrapi(_index + step, 0, _tiles.size()), true)


func _select(index: int, click: bool) -> void:
	if index == _index or index < 0 or index >= _tiles.size():
		return
	_index = index
	_refresh()
	if click:
		UIStyle.play_tick()


func _confirm() -> void:
	if _closing or not _armed:
		return
	var enabled := true if _index == 0 else _photo_ok
	if not enabled:
		_deny()
		return
	var mode := "travel" if _index == 0 else "photo"
	_close()
	UIStyle.play_confirm()
	chosen.emit(mode)


func _deny() -> void:
	if _index < _tiles.size():
		UIStyle.wobble(_tiles[_index])
	UIStyle.play_cancel()


func _refresh() -> void:
	for i in _tiles.size():
		var on := i == _index
		var enabled := true if i == 0 else _photo_ok
		var chosen_look := on and enabled
		var tile := _tiles[i]
		var bg := _tile_bgs[i]
		if not enabled:
			# finding 5, round 2: a real second cue beyond colour - see `HatchOverlay` and the
			# `DISABLED_FILL` comment above. Style goes on `bg` now, not `tile` (`tile` is a plain
			# Control since the badge-position fix; it has no "panel" theme type of its own).
			bg.add_theme_stylebox_override("panel", UIStyle.make_panel_style(
				DISABLED_FILL, UIStyle.RADIUS_CARD, DISABLED_EDGE, 3, 0, 12.0))
		else:
			bg.add_theme_stylebox_override("panel", UIStyle.make_panel_style(
				UIStyle.WHITE if chosen_look else UIStyle.CREAM_INSET, UIStyle.RADIUS_CARD,
				UIStyle.YELLOW_EDGE if chosen_look else UIStyle.CREAM_EDGE, 4 if chosen_look else 2,
				10 if chosen_look else 0, 12.0))
		if i < _hatches.size() and _hatches[i] != null:
			_hatches[i].visible = not enabled
		_titles[i].add_theme_color_override("font_color",
			DISABLED_EDGE if not enabled else (UIStyle.TEXT_BROWN if on else UIStyle.TEXT_SOFT))
		# Selecting a disabled tile (arrow keys can still land on it) still gets full opacity - it
		# needs to be readable to explain itself - but it never gets the warm "chosen" treatment
		# above, so highlighting it cannot make it look available.
		tile.modulate.a = 1.0 if (on or enabled) else 0.82


func _cancel() -> void:
	if _closing:
		return
	_close()
	cancelled.emit()
	UIStyle.play_cancel()


func _close() -> void:
	_closing = true
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "offset", Vector2(0.0, 300.0), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(_scrim, "modulate:a", 0.0, 0.18)
	t.chain().tween_callback(queue_free)
