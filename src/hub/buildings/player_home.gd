extends Building
## The player's home habitat, on the home planet. A little white dome with a band in the player's
## own accent colour, an arched door, two portholes that glow after dusk, a blinking antenna, a
## solar panel, a doormat and a mailbox with a flag.
##
## Door -> "Home sweet home!" and an offer to save the game.
## Mailbox -> a letter from Professor Comet on day one (else "No new mail"), then "Rename my
## planet" (BUILD_PLAN Phase 4 builder I) - moved here from the Town Hall, which no longer has any
## mayor duties (docs/CORE_LOOP.md "no mayor role").

const RENAME_POPUP := "res://src/hub/rename_popup.tscn"

const DRUM_R := 2.32
const DRUM_TOP := 0.86
const DOME_H := 2.42
const DOOR_W := 1.06
const DOOR_H := 1.86
const PORCH_Y := 0.22            # floor level of the entrance porch
const FACE_Z := -2.30            # front of the entrance porch
const PORCH_HW := 0.86
const PORT_Y := 1.42
const PORT_R := 0.44
const MAIL_POS := Vector3(2.30, 0.0, -2.30)
const ANTENNA_X := -1.35
const SOLAR_POS := Vector3(-2.42, 0.0, -0.85)
const HOME_ACCENT := Color("#5b7cff")

var _flag: Node3D
var _beacon: MeshInstance3D
var _mailbox: Interactable
var _accent := Color("#ff7a59")
var _sign_label: Label3D
var _rename_popup: Node


func _init() -> void:
	building_id = "player_home"
	display_name = "Home"
	ground_sink = 0.20
	ground_radius = 16.0
	door_local = Vector3(0.0, 0.35, FACE_Z - 1.05)
	door_prompt = "Home"


func _footprint_shapes() -> Array:
	return [
		[Building.cyl_shape(DRUM_R + 0.10, 3.2), Vector3(0.0, 1.5, 0.0)],
		[_box(Vector3(PORCH_HW * 2.0 + 0.2, 2.4, 1.1)), Vector3(0.0, 1.2, -1.85)],
		Building.step_block(2.0, FACE_Z, -3.25, 0.5),
		[Building.cyl_shape(0.30, 1.6), Vector3(MAIL_POS.x, 0.7, MAIL_POS.z)],
	]


func _box(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


# R2.9: the habitat's shell is the largest single surface the player ever stands next to, so it is
# the one that most needed this. It is PANELLED METAL - a soft travelling sheen, brushed grain up
# close, and cylindrical seams round its own +Y axis: rings every 0.71 m and 12 gores, one between
# each pair of the six meridian ribs already modelled, so the seams reinforce the ribs instead of
# fighting them. The seams fade where the surface faces along the axis, which is what stops the 12
# gores converging into moire at the crown.
const SHELL_OPTS := {
	"seam_mode": 2, "pitch_a": 1.4, "gores": 12.0, "seam_strength": 0.9,
	"seam_far": 40.0, "macro_scale": 2.4, "macro_amount": 0.42,
}


func _build() -> void:
	_accent = Color(str(GameState.player_style.get("accent_color", "#ff7a59")))
	var kit := DecoKit.new()        # buried stone apron and the doorstep
	var shell := DecoKit.new()      # the panelled habitat: drum, dome, accent band, porch, hatch
	var wood := DecoKit.new()       # the door leaf and the mailbox post
	var metal := DecoKit.new()      # porthole rings, mullions, the solar frame, sign hardware
	var deco := DecoKit.new()       # planters, the doormat, the solar cells
	_build_shell(kit, shell)
	_build_front(shell, wood, metal, deco)
	_build_yard(metal, deco)
	add_wall(kit.commit(), "Apron")
	add_panel(shell.commit(), "Habitat", SHELL_OPTS)
	add_wood(wood.commit(), Vector3.UP, "Timber")
	add_metal(metal.commit(), "Fittings")
	add_body(deco.commit(), "Props")
	_build_antenna()
	_build_mailbox()
	_build_glow()
	animate()


func _build_shell(kit: DecoKit, shell: DecoKit) -> void:
	# buried apron ring, then the drum and the dome
	kit.cone(Vector3(0.0, -0.72, 0.0), DRUM_R + 0.30, DRUM_R + 0.20, 0.86, STONE_DEEP, Basis.IDENTITY, 26)
	kit.torus(Vector3(0.0, 0.10, 0.0), DRUM_R + 0.18, 0.09, STONE, Basis.IDENTITY, 26)
	shell.cone(Vector3(0.0, 0.02, 0.0), DRUM_R + 0.04, DRUM_R, DRUM_TOP, CREAM_LIT, Basis.IDENTITY, 26)
	# accent band: the player's own colour, wrapped round the base like an AC roof stripe
	shell.cone(Vector3(0.0, 0.02, 0.0), DRUM_R + 0.07, DRUM_R + 0.05, 0.42, _accent, Basis.IDENTITY, 26)
	shell.torus(Vector3(0.0, 0.45, 0.0), DRUM_R + 0.06, 0.045, CREAM_LIT, Basis.IDENTITY, 26)
	shell.dome(Vector3(0.0, DRUM_TOP, 0.0), DRUM_R, Color("#e7dfd0"), DOME_H / DRUM_R, Basis.IDENTITY, 26)
	# six meridian seams so the dome is a built habitat, not a bubble
	for i in 6:
		var a := TAU * float(i) / 6.0
		var prev := Vector3(sin(a) * DRUM_R, DRUM_TOP, cos(a) * DRUM_R)
		for s in range(1, 6):
			var t := PI * 0.5 * float(s) / 5.0
			var rr := DRUM_R * cos(t) * 1.006
			var p := Vector3(sin(a) * rr, DRUM_TOP + sin(t) * DOME_H * 1.004, cos(a) * rr)
			shell.bar(prev, p, 0.032, CREAM_DEEP, 5)
			prev = p
	shell.torus(Vector3(0.0, DRUM_TOP + 0.03, 0.0), DRUM_R * 0.995, 0.05, CREAM_DEEP, Basis.IDENTITY, 26)
	# hatch cap on the crown
	shell.cone(Vector3(0.0, DRUM_TOP + DOME_H - 0.10, 0.0), 0.36, 0.30, 0.20, _accent, Basis.IDENTITY, 16)
	shell.torus(Vector3(0.0, DRUM_TOP + DOME_H + 0.08, 0.0), 0.30, 0.045, CREAM_DEEP, Basis.IDENTITY, 16)


func _build_front(kit: DecoKit, wood: DecoKit, metal: DecoKit, deco: DecoKit) -> void:
	# a small entrance porch so the door is a real doorway and not a decal on a sphere
	kit.rbox(Vector3(0.0, PORCH_Y + 1.10, -1.85), Vector3(PORCH_HW * 2.0, 2.20, 1.05), 0.22, CREAM_LIT, Basis.IDENTITY, 1)
	kit.rbox(Vector3(0.0, PORCH_Y + 2.26, -1.85), Vector3(PORCH_HW * 2.0 + 0.28, 0.18, 1.30), 0.05, _accent, Basis.IDENTITY, 0)
	build_door(kit, Vector3(0.0, PORCH_Y, FACE_Z), DOOR_W, DOOR_H, CREAM_LIT.lightened(0.16), Color("#b9825a"), WOOD_DARK, wood, metal)
	build_steps(kit, 1.80, FACE_Z, 0.80, PORCH_Y, 0.14)
	# doormat, sunk into the top step
	deco.rbox(Vector3(0.0, PORCH_Y + 0.02, FACE_Z + 0.30), Vector3(1.10, 0.05, 0.58), 0.02, _accent.darkened(0.30), Basis.IDENTITY, 0)
	deco.rbox(Vector3(0.0, PORCH_Y + 0.045, FACE_Z + 0.30), Vector3(0.94, 0.03, 0.44), 0.015, Color("#e3d6bb"), Basis.IDENTITY, 0)
	for i in 3:
		deco.rbox(Vector3(-0.28 + float(i) * 0.28, PORCH_Y + 0.06, FACE_Z + 0.30), Vector3(0.045, 0.02, 0.38), 0.008, _accent.darkened(0.15), Basis.IDENTITY, 0)

	# two brass-ringed portholes flanking the porch
	for s in [-1.0, 1.0]:
		var px: float = 1.32 * s
		var pz: float = -sqrt(maxf(DRUM_R * DRUM_R - px * px, 0.04))
		var yaw := Basis(Vector3.UP, atan2(px, pz))
		metal.lathe(PackedVector2Array([Vector2(PORT_R, 0.0), Vector2(PORT_R + 0.13, 0.02), Vector2(PORT_R + 0.14, 0.12),
				Vector2(PORT_R + 0.01, 0.17), Vector2(PORT_R - 0.02, 0.09)]),
				20, Transform3D(yaw * Basis(Vector3.RIGHT, -PI * 0.5), Vector3(px, PORT_Y, pz)), _accent.darkened(0.10))
		deco.disc(Vector3(px, PORT_Y, pz) + yaw * Vector3(0.0, 0.0, -0.06), PORT_R, Color("#494560"),
				yaw * Basis(Vector3.RIGHT, -PI * 0.5), 20)
		for k in 2:
			metal.rbox(Vector3(px, PORT_Y, pz) + yaw * Vector3(0.0, 0.0, -0.10), Vector3(PORT_R * 2.0, 0.045, 0.045), 0.014,
					CREAM_DEEP, yaw * Basis(Vector3.FORWARD, PI * 0.5 * float(k)), 0)

	# hanging sign with the planet's name - kept live so a rename at the mailbox (this same visit,
	# no reload) shows up on the sign right away instead of waiting for the next planet load.
	var plate := build_hanging_sign(kit, Vector3(0.0, PORCH_Y + 3.02, -1.60), 1.76, 0.52, CREAM_LIT, WOOD, 0.62, 0.20, wood, metal)
	_sign_label = add_label(GameState.home_planet_name, plate + Vector3(0.0, 0.0, -0.14), 0.21)
	set_meta("sign_plate", plate)


func _build_yard(kit: DecoKit, deco: DecoKit) -> void:
	build_planter(deco, Vector3(-1.55, ground_y(2.7) - 0.02, -2.20), 0.92)
	build_planter(deco, Vector3(1.52, ground_y(2.7) - 0.02, -2.24), 0.85, TERRACOTTA.darkened(0.08))
	# a tiny solar panel on a tilted frame
	var sp := Vector3(SOLAR_POS.x, ground_y(Vector2(SOLAR_POS.x, SOLAR_POS.z).length()) - 0.02, SOLAR_POS.z)
	var yaw := Basis(Vector3.UP, deg_to_rad(34.0))
	for s in [-1.0, 1.0]:
		kit.cone(sp + yaw * Vector3(0.42 * s, 0.0, 0.0), 0.075, 0.055, 0.72, METAL_DARK, Basis.IDENTITY, 10)
	var tilt := yaw * Basis(Vector3.RIGHT, deg_to_rad(-34.0))
	kit.rbox(sp + Vector3(0.0, 0.86, 0.0), Vector3(1.24, 0.09, 0.86), 0.03, METAL, tilt, 0)
	deco.rbox(sp + Vector3(0.0, 0.90, 0.0), Vector3(1.10, 0.04, 0.72), 0.015, Color("#2c3c66"), tilt, 0)
	for i in 3:
		deco.rbox(sp + Vector3(0.0, 0.925, 0.0) + tilt * Vector3(-0.36 + float(i) * 0.36, 0.0, 0.0),
				Vector3(0.025, 0.02, 0.70), 0.008, Color("#6f86bd"), tilt, 0)


func _build_antenna() -> void:
	var base := Vector3(ANTENNA_X, DRUM_TOP + sqrt(maxf(DOME_H * DOME_H * (1.0 - (ANTENNA_X / DRUM_R) ** 2), 0.0)) - 0.15, 0.10)
	var kit := DecoKit.new()
	kit.cone(base, 0.085, 0.05, 1.30, METAL, Basis.IDENTITY, 10)
	kit.torus(base + Vector3(0.0, 0.42, 0.0), 0.11, 0.03, METAL_DARK, Basis.IDENTITY, 12)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.16, 0.03), Vector2(0.30, 0.13), Vector2(0.32, 0.15),
			Vector2(0.20, 0.08), Vector2(0.0, 0.02)]),
			16, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-32.0)), base + Vector3(0.0, 1.34, 0.0)), Color("#e7dfd0"))
	add_metal(kit.commit(), "Antenna")
	var b := DecoKit.new()
	b.sphere(base + Vector3(0.0, 1.52, 0.0), 0.085, Color("#ff5c5c"), Vector3.ONE, 10)
	_beacon = add_glow(b.commit(), 3.0, "Beacon", 1.6, 0.7)


func _build_mailbox() -> void:
	var base := Vector3(MAIL_POS.x, ground_y(Vector2(MAIL_POS.x, MAIL_POS.z).length()) - 0.02, MAIL_POS.z)
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.26, 0.0), Vector2(0.23, 0.08), Vector2(0.10, 0.13), Vector2(0.0, 0.14)]),
			16, Transform3D(Basis.IDENTITY, base), STONE_DEEP)
	add_wall(kit.commit(), "MailboxBase")
	# the post is a turned timber; the box is painted sheet
	var pk := DecoKit.new()
	pk.cone(base + Vector3(0.0, 0.10, 0.0), 0.075, 0.06, 0.92, WOOD_DARK, Basis.IDENTITY, 10)
	add_wood(pk.commit(), Vector3.UP, "MailboxPostMesh")
	var bk := DecoKit.new()
	bk.rbox(base + Vector3(0.0, 1.20, 0.0), Vector3(0.46, 0.42, 0.72), 0.16, _accent, Basis.IDENTITY, 1)
	bk.rbox(base + Vector3(0.0, 1.20, -0.36), Vector3(0.36, 0.30, 0.06), 0.05, CREAM_LIT, Basis.IDENTITY, 0)
	bk.sphere(base + Vector3(0.0, 1.06, -0.40), 0.045, GOLD, Vector3.ONE, 8)
	add_panel(bk.commit(), "MailboxBox", {"pitch_a": 2.6, "pitch_b": 1.6, "seam_strength": 0.6})
	# the little flag, raised when there is unread mail
	_flag = pivot("MailFlag", base + Vector3(0.26, 1.06, 0.0))
	var fk := DecoKit.new()
	fk.cone(Vector3(0.0, 0.0, 0.0), 0.026, 0.022, 0.42, Color("#e0e5ee"), Basis.IDENTITY, 8)
	fk.rbox(Vector3(0.10, 0.34, 0.0), Vector3(0.22, 0.16, 0.02), 0.02, Color("#e04a4a"), Basis.IDENTITY, 0)
	add_metal(fk.commit(), "FlagMesh", _flag)
	_refresh_flag()


func _build_glow() -> void:
	var panes := DecoKit.new()
	for s in [-1.0, 1.0]:
		var px: float = 1.32 * s
		var pz: float = -sqrt(maxf(DRUM_R * DRUM_R - px * px, 0.04))
		var yaw := Basis(Vector3.UP, atan2(px, pz))
		panes.disc(Vector3(px, PORT_Y, pz) + yaw * Vector3(0.0, 0.0, -0.055), PORT_R - 0.04, WINDOW_WARM,
				yaw * Basis(Vector3.RIGHT, -PI * 0.5), 20)
	add_glow(panes.commit(), 2.2, "Portholes", 0.0, 0.0, 1.0)
	# both lamps sit inside the shell / porch geometry (see Building.add_light)
	for s in [-1.0, 1.0]:
		var px: float = 1.32 * s
		var pz: float = -sqrt(maxf(DRUM_R * DRUM_R - px * px, 0.04)) + 0.78
		add_light(Vector3(px, PORT_Y, pz), Color("#ffdcab"), 1.3, 5.5)
	add_light(Vector3(0.0, PORCH_Y + 1.40, -1.85), Color("#ffe3b8"), 1.3, 5.5)


func _animate(t: float, _delta: float) -> void:
	if _flag:
		# flag UP when there is unread mail, folded down once it has been read
		var want: float = 0.0 if _has_mail() else -1.25
		_flag.rotation.z = lerpf(_flag.rotation.z, want, 0.08)
	if _beacon:
		_beacon.rotation.y = t * 0.4


func _refresh_flag() -> void:
	if _flag:
		_flag.rotation.z = 0.0 if _has_mail() else -1.25


func _has_mail() -> bool:
	return not GameState.flag("mail_day1_read")


# ----------------------------------------------------------------------------- interaction
func _ready() -> void:
	super()
	var base_y := ground_y(Vector2(MAIL_POS.x, MAIL_POS.z).length())
	# NOT "Mailbox": a mailbox MESH used to own that name on this node, so Godot silently renamed
	# the Interactable to `@Area3D@128` and nothing could address it by name (integration critic).
	#
	# Reach 2.05, pulled in from 2.3, and the anchor dropped from +1.15 m to +0.80 m. Both numbers
	# matter, because Player._update_interact_target measures from the player's FEET to the anchor
	# and then takes the NEAREST candidate: at +1.15 m even a 1.2 m approach measures 1.5 m, so a
	# reach much tighter than this drops the mailbox out of the running entirely and hands the
	# player to the door instead. As set, standing at the post measures ~1.45 m to the mailbox
	# against ~1.95 m to the door (the mailbox wins), and standing at the door measures ~2.4 m to
	# the mailbox, which is outside its reach (the door wins). The old 2.3 m reach on a +1.15 m
	# anchor overlapped the door's zone from every angle.
	_mailbox = add_interactable("MailboxPost", Vector3(MAIL_POS.x, base_y + 0.80, MAIL_POS.z - 0.20),
		"Mail", 2.05, _on_mail)


func _on_door(player: Node3D) -> void:
	if not begin_flow(player):
		return
	await say(GameState.player_style.get("name", "Astro"), [
		"Home sweet home. Boots off, helmet on the hook.",
		"The porthole looks straight out at Zorp's world.",
	], "astro", HOME_ACCENT)
	# A LOOP, like the mailbox's: with two things to do at the door ("Save game" and, until the
	# planet is at its biggest, "Make my planet bigger") a single question would make the player walk
	# back to the door to do the second one.
	while true:
		var opts: Array = ["Save game"]
		var grow_idx := -1
		if not GameState.home_size_at_max():
			grow_idx = opts.size()
			# 33 characters at the widest price, inside the 60 a phone line holds.
			opts.append("Make my planet bigger (%d scrap)" % GameState.home_size_cost())
		opts.append("Just looking")
		var choice: int = await ask("Anything else?", opts)
		if choice == 0:
			var ok: bool = SaveManager.save_game()
			if ok:
				toast("Saved!", "stardust")
				AudioManager.play_sfx("quest_complete", -6.0)
			else:
				toast("Could not save.", "warn")
		elif choice == grow_idx and grow_idx >= 0:
			if await _grow_flow():
				break   # the planet just moved: close the box so the player can look at it
		else:
			break
	AudioManager.play_sfx("door_close", -8.0)
	end_flow()


# ----------------------------------------------------------------------- make my planet bigger
## STYLE_GUIDE R2.11 / docs/OPEN_ISSUES.md 66. The pieces have been in the game since R2.11 and
## nothing ever wrote to them: PlanetData.HOME_RADII is the table of sizes, GameState.home_planet_size
## is the saved index into it, and Planet.regrow() moves the live world onto the new ground. This is
## the one place that spends the scrap and pulls the lever.
##
## Returns true when the planet actually grew, which closes the door menu so the first thing the
## player sees afterwards is their bigger world rather than another dialogue box.
func _grow_flow() -> bool:
	var cost := GameState.home_size_cost()
	var next_level := GameState.home_planet_size + 1
	var from_m := PlanetData.home_radius_for_level(GameState.home_planet_size)
	var to_m := PlanetData.home_radius_for_level(next_level)
	if not GameState.can_afford_scrap(cost):
		await say(_who(), [
			"Pushing the ground out costs %d scrap." % cost,
			"I have %d. Not yet, then." % GameState.scrap,
			"Shards and space junk both pay in scrap.",
		], "astro", HOME_ACCENT)
		return false
	var lines: Array = [
		"I could push the ground out a bit.",
		"From %d metres of world to %d." % [int(from_m), int(to_m)],
		"More room for trees, plants and my things.",
		"It costs %d scrap. I have %d." % [cost, GameState.scrap],
	]
	if next_level >= GameState.home_size_max():
		lines.append("That is as big as this planet gets.")
	await say(_who(), lines, "astro", HOME_ACCENT)
	var yes: int = await ask("Grow the planet for %d scrap?" % cost, ["Yes please", "Not now"])
	if yes != 0:
		return false
	if not GameState.grow_home():
		toast("Could not grow the planet.", "warn")
		return false
	AudioManager.play_sfx("quest_complete", -3.0)
	var r := _regrow_planet()
	toast("Your planet grew to %d metres!" % int(to_m if r <= 0.0 else r), "scrap")
	return true


## Grows the LIVE world to the size GameState now holds. Guarded on "home" because `regrow()` frees
## and rebuilds the collectibles, and on any world with neighbours that could drop a favour's
## fetch target (favor_system only ever spawns those on an NPC's own planet, never here).
func _regrow_planet() -> float:
	var p := get_tree().get_first_node_in_group("planet") as Planet
	if p == null or p.data == null or p.data.id != "home":
		return 0.0
	return p.regrow()


func _who() -> String:
	return str(GameState.player_style.get("name", "Astro"))


func _on_mail(player: Node3D) -> void:
	if not begin_flow(player):
		return
	if _has_mail():
		GameState.set_flag("mail_day1_read")
		AudioManager.play_sfx("pickup", -5.0)
		# From Professor Comet, the sky-watching scientist - not a mayor (docs/CORE_LOOP.md, "Changed
		# after the build plan"), so no Town Hall and no plot deeds. A new game is the Stranded campaign,
		# which opens with your ship crash-landing here, so the letter is his note that he saw it come
		# down. Changed by the lead after Phase 1 builder C listed this string but did not own the file.
		# Lines kept to 48 characters or fewer, the longest line the old letter used.
		await say("A letter from Professor Comet", [
			"Dear neighbour,",
			"I saw your ship come down on my telescope.",
			"Nobody hurt - that is what matters!",
			"Your rocket can still hop to nearby worlds.",
			"  - Professor Comet",
		], "elder", Color("#6fc3ff"))
		_refresh_flag()
	else:
		await say("Mailbox", ["No new mail. The flag is down."], "astro", HOME_ACCENT)
	# "Rename my planet" moved here from the Town Hall (BUILD_PLAN Phase 4 builder I): the mayor's
	# door duties are gone, and the mailbox is the one place on your own planet you already read
	# your planet's name off, on the hanging sign right above it.
	while true:
		var choice: int = await ask("Anything else?", ["Rename my planet", "Leave"])
		if choice == 0:
			await _rename_flow()
		else:
			break
	end_flow()


## Same rename popup and flow the Town Hall used to run, moved to the mailbox. `_sign_label` lets
## the hanging sign pick up the new name immediately, in this same visit, with no planet reload.
func _rename_flow() -> void:
	var popup := _get_rename_popup()
	if popup == null:
		await say("Mailbox", ["The rename form seems to be missing. Try again later!"], "astro", HOME_ACCENT)
		return
	var new_name: String = await popup.ask(GameState.home_planet_name)
	if new_name == "" or new_name == GameState.home_planet_name:
		await say("Mailbox", ["Keeping the old name, then."], "astro", HOME_ACCENT)
		return
	_apply_rename(new_name)
	await say("Mailbox", ["Renamed! Welcome home to %s." % new_name], "astro", HOME_ACCENT)


## Everything a rename actually changes, split out from the popup/dialogue steps above so it can be
## called (and verified) on its own: the save data, the toast + sfx, and the sign mesh in this same
## visit. `_sign_label` may be null if this is ever called before `_build()` has run.
func _apply_rename(new_name: String) -> void:
	GameState.home_planet_name = new_name
	if _sign_label:
		_sign_label.text = new_name
	toast("Your planet is now %s!" % new_name, "stardust")
	AudioManager.play_sfx("quest_complete", -4.0)


func _get_rename_popup() -> Node:
	if _rename_popup != null and is_instance_valid(_rename_popup):
		return _rename_popup
	if not ResourceLoader.exists(RENAME_POPUP):
		return null
	var hud := get_node_or_null("/root/World/HUD")
	_rename_popup = load(RENAME_POPUP).instantiate()
	if hud:
		hud.add_child(_rename_popup)
	else:
		get_tree().root.add_child(_rename_popup)
	return _rename_popup
