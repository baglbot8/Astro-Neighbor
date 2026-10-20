extends Control
## PROBE: each outing's title baked the way SafariIntro bakes it (its fit and cap height at this window, with the
## backdrop included in the fit), one at a time: atlas size and the texture memory it adds. `--bscale=X` overrides
## every style's backdrop_scale (what-if only). Not gameplay.
const FILES := {"zorp": "res://src/planet_safari/worlds/zorp.gd", "bolt": "res://src/planet_safari/worlds/bolt.gd",
	"fen": "res://src/planet_safari/worlds/fen.gd", "grig": "res://src/planet_safari/worlds/grig.gd",
	"vela": "res://src/planet_safari/worlds/vela.gd", "jungle": "res://src/planet_safari/worlds/jungle.gd",
	"meteor": "res://src/meteor_survey/meteor_survey_level.gd", "cave": "res://src/cave/cave_world.gd"}

func _mem() -> float:
	return Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0

func _ready() -> void:
	for i in 4:
		await get_tree().process_frame
	var bscale := -1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bscale="):
			bscale = float(a.substr(9))
	var stretch := get_tree().root.get_final_transform().get_scale().y
	var vp := get_viewport().get_visible_rect().size
	for pid: String in FILES:
		var w: Object = load(FILES[pid]).new()
		var data: Dictionary = w.call("intro_data") if w.has_method("intro_data") else {}
		if w is Node:
			(w as Node).free()
		var st := TitleLettering.full_style(data.get("title_style", {}))
		if bscale > 0.0:
			st["backdrop_scale"] = bscale
		var lines := PackedStringArray(data.get("title_lines", st.get("lines", [pid.to_upper()])))
		var m0 := _mem()
		var tl := TitleLettering.new()
		add_child(tl)
		tl.build(lines, st)
		var sub_h := 45.0
		var bs := tl.block_size
		var fit := minf((vp.y * SafariIntro.TITLE_MAX_H - sub_h - 14.0) / bs.y, vp.x * SafariIntro.TITLE_MAX_W / bs.x)
		var ext := Vector2(maxf(bs.x, tl.backdrop_extent.x), maxf(bs.y, tl.backdrop_extent.y))
		var g := 1.0 + SafariIntro.TITLE_GROW
		fit = minf(fit, minf((vp.x - 2.0 * SafariIntro.TITLE_EDGE * vp.y) / (ext.x * g), 2.0 * vp.y * (SafariIntro.C_TITLE_CENTER_Y - SafariIntro.TITLE_EDGE) / (ext.y * g)))
		tl.bake_start(TitleLettering.BUILD_CAP_PX * fit * g * stretch * SafariIntro.TITLE_BAKE_SCALE)
		await get_tree().process_frame
		await get_tree().process_frame
		var m1 := _mem()
		tl.bake_finish()
		print("ATLAS %s: backdrop_scale %.2f atlas %s = %.2f MB RGBA8, texmem +%.2f MB" % [pid, float(st.get("backdrop_scale", 0.5)),
			str(tl.atlas_size), tl.atlas_size.x * tl.atlas_size.y * 4.0 / 1048576.0, m1 - m0])
		tl.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	get_tree().quit()
