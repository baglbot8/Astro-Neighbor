class_name PrintGift
extends CanvasLayer
## SPIKE (2026-09-20, scratch only). GIVING a print to a neighbour — the other half of "a photo is
## worth more than its price". The user: "should we have taking photos more important than just
## giving you money?" This file is half the answer (the journal, sky_journal.gd, is the other half):
## a print handed to a neighbour raises friendship and is HUNG where the player can see it later, and
## it costs the player NOTHING from the journal — see the header note below.
##
## Deliberately NOT wired into the shared `Conversation` / `DialogueRunner` flow
## (src/dialogue/conversation.gd, src/characters/npc_data.gd): this builder owns two new files only
## (`sky_journal.gd`, this one) and does not touch Gloop's table or gloop_npc.gd, so touching the
## shared talk system that every other neighbour's favours and small talk depend on was out of scope
## for one round. Instead this opens its OWN small dialogue-style card, in the same visual language
## as SkyWatch's, over the "Give a print" button on a filled journal page. ROUGH ON THE PLUMBING,
## the box the player sees and the line the neighbour says are the real thing being judged.
##
## THREE NEIGHBOURS WANT A KIND OF SIGHT, one line each, read off their existing npc_data.gd voice
## (Fen's logbook and pools/light, Bolt's counting/precision, Grig's numbered steps/records):
##   FEN   wants AURORAS — the light-on-a-pool kind of sight her own notes already chase.
##   BOLT  wants PRECISION — any sight held at least 85% sharp, not any one kind.
##   GRIG  wants RECORDS — the rarest sights (rarity 3), something worth a number.
## A print that matches gets a warmer line and +3 friendship; any other print still gets a real
## reaction and +1 — the point is a neighbour is glad you thought of them even when you guessed wrong.
##
## GLOOP SELLS COPIES, so does every neighbour here: `open_picker` is handed a JOURNAL RECORD
## (sky_journal.gd's `record_for()`), which is read-only — nothing here calls a Journal setter, ever.
## The journal's page does not shrink, its "best shot" does not change, and its count does not drop.
## The hang's picture is a freshly RE-RENDERED copy from the record's own scalar fields (see
## `_render_hang_image`, the same shader technique as SkyWatch's own preview) — the journal's actual
## Image object is never touched, moved, or handed off. No print is EVER removed from `PrintBag`'s
## satchel either, because this never reads or writes PrintBag at all — giving and selling are two
## unrelated doors onto the same journal page.
##
## PERSISTENCE, HONESTLY: `GameState.flags["sky_gifts"]` (plain scalars only — id, day, hour,
## sharpness, world) survives a save exactly like PrintBag's own flags do. The framed PICTURE itself
## is rebuilt from that record with the real eyepiece shader (same technique as
## SkyWatch._render_preview), NOT re-saved as image bytes, so it looks right after a reload within
## the same running app. It has NOT been tested across an actual app relaunch this round — say what
## is unproven, CLAUDE.md — only within one continuous play session, which is what a real phone
## session actually is.
##
## THE HOUSE, HONESTLY: no neighbour has an interior in this build (checked — only hub buildings and
## the player's own home have scenes). "Hung in their house" is built here as a small standing frame
## on a post, planted at the neighbour's own home spot on their planet — a porch display, not a wall
## inside four walls. Good enough to judge the IDEA; not a real interior.
##
## Owned and instantiated by sky_journal.gd (`gift = PrintGift.new(); add_child(gift)`), so it needs
## no manual wiring — but it can be added anywhere the same way and driven directly for testing.

const EYE_SHADER := preload("res://src/sky/sky_eyepiece.gdshader")

const NPC_IDS := ["fen", "bolt", "grig"]

## One line of WHY, per neighbour, shown on the picker so the player can guess before giving.
const WANTS_BLURB := {
	"fen": "wants light on a pool — an aurora, for the logbook",
	"bolt": "wants precision — any sight held sharp, 85%+",
	"grig": "wants a record — the rarest sights, rarity 3",
}

## Reaction lines in each neighbour's own voice (read off npc_data.gd's existing greet/small_talk
## entries for tone — Fen: quiet, notices light and the logbook; Bolt: literal, counts things;
## Grig: numbers every riser). "liked" = matched their want; "any" = every other case.
const REACTIONS := {
	"fen": {
		"liked": [
			"Light on a pool. I will write the date beside it.",
			"Ah. The pools will like this one. Sit, look again.",
		],
		"any": [
			"A picture. The sky held still for you, then.",
			"I will find it a page. The book has room.",
		],
	},
	"bolt": {
		"liked": [
			"Ninety-one percent? No — check again. Excellent.",
			"Sharp edges. I am recalibrating my approval.",
		],
		"any": [
			"A picture! I will count the stars in it. Later.",
			"Logged. Filed under things I did not expect today.",
		],
	},
	"grig": {
		"liked": [
			"Rare. I will number it. Riser forty-one, I think.",
			"That one goes on the top step. It earned it.",
		],
		"any": [
			"A picture, from you, of the sky. I will keep it.",
			"Not numbered yet. Give me a moment. There. Six-B.",
		],
	},
}

const FRIENDSHIP_LIKED := 3
const FRIENDSHIP_ANY := 1

const FLAGS_KEY := "sky_gifts"  # GameState.flags[FLAGS_KEY] : npc_id -> record (see _store)

var journal: Node = null  # set by SkyJournal after add_child, so open_to() can jump back

var _pending: Dictionary = {}
var _root: Control
var _picker: PanelContainer
var _card: PanelContainer
var _card_line: Label
var _card_hung: Label


func _ready() -> void:
	layer = 44  # above the journal panel (42) and SkyWatch (40)
	name = "PrintGift"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	EventBus.planet_loaded.connect(_on_planet_loaded)
	call_deferred("_on_planet_loaded", GameState.current_planet_id)  # catch the world already loaded


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIStyle.theme()
	add_child(_root)

	_picker = PanelContainer.new()
	_picker.visible = false
	_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_picker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_picker.grow_vertical = Control.GROW_DIRECTION_BOTH
	_picker.add_theme_stylebox_override("panel", UIStyle.make_panel_style(SkyWatch.C_CREAM, 26))
	_root.add_child(_picker)

	_card = PanelContainer.new()
	_card.visible = false
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_card.add_theme_stylebox_override("panel", UIStyle.make_panel_style(SkyWatch.C_CREAM, 26))
	_root.add_child(_card)


# ------------------------------------------------------------------ the picker
## Public. `record` is a sky_journal.gd `record_for()` dict — READ-ONLY, never mutated here.
func open_picker(record: Dictionary) -> void:
	if record.is_empty():
		return
	_pending = record
	_fill_picker()
	_picker.visible = true
	_card.visible = false


func _fill_picker() -> void:
	for c in _picker.get_children():
		c.queue_free()
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 26)
	_picker.add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.custom_minimum_size = Vector2(680, 0)
	m.add_child(col)

	var ev: Dictionary = _pending.get("event", {})
	col.add_child(_head("Give \"%s\" to..." % str(ev.get("title", "a print"))))
	col.add_child(_small("The original stays in your journal. This is a copy, like Gloop sells."))

	for npc_id in NPC_IDS:
		var d := NpcData.get_data(npc_id)
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UIStyle.make_panel_style(Color("#e3e5ee"), 18))
		col.add_child(row)
		var mm := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			mm.add_theme_constant_override("margin_" + side, 12)
		row.add_child(mm)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		mm.add_child(hb)
		var txt := VBoxContainer.new()
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(txt)
		txt.add_child(_body(str(d.get("display_name", npc_id.capitalize()))))
		txt.add_child(_small(str(WANTS_BLURB.get(npc_id, ""))))
		hb.add_child(_mk_button("Give", func(): _give_to(npc_id)))

	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(foot)
	foot.add_child(_mk_button("Never mind", func(): _picker.visible = false))


func _matches(npc_id: String, rec: Dictionary) -> bool:
	var ev: Dictionary = rec.get("event", {})
	var sharp := float(rec.get("best_sharpness", 0.0))
	var rarity := int(ev.get("rarity", 1))
	match npc_id:
		"fen":
			return int(ev.get("kind", -1)) == SkyEvents.KIND_AURORA
		"bolt":
			return sharp >= 0.85
		"grig":
			return rarity >= 3
	return false


func _give_to(npc_id: String) -> void:
	if _pending.is_empty():
		return
	var rec := _pending
	var liked := _matches(npc_id, rec)
	var pool: Array = REACTIONS.get(npc_id, {}).get("liked" if liked else "any", ["Thank you."])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var line: String = pool[rng.randi_range(0, pool.size() - 1)]
	var gain := FRIENDSHIP_LIKED if liked else FRIENDSHIP_ANY

	GameState.add_friendship(npc_id, gain)
	UIStyle.play_sfx("friendship_up", -8.0)
	_store(npc_id, rec)
	_spawn_hang_if_present(npc_id)

	var d := NpcData.get_data(npc_id)
	_fill_card(str(d.get("display_name", npc_id.capitalize())), line, liked, gain)
	_picker.visible = false
	_card.visible = true
	EventBus.toast_requested.emit("%s: +%d friendship" % [str(d.get("display_name", npc_id)), gain], "star")


func _fill_card(display_name: String, line: String, liked: bool, gain: int) -> void:
	for c in _card.get_children():
		c.queue_free()
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 26)
	_card.add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(560, 0)
	m.add_child(col)
	col.add_child(_head(display_name))
	_card_line = _body("\"%s\"" % line)
	_card_line.autowrap_mode = TextServer.AUTOWRAP_WORD
	col.add_child(_card_line)
	col.add_child(_small(("Loved it — " if liked else "") + "+%d friendship" % gain))
	_card_hung = _small("Hung at %s's place. Walk by to see it." % display_name)
	col.add_child(_card_hung)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(foot)
	foot.add_child(_mk_button("Close", func(): _card.visible = false))


func _head(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", SkyWatch.C_TEXT)
	return l


func _body(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", SkyWatch.C_TEXT)
	return l


func _small(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", SkyWatch.C_SOFT)
	return l


func _mk_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_override("font", UIStyle.ui_font())
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", SkyWatch.C_TEXT)
	b.add_theme_stylebox_override("normal", UIStyle.make_pill_style(SkyWatch.C_CREAM))
	b.add_theme_stylebox_override("hover", UIStyle.make_pill_style(Color("#f6f7fb")))
	b.add_theme_stylebox_override("pressed", UIStyle.make_pill_style(Color("#d5d8e4")))
	b.pressed.connect(cb)
	return b


# ------------------------------------------------------------------ persistence (scalars only)
func _store(npc_id: String, rec: Dictionary) -> void:
	var ev: Dictionary = rec.get("event", {})
	var all: Dictionary = GameState.flags.get(FLAGS_KEY, {})
	if not (all is Dictionary):
		all = {}
	all[npc_id] = {
		"event_id": str(rec.get("event_id", "")),
		"title": str(ev.get("title", "A sight")),
		"kind": int(ev.get("kind", 0)),
		"tint_a": str(ev.get("tint_a", "#ffffff")),
		"tint_b": str(ev.get("tint_b", "#ffffff")),
		"sharpness": float(rec.get("best_sharpness", 0.0)),
		"day": int(rec.get("best_day", 0)),
		"hour": float(rec.get("best_hour", 0.0)),
	}
	GameState.flags[FLAGS_KEY] = all


func _hang_record(npc_id: String) -> Dictionary:
	var all: Dictionary = GameState.flags.get(FLAGS_KEY, {})
	if not (all is Dictionary):
		return {}
	var r: Variant = all.get(npc_id, {})
	return r if r is Dictionary else {}


# ------------------------------------------------------------------ the hang (a framed print in the world)
func _on_planet_loaded(_planet_id: String) -> void:
	for npc_id in NPC_IDS:
		if not _hang_record(npc_id).is_empty():
			_spawn_hang_if_present(npc_id)


## If `npc_id` is standing in the currently loaded world (world.gd names NPC children by npc id),
## plants — or replaces — their framed print near their own home spot. A no-op when they are not on
## the loaded planet; `_on_planet_loaded` calls this again the next time their world loads.
func _spawn_hang_if_present(npc_id: String) -> void:
	var rec := _hang_record(npc_id)
	if rec.is_empty():
		return
	var npc := get_tree().root.find_child(npc_id, true, false)
	if npc == null or not (npc is Node3D):
		return
	var planet := get_tree().get_first_node_in_group("planet")
	if planet == null:
		return
	var old := get_tree().root.find_child("PrintHang_%s" % npc_id, true, false)
	if old != null:
		old.queue_free()

	# resolve_home_dir(), not the `home_dir` var directly: the var only updates on the NPC's own
	# first physics frame (_place_home), and this can run before that frame — same reason
	# replay_board_prop.gd's _neighbour_homes() uses the same accessor (npc.gd's own comment on it).
	var home_dir: Vector3 = (npc as NPC).resolve_home_dir() if npc is NPC else Vector3.UP
	if home_dir.length_squared() < 0.0001:
		home_dir = (npc as Node3D).global_position.normalized()
	# A little off to the side of the neighbour's own spot, so the frame does not stand on top of them.
	var side := Vector3.UP.cross(home_dir)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT.cross(home_dir)
	side = side.normalized()
	var plant_dir := (home_dir + side * 0.09).normalized()

	var xf: Transform3D = planet.call("surface_transform", plant_dir, -side)
	var hang := await _build_hang_node(npc_id, rec)
	hang.global_transform = xf
	(planet as Node).add_child(hang)


func _build_hang_node(npc_id: String, rec: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "PrintHang_%s" % npc_id
	var accent := Color(str(NpcData.get_data(npc_id).get("accent", "#8a8fae")))

	var post := MeshInstance3D.new()
	post.name = "Post"
	var pc := CylinderMesh.new()
	pc.top_radius = 0.028
	pc.bottom_radius = 0.034
	pc.height = 1.05
	pc.radial_segments = 8
	pc.material = _mat(Color("#3a3f57"), 0.5)
	post.mesh = pc
	post.position = Vector3(0.0, 0.525, 0.0)
	root.add_child(post)

	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var fb := BoxMesh.new()
	fb.size = Vector3(0.40, 0.40, 0.03)
	fb.material = _mat(accent, 0.4)
	frame.mesh = fb
	frame.position = Vector3(0.0, 1.10, 0.0)
	frame.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	root.add_child(frame)

	var pic := MeshInstance3D.new()
	pic.name = "Picture"
	var pm := QuadMesh.new()
	pm.size = Vector2(0.32, 0.32)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_texture = ImageTexture.create_from_image(await _render_hang_image(rec))
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Visible from either side: this is a freestanding easel (see the header's honesty note on "the
	# house"), and a player can walk up to it from any direction on an open planet surface.
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pm.material = pmat
	pic.mesh = pm
	pic.position = Vector3(0.0, 1.10, 0.019)
	pic.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	root.add_child(pic)

	var label3d := Label3D.new()
	label3d.name = "Label"
	label3d.text = str(rec.get("title", "A print"))
	label3d.font_size = 34
	label3d.outline_size = 10
	label3d.pixel_size = 0.0026
	label3d.position = Vector3(0.0, 0.86, 0.0)
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label3d)
	return root


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


## Re-renders the print with the REAL eyepiece shader from the stored scalar fields — see the header
## note on persistence. Same 192x192 one-shot SubViewport technique as SkyWatch._render_preview.
func _render_hang_image(rec: Dictionary) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(192, 192)
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.disable_3d = true
	add_child(vp)
	var rect := ColorRect.new()
	rect.size = Vector2(192, 192)
	var mat := ShaderMaterial.new()
	mat.shader = EYE_SHADER
	rect.material = mat
	vp.add_child(rect)
	var id := str(rec.get("event_id", "x"))
	var day_n := int(rec.get("day", 0))
	mat.set_shader_parameter("kind", int(rec.get("kind", 0)))
	mat.set_shader_parameter("tint_a", Color(str(rec.get("tint_a", "#ffffff"))))
	mat.set_shader_parameter("tint_b", Color(str(rec.get("tint_b", "#ffffff"))))
	# Same seed formula SkyWatch.start_watch uses (id + day), so a re-render matches the moment it
	# was actually taken rather than drawing a random new pattern each time.
	mat.set_shader_parameter("seed", 1.0 + float(abs(hash(id + str(day_n))) % 1000) * 0.017)
	mat.set_shader_parameter("t", 1.2)
	mat.set_shader_parameter("aim", Vector2.ZERO)
	var sharp := float(rec.get("sharpness", 0.7))
	mat.set_shader_parameter("blur", clampf(1.0 - sharp, 0.0, 1.0) * 0.75)
	mat.set_shader_parameter("sky_light", 0.0)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


# ------------------------------------------------------------------ debug hooks (captures)
func debug_open(record: Dictionary) -> void:
	open_picker(record)


func debug_give(npc_id: String) -> void:
	_give_to(npc_id)


func debug_close() -> void:
	_picker.visible = false
	_card.visible = false


func debug_hang_count() -> int:
	var all: Dictionary = GameState.flags.get(FLAGS_KEY, {})
	return all.size() if all is Dictionary else 0
