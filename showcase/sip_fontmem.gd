extends Control
## PROBE: the texture memory a card subtitle label leaves behind (Baloo 2's glyph cache), ONE variant per process
## (the cache is shared and only grows): --fm=size,outline,shadow_outline (shadow_outline -1 = no shadow).
func _mem() -> float:
	return Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	var cfg := PackedStringArray(["30", "7", "1"])
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fm="):
			cfg = a.substr(5).split(",")
	await _frames(5)
	var m0 := _mem()
	var l := Label.new()
	l.text = "The Glowing Garden"
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", int(cfg[0]))
	l.add_theme_color_override("font_color", UIStyle.CREAM)
	l.add_theme_color_override("font_outline_color", Color(UIStyle.NAVY, 0.85))
	l.add_theme_constant_override("outline_size", int(cfg[1]))
	if int(cfg[2]) >= 0:
		l.add_theme_color_override("font_shadow_color", Color(UIStyle.NAVY, 0.45))
		l.add_theme_constant_override("shadow_offset_y", 3)
		l.add_theme_constant_override("shadow_outline_size", int(cfg[2]))
	add_child(l)
	await _frames(3)
	var m1 := _mem()
	l.queue_free()
	await _frames(3)
	print("FONTMEM %s: +%.2f MB while drawn, +%.2f MB after free" % [",".join(cfg), m1 - m0, _mem() - m0])
	get_tree().quit()
