extends Node2D
## TITLE CONTACT SHEET (builder SINTRO, 2026-10-19): every outing's name in the planet lettering, baked exactly as
## the intro bakes it, plus Zorp's name through the example title file (backdrop + replacement glyph) to prove THE
## PLANET INTERFACE. Inert unless `--sit` is passed (tools/check.sh runs every showcase scene).
##   godot --path <copy> --rendering-method gl_compatibility --resolution 2556x1179 --always-on-top \
##     --position 100,100 --quit-after 600 res://showcase/safari_intro_titles.tscn -- --sit --sit-out=<abs png>

const NAMES := [["ZORP'S VIOLET", "HOLLOW"], ["BOLT'S CHROME", "YARD"], ["FEN'S LONG", "DUSK"],
	["GRIG'S CHALK", "STEPS"], ["VELA'S STILL", "FROST"], ["THE TANGLE"], ["THE CRYSTAL", "CAVE"], ["THE METEOR"],
	["ZORP'S VIOLET", "HOLLOW"], ["0123456789", "QXJ-K.MU"]]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--sit"):
		return
	var out := ""
	for a in args:
		if a.begins_with("--sit-out="):
			out = a.substr(10)
	var bg := ColorRect.new()
	bg.color = Color("#2a2340")
	bg.size = Vector2(4000, 3000)
	add_child(bg)
	var zw: Node = load("res://src/planet_safari/worlds/zorp.gd").new()
	var zstyle: Dictionary = zw.call("intro_title_style")
	zw.free()
	var vp := get_viewport().get_visible_rect().size
	var cols := 2
	var rows := 5
	var cell := Vector2(vp.x / cols, vp.y / rows)
	var titles: Array[TitleLettering] = []
	var fallbacks := 0
	for i in NAMES.size():
		var st := zstyle.duplicate()
		# The glyph rows show the bare stroke font (no crest behind every row); row 9 is the M2 mushroom T.
		st.erase("title_file")
		if i == 8:
			st["title_file"] = "res://src/planet_safari/titles/zorp_title.gd"
			st["title_preset"] = "mushroom_t"
			st["bulb_skip"] = "IT"
		var t := TitleLettering.new()
		add_child(t)
		t.build(PackedStringArray(NAMES[i]), TitleLettering.full_style(st))
		var k := minf(cell.x * 0.86 / t.block_size.x, cell.y * 0.8 / t.block_size.y)
		t.scale = Vector2.ONE * k
		t.position = Vector2(cell.x * (float(i % cols) + 0.5), cell.y * (float(i / cols) + 0.5))
		t.bake_start(TitleLettering.BUILD_CAP_PX * k * get_tree().root.get_final_transform().get_scale().y)
		titles.append(t)
		fallbacks += t.fallback_count()
	await get_tree().process_frame
	await get_tree().process_frame
	for t in titles:
		t.bake_finish()
		t.set_strength(1.0)
	await get_tree().process_frame
	await get_tree().process_frame
	print("SIT fallbacks=%d atlases=%s" % [fallbacks, str(titles.map(func(t: TitleLettering) -> Vector2i: return t.atlas_size))])
	if out != "":
		get_viewport().get_texture().get_image().save_png(out)
		print("SIT saved %s" % out)
	get_tree().quit()
