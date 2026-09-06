extends Control
## Onboarding showcase: the favour log and the hint channel, on a schedule, with the real HUD so
## toasts and the dialogue box behave exactly as they do in game.
##
##   tools/capture.sh showcase/onboarding_journal.tscn onboarding 540
##
## The tour, in order:
##   0.5 s   the log with three favours — including the critic's exact case, Zorp asking for
##           Stardust Shards, with "Found on Little Orbit, Starport Plaza" underneath
##   5.0 s   log closes; three hints are requested WHILE a conversation is open — nothing appears
##   9.0 s   the conversation ends and the hints arrive one at a time, MIN_GAP apart
##  14.0 s   the same three hints are requested again — nothing appears, because they are seen
##  16.0 s   favours cleared: the day-one log, which becomes a field guide of what grows where
##  20.0 s   STRESS: one favour from every neighbour in the game at once — the list scrolls, the
##           panel does not grow past the window and no row overflows
##
## The intro itself is not here — a radio call needs the real world, so it is played in
## src/world/world.tscn with tests/director/intro_first_run.json.

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")

var _hud: Hud
var _journal: JournalPanel
var _t := 0.0
var _next := 0
var _steps: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := Backdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_journal = JournalPanel.new()
	_journal.name = "JournalPanel"
	_hud.add_child(_journal)
	HintChannel.get_or_create()
	HintChannel.reset_all()
	_seed_favors()
	_steps = [
		[0.4, func() -> void: _journal.open(false)],
		[5.0, func() -> void: _journal.close()],
		[5.6, func() -> void: _talk()],
		[5.9, func() -> void: _request_hints()],
		[9.0, func() -> void: _hud.dialogue_box.hide_box()],
		[14.0, func() -> void: _request_hints()],
		[16.0, func() -> void:
			GameState.favors.clear()
			_journal.open(false)],
		[19.5, func() -> void: _journal.close()],
		[20.0, func() -> void:
			_seed_every_npc()
			_journal.open(false)],
		[22.5, func() -> void: _scroll_down()],
		[25.0, func() -> void: _scroll_down()],
	]


func _seed_favors() -> void:
	# The exact shape the integration critic complained about: an errand for something that does
	# not grow where the neighbour lives.
	GameState.favors = {
		"zorp_demo": {"id": "zorp_demo", "npc": "zorp", "type": "bring", "target_item": "stardust_shard",
			"count": 3, "progress": 1, "state": "active", "reward_stardust": 90, "deliver_to": ""},
		"bolt_demo": {"id": "bolt_demo", "npc": "bolt", "type": "fetch", "target_item": "gear_bit",
			"count": 4, "progress": 4, "state": "active", "reward_stardust": 120, "deliver_to": ""},
		"mayor_demo": {"id": "mayor_demo", "npc": "mayor_orbit", "type": "deliver", "target_item": "gift_mayor_orbit",
			"count": 1, "progress": 0, "state": "active", "reward_stardust": 70, "deliver_to": "zorp"},
	}
	GameState.add_item("gift_mayor_orbit")


## Stress: every neighbour in the game wants something at once.
func _seed_every_npc() -> void:
	GameState.favors.clear()
	var kinds := ["fetch", "bring", "deliver"]
	var items := ["gear_bit", "stardust_shard", "crystal_chunk", "moon_flower"]
	var i := 0
	for npc_id: String in NpcData.ids():
		var kind: String = kinds[i % kinds.size()]
		var f := {
			"id": "stress_%s" % npc_id, "npc": npc_id, "type": kind,
			"target_item": items[i % items.size()], "count": 2 + (i % 3), "progress": i % 3,
			"state": "active", "reward_item": "", "reward_stardust": 90, "deliver_to": "",
		}
		if kind == "deliver":
			f["target_item"] = "gift_%s" % npc_id
			f["count"] = 1
			f["deliver_to"] = "bolt" if npc_id != "bolt" else "zorp"
		GameState.favors[str(f["id"])] = f
		i += 1


func _scroll_down() -> void:
	Input.action_press("move_back")
	await get_tree().create_timer(0.9).timeout
	Input.action_release("move_back")


func _talk() -> void:
	_hud.dialogue_box.show_lines("Zorp", [
		"A hint should never land on top of me.",
		"That is the whole point of the channel.",
	], "alien", Color("#8a4fe8"))


func _request_hints() -> void:
	HintChannel.request("demo_move", "Have a wander — WASD walks, Shift runs.", "star")
	HintChannel.request("demo_collect", "Yellow shards are Stardust. Press E to grab one.", "stardust_shard")
	HintChannel.request("demo_place", "Press Tab to open your bag and place something.", "deco_moon_lamp")


func _process(delta: float) -> void:
	_t += delta
	while _next < _steps.size() and _t >= float(_steps[_next][0]):
		var cb: Callable = _steps[_next][1]
		cb.call()
		_next += 1


## Thin-atmosphere backdrop (docs/STYLE_GUIDE.md R2.1): near-black zenith, a warm dust rim at the
## limb, stars in daylight, and a muted pastel meadow arc. Matches gameplay values so the panel is
## judged against the contrast it really sits on.
class Backdrop extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var horizon := h * 0.62
		var steps := 30
		for i in steps:
			var f := float(i) / float(steps - 1)
			var c := Color("#0a0f2e").lerp(Color("#3b3350"), pow(f, 1.7))
			draw_rect(Rect2(0.0, horizon * float(i) / float(steps), w, horizon / float(steps) + 1.0), c)
		draw_rect(Rect2(0.0, horizon - 26.0, w, 26.0), Color("#6a5a58"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for _i in 150:
			var p := Vector2(rng.randf() * w, rng.randf() * (horizon - 30.0))
			draw_circle(p, rng.randf_range(0.6, 1.4), Color(1, 1, 1, rng.randf_range(0.25, 0.8)))
		# planet limb: a calm arc, not a wobbly line
		var ground := Color("#5d8f5f")
		draw_rect(Rect2(0.0, horizon, w, h - horizon), ground)
		var pts := PackedVector2Array()
		pts.append(Vector2(0.0, h))
		for i in 41:
			var x := w * float(i) / 40.0
			var t := (float(i) / 40.0) * 2.0 - 1.0
			pts.append(Vector2(x, horizon + 54.0 * t * t))
		pts.append(Vector2(w, h))
		draw_colored_polygon(pts, ground)
		# gentle, low-contrast banding only (docs/STYLE_GUIDE.md: variation must be tasteful)
		for i in 9:
			var y := horizon + 64.0 + float(i) * 26.0
			if y > h:
				break
			draw_rect(Rect2(0.0, y, w, 13.0), ground.darkened(0.05))
