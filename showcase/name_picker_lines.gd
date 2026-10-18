extends Node
## LINE-LENGTH GATE for the 2026-10-18 opening (docs/INTRO_SPEC.md 9, gate 2). Reads the radio call's
## source (`IntroDirector._campaign_call`) and the Day-1 letter (`player_home.gd` `_on_mail`), lists
## every box, and fails any box over MAX_CHARS. A box with "\n" is an older two-line box and is checked
## line by line; every box new on 2026-10-18 is a single line and is checked whole. "%s" is filled with
## the longest NamePicker name. A failure is a push_error, so tools/check.sh (which runs every showcase)
## goes red on it.
##   godot --headless --path . res://showcase/name_picker_lines.tscn

const MAX_CHARS := 60
const SOURCES := [
	["res://src/onboarding/intro_director.gd", "func _campaign_call("],
	["res://src/hub/buildings/player_home.gd", "func _on_mail("],
]


func _ready() -> void:
	var longest := ""
	for n in NamePicker.NAMES:
		if n.length() > longest.length():
			longest = n
	var consts := {
		"CALL_HURT": IntroDirector.CALL_HURT, "CALL_ASK_NAME": IntroDirector.CALL_ASK_NAME,
		"CALL_WELCOME": IntroDirector.CALL_WELCOME, "CALL_SHIP": IntroDirector.CALL_SHIP,
		"CALL_BUSY": IntroDirector.CALL_BUSY, "CALL_MEET": IntroDirector.CALL_MEET,
		"CALL_HOP": IntroDirector.CALL_HOP,
	}
	var boxes: Array[String] = []
	for src: Array in SOURCES:
		var body := _function_body(str(src[0]), str(src[1]))
		if body == "":
			push_error("LINECHECK: could not find %s in %s" % [src[1], src[0]])
			continue
		var re := RegEx.new()
		re.compile("\"((?:[^\"\\\\]|\\\\.)*)\"|\\b(CALL_[A-Z_]+)\\b")
		for m in re.search_all(body):
			var s := m.get_string(1) if m.get_string(2) == "" else str(consts.get(m.get_string(2), ""))
			if s.strip_edges() == "" or s.begins_with("res://") or s.length() < 4:
				continue
			boxes.append(s.replace("\\n", "\n").replace("%s", longest).replace("%d", "99"))
	var bad := 0
	var worst := 0
	for b in boxes:
		var parts := b.split("\n")
		var n := 0
		for p in parts:
			n = maxi(n, p.length())
		worst = maxi(worst, n)
		var mark := "ok  " if n <= MAX_CHARS else "LONG"
		if n > MAX_CHARS:
			bad += 1
		print("LINECHECK %s %2d %s" % [mark, n, b.replace("\n", " | ")])
	print("LINECHECK boxes=%d longest=%d over_%d=%d (name filled as %s)" % [boxes.size(), worst, MAX_CHARS, bad, longest])
	if bad > 0:
		push_error("LINECHECK: %d box(es) over %d characters" % [bad, MAX_CHARS])
	get_tree().quit(1 if bad > 0 else 0)


static func _function_body(path: String, header: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	var i := text.find(header)
	if i < 0:
		return ""
	var j := text.find("\nfunc ", i + header.length())
	var body := text.substr(i, (j - i) if j > 0 else -1)
	# Comment lines quote words too; they are not boxes.
	var kept: PackedStringArray = []
	for line in body.split("\n"):
		if not line.strip_edges().begins_with("#"):
			kept.append(line)
	return "\n".join(kept)
