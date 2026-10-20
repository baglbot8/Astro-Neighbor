extends Node2D
## TITLE STILLS for the Tangle's and the Meteor's draft lettering (builder JUNGLE+METEOR intro, 2026-10-20). A test
## harness: inert unless `--smt` is passed (tools/check.sh runs every showcase scene). Bakes one outing's title exactly
## as SafariIntro does (its `intro_data()` style, TitleLettering.bake_start/bake_finish) over an optional background
## frame, at the intro's scene-1 place and size, at strength `--smt-alpha`, and saves the frame.
##   godot --path <copy> --rendering-method gl_compatibility --resolution 2556x1179 --always-on-top --position 100,100 \
##     --quit-after 600 res://showcase/safari_intro_meteor_titles.tscn -- --smt --smt-planet=jungle|meteor \
##     [--smt-bg=<abs png>] [--smt-alpha=1.0] --smt-out=<abs png>


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--smt"):
		return
	var out := ""
	var bg_path := ""
	var alpha := 1.0
	var which := "jungle"
	for a in args:
		if a.begins_with("--smt-out="):
			out = a.substr(10)
		elif a.begins_with("--smt-bg="):
			bg_path = a.substr(9)
		elif a.begins_with("--smt-alpha="):
			alpha = float(a.substr(12))
		elif a.begins_with("--smt-planet="):
			which = a.substr(13)
	var vp := get_viewport().get_visible_rect().size
	var bg := ColorRect.new()
	bg.color = Color("#2a2340")
	bg.size = vp
	add_child(bg)
	if bg_path != "":
		var img := Image.load_from_file(bg_path)
		if img != null:
			var tr := TextureRect.new()
			tr.texture = ImageTexture.create_from_image(img)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.size = vp
			add_child(tr)
	var data: Dictionary
	if which == "meteor":
		data = MeteorSurveyLevel.intro_data()
	else:
		var jw: Node = load("res://src/planet_safari/worlds/jungle.gd").new()
		data = jw.call("intro_data")
		jw.free()
	var st := TitleLettering.full_style(data.get("title_style", {}))
	var t := TitleLettering.new()
	add_child(t)
	t.build(PackedStringArray(data["title_lines"]), st)
	# SafariIntro's fit: the block (plus a subtitle line) in 40% of the height, 80% of the width; centre at 0.40.
	var sub_h := 44.0
	var fit := minf((vp.y * SafariIntro.TITLE_MAX_H - sub_h - 14.0) / t.block_size.y, vp.x * SafariIntro.TITLE_MAX_W / t.block_size.x)
	t.scale = Vector2.ONE * fit
	var block_h := t.block_size.y * fit + 14.0 + sub_h
	var top := vp.y * SafariIntro.C_TITLE_CENTER_Y - block_h * 0.5
	t.position = Vector2(vp.x * 0.5, top + t.block_size.y * fit * 0.5)
	var stretch := get_tree().root.get_final_transform().get_scale().y
	t.bake_start(TitleLettering.BUILD_CAP_PX * fit * stretch * SafariIntro.TITLE_BAKE_SCALE)
	var sub := Label.new()
	sub.text = str(data.get("subtitle", ""))
	sub.add_theme_font_override("font", UIStyle.ui_font())
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", UIStyle.CREAM)
	sub.add_theme_color_override("font_outline_color", Color(UIStyle.NAVY, 0.85))
	sub.add_theme_constant_override("outline_size", 7)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(vp.x, sub_h)
	sub.position = Vector2(0.0, top + t.block_size.y * fit + 14.0)
	sub.modulate.a = alpha
	add_child(sub)
	await get_tree().process_frame
	await get_tree().process_frame
	t.bake_finish()
	t.set_strength(alpha)
	for i in 20:
		await get_tree().process_frame
	print("SMT %s fallbacks=%d atlas=%s block=%s fit=%.3f" % [which, t.fallback_count(), str(t.atlas_size),
		str(t.block_size), fit])
	if out != "":
		var shot := get_viewport().get_texture().get_image()
		shot.save_png(out)
		print("SMT saved %s %dx%d" % [out, shot.get_width(), shot.get_height()])
	get_tree().quit()
