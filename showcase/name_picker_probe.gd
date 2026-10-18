extends Node
## Director probe for the opening flow (tests/director/flow_*.json). Spawned with
##   {"call": {"node": "/root/World", "method": "_spawn_optional", "args": ["res://showcase/name_picker_probe.tscn", "FlowProbe"]}}
## Prints the end state the skip and played paths must agree on, and taps NamePicker pills.
## Does nothing on its own (tools/check.sh runs it as a scene for 3 s).

const FLAGS := ["intro_crash_done", "intro_greeted", "intro_beat_move", "intro_beat_scrap",
	"intro_beat_rocket", "intro_beat_fly", "intro_done"]


var _confirms := 0


func _ready() -> void:
	# Counts skip pop-ups: SkipConfirm's ConfirmPopup opens the "confirm" modal once per question.
	EventBus.ui_modal_opened.connect(func(m: String) -> void:
		if m == "confirm":
			_confirms += 1
			print("FLOWPROBE confirm pop-up #%d opened" % _confirms))


func state(tag: String) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	var pad := get_node_or_null("/root/World/Rocket")
	var rocket: Node3D = pad.get("rocket") as Node3D if pad != null else null
	var f := {}
	for k in FLAGS:
		f[k] = GameState.flag(k)
	var cam := get_viewport().get_camera_3d()
	print("FLOWPROBE [%s] flags=%s name=%s player=%s visible=%s input=%s modals=%s finish=%s rocket=%s cam=%s crash=%s cockpit=%s confirms=%d fade=%.2f" % [
		tag, str(f), str(GameState.player_style.get("name", "")),
		str(p.global_position.snapped(Vector3.ONE * 0.001)) if p != null else "-",
		str(p.visible) if p != null else "-", str(p.get("input_enabled")) if p != null else "-",
		str(EventBus.open_modals()),
		str(rocket.call("finish_stage")) if rocket != null else "-",
		str(rocket.global_position.snapped(Vector3.ONE * 0.001)) if rocket != null else "-",
		cam.name if cam != null else "-",
		str(get_node_or_null("/root/World/Onboarding/CrashIntro") != null),
		str(get_node_or_null("/root/World/Onboarding/CockpitIntro") != null), _confirms,
		(SceneRouter.get("_fade") as ColorRect).color.a if SceneRouter.get("_fade") != null else -1.0])


func tap(which: String) -> void:
	var picker := get_tree().root.find_child("NamePicker", true, false)
	if picker == null:
		print("FLOWPROBE tap %s: no picker open" % which)
		return
	picker.call("debug_tap", which)


func picker_report(tag: String) -> void:
	var picker := get_tree().root.find_child("NamePicker", true, false)
	if picker == null:
		print("FLOWPROBE picker_report %s: no picker open" % tag)
		return
	picker.call("debug_report", tag)
