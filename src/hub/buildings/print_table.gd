class_name PrintTable
extends Building
## GLOOP'S PRINT TABLE on the Commons (sky-watching spike, 2026-09-20).
##
## THE WHOLE POINT: there is NO SHOP MENU. You walk up, you press interact once, and the loop moves
## one step. The table decides which step that is:
##
##   1. you are carrying prints        -> Gloop takes ALL of them in one tap, says something about
##                                        the best one, and they go on the table overnight
##   2. you handed some in earlier today -> Gloop tells you to come back in the morning
##   3. a batch has been on the table since an earlier day -> THE PAYOUT: coins, which one sold
##                                        best, and WHY ("Fen bought two. He says the light was
##                                        wrong.") — the why is the hook for the next night
##   4. nothing to do                  -> one line of Gloop
##
## The same four steps run whether you press on the TABLE or on GLOOP (gloop_npc.gd calls
## `run_flow` straight through), because "walk up and press once" is the interaction being tested
## and making the player find the right collider is not.
##
## IT ALSO OWNS GLOOP. `_on_attached` spawns `gloop.tscn` beside the table and pins its home there,
## so this spike adds ONE id to hub.tres (`buildings`) and nothing else to any shared file.
##
## Print shape: see `src/spike/print_bag.gd` — a plain Dictionary with id / name / rarity /
## sharpness / when, stored in `GameState.flags`. The SKY builder only has to call
## `PrintBag.add(...)` (or `PrintTable.give_print(...)`) when the telescope makes one.

const GLOOP_SCENE := "res://src/characters/npcs/gloop.tscn"

## Where the table stands on the Commons: about 8 m from the plaza centre, off toward the clothes
## store side, so it is in shot the moment you land but not on the spawn disc or a building's steps.
## Not in `Planet.HUB_BUILDING_DIRS` (a shared file); `attach_to_planet` is overridden instead.
## Away from the rocket pad (`pad_dir` 0.55/0.75/0.35) and the bunting round it — the first
## placement put the stall inside the pad's flags and Gloop read as part of the rocket.
const TABLE_DIR := Vector3(-0.270, 0.836, 0.478)
## Gloop stands at the far END of the table, not behind it: behind a 0.85 m top, a 1.05 m blob is a
## head poking over a plank. At the end the whole silhouette is in the shot. Table-local metres.
const GLOOP_STAND := Vector3(-1.55, 0.0, 0.45)

# --- palette. Deliberately plainer than the shop buildings: this is a trestle and a crate.
const TOP := Color("#c08b52")
const TOP_DARK := Color("#8a5f37")
const LEG := Color("#6a4726")
const CLOTH := Color("#c0aa83")   ## warm cream. Round 1 used a blue-grey and the table read as a blue slab under moonlight.
const CARD := Color("#d2c7ae")
const CARD_INK := Color("#4c4436")
const LAMP := Color("#ffd489")

var _gloop: Node = null
## Print cards standing on the table — rebuilt whenever the table's contents change, so a full
## table LOOKS full. Rough: three cards maximum, and they are flat rectangles.
var _cards: Node3D
var _last_card_count: int = -1
var _prompt_poll: float = 0.0


func _init() -> void:
	building_id = "print_table"
	display_name = "Gloop's Table"
	ground_sink = 0.06
	footprint_size = Vector3(2.30, 0.95, 0.90)
	footprint_offset = Vector3(0.0, 0.0, 0.0)
	door_local = Vector3(0.0, 0.95, -0.95)
	door_prompt = "Hand in prints"


# ==================================================================================== placement
## The Commons does not know this building id, and `Planet.HUB_BUILDING_DIRS` is a shared file, so
## the table places itself. Same rule as the base class otherwise: sit on the surface, face the
## plaza centre.
func attach_to_planet(p: Planet) -> void:
	planet = p
	if p == null:
		return
	var dir := TABLE_DIR.normalized()
	var here := p.surface_point(dir)
	var centre := p.surface_point(p.data.spawn_dir.normalized() if p.data != null else dir)
	var toward_plaza := centre - here
	if toward_plaza.length_squared() < 0.0001:
		toward_plaza = Vector3.FORWARD
	global_transform = p.surface_transform(dir, toward_plaza)
	global_position -= global_transform.basis.y * ground_sink
	_on_attached(p, dir)


func _on_attached(p: Planet, dir: Vector3) -> void:
	_clear_pitch(p)
	_spawn_gloop(p, dir)
	_refresh_cards()


## CLEARS THE PITCH. `Planet` flattens and reserves a disc for every id in `data.buildings` that
## `building_dir()` knows — and it does not know "print_table", because that dictionary lives in
## planet.gd, a shared file this spike does not touch. So the scatter pass drops flowers, rocks and
## collectibles straight through the table and Gloop stands in a flowerbed (measured: round 1 put a
## flower patch under Gloop's feet). This deletes whatever landed inside the stall's footprint.
##
## ROUGH AND HONEST: the real fix is one line in `Planet.HUB_BUILDING_DIRS` plus a flat disc, which
## the lead should make if this spike is kept. Deleting props after the fact leaves the GROUND
## un-flattened under the table, so the legs can still sit on a slope.
const PITCH_CLEAR_M := 2.6


func _clear_pitch(p: Planet) -> void:
	var centre := global_position
	var world := get_tree().root.get_node_or_null("World")
	if world == null or p == null:
		return
	for branch_name in ["Props", "Decorations", "Collectibles", "TrashField", "Planet"]:
		var branch := world.find_child(branch_name, true, false)
		if branch == null:
			continue
		_clear_under(branch, centre)


func _clear_under(n: Node, centre: Vector3) -> void:
	for c: Node in n.get_children():
		if c is Node3D and (c as Node3D).global_position.distance_to(centre) < PITCH_CLEAR_M:
			print("[PrintTable] cleared prop ", c.name, " at ", (c as Node3D).global_position.distance_to(centre), " m")
			c.queue_free()
		else:
			_clear_under(c, centre)


## Spawns Gloop behind the table. Done here and not from `hub.tres`'s npc list so the neighbour is
## pinned to the table instead of wandering the plaza, and so this spike touches one shared line.
func _spawn_gloop(p: Planet, dir: Vector3) -> void:
	if not ResourceLoader.exists(GLOOP_SCENE):
		push_warning("PrintTable: missing " + GLOOP_SCENE)
		return
	var n: Node = load(GLOOP_SCENE).instantiate()
	n.name = "gloop"
	# a point GLOOP_BEHIND metres along the table's own +Z (away from the plaza), as a direction
	var behind_point := global_transform * GLOOP_STAND
	var behind_dir := (behind_point - p.global_position).normalized()
	n.set("spike_home", behind_dir)
	n.set("spike_table", self)
	n.set("planet", p)
	get_parent().add_child(n)
	_gloop = n


func gloop() -> Node:
	return _gloop if is_instance_valid(_gloop) else null


# ==================================================================================== geometry
func _build() -> void:
	var wood := DecoKit.new()
	var kit := DecoKit.new()
	var metal := DecoKit.new()

	# trestle top, with a lip so prints do not read as floating
	wood.rbox(Vector3(0.0, 0.80, 0.0), Vector3(2.20, 0.10, 0.80), 0.03, TOP, Basis.IDENTITY, 1)
	wood.rbox(Vector3(0.0, 0.73, 0.0), Vector3(2.10, 0.06, 0.72), 0.02, TOP_DARK, Basis.IDENTITY, 0)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			wood.rbox(Vector3(0.92 * sx, 0.36, 0.28 * sz), Vector3(0.10, 0.72, 0.10), 0.02, LEG, Basis.IDENTITY, 0)
		# cross brace, so the legs are a trestle and not four sticks
		wood.rbox(Vector3(0.92 * sx, 0.24, 0.0), Vector3(0.07, 0.07, 0.62), 0.02, LEG, Basis.IDENTITY, 0)
	wood.rbox(Vector3(0.0, 0.24, 0.0), Vector3(1.80, 0.07, 0.07), 0.02, LEG, Basis.IDENTITY, 0)

	# a narrow cloth at the back edge and a short front drape. Round 1 ran a wide blue-grey runner
	# across the whole top and the table READ AS A BLUE SLAB at 6 m, not as timber.
	kit.rbox(Vector3(0.0, 0.856, 0.30), Vector3(2.24, 0.03, 0.18), 0.01, CLOTH, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.66, -0.41), Vector3(2.24, 0.22, 0.03), 0.01, CLOTH, Basis.IDENTITY, 0)

	# the crate the sold prints go into, at Gloop's end
	wood.rbox(Vector3(0.80, 0.98, 0.18), Vector3(0.46, 0.26, 0.34), 0.02, TOP_DARK, Basis.IDENTITY, 0)
	wood.rbox(Vector3(0.80, 1.12, 0.18), Vector3(0.48, 0.04, 0.36), 0.01, TOP, Basis.IDENTITY, 0)

	# a lamp post at the far end, so the table is findable at night (nights are long now)
	metal.bar(Vector3(1.22, 0.0, 0.34), Vector3(1.22, 1.85, 0.34), 0.035, METAL_DARK, 8)
	metal.rbox(Vector3(1.22, 1.92, 0.34), Vector3(0.22, 0.18, 0.22), 0.04, BRONZE, Basis.IDENTITY, 0)

	add_wood(wood.commit(), Vector3.UP, "Timber")
	add_body(kit.commit(), "Cloth")
	add_metal(metal.commit(), "Post")

	var glow := DecoKit.new()
	glow.sphere(Vector3(1.22, 1.92, 0.34), 0.10, LAMP)
	add_glow(glow.commit(), 2.2, "LampGlow")
	add_light(Vector3(1.22, 1.86, 0.34), LAMP, 1.6, 6.5)

	_cards = pivot("Cards", Vector3.ZERO)
	animate()
	# NO extra interactable here. `Building._ready()` already makes one at `door_local` with
	# `door_prompt` wired to `_on_door` — adding a second put two prompts on the same 2 m of table.


## The prompt is the whole UI. It has to say which of the four steps pressing will run, or the
## player has no idea whether walking over is worth it — polled, not per frame, because the day can
## roll over while you stand there.
func _animate(_time: float, delta: float) -> void:
	_prompt_poll -= delta
	if _prompt_poll > 0.0:
		return
	_prompt_poll = 0.5
	if door == null:
		return
	var want := "Talk to Gloop"
	if PrintBag.payout_ready():
		want = "Take earnings"
	elif PrintBag.bag_count() > 0:
		want = "Hand in prints"
	if door.prompt_text != want:
		door.prompt_text = want
	_refresh_cards()


## Up to three print cards standing on the table, one per print waiting to sell. Rough on purpose:
## flat rectangles with a dark band for the picture.
func _refresh_cards() -> void:
	if _cards == null:
		return
	var n: int = mini(PrintBag.table().size(), 3)
	if n == _last_card_count:
		return
	_last_card_count = n
	for c: Node in _cards.get_children():
		c.queue_free()
	if n <= 0:
		return
	var kit := DecoKit.new()
	for i in n:
		var x := -0.55 + 0.52 * float(i)
		var lean := Basis(Vector3.RIGHT, 0.22)
		kit.rbox(Vector3(x, 1.06, 0.10), Vector3(0.40, 0.44, 0.03), 0.01, CARD, lean, 0)
		kit.rbox(Vector3(x, 1.08, 0.085), Vector3(0.32, 0.30, 0.02), 0.01, CARD_INK, lean, 0)
	var mi := MeshInstance3D.new()
	mi.name = "CardMeshes"
	mi.mesh = kit.commit()
	mi.material_override = body_material()
	_cards.add_child(mi)


# =================================================================================== the flow
## The base class wires this to the interactable it builds at `door_local`.
func _on_door(player: Node3D) -> void:
	await run_flow(player)


## THE ONE TAP. Public, because gloop_npc.gd routes the neighbour's own interact straight here.
func run_flow(player: Node3D = null) -> void:
	if not _flow_guard(player):
		return
	var g := gloop()
	if g != null and g.has_method("attend"):
		g.call("attend", player)
	if PrintBag.payout_ready():
		await _payout()
	elif PrintBag.bag_count() > 0:
		await _hand_in()
	elif not PrintBag.table().is_empty():
		await _say([GloopLines.any(GloopLines.WAITING)])
	else:
		await _idle_chat()
	if g != null and g.has_method("release"):
		g.call("release")
	_refresh_cards()
	end_flow()


## Like `begin_flow` but without the door SFX — there is no door, and a jelly does not creak.
func _flow_guard(player: Node3D) -> bool:
	if _busy:
		return false
	_busy = true
	if player and player.has_method("face_toward"):
		player.face_toward(to_global(Vector3(0.0, 1.0, 0.0)))
	return true


## STEP 1 — the hand-over. ONE tap moves everything in the satchel onto the table. Gloop reacts to
## the BEST one by name, so the player learns immediately which of the night's shots was worth it.
func _hand_in() -> void:
	var carried := PrintBag.bag()
	var count := carried.size()
	var best := _best_of(carried)
	var lines: Array[String] = []
	if not GameState.flag("gloop_met"):
		GameState.set_flag("gloop_met")
		lines.append_array(GloopLines.INTRO)
	if count == 1:
		lines.append("One photo. Let me see it.")
	else:
		lines.append("%d photos! Quite a haul." % count)
	lines.append(GloopLines.take_line(PrintBag.pay_for(best), str(best.get("id", ""))))
	lines.append("\"%s\". That is the best of them." % PrintBag.label(best))
	lines.append(GloopLines.any(GloopLines.TAKE_DONE))
	PrintBag.drop_all()
	await _say(lines)
	toast("Gloop took %d print%s" % [count, "" if count == 1 else "s"], "star")
	AudioManager.play_sfx("place", -6.0)


## STEP 3 — the next morning. Coins, the best seller, and WHY it sold. The "why" is an opinion about
## the picture, which is the nudge toward tonight's shot.
func _payout() -> void:
	var sold := PrintBag.table()
	var total := 0
	for p: Dictionary in sold:
		total += PrintBag.pay_for(p)
	var best := _best_of(sold)
	var buyer: Array = GloopLines.pick(GloopLines.BUYERS, str(best.get("id", "")) + str(GameState.day_count))
	var lines: Array[String] = [GloopLines.any(GloopLines.PAYOUT_OPEN)]
	lines.append("%s. %d stardust." % ["1 picture sold" if sold.size() == 1 else "%d pictures sold" % sold.size(), total])
	lines.append("\"%s\" sold best. %s bought it." % [PrintBag.label(best), buyer[0]])
	lines.append(str(buyer[1]))
	PrintBag.clear_table()
	GameState.flags[PrintBag.PAID] = {"total": total, "best": PrintBag.label(best), "buyer": buyer[0], "day": GameState.day_count}
	GameState.add_stardust(total)
	await _say(lines)
	toast("+%d stardust from Gloop" % total, "stardust")
	AudioManager.play_sfx("pickup", -4.0)


## STEP 4 — nothing to do. One greeting, one piece of small talk, out. Never a menu.
func _idle_chat() -> void:
	var lines: Array[String] = []
	if not GameState.flag("gloop_met"):
		GameState.set_flag("gloop_met")
		lines.append_array(GloopLines.INTRO)
	else:
		lines.append(GloopLines.any(GloopLines.IDLE_GREET))
		lines.append(GloopLines.any(GloopLines.SMALL_TALK))
	await _say(lines)


func _say(lines: Array) -> void:
	await say(GloopLines.NAME, lines, GloopLines.VOICE, GloopLines.ACCENT)


static func _best_of(prints: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_pay := -1
	for p: Dictionary in prints:
		var v := PrintBag.pay_for(p)
		if v > best_pay:
			best_pay = v
			best = p
	return best


# ======================================================================================= api
## For the SKY builder and for the dev menu: put a print in the player's satchel.
static func give_print(p: Dictionary) -> void:
	PrintBag.add(p)
	EventBus.toast_requested.emit("Print: %s" % PrintBag.label(p), "star")


# ================================================================================ dev / capture
## EVERYTHING BELOW IS SYNTHETIC. These are the hooks a Director timeline uses to film the loop
## without a human at the controls; none of them goes through real input, and none of them proves
## that a finger on a phone works. They are named dev_* so that is never in doubt.
const DEV_PRINTS := [
	["Long Night over Fen", 0.82, 0.91],
	["Morning Stars, Low", 0.41, 0.74],
	["Smudge (moved)", 0.18, 0.22],
]


## Fills the satchel with `n` stub prints from DEV_PRINTS.
func dev_seed(n: int = 3) -> void:
	for i in n:
		var row: Array = DEV_PRINTS[i % DEV_PRINTS.size()]
		PrintBag.add(PrintBag.make("dev_d%d_%d" % [GameState.day_count, i], str(row[0]), float(row[1]), float(row[2]),
			"morning" if i == 1 else "night"))
	_refresh_cards()


## Stands the player `dist` metres in front of the table, FACING it, and reseats the camera behind
## them so the shot is the gameplay camera and not a stray heading.
func dev_stand_at(dist: float = 6.5, cam_dist: float = 0.0) -> void:
	var p := _player()
	if p == null or planet == null:
		return
	# THE FRAMING TOOK THREE TRIES, all measured on real frames, so do not "simplify" it back:
	#   square in front of the table  -> the astronaut's helmet sat on top of Gloop
	#   at the crate end, looking back -> the TABLE stood between the camera and Gloop
	#   diagonally outside Gloop      -> the camera clipped into a plaza prop and went dither-faded,
	#                                    and the player fell out of the interactable's 3 m reach
	var to_dir := planet.dir_of(to_global(Vector3(-1.30, 0.0, -dist)))
	var stand := planet.surface_point(to_dir)
	# Aim ACROSS the stall rather than at Gloop: the camera centres the player's helmet, so the
	# subject has to sit about 25 degrees off the forward axis to be in clear air.
	var target := to_global(Vector3(0.25, 0.60, 1.00))
	p.call("place_on_planet", to_dir, target - stand, 0.06)
	var rig := get_node_or_null("/root/World/CameraRig")
	if rig != null and rig.has_method("reseat_behind_player"):
		if cam_dist > 0.0 and rig.has_method("debug_set_framing"):
			rig.call("debug_set_framing", cam_dist, -1.0)
		rig.call("reseat_behind_player")


## Free framing for the capture sheet: stand at table-local (x, 0, z), look at table-local
## (ax, 0.6, az), camera `cam` metres back. `dev_stand_at` is the one the flow uses; this is for
## shots that need the stall seen from somewhere the player would not normally press from.
func dev_look_from(x: float, z: float, ax: float, az: float, cam: float = 4.0) -> void:
	var p := _player()
	if p == null or planet == null:
		return
	var to_dir := planet.dir_of(to_global(Vector3(x, 0.0, z)))
	var stand := planet.surface_point(to_dir)
	p.call("place_on_planet", to_dir, to_global(Vector3(ax, 0.60, az)) - stand, 0.06)
	var rig := get_node_or_null("/root/World/CameraRig")
	if rig != null and rig.has_method("reseat_behind_player"):
		if rig.has_method("debug_set_framing"):
			rig.call("debug_set_framing", cam, -1.0)
		rig.call("reseat_behind_player")


## The night passes: a new day, at half past seven in the morning.
##
## `GameState.time_of_day` alone is NOT enough and writing only it is a silent no-op: environment.gd
## keeps its own `_hour` and writes GameState back every frame from it. `Environment.set_time()` is
## the one that moves the sky.
func dev_next_day() -> void:
	GameState.day_count += 1
	var env := get_tree().root.find_child("Environment", true, false)
	if env != null and env.has_method("set_time"):
		env.call("set_time", 7.5)
	else:
		GameState.time_of_day = 7.5
	_prompt_poll = 0.0


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D
